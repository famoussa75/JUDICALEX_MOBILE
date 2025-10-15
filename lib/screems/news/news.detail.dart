import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
///import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../db/base_sqlite.dart';
import '../../widget/user_provider.dart';
import '../API/api.new.dart'; // pour formater la date
import 'dart:io';
import 'package:path_provider/path_provider.dart';



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

  /*

  void _fetchData() async {
    await fetchPosts().then((_) {
      setState(() {
        shuffledPosts = List<Map<String, dynamic>>.from(post)..shuffle();
      });
    });
    fetchAds();
  }

   */

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

  Future<void> fetchComments(int postId) async {
    if (domainName == null || domainName!.isEmpty) return;
    try {
      String? domainName = await DatabaseHelper().getDomainName();
      if (domainName == null || domainName.isEmpty) {
        throw Exception('Nom de domaine non défini ou vide.');
      }
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final apiUrl = Uri.https(domainName,"/api/posts/$postId/comments/list/");
      final response = await http.get(apiUrl);

      logger.i('📡 Chargement des commentaires depuis : $apiUrl');


      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Si l’API renvoie un objet et non une liste
        List<dynamic> commentList;
        if (data is Map && data['comments'] != null) {
          commentList = data['comments'];
        } else if (data is List) {
          commentList = data;
        } else {
          commentList = [];
        }


        if (!mounted) return;

        setState(() {
          comments = commentList;
        });

        logger.i('✅ ${comments.length} commentaires chargés');
      } else {
        logger.e('❌ Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      logger.e('💥 Erreur fetchComments: $e');
    }
  }

  Future<void> modifierCommentaire(int commentId,int userId, String nouveauContenu) async {
    try {

      // 2️⃣ Récupérer le token de l'utilisateur
      String? token = await DatabaseHelper().getUserToken(userId.toString());
      String? domainName = await DatabaseHelper().getDomainName();
      if (domainName == null || domainName.isEmpty) throw Exception("Nom de domaine non défini");

      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final apiUrl = Uri.https(domainName, "/api/comments/$commentId/update/");

      // Corps de la requête
      final body = json.encode({
        "content": nouveauContenu,
      });

      final response = await http.put(
        apiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token', // si ton API utilise un token
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ///print("✅ Commentaire modifié avec succès !");
       /// print("Réponse de l'API : ${response.body}");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Commentaire modifié avec succès !',
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Erreur lors de la modification ',
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
       // print("❌ Erreur lors de la modification : ${response.statusCode}");
        //print("Détails : ${response.body}");
      }
    } catch (e) {
      ///print("💥 Exception modifierCommentaire : $e");
      ///logger.w("Header Ad: $ad");
      //           }

      logger.w("💥 Exception modifierCommentaire :");
    }
  }

  Future<void> supprimerCommentaire(int commentId, int userId) async {
    try {
      // Récupérer le token
      String? token = await DatabaseHelper().getUserToken(userId.toString());
      String? domainName = await DatabaseHelper().getDomainName();
      if (domainName == null || domainName.isEmpty) throw Exception("Nom de domaine non défini");

      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final apiUrl = Uri.https(domainName, "/api/comments/$commentId/delete/");

      final response = await http.delete(
        apiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Commentaire supprimé avec succès !',
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
       /// print("✅ Commentaire supprimé avec succès !");
        /// Supprimer localement pour mise à jour instantanée
        setState(() {
          comments.removeWhere((c) => c["id"] == commentId);
        });
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Erreur lors de la suppression ',
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

      ///  print("❌ Erreur lors de la suppression : ${response.statusCode}");
       /// print("Détails : ${response.body}");
      }
    } catch (e) {
      logger.w("💥 Exception supprimerCommentaire :");
     /// print("💥 Exception supprimerCommentaire : $e");
    }
  }




  @override
  void initState() {
    super.initState();

    _controller = PageController(initialPage: 0, viewportFraction: 0.9);
    comments = widget.post["comments"] ?? [];

    // Charger le domaine et les ads
    _loadDomainAndAds();

    // Recharge les commentaires dès que la page est affichée
    if (widget.post['id'] != null) {
      fetchComments(widget.post['id']);
    }
    // Header
    _pageControllerHeader = PageController(viewportFraction: 0.9);

    // Timer auto-scroll
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

// Méthode async séparée
  Future<void> _loadDomainAndAds() async {
    await _loadDomain();
    await fetchAds();

    if (widget.post['id'] != null) {
      await fetchComments(widget.post['id']);
    }
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
                SizedBox(
                  height: 200,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔹 Bouton de partage
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.blue),
                      onPressed: () async {
                        try {
                          // 🔹 1. Génère le lien de l’article
                          final String articleUrl = await _newsApi.generateArticleUrl(widget.post['slug']);

                          // 🔹 2. Récupère l’URL de l’image de l’article
                          final String imageUrl = widget.post['image']; // ex: "https://judicalex-gn.org/media/articles/img1.jpg"

                          // 🔹 3. Télécharge l’image temporairement
                          final response = await http.get(Uri.parse(imageUrl));
                          final tempDir = await getTemporaryDirectory();
                          final file = File('${tempDir.path}/article_image.jpg');
                          await file.writeAsBytes(response.bodyBytes);

                          // 🔹 4. Partage l’image + le texte du lien
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text: 'Découvrez cet article : $articleUrl',
                          );
                        } catch (e) {
                          print('Erreur lors du partage : $e');
                        }
                      },
                    ),
                    // 🔹 Champ de saisie
                    Expanded(
                      child: TextField(
                        controller: _controllers[widget.post['id']] ??= TextEditingController(),
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Écrire un commentaire...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 🔹 Bouton d'envoi
                    _isSending
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _isSending
                          ? null
                          : () async {
                        final text = _controllers[widget.post['id']]?.text ?? '';
                        if (text.trim().isEmpty) return;

                        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
                        if (user != null) {
                          setState(() => _isSending = true);
                          try {
                            await envoyerCommentaire(user.id, widget.post['id'], text);
                            if (widget.post['id'] != null) {
                              await fetchComments(widget.post['id']);
                            }
                            _controllers[widget.post['id']]?.clear();
                          } finally {
                            setState(() => _isSending = false);
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
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: (
                                        comment['user_photo'] != null &&
                                            comment['user_photo'].isNotEmpty &&
                                            comment['user_photo'] != '/static/images/default-avatar.png'
                                    )
                                        ? (comment['user_photo'].startsWith('http')
                                        ? NetworkImage(comment['user_photo'])
                                        : NetworkImage('https://judicalex-gn.org/${comment['user_photo']}'))
                                        : null,
                                    child: (
                                        comment['user_photo'] == null ||
                                            comment['user_photo'].isEmpty ||
                                            comment['user_photo'] == '/static/images/default-avatar.png'
                                    )
                                        ? const Icon(Icons.person, size: 24, color: Colors.grey)
                                        : null,
                                  ),

                                  const SizedBox(width: 10,),
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
                                  const Spacer(),
                                  const SizedBox(width: 4), // ⚡️ petit espace entre prénom et nom
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
                            if (user?.id == comment["user"]) {
                              return PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'modifier') {
                                    final nouveauContenu = await showDialog<String>(
                                      context: context,
                                      builder: (context) {
                                        final controller = TextEditingController(text: comment["content"]);
                                        return AlertDialog(
                                          title: const Text('Modifier le commentaire'),
                                          content: TextField(
                                            controller: controller,
                                            maxLines: null,
                                            decoration: const InputDecoration(
                                              hintText: 'Écrire un commentaire...',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Annuler'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, controller.text),
                                              child: const Text('Modifier'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (nouveauContenu != null && nouveauContenu.trim().isNotEmpty) {
                                      // 🔹 Appel API
                                      await modifierCommentaire(comment["id"], user!.id, nouveauContenu);


                                      // 🔹 Mettre à jour localement
                                      final index = comments.indexWhere((c) => c["id"] == comment["id"]);
                                      if (index != -1) {
                                        setState(() {
                                          comments[index]["content"] = nouveauContenu;
                                        });
                                      }
                                    }
                                  } else if (value == 'supprimer') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Confirmer la suppression"),
                                          content: const Text("Voulez-vous vraiment supprimer ce commentaire ?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text("Annuler"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text("Supprimer"),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await supprimerCommentaire(comment["id"], user!.id);
                                      }
                                    }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'modifier',
                                    child: Row(
                                      children: [
                                        Text('Modifier',style: TextStyle(color: Colors.blue),),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'supprimer',
                                    child: Text('Supprimer',style: TextStyle(color: Colors.red),),
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