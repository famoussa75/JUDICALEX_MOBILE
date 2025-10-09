import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';

import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../db/base_sqlite.dart';
import '../../widget/user_provider.dart';
import '../API/api.new.dart'; // pour formater la date

class Newsdetail extends StatefulWidget {

  final dynamic post;
  const Newsdetail({super.key, required this.post});

  @override
  State<Newsdetail> createState() => _NewsdetailState();
}

class _NewsdetailState extends State<Newsdetail> {

  var logger = Logger();

  List<dynamic> comments = [];

  List<dynamic> headerAds = [];

  late PageController _pageControllerHeader;
  int _currentPagePubHeader = 0;
  Timer? _timerheader;

  // Instance de l'API
  final NewsApi _newsApi = NewsApi();
  List<dynamic> post = [];
  List<Map<String, dynamic>> shuffledPosts = [];

  bool _isSending = false;

  bool _isRefreshing = false;

  void _fetchData() async {
    await fetchPosts().then((_) {
      setState(() {
        shuffledPosts = List<Map<String, dynamic>>.from(post)..shuffle();
      });
    });
    fetchAds();
  }

  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
    });
    try {
      final posts = await _newsApi.fetchPosts();
      setState(() {
        post = posts;
        isLoading = false;
      });

      for (var item in posts) {
        /// logger.w(item);
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      logger.e('Erreur : $error');
    }
  }

  Future<void> _refreshPage() async {
    setState(() {
      _isRefreshing = true;
    });

    // Recharger les posts et mettre à jour la page
    final updatedPosts = await _newsApi.fetchPosts();
    setState(() {
      post = updatedPosts;
      shuffledPosts = List<Map<String, dynamic>>.from(post)..shuffle();
    });

    await fetchPosts();
    shuffledPosts.shuffle();

    setState(() {
      _isRefreshing = false;
    });
  }

  Set<int> _commentVisible = {};
  Map<int, TextEditingController> _controllers = {};

  Future<void> envoyerCommentaire(int userId, int postId, String comment) async {
    try {
      final success = await _newsApi.envoyerCommentaire(userId, postId, comment);
      if (success) {
        // 1️⃣ Vider le TextEditingController du post
        _controllers[postId]!.clear();
        // 2️⃣ Masquer le champ commentaire
        setState(() => _commentVisible.remove(postId));
        // 3️⃣ Afficher un message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Commentaire envoyé avec succès !',
              style: TextStyle(
                color: Colors.white, // couleur du texte
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green, // couleur de fond du SnackBar
            behavior: SnackBarBehavior.floating, // joli effet flottant
            margin: EdgeInsets.all(12), // petit espace autour
            duration: Duration(seconds: 3), // durée d'affichage
          ),
        );
        // 4️⃣ Recharger les posts et mettre à jour la page
        final updatedPosts = await _newsApi.fetchPosts();
        setState(() {
          post = updatedPosts;
          shuffledPosts = List<Map<String, dynamic>>.from(post)..shuffle();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }



  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0, viewportFraction: 0.9);
    comments = widget.post["comments"] ?? [];
    _loadDomain();
    fetchAds();

    /// header
    _pageControllerHeader = PageController(viewportFraction: 0.9); // 70% largeur

    // Timer auto-scroll toutes les 10s
    _timerheader = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_pageControllerHeader.hasClients) {
        if (_currentPagePubHeader < headerAds.length - 1) {
          _currentPagePubHeader++;
        } else {
          _currentPagePubHeader = 0;
        }
        _pageControllerHeader.animateToPage(
          _currentPagePubHeader,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    ///header
    _timerheader?.cancel();          // <- stoppe le Timer d’abord
    _pageControllerHeader.dispose(); // <- puis libère le contrôleur
  }

  String parseHtmlString(String htmlString) {
    final document = html_parser.parse(htmlString);
    return document.body?.text ?? '';
  }

  late final PageController _controller;
  int _currentPage = 0;

  Future<String> generateArticleUrl(String slug) async {
    // Récupérer le nom de domaine depuis la base de données
    String? domainName = await DatabaseHelper().getDomainName();

    // Assurez-vous que le nom de domaine ne se termine pas par un slash
    if (domainName != null && domainName.endsWith('/')) {
      domainName = domainName.substring(0, domainName.length - 1);
    }
    return '$domainName/blog/post/$slug/';
  }

  String? domainName;
  Future<void> _loadDomain() async {
    final dbHelper = DatabaseHelper();
    final name = await dbHelper.getDomainName();
    setState(() {
      domainName = name;
      isLoading = false;
    });
  }

  Future<void> fetchAds() async {
    try {
      String? domainName = await DatabaseHelper().getDomainName();
      if (domainName != null && domainName.isNotEmpty) {

        // Supprimer 'https://' ou 'http://' du domaine s'il est déjà présent
        if (domainName.startsWith('http://')) {
          domainName = domainName.replaceFirst('http://', '');
        } else if (domainName.startsWith('https://')) {
          domainName = domainName.replaceFirst('https://', '');
        }
        // Retirer le préfixe "http://" ou "https://"
        domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
        domainName = domainName.endsWith('/')
            ? domainName.substring(0, domainName.length - 1)
            : domainName;

        final apiUrl = Uri.https(domainName, "/api/ads/");
        final response = await http.get(apiUrl);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData =
          json.decode(utf8.decode(response.bodyBytes));

          // 🧩 Vérification avant d'appeler setState
          if (!mounted) return;

          setState(() {
            headerAds = jsonData["header"] ?? [];
            ///sidebarAds = jsonData["sidebar"] ?? [];
          });

          // 🔹 Log uniquement les pubs header
          for (var ad in headerAds) {
            /// logger.w("Header Ad: $ad");
          }
          /*
          // 🔹 Log uniquement les pubs sidebar
          for (var ad in sidebarAds) {
            /// logger.w("Sidebar Ad: $ad");
          }

           */
        }else {
          // throw Exception('Erreur lors de la récupération des données: ${response.statusCode}');
          throw Exception('Erreur lors de la récupération des données');
        }
      }
    } catch (e) {
      logger.e("Erreur fetchAds: $e");
    }
  }





  String formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(dateTime); // jour/mois/année
    } catch (e) {
      return dateString; // si erreur de parsing, on retourne brut
    }
  }

  bool isLoading = true;





  @override
  Widget build(BuildContext context) {

    final user = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        iconTheme: const  IconThemeData(color:Colors.white),
        centerTitle: true,
        title: const Text("Détails",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.white),), // Afficher le titre dans l'AppBar
        toolbarHeight: 60,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            margin :const EdgeInsets.all(13.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20,),
            SizedBox(
              height: 240,
              child: headerAds.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageControllerHeader,
                    itemCount: headerAds.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final ad = headerAds[index];
                      final rawImage = ad["image"] ?? "";

                      final imageUrl = rawImage.startsWith("http")
                          ? rawImage
                          : "https://${domainName?.replaceAll(RegExp(r'^https?://'), '')}${rawImage.startsWith("/") ? rawImage : "/$rawImage"}";

                      return GestureDetector(
                        onTap: () => launchUrl(Uri.parse(ad["link"])),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.white,
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                    child: Icon(Icons.broken_image,
                                        size: 48, color: Colors.grey));
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Indicateurs de page
                  Positioned(
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(headerAds.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 14 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i ? Colors.blueAccent : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20,),
                Text(
                  widget.post['title'] ?? 'Pas de titre ',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 10),
                // Affichage de l'image si elle existe (en dessous de la description)
                widget.post['image'] != null
                    ? Image.network(
                  widget.post['image'], // URL de l'image
                  width: double.infinity,
                  fit: BoxFit.cover, // Adapter l'image au conteneur
                )
                    : Container(), // Si aucune image n'est fournie
                const SizedBox(height: 10,),
                Text(
                  parseHtmlString(widget.post['content'] ?? 'Pas de description'),
                  style: const  TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 30,),
                // juste après la ListView.builder des commentaires
                const SizedBox(height: 20),

// Champ pour écrire un commentaire
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controllers[widget.post['id']] ??= TextEditingController(),
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Écrire un commentaire...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isSending
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.send, color: Colors.blue),
                      onPressed: _isSending
                          ? null // désactive le bouton pendant l'envoi
                          : () async {
                        final text = _controllers[widget.post['id']]?.text ?? '';
                        if (text.trim().isEmpty) return;

                        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
                        if (user != null) {
                          setState(() => _isSending = true); // ⬅ démarre l’indicateur

                          try {
                            await envoyerCommentaire(user.id, widget.post['id'], text);

                            // Mettre à jour directement la liste des commentaires
                            setState(() {
                              comments.insert(0, {
                                'user': user.id,
                                'content': text,
                                'created_at': DateTime.now().toIso8601String(),
                              });
                              _controllers[widget.post['id']]?.clear();
                            });
                          } finally {
                            setState(() => _isSending = false); // ⬅ stop l’indicateur
                          }
                        }
                      },
                    ),

                  ],
                ),
                const SizedBox(height: 20,),
                const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mode_comment_sharp),
                        SizedBox(width: 10,),
                        Text("Commentaires",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),)
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20,),
                comments.isNotEmpty
                ?ListView.builder(
                  shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder:(context, index ){
                    final comment = comments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // ⚡️ aligner à gauche
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child:Icon(
                                    Icons.person,size: 30,
                                  )
                                ),
                                const SizedBox(width: 4), // ⚡️ petit espace entre prénom et nom
                                Flexible(
                                  child: Text(
                                    comment["user_first_name"] ?? " ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4), // ⚡️ petit espace entre prénom et nom
                                Flexible(
                                  child: Text(
                                    comment["user_last_name"] ?? " ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    comment["content"] ?? "",
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        trailing: () {
                          // Affiche les IDs dans la console pour debug
                          ///print("ID utilisateur connecté: ${user?.id}");
                          ///print("ID auteur du commentaire: ${comment["user"]}");

                          // Affiche le menu seulement si l'utilisateur est l'auteur
                          if (user?.id == comment["user"]) {
                            return PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'modifier') {
                                  // Appeler la fonction de modification
                                } else if (value == 'supprimer') {
                                  // Appeler la fonction de suppression
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'modifier',
                                  child: Text('Modifier'),
                                ),
                                const PopupMenuItem(
                                  value: 'supprimer',
                                  child: Text('Supprimer'),
                                ),
                              ],
                            );
                          } else {
                            return null;
                          }
                        }(), // <-- on exécute la fonction immédiatement
                        subtitle: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            formatDate(comment["created_at"]),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                    }
                ) : const Text("Auccun Commentaire Disponible."),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
