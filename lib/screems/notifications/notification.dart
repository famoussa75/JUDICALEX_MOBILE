import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../db/base_sqlite.dart';
import '../../widget/bottom_navigation_bar.dart';
import '../../widget/domain_provider.dart';
import '../../widget/drawer.dart';
import '../../widget/notifications.dart';
import '../../widget/user_provider.dart';
import 'flutter_local_notifications.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> notifications = [];
  Timer? timer;
  bool showErrorOnce = false;
  bool isLoading = true;
  int totalNotifications = 0;
  bool hasShownSocketError = false;
  int? selectedIndex;
  String searchQuery = "";

  // Variable pour stocker les notifications précédentes non lues
  List<Map<String, dynamic>> previousUnreadNotifications = [];

  @override
  void initState() {
    super.initState();
    fetchnotifications();
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchnotifications();
    });

    // Vérifier si le widget est monté avant d'accéder au Provider
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<NotificationProvider>(context, listen: false).startFetchingNotifications(context);
      });
    }

    _loadNotifications();
  }

  @override
  void dispose() {
    // Arrêter le Timer pour éviter les fuites de mémoire
    timer?.cancel();

    // Vérifier si le widget est monté avant d'accéder au Provider
    if (mounted) {
      try {
        Provider.of<NotificationProvider>(context, listen: false).stopFetchingNotifications();
      } catch (e) {
        // Ignorer les erreurs si le Provider n'est plus disponible
      }
    }

    super.dispose();
  }

  Future<Map<String, dynamic>> fetchnotifications() async {

    if (!mounted) return {};

    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      if (mounted) setState(() => isLoading = false);
      return {};
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;
      final url = Uri.parse('https://$domainName/api/notifications/all/');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      });

      if (!mounted) return {};

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedResponse is Map && decodedResponse.containsKey('notifications')) {
          final fetchedNotifications = List<Map<String, dynamic>>.from(decodedResponse['notifications']);
          final dbHelper = DatabaseHelper();

          // Récupérer les IDs déjà présents dans SQLite
          final existingNotifications = await dbHelper.getNotifications();
          final existingIds = existingNotifications.map((e) => e['notif_id']).toSet();

          // Filtrer uniquement les nouvelles notifications non présentes dans SQLite
          final newNotifications = fetchedNotifications.where((notif) => !existingIds.contains(notif['id'])).toList();

          // Insérer les nouvelles notifications
          for (var notif in newNotifications) {
            await dbHelper.insertNotification({
              'notif_id': notif['id'],
              'title': notif['title'] ?? 'Notification',
              'message': notif['message'] ?? 'No message available',
              'is_read': (notif['is_read'] is bool ? (notif['is_read'] ? 1 : 0) : notif['is_read']),
            });
          }

          // Mettre à jour la liste et le compteur des notifications
          final unreadNotifications = fetchedNotifications.where((n) =>
          (n['is_read'] is bool ? n['is_read'] == false : n['is_read'] == 0)
          ).toList();

          if (mounted) {
            setState(() {
              notifications = fetchedNotifications;
              previousUnreadNotifications = unreadNotifications;
              Provider.of<NotificationModel>(context, listen: false)
                  .setTotalNotifications(unreadNotifications.length);
              isLoading = false;
            });
          }
        } else {
          _showError("La réponse du serveur ne contient pas de notifications.");
        }
      } else {
        _showError("Erreur API : ${response.statusCode}");
      }
    } on SocketException {
      if (!hasShownSocketError && mounted) hasShownSocketError = true;
    } on FormatException {
      if (mounted) _showError("Erreur de format. La réponse du serveur est invalide.");
    } on TimeoutException {
      if (mounted) _showError("Délai d'attente dépassé. Veuillez réessayer.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
    return {};
  }


  Future<void> markAsRead(int notificationId) async {
    if (!mounted) return;

    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      if (mounted) {
        _showError("Erreur d'authentification ou configuration. Veuillez vérifier vos paramètres.");
      }
      return;
    }

    domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
    domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;

    final url = Uri.parse('https://$domainName/api/notifications/$notificationId/mark-as-read/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            notifications = notifications.map((notification) {
              if (notification['id'] == notificationId) {
                notification['is_read'] = true;
              }
              return notification;
            }).toList();
          });
        }
      } else {
        debugPrint("Erreur API : ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur réseau : $e");
    }
  }

  Future<void> suppression() async {
    if (!mounted) return;

    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      if (mounted) {
        _showError("Erreur d'authentification ou configuration. Veuillez vérifier vos paramètres.");
      }
      return;
    }

    domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
    domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;
    final url = Uri.parse('https://$domainName/api/notifications/delete-all/');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        debugPrint("Toutes les notifications ont été supprimées avec succès.");
        if (mounted) {
          setState(() {
            notifications.clear();
          });
        }
      } else {
        debugPrint("Erreur API : ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur réseau : $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message))
      );
    }
  }

  Future<void> _loadNotifications() async {
    final dbHelper = DatabaseHelper();
    final data = await dbHelper.getNotifications();
    if (mounted) {
      setState(() {
        notifications = data;
      });
    }
  }

  Future<void> _refreshPage() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });
    await fetchnotifications();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;

    // Calculer les nombres
    final unreadCount = notifications.where((n) => n['is_read'] == false).length;
    final readCount = notifications.length - unreadCount;
    final totalCount = notifications.length;

    return Scaffold(
      drawer: const MyDrawer(),
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
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "images/judicalex-blanc1.png",
              height: 80,
            ),
          ),
          title: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              splashRadius: 24,
              tooltip: "Notifications",
              onPressed: () async {
                try {
                  // 🔄 Actualiser d'abord les notifications depuis ton API
                  await NotificationFetcher.fetchAndSaveNotifications(context);

                  // 📥 Puis récupérer les notifications stockées localement
                  final notifications = await DatabaseHelper().getNotifications();

                  if (!context.mounted) return;

                  // 🪟 Afficher la boîte de dialogue
                  showDialog(
                    context: context,
                    builder: (context) => CustomDialogBox(
                      title: "Notifications récentes",
                      message: notifications.isEmpty
                          ? "Aucune notification disponible."
                          : notifications
                          .take(3) // Affiche les 3 plus récentes
                          .map((n) => "• ${n['message']}")
                          .join("\n\n"),
                      confirmText: "Tout voir",
                      onConfirm: () {
                        Navigator.pop(context); // Fermer la boîte avant de naviguer
                        Navigator.pushNamed(context, "/NotificationPage");
                      },
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  // 🚨 En cas d’erreur, afficher une boîte d’erreur simple
                  showDialog(
                    context: context,
                    builder: (context) => CustomDialogBox(
                      title: "Erreur",
                      message: "Impossible de charger les notifications : $e",
                      confirmText: "OK",
                      onConfirm: () => Navigator.pop(context),
                    ),
                  );
                }
              },
            )
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: user == null
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info, size: 48),
              SizedBox(height: 8),
              Text(
                "L'accès à ces informations est réservé aux utilisateurs connectés. Veuillez vous connecter pour continuer.",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : Column(
          children: [
            // Champ de recherche
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Rechercher...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (query) {
                  if (mounted) {
                    setState(() {
                      searchQuery = query;
                    });
                  }
                },
              ),
            ),

            // Compteurs
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Non lues : $unreadCount",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    "Lues : $readCount",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    "Total : $totalCount",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            // Notifications header avec bouton de suppression
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Notifications",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirmer la suppression"),
                            content: const Text(
                                "Voulez-vous vraiment supprimer toutes les notifications ?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Annuler"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await suppression();
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Vider les Notifications"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Liste des notifications
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : notifications.isEmpty
                  ? const Center(child: Text('Aucune notification disponible.'))
                  : _buildNotificationList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(child: CustomNavigator(currentIndex: 5)),
    );
  }

  Widget _buildNotificationList() {
    // Filtrer selon la recherche
    final filtered = notifications.where((notification) {
      final message = (notification['message'] ?? "").toLowerCase();
      return searchQuery.isEmpty || message.contains(searchQuery.toLowerCase());
    }).toList();

    // Trier : non lues en premier
    filtered.sort((a, b) {
      final aRead = a['is_read'] == true;
      final bRead = b['is_read'] == true;
      if (aRead == bRead) return 0;
      return aRead ? 1 : -1;
    });

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final notification = filtered[index];
        if (notification == null || !notification.containsKey('id') || !notification.containsKey('objet_cible')) {
          return const SizedBox();
        }

        final idAffaire = notification['objet_cible'];
        final notificationId = notification['id'];
        final bool isSelected = selectedIndex == index;

        Color cardColor;
        if (isSelected) {
          cardColor = const Color(0xFFDFB23D);
        } else if (notification['is_read'] == false) {
          cardColor = Colors.white;
        } else {
          cardColor = Colors.grey[200]!;
        }

        return Dismissible(
          key: Key(notification['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Confirmer"),
                content: const Text("Voulez-vous supprimer cette notification ?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Annuler"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            if (mounted) {
              setState(() {
                filtered.removeAt(index);
              });
            }
          },
          child: Card(
            margin: const EdgeInsets.all(8.0),
            color: cardColor,
            child: ListTile(
              onTap: () async {
                if (!notification['is_read']) {
                  await markAsRead(notificationId);
                }

                if (mounted) {
                  setState(() {
                    selectedIndex = index;
                  });
                }

                _showAffaireDetailsDialog(idAffaire);

                if (mounted) {
                  setState(() {
                    selectedIndex = null;
                  });
                }
              },
              title: Text(
                notification['message'] ?? 'Sans message',
                style: TextStyle(
                  fontWeight: notification['is_read'] == false
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: notification['is_read'] == false ? Colors.black : Colors.black54,
                ),
              ),
              leading: Icon(
                notification['is_read'] == false
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: notification['is_read'] == false ? const Color(0xFFDFB23D) : Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> fetchRoleDetailsDecision(int idAffaire) async {
    if (!mounted) return {};

    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      if (mounted) {
        _showError("Erreur d'authentification ou configuration.");
      }
      return {};
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;

      final url = Uri.parse('https://$domainName/api/affaire/$idAffaire/');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      });

      if (!mounted) return {};

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        if (mounted) {
          _showError('Erreur lors de la récupération des détails.');
        }
        return {};
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur');
      }
      return {};
    }
  }

  void _showAffaireDetailsDialog(int idAffaire) async {
    try {
      final data = await fetchRoleDetailsDecision(idAffaire);
      final decisions = data['decisions'] ?? [];

      if (mounted) {
        setState(() {
          selectedIndex = null;
        });
      }

      if (!mounted) return;

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(0.2),
        pageBuilder: (context, anim1, anim2) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Center(
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            "/Decisions",
                            arguments: {'id': idAffaire},
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AFFAIRE N° : ${data['affaire']['id']}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: "Objet: ",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: data['affaire']['objet'] ?? 'Objet non précisé',
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (decisions.isNotEmpty)
                        Expanded(
                          child: PageView.builder(
                            itemCount: decisions.length,
                            itemBuilder: (context, index) {
                              return _buildDecisionCard(decisions[index], index, decisions.length);
                            },
                          ),
                        )
                      else
                        const Center(child: Text("Aucune décision disponible.")),

                      const SizedBox(height: 10),
                      Center(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDFB23D), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          child: const Text(
                            "Retour",
                            style: TextStyle(color: Color(0xFFDFB23D)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors du chargement des détails")),
        );
      }
    }
  }

  Widget _buildDecisionCard(Map<String, dynamic> decision, int index, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("Décision ${index + 1}/$total",
                  style: const TextStyle(fontWeight: FontWeight.bold, color:  Color(0xFFDFB23D))),
            ),
            const Divider(),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Type: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['typeDecision'] ?? 'Non spécifié'),
                ],
              ),
            ),
            // ... (le reste de votre code pour _buildDecisionCard reste inchangé)
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Date: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['dateDecision'] ?? 'Non précisé'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Président: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['president'] ?? 'Inconnu'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Greffier: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['greffier'] ?? 'Inconnu'),
                ],
              ),
            ),
            RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Décision: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(
                    text: decision['decision'] ?? 'Inconnu',
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Prochaine Audience: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['prochaineAudience'] ?? 'Non précisé'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}