import 'dart:async';
import 'dart:convert';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:flutter/material.dart';
///import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/parser.dart' as html_parser;
///import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/base_sqlite.dart';
import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';
import '../../widget/user_provider.dart';
import '../notifications/flutter_local_notifications.dart';
import 'news.detail.dart';

class News extends StatefulWidget {
  const News({super.key});

  @override
  NewsState createState() => NewsState();
}

class NewsState extends State<News> {

  // Déclare en haut de ton StatefulWidget
  Set<int> _commentVisible = {};
  Map<int, TextEditingController> _controllers = {};

  List<dynamic> headerAds = [];
  List<dynamic> sidebarAds = [];

  List<dynamic> post = [];
  bool isLoading = true;
  final TextEditingController commentController = TextEditingController();


  late PageController _pageController;
  int _currentPagePub = 0;
  Timer? _timer;

  late PageController _pageControllerHeader;
  int _currentPagePubHeader = 0;
  Timer? _timerheader;

  List<Map<String, dynamic>> shuffledPosts = [];



  @override
  void initState() {
    super.initState();
    fetchPosts().then((_) {
      setState(() {
        shuffledPosts = List<Map<String, dynamic>>.from(post)..shuffle();
      });
    });
    fetchAds();
    // Démarrer le Timer pour les notifications
    Provider.of<NotificationProvider>(context, listen: false)
        .startFetchingNotifications(context);
   /// _controller = PageController(initialPage: 0, viewportFraction: 0.9);
    _loadDomain();
    /// sidebar
    _pageController = PageController(viewportFraction: 0.7); // 70% largeur

    // Timer auto-scroll toutes les 10s
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPagePub < sidebarAds.length - 1) {
          _currentPagePub++;
        } else {
          _currentPagePub = 0;
        }
        _pageController.animateToPage(
          _currentPagePub,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });

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
    commentController.dispose();
    super.dispose();
    ///sidebar
    _timer?.cancel();          // <- stoppe le Timer d’abord
    _pageController.dispose(); // <- puis libère le contrôleur
    ///header
    _timerheader?.cancel();          // <- stoppe le Timer d’abord
    _pageControllerHeader.dispose(); // <- puis libère le contrôleur
  }

  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true; // 🔹 afficher le loader avant la requête
    });
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

          for (var item in jsonData) {
            ///logger.w(item);
          }

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

          setState(() {
            headerAds = jsonData["header"] ?? [];
            sidebarAds = jsonData["sidebar"] ?? [];
          });

          // 🔹 Log uniquement les pubs header
          for (var ad in headerAds) {
           /// logger.w("Header Ad: $ad");
          }

          // 🔹 Log uniquement les pubs sidebar
          for (var ad in sidebarAds) {
           /// logger.w("Sidebar Ad: $ad");
          }
        }else {
          // throw Exception('Erreur lors de la récupération des données: ${response.statusCode}');
          throw Exception('Erreur lors de la récupération des données');
        }
      }
    } catch (e) {
      logger.e("Erreur fetchAds: $e");
    }
  }






  Future<String> generateArticleUrl(String slug) async {
    // Récupérer le nom de domaine depuis la base de données
    String? domainName = await DatabaseHelper().getDomainName();

    // Assurez-vous que le nom de domaine ne se termine pas par un slash
    if (domainName != null && domainName.endsWith('/')) {
      domainName = domainName.substring(0, domainName.length - 1);
    }
    return '$domainName/blog/post/$slug/';
  }

  ///bool _showCommentField = false;
 /// final TextEditingController _commentController = TextEditingController();

  /*
  void _toggleCommentField() {
    setState(() {
      _showCommentField = !_showCommentField;
    });
  }

   */

  ///late final PageController _controller;
  int _currentPage = 0;



  String? domainName;
  Future<void> _loadDomain() async {
    final dbHelper = DatabaseHelper();
    final name = await dbHelper.getDomainName();
    setState(() {
      domainName = name;
      isLoading = false;
    });
  }

  /*
  Future<void> _launchURL(String url) async {
    try {
      await FlutterWebBrowser.openWebPage(
        url: url,
        customTabsOptions: const  CustomTabsOptions(
          colorScheme: CustomTabsColorScheme.dark,
          toolbarColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : Impossible d\'ouvrir $url')),
      );
    }
  }

   */



  bool _isRefreshing = false; // 🔹 Pull-to-refresh

  // --- Fonction de refresh
  Future<void> _refreshPage() async {
    setState(() {
      _isRefreshing = true; // 🔹 on indique qu'on rafraîchit
    });

    await fetchPosts(); // 🔹 recharge les données
    // 🔹 Mélanger les posts aléatoirement
    shuffledPosts.shuffle();

    setState(() {
      _isRefreshing = false; // 🔹 fin du rafraîchissement
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


    String parseHtmlString(String htmlString) {
      final document = html_parser.parse(htmlString);
      return document.body?.text ?? '';
    }



    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    /*
    // 1️⃣ Définir le controller avec viewportFraction
    final PageController _controller = PageController(
      viewportFraction: 0.9, // 80% de la largeur, laisse 20% visible pour les autres pages
      initialPage: 0,
    );

     */


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
                // Animation ou vibration peut-être
                Navigator.pushNamed(context, "/NotificationPage");
              },
              splashRadius: 24,
              tooltip: "Notifications",
            ),
          ],
        ),
      ),

        drawer: const MyDrawer(),
          body: RefreshIndicator(
              onRefresh: _refreshPage,
              child: (domainName?.isEmpty ?? true)
                  ? const Center(
                child: Text(
                  "Cliquez sur 'Autres' puis choisissez votre pays",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              )
              : ListView(
              children: [
                const SizedBox(height: 20),
                /*
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

                 */
                const SizedBox(height: 20,),
                // 2️⃣ Modifier le SizedBox et PageView.builder

                SizedBox(
                  height: 240,
                  child: Stack(
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
                              margin: const EdgeInsets.symmetric(horizontal: 8), // espace entre les pages
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  // 🔹 affiché pendant le chargement
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child; // image chargée
                                    return const Center(
                                      child: CircularProgressIndicator(), // loader pendant téléchargement
                                    );
                                  },
                                  // 🔹 affiché si erreur
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // 🔹 Les indicateurs de page
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

                ListView.builder(
                  itemCount: shuffledPosts.length + 1, // +1 pour le PageView à l'index 3
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    // PageView à la position 3
                    if (index == 3) {
                      return SizedBox(
                        height: 300,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: sidebarAds.length,
                          itemBuilder: (context, adIndex) {
                            final ad = sidebarAds[adIndex];
                            final rawImage = ad["image"] ?? "";
                            final safeDomain = domainName ?? '';
                            final imageUrl = rawImage.startsWith("http")
                                ? rawImage
                                : "https://${safeDomain.replaceAll(RegExp(r'^https?://'), '')}${rawImage.startsWith('/') ? rawImage : '/$rawImage'}";

                            return GestureDetector(
                              onTap: () => launchUrl(Uri.parse(ad["link"])),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Image.network(
                                      imageUrl,
                                      errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }

                    // ⚡ Ajuster l’index pour les posts après le PageView
                    final postIndex = index > 3 ? index - 1 : index;
                    if (postIndex >= shuffledPosts.length) return const SizedBox.shrink();

                    final posts = shuffledPosts[postIndex];
                    final postId = posts['id'];
                    final userId = user?.id;

                    if (!_controllers.containsKey(postId)) {
                      _controllers[postId] = TextEditingController();
                    }

                    if (posts['status'] != 'published') {
                      return const SizedBox.shrink(); // ignorer les posts non publiés
                    }

                    return Card(
                      key: ValueKey(postId), // clé unique pour éviter les conflits
                      margin: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: (posts['author'] != null &&
                                    posts['author']['groups'] != null &&
                                    (posts['author']['groups'] as List).contains('Contributeur') &&
                                    posts['author']['photo'] != null)
                                    ? NetworkImage(posts['author']['photo'])
                                    : const AssetImage('images/logo-icon.png') as ImageProvider,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (posts['author'] != null &&
                                    posts['author']['groups'] != null &&
                                    (posts['author']['groups'] as List).contains('Contributeur'))
                                    ? "${posts['author']['first_name'] ?? ''} ${posts['author']['last_name'] ?? ''}"
                                    : "Judicalex Guinée",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(10),
                                width: 200,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1e293b), Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (posts['author'] != null &&
                                          posts['author']['groups'] != null &&
                                          (posts['author']['groups'] as List)
                                              .contains('Contributeur'))
                                          ? "Contribution"
                                          : "News",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                              parseHtmlString(posts['content'] ?? 'Pas de description'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => Newsdetail(post: posts)),
                              );
                            },
                          ),
                          if (posts['image'] != null)
                            Image.network(
                              posts['image'],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey.shade300,
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share, color: Colors.blue),
                                onPressed: () async {
                                  final String articleUrl = await generateArticleUrl(posts['slug']);
                                  Share.share(articleUrl);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.comment, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    if (_commentVisible.contains(postId)) {
                                      _commentVisible.remove(postId);
                                    } else {
                                      _commentVisible.add(postId);
                                    }
                                  });
                                },
                              ),
                              Text(
                                "${posts['comments'] != null ? (posts['comments'] as List).length : 0} commentaires",
                                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Newsdetail(post: posts)),
                                  );
                                },
                                child: const Text(
                                  "Lire plus +",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orangeAccent,
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          if (_commentVisible.contains(postId))
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controllers[postId],
                                      decoration: const InputDecoration(
                                        hintText: "Écrire un commentaire...",
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: Colors.blue),
                                    onPressed: () async {
                                      final comment = _controllers[postId]!.text.trim();
                                      if (comment.isNotEmpty && userId != null) {
                                        await _submitComment(userId, postId, comment);
                                        _controllers[postId]!.clear();
                                        setState(() => _commentVisible.remove(postId));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Commentaire envoyé !')),
                                        );
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

                /*
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient:const  LinearGradient(
                        colors: [
                          Color(0xFF1e293b),
                          Colors.white,
                        ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ce que nous offrons",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20,color: Colors.white),)
                    ],
                  ),
                ),
                const SizedBox(height: 20,),
                SizedBox(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: SizedBox(
                                  height: 100,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          'images/rccm.jpg',
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const Text(
                                        "RCMM",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              offset: Offset(1, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (_)=> const Role()));
                                },
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: SizedBox(
                                    height: 100,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.asset(
                                            'images/procedure.jpg',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const Text(
                                          "Procédures",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black54,
                                                offset: Offset(1, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: SizedBox(
                                  height: 100,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          'images/jurisprudence.jpg',
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const Text(
                                        "Jurisprudence",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              offset: Offset(1, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: SizedBox(
                                  height: 100,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          'images/Annuaire.jpg',
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const Text(
                                        "Annuaire",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              offset: Offset(1, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap:(){
                                  Navigator.push(context, MaterialPageRoute(builder: (_)=> const CodeCivil() ));
                                },
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: SizedBox(
                                    height: 100,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.asset(
                                            'images/liensUtiles.jpg',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const Text(
                                          "Liens utiles",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black54,
                                                offset: Offset(1, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 20,),
                Container(
                  margin: const  EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration:  BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1e293b),
                          Colors.white
                        ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Contributions",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color: Colors.white),)
                    ],
                  ),
                ),

                  (post.isEmpty || isLoading) // ✅ condition pour savoir si les données sont chargées
                      ? const Center(
                    child: CircularProgressIndicator(),
                  )
                  :  ListView.builder(
                  itemCount: post.length,
                  shrinkWrap:
                  true, // ⚡ nécessaire pour éviter conflits de taille
                  physics:
                  const NeverScrollableScrollPhysics(), // ⚡ empêche le scroll interne
                  itemBuilder: (context, index) {
                    final posts = post[index];

                    final  postId = posts['id']; // récupère l'id du post
                    final  userId = user?.id; // récupère l'id de l'utilisateur connecté
                    // Vérifie si l'auteur est contributeur
                    bool isContributeur = posts['author'] != null &&
                        posts['author']['groups'] != null &&
                        (posts['author']['groups'] as List).contains('Contributeur');
                    if (!isContributeur) {
                      // Si pas contributeur, on ne retourne rien (ou SizedBox vide)
                      return const SizedBox.shrink();
                    }
                    return Card(
                      margin: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Vérifie si l'auteur existe
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: (posts['author'] != null &&
                                    posts['author']['groups'] != null &&
                                    (posts['author']['groups'] as List).contains('Contributeur') &&
                                    posts['author']['photo'] != null)
                                    ? NetworkImage(posts['author']['photo'])
                                    : const AssetImage('images/logo-icon.png') as ImageProvider,
                              ),
                              const SizedBox(width: 8),

                              Text(
                                (posts['author'] != null &&
                                    posts['author']['groups'] != null &&
                                    (posts['author']['groups'] as List).contains('Contributeur'))
                                    ? "${posts['author']['first_name'] ?? ''} ${posts['author']['last_name'] ?? ''}"
                                    : "Judicalex Guinée",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
                              parseHtmlString(posts['content'] ?? 'Pas de description'),
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
                            (post.isEmpty || isLoading)
                                ? const Center(
                              child: CircularProgressIndicator(),
                            )
                                : Image.network(
                              posts['image'],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              // 🔹 Loader pendant le téléchargement
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child; // image chargée
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              // 🔹 Icône si erreur
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                );
                              },
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
                                  await generateArticleUrl(posts['slug']);
                                  Share.share(articleUrl);
                                },
                              ),

                              const SizedBox(width: 8),

                              // Bouton commentaire
                              // Bouton commentaire
                              IconButton(
                                icon: const Icon(Icons.comment, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    if (_commentVisible.contains(postId)) {
                                      _commentVisible.remove(postId); // ferme le champ
                                    } else {
                                      _commentVisible.add(postId);    // ouvre le champ
                                    }
                                  });
                                },
                              ),

                              // Compteur de commentaires
                              const SizedBox(width: 4),
                              // Compteur de commentaires
                              Text(
                                "${posts['comments'] != null ? (posts['comments'] as List).length : 0} commentaires",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400], // couleur visible sur fond clair/foncé
                                ),
                              ),

                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  // 🔹 Quand on clique, on navigue vers la page de détail
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Newsdetail(post: posts),
                                    ),
                                  );
                                },
                                child:const Column(
                                  crossAxisAlignment: CrossAxisAlignment.end, // 🔹 à droite
                                  children: [
                                    Align(
                                      child: Text(
                                        "Lire plus + ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orangeAccent,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Champ commentaire spécifique au post
                          if (_commentVisible.contains(postId))
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controllers[postId],
                                      decoration: const InputDecoration(
                                        hintText: "Écrire un commentaire...",
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: Colors.blue),
                                    onPressed: () async {
                                      final comment = _controllers[postId]!.text.trim();
                                      if (comment.isNotEmpty && userId != null) {
                                        await _submitComment(userId, postId, comment);
                                        _controllers[postId]!.clear();
                                        setState(() => _commentVisible.remove(postId));

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Commentaire envoyé !')),
                                        );
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

                   */

              ],
          )
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

