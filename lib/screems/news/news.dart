import 'dart:async';
import 'package:flutter/material.dart';
///import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../db/base_sqlite.dart';
import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';
import '../../widget/user_provider.dart';
import '../API/api.new.dart';
import '../notifications/flutter_local_notifications.dart';
import 'news.detail.dart';

class News extends StatefulWidget {
  const News({super.key});

  @override
  NewsState createState() => NewsState();
}

class NewsState extends State<News> {
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

  bool _isSending = false;

  late PageController _pageControllerHeader;
  int _currentPagePubHeader = 0;
  Timer? _timerheader;

  List<Map<String, dynamic>> shuffledPosts = [];

  // Instance de l'API
  final NewsApi _newsApi = NewsApi();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startTimers();
    Provider.of<NotificationProvider>(context, listen: false)
        .startFetchingNotifications(context);
    _loadDomain();
  }

  void _fetchData() async {
    await fetchPosts().then((_) {
      setState(() {
        shuffledPosts = List<Map<String, dynamic>>.from(post)..shuffle();
      });
    });
    fetchAds();
  }

  void _startTimers() {
    // Timer sidebar
    _pageController = PageController(viewportFraction: 0.7);
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

    // Timer header
    _pageControllerHeader = PageController(viewportFraction: 0.9);
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
    _timer?.cancel();
    _pageController.dispose();
    _timerheader?.cancel();
    _pageControllerHeader.dispose();
    super.dispose();
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

  Future<void> fetchAds() async {
    try {
      final adsData = await _newsApi.fetchAds();
      setState(() {
        headerAds = adsData['headerAds'] ?? [];
        sidebarAds = adsData['sidebarAds'] ?? [];
      });

      for (var ad in headerAds) {
        /// logger.w("Header Ad: $ad");
      }

      for (var ad in sidebarAds) {
        /// logger.w("Sidebar Ad: $ad");
      }
    } catch (e) {
      logger.e("Erreur fetchAds: $e");
    }
  }
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


  String? domainName;
  Future<void> _loadDomain() async {
    final dbHelper = DatabaseHelper();
    final name = await dbHelper.getDomainName();


    setState(() {
      domainName = name;
      isLoading = false;
    });
  }

  bool _isRefreshing = false;

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

  @override
  Widget build(BuildContext context) {
    String parseHtmlString(String htmlString) {
      final document = html_parser.parse(htmlString);
      return document.body?.text ?? '';
    }

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
          leadingWidth: 140,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Image.asset(
              "images/judicalex-blanc.png",
              height: 80,
            ),
          ),
          title: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
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
            const SizedBox(height: 40),

            // Header Ads Carousel
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageControllerHeader,
                    itemCount: headerAds.length,
                    onPageChanged: (index) => setState(() => _currentPagePubHeader = index),
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
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
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
                  Positioned(
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(headerAds.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPagePubHeader == i ? 14 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPagePubHeader == i ? Colors.blueAccent : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Posts List with Sidebar Ads
            ListView.builder(
              itemCount: shuffledPosts.length + 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
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

                final postIndex = index > 3 ? index - 1 : index;
                if (postIndex >= shuffledPosts.length) return const SizedBox.shrink();

                final posts = shuffledPosts[postIndex];
                final postId = posts['id'];
                final userId = user?.id;

                if (!_controllers.containsKey(postId)) {
                  _controllers[postId] = TextEditingController();
                }

                if (posts['status'] != 'published') {
                  return const SizedBox.shrink();
                }

                return Card(
                  key: ValueKey(postId),
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
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1e293b), Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (posts['author'] != null &&
                                        posts['author']['groups'] != null &&
                                        (posts['author']['groups'] as List).contains('Contributeur'))
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
                              final String articleUrl = await _newsApi.generateArticleUrl(posts['slug']);
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
                              // Puis ton IconButton
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
                                  final comment = _controllers[postId]!.text.trim();
                                  if (comment.isNotEmpty && userId != null) {
                                    setState(() => _isSending = true); // démarre le spinner
                                    try {
                                      await envoyerCommentaire(userId, postId, comment);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => Newsdetail(post: posts)),
                                      );

                                    } finally {
                                      setState(() => _isSending = false); // arrête le spinner
                                    }
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
          ],
        ),
      ),
      bottomNavigationBar: const CustomNavigator(currentIndex: 0),
    );
  }
  var logger = Logger();
}