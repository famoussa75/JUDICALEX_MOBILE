import 'dart:convert';
import 'package:ejustice/db/base_sqlite.dart';
import 'package:ejustice/screems/news/news.detail.dart';
import 'package:ejustice/screems/notifications/flutter_local_notifications.dart';
import 'package:ejustice/widget/bottom_navigation_bar.dart';
import 'package:ejustice/widget/user_provider.dart';
import 'package:ejustice/widget/drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class News extends StatefulWidget {
  const News({super.key});

  @override
  NewsState createState() => NewsState();
}

class NewsState extends State<News> {
  List<dynamic> post = [];
  bool isLoading = true;
  final TextEditingController commentController = TextEditingController();
  final Set<int> _visibleCommentFields = {};

  @override
  void initState() {
    super.initState();
    fetchPosts();
    // Démarrer le Timer pour les notifications
    Provider.of<NotificationProvider>(context, listen: false)
        .startFetchingNotifications(context);
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> fetchPosts() async {
    try {
      // Récupérer le nom de domaine depuis la base de données
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

        // Concaténer le nom de domaine avec l'endpoint API
        final apiUrl = 'https://$domainName/api/posts/';
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final List<dynamic> jsonData =
              json.decode(utf8.decode(response.bodyBytes));
          setState(() {
            post = jsonData;
            isLoading = false;
          });
        } else {
          // throw Exception('Erreur lors de la récupération des données: ${response.statusCode}');
          throw Exception('Erreur lors de la récupération des données');
        }
      } else {
        throw Exception('Nom de domaine non défini ou vide.');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      logger.e('Erreur : $error');
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url); // Pour Android, lance dans un navigateur externe
    } else {
      throw 'Impossible de lancer l\'URL $url';
    }
  }

  Future<String> generateArticleUrl(int postId) async {
    // Récupérer le nom de domaine depuis la base de données
    String? domainName = await DatabaseHelper().getDomainName();

    // Assurez-vous que le nom de domaine ne se termine pas par un slash
    if (domainName != null && domainName.endsWith('/')) {
      domainName = domainName.substring(0, domainName.length - 1);
    }
    return '$domainName/blog/post/$postId/';
  }

  bool _showCommentField = false;
  final TextEditingController _commentController = TextEditingController();

  void _toggleCommentField() {
    setState(() {
      _showCommentField = !_showCommentField;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> stories = [
      'images/img.png',
      'images/img2.jpg',
      'images/img3.jpg',
      'images/img4.jpg',
      'images/img5.jpg',
      'images/img6.jpg',
    ];

    // Liste des données pour chaque container
    final List<Map<String, String>> items = [
      {"icon": "🔗", "text": "L’accès à la justice est l’un des piliers fondamentaux de tout système juridique équitable. Garantir que chaque citoyen, sans distinction de statut social ou économique, puisse faire valoir ses droits devant les tribunaux est un impératif1"},
      {"icon": "💬", "text": "L’accès à la justice est l’un des piliers fondamentaux de tout système juridique équitable. Garantir que chaque citoyen, sans distinction de statut social ou économique, puisse faire valoir ses droits devant les tribunaux est un impératif"},
      {"icon": "🔗", "text": "L’accès à la justice est l’un des piliers fondamentaux de tout système juridique équitable. Garantir que chaque citoyen, sans distinction de statut social ou économique, puisse faire valoir ses droits devant les tribunaux est un impératif"},
      {"icon": "📌", "text": "L’accès à la justice est l’un des piliers fondamentaux de tout système juridique équitable. Garantir que chaque citoyen, sans distinction de statut social ou économique, puisse faire valoir ses droits devant les tribunaux est un impératif"},
      {"icon": "⭐", "text": "L’accès à la justice est l’un des piliers fondamentaux de tout système juridique équitable. Garantir que chaque citoyen, sans distinction de statut social ou économique, puisse faire valoir ses droits devant les tribunaux est un impératif"},
    ];

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: AppBar(
            backgroundColor: const Color(0xFF1e293b),
            shadowColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            automaticallyImplyLeading: true,
            leadingWidth: 140, // 👈 augmente la largeur réservée à gauche
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                "images/judicalex-blanc.png",
                height: 80, // 👈 tu peux tester 80 ou 100
              ),
            ),
            title: const SizedBox.shrink(),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, "/NotificationPage");
                },
              ),
            ],
          ),
        ),

        drawer: const MyDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 20),

                // 🔹 Carrousel horizontal
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            story,
                            width: 160,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 🔹 Titre "Actualités"
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Actualités",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),

                // 🔹 Liste des posts
                ListView.builder(
                  itemCount: post.length,
                  shrinkWrap:
                      true, // ⚡ nécessaire pour éviter conflits de taille
                  physics:
                      const NeverScrollableScrollPhysics(), // ⚡ empêche le scroll interne
                  itemBuilder: (context, index) {
                    final posts = post[index];
                    final postId = posts['id'];

                    return Card(
                      margin: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Avatar de l'auteur
                              CircleAvatar(
                                backgroundImage: posts['author_image'] != null
                                    ? NetworkImage(posts['author_image'])
                                    : AssetImage('images/guinee.png') as ImageProvider,
                                radius: 20,
                              ),
                              const SizedBox(width: 8),

                              // Nom de l'auteur ou autre info
                              Text(
                                posts['author_name'] ?? 'Judicalex',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ]
                          ),
                          // --- Titre & contenu
                          ListTile(
                            title: Text(
                              posts['title'] ?? 'Pas de titre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            subtitle: Text(
                              posts['content'] ?? 'Pas de description',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black54),
                            ),
                            onTap: () {
                              // 🔹 Quand on clique, on navigue vers la page de détail
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Newsdetail(post: posts),
                                ),
                              );
                            },
                          ),

                          // --- Image
                          if (posts['image'] != null)
                            Image.network(
                              posts['image'],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),

                          // --- Boutons (partager + commenter)
                          Row(
                            children: [
                              // Icône partager
                              IconButton(
                                icon:
                                    const Icon(Icons.share, color: Colors.blue),
                                onPressed: () async {
                                  final String articleUrl =
                                      await generateArticleUrl(posts['id']);
                                  Share.share(articleUrl);
                                },
                              ),

                              const SizedBox(width: 8),

                              // Bouton commentaire
                              IconButton(
                                icon: const Icon(Icons.comment,
                                    color: Colors.grey),
                                onPressed: _toggleCommentField,
                              ),

                              // Compteur de commentaires
                              const SizedBox(width: 4),
                              Text(
                                "10 commentaires",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[
                                      400], // couleur visible sur fond clair/foncé
                                ),
                              ),

                              const SizedBox(width: 60),
                              const Text(
                                "Lire plus +",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors
                                      .orange, // couleur visible sur fond clair/foncé
                                ),
                              ),
                            ],
                          ),

                          // --- Champ commentaire (affiché uniquement si _showCommentField = true)
                          if (_showCommentField)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      decoration: const InputDecoration(
                                        hintText: "Écrire un commentaire...",
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send,
                                        color: Colors.blue),
                                    onPressed: () {
                                      final comment =
                                          _commentController.text.trim();
                                      if (comment.isNotEmpty) {
                                        print("Commentaire posté: $comment");
                                        // 👉 ici tu peux appeler ton API pour sauvegarder le commentaire
                                        _commentController.clear();
                                        setState(
                                            () => _showCommentField = false);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            story,
                            width: 350,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                ListView.builder(
                  itemCount: post.length,
                  shrinkWrap:
                      true, // ⚡ nécessaire pour éviter conflits de taille
                  physics:
                      const NeverScrollableScrollPhysics(), // ⚡ empêche le scroll interne
                  itemBuilder: (context, index) {
                    final posts = post[index];
                    final postId = posts['id'];

                    return Card(
                      margin: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                              children: [
                                // Avatar de l'auteur
                                CircleAvatar(
                                  backgroundImage: posts['author_image'] != null
                                      ? NetworkImage(posts['author_image'])
                                      : AssetImage('images/guinee.png') as ImageProvider,
                                  radius: 20,
                                ),
                                const SizedBox(width: 8),

                                // Nom de l'auteur ou autre info
                                Text(
                                  posts['author_name'] ?? 'Judicalex',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ]
                          ),

                          ListTile(
                            title: Text(
                              posts['title'] ?? 'Pas de titre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            subtitle: Text(
                              posts['content'] ?? 'Pas de description',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black54),
                            ),
                            onTap: () {
                              // 🔹 Quand on clique, on navigue vers la page de détail
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Newsdetail(post: posts),
                                ),
                              );
                            },
                          ),
                          if (posts['image'] != null)
                            Image.network(
                              posts['image'],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          // etc... (bouton partager, commentaires, etc.)

                          Row(
                            children: [
                              // Icône partager
                              IconButton(
                                icon:
                                    const Icon(Icons.share, color: Colors.blue),
                                onPressed: () async {
                                  final String articleUrl =
                                      await generateArticleUrl(posts['id']);
                                  Share.share(articleUrl);
                                },
                              ),

                              const SizedBox(width: 8),

                              // Bouton commentaire
                              IconButton(
                                icon: const Icon(Icons.comment,
                                    color: Colors.grey),
                                onPressed: _toggleCommentField,
                              ),

                              // Compteur de commentaires
                              const SizedBox(width: 4),
                              Text(
                                "10 commentaires",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[
                                      400], // couleur visible sur fond clair/foncé
                                ),
                              ),

                              const SizedBox(width: 60),
                              const Text(
                                "Lire plus +",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors
                                      .orange, // couleur visible sur fond clair/foncé
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                  },
                ),
                SizedBox(
                  width: double.infinity,
                  height: 230, // tu peux ajuster la hauteur
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          width: 390, // largeur du container
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1e293b),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Partie 1 : icône ou image à gauche
                              item["icon"]!.startsWith("images/")
                                  ? Image.asset(
                                item["icon"]!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                                  : Text(
                                item["icon"]!,
                                style: const TextStyle(fontSize: 30),
                              ),

                              const SizedBox(width: 12), // espace entre image et texte

                              // Partie 2 : texte à droite
                              Expanded(
                                child: Text(
                                  item["text"]!,
                                  style: const TextStyle(color:Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const CustomNavigator(currentIndex: 0),
    );
  }

  var logger = Logger(); // Create a logger instance

  Future<void> _submitComment(int userId, int postId, String comment) async {
    const String apiUrl = "https://judicalex-gn.org/api/comments/";

    try {
      logger.i(
          'Envoi du commentaire: userId=$userId, postId=$postId, comment=$comment');

      // Récupérer le token CSRF
      final String? csrfToken = await fetchCsrfToken();

      if (csrfToken == null) {
        throw Exception('Token CSRF introuvable');
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
        },
        body: jsonEncode({
          'user_id': userId,
          'post_id': postId,
          'content': comment,
        }),
      );

      if (response.statusCode == 201) {
        logger.i('Commentaire envoyé avec succès');
      } else {
        logger.e('Erreur lors de l\'envoi du commentaire: ${response.body}');
        throw Exception(
            'Erreur lors de l\'envoi du commentaire: ${response.statusCode}');
      }
    } catch (error) {
      logger.e('Erreur: $error');
    }
  }

  Future<String?> fetchCsrfToken() async {
    String? domainName = await DatabaseHelper().getDomainName();

    if (domainName != null) {
      // Supprime le protocole (http:// ou https://) et le slash final s'il existe
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;
    }

    try {
      final response =
          await http.get(Uri.parse("https://$domainName/api/csrf-token/"));
      // final response = await http.get(Uri.parse("https://judicalex-gn.org/api/csrf-token/"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[
            'csrf_token']; // Vérifiez que ce champ existe dans la réponse
      } else {
        //logger.e('Erreur lors de la récupération du token CSRF : ${response.body}');
        // throw Exception('Échec de la récupération du token CSRF : ${response.statusCode}');
        logger.e(
            'Erreur lors de la récupération du token CSRF : ${response.body}');
        throw Exception(
            'Échec de la récupération du token CSRF : ${response.statusCode}');
      }
    } catch (error) {
      logger.e('Erreur : $error');
      return null;
    }
  }
}
