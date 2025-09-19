import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:ejustice/db/base_sqlite.dart';
///import 'package:ejustice/main.dart';
import 'package:ejustice/screems/notifications/flutter_local_notifications.dart';
import 'package:ejustice/widget/bottom_navigation_bar.dart';
import 'package:ejustice/widget/domain_provider.dart';
import 'package:ejustice/widget/drawer.dart';
import 'package:ejustice/widget/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
 const  NotificationPage({super.key});
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> notifications = [];
  Timer? timer;
  bool showErrorOnce = false; // Éviter les messages répétitifs
  bool isLoading = true;
  int totalNotifications =0;

  bool hasShownSockertError = false;

  int? selectedIndex; // 🔹 index du rôle sélectionné



  @override
  void initState(){
    super.initState();
    fetchnotifications();
    timer = Timer.periodic(const Duration(seconds:5), (timer){
      fetchnotifications();
    });
    // Démarrer le Timer pour les notifications
    Provider.of<NotificationProvider>(context, listen: false).startFetchingNotifications(context);
    _loadNotifications(); // <- ici
  }


  @override
  void dispose() {
    // Arrêter le Timer pour éviter les fuites de mémoire
    Provider.of<NotificationProvider>(context, listen: false).stopFetchingNotifications();
    timer?.cancel(); // Annuler le Timer à la fermeture de l'écran
    super.dispose();
  }

  // Variable pour stocker les notifications précédentes non lues
  List<Map<String, dynamic>> previousUnreadNotifications = [];


  Future<Map<String, dynamic>> fetchnotifications() async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      if (!showErrorOnce) {
        // _showError("Authentication error or configuration issue. Please check your settings.");
        showErrorOnce = true;
      }
      if(mounted){
        setState(() {
          isLoading = false; // Stop loading even in case of an error
        });
      }
      return {};
    }

    try {
      // Clean and format the domain name
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;
      final url = Uri.parse('https://$domainName/api/notifications/all/');

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      });

      if (response.statusCode == 200) {
        try {
          var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

          if (decodedResponse is Map && decodedResponse.containsKey('notifications')) {
            notifications = List<Map<String, dynamic>>.from(decodedResponse['notifications']);
            //print('desciosn');
            //print(notifications);
            // Filtrer les notifications non lues
            var unreadNotifications = notifications.where((notification) {
              return (notification['is_read'] is bool ? notification['is_read'] == false : notification['is_read'] == 0);
            }).toList();
            // Afficher le nombre de notifications non lues après le filtrage
            //print("Non read notifications: ${unreadNotifications.length}");

            /// Insérer dans SQLite (éviter doublons)
            final dbHelper = DatabaseHelper();
            for (var notif in unreadNotifications) {
              await dbHelper.insertNotification({
                'notif_id': notif['id'],  // Assure-toi que l’API envoie un id unique
                'title': notif['title'] ?? 'Notification',
                'message': notif['message'] ?? 'No message available',
                'is_read': (notif['is_read'] is bool ? (notif['is_read'] ? 1 : 0) : notif['is_read']),
              });
            }


            if (unreadNotifications.length > previousUnreadNotifications.length) {
              /*
              // Convert unread notifications to the required format
              List<Map<String, String>> notificationData = unreadNotifications.map((notification) {
                return {
                  'title': (notification['title'] ?? 'Notification').toString(),
                  'message': (notification['message'] ?? 'No message available').toString(),
                };
              }).toList();

               */

              // Show grouped notifications
             // await showGroupedNotifications(notificationData,flutterLocalNotificationsPlugin);
            }
            if(mounted){
              setState(() {
                notifications = List<Map<String, dynamic>>.from(decodedResponse['notifications']);
                Provider.of<NotificationModel>(context, listen: false).setTotalNotifications(unreadNotifications.length);
                previousUnreadNotifications = unreadNotifications; // Update the cache
                showErrorOnce = false; // Reset on success
                isLoading = false; // Stop loading
              });
            }
          } else {
            _showError("The response doesn't contain notifications.");
          }
        } catch (e) {
          _showError("Error processing data");
        }
      } else {
        if (response.statusCode == 401) {
          _showError("Unauthorized access. Please check your authentication token.");
        } else if (response.statusCode == 404) {
          _showError("API not found. Please check the URL.");
        } else {
          _showError("Unexpected error.");
        }
      }
      return {};
    } on SocketException {
      if(!hasShownSockertError){
        _showError("Pas de connexion Internet. Veuillez vérifier votre réseau.");
        hasShownSockertError =  true;
      }
      return {};
    } on FormatException {
      if(!hasShownSockertError){
        _showError("Erreur de format. La réponse du serveur est invalide.");
      }
      return {};
    } on TimeoutException {
      if (!hasShownSockertError){
        _showError("Délai d'attente dépassé. Veuillez réessayer.");
      }
      return {};
    }
    finally {
      if(mounted){
        setState(() {
          isLoading = false; // Ensure loading stops in all cases
        });
      }
    }
  }


  Future<void> fetchNotificationsAndShow(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    // Call fetchnotifications method to get the notification data
    Map<String, dynamic> notificationData = await fetchnotifications();

    if (notificationData.isNotEmpty && notificationData.containsKey('notifications')) {
      List<Map<String, String>> notifications = List<Map<String, String>>.from(notificationData['notifications']);

      // Check if there are any unread notifications and show them
      if (notifications.isNotEmpty) {
        ///await showGroupedNotifications(notifications, flutterLocalNotificationsPlugin);
      }
    } else {
      // Handle the case where no notifications were retrieved
      //print("No notifications to display.");
    }
  }

// notification.dart

  Future<int> getNotificationsCount() async {
    final Map<String, dynamic> notificationsResponse = await fetchnotifications();

    // Vérifiez si la réponse contient des notifications
    if (notificationsResponse.isNotEmpty && notificationsResponse.containsKey('notifications')) {
      // Filtrer les notifications non lues
      var unreadNotifications = notificationsResponse['notifications'].where((notification) {
        return (notification['is_read'] is bool ? notification['is_read'] == false : notification['is_read'] == 0);
      }).toList();

      // Retourner le nombre de notifications non lues
      return unreadNotifications.length;
    } else {
      return 0; // Aucun nombre de notifications non lues
    }
  }





  Future<void> markAsRead(int notificationId) async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      _showError("Erreur d'authentification ou configuration. Veuillez vérifier vos paramètres.");
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

      if (response.statusCode == 200) {
        setState(() {
          notifications = notifications.map((notification) {
            if (notification['id'] == notificationId) {
              notification['is_read'] = true;
            }
            return notification;
          }).toList();
        });
      } else {
        debugPrint("Erreur API : ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur réseau : $e");
    }
  }

  Future<void> suppression() async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      _showError("Erreur d'authentification ou configuration. Veuillez vérifier vos paramètres.");
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

      if (response.statusCode == 200) {
        debugPrint("Toutes les notifications ont été supprimées avec succès.");
      } else {
        debugPrint("Erreur API : ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur réseau : $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  }
  List<Map<String, dynamic>> notification = [];

  Future<void> _loadNotifications() async {
    final dbHelper = DatabaseHelper();
    final data = await dbHelper.getNotifications(); // récupère toutes les notifications
    setState(() {
      notifications = data;
    });
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
          leadingWidth: 140, // 👈 augmente la largeur réservée à gauche
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
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
      body: user == null
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
          // 🔹 Champ de recherche
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
                setState(() {});
              },
            ),
          ),

          // 🔹 Compteurs
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

          // 🔹 Liste des notifications
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 🔹 ListView dans Expanded
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                ? const Center(child: Text('Aucune notification disponible.'))
                : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final idAffaire = notification['objet_cible'];
                final notificationId = notification['id'];

                // Vérifie si c’est l’élément sélectionné
                final bool isSelected = selectedIndex == index;

                // Définir la couleur de la carte
                Color cardColor;
                if (isSelected) {
                  cardColor = Colors.orangeAccent; // sélection temporaire
                } else if (notification['is_read'] == false) {
                  cardColor = Colors.white; // non lu
                } else {
                  cardColor = Colors.grey[200]!; // lu
                }

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  color: cardColor,
                  child: ListTile(
                    onTap: () async {
                      // Marquer comme lue si ce n'est pas déjà le cas
                      if (!notification['is_read']) {
                        await markAsRead(notificationId);
                        setState(() {
                          notification['is_read'] = true;
                        });
                      }

                      // Mettre à jour la sélection temporaire
                      setState(() {
                        selectedIndex = index;
                      });

                      // Afficher les détails
                      _showAffaireDetailsDialog(idAffaire);

                      // Réinitialiser la sélection après fermeture du dialogue
                      setState(() {
                        selectedIndex = null;
                      });
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
                      color: notification['is_read'] == false ? Colors.green : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavigator(currentIndex: 5),
    );
  }


  Future<Map<String, dynamic>> fetchRoleDetailsDecision(int idAffaire) async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      _showError("Erreur d'authentification ou configuration.");
      return {};
    }

    try {

      // Retirer le préfixe "http://" ou "https://"
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;

      final url = Uri.parse('https://$domainName/api/affaire/$idAffaire/');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      });

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        _showError('Erreur lors de la récupération des détails.');
        return {};
      }
    } catch (e) {

      // _showError('Erreur: $e');
      _showError('Erreur');
      return {};
    }
  }


  void _showAffaireDetailsDialog(int  idAffaire) async {
    try {
      final data = await fetchRoleDetailsDecision(idAffaire);
      final decisions = data['decisions'] ?? [];
      setState(() {
        selectedIndex = null;
      });
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(0.2), // un léger voile en plus du flou
        pageBuilder: (context, anim1, anim2) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // ✅ flou appliqué
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
                            side: const BorderSide(color: Colors.orangeAccent, width: 1.5), // ✅ couleur & épaisseur de la bordure
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // ✅ coins arrondis
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          child: const Text(
                            "Retour",
                            style: TextStyle(color: Colors.orangeAccent), // ✅ couleur du texte
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des détails")),
      );
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
            ),
            const Divider(),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const  WidgetSpan(
                    child: Text(
                      "Type: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)), // espace
                  TextSpan(text: decision['typeDecision'] ?? 'Non spécifié'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const  WidgetSpan(
                    child: Text(
                      "Date: ",
                      style:  TextStyle(fontWeight: FontWeight.bold),
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
                  const  WidgetSpan(
                    child: Text(
                      "Président: ",
                      style:  TextStyle(fontWeight: FontWeight.bold),
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
                  const  WidgetSpan(
                    child: Text(
                      "Greffier: ",
                      style:  TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['greffier'] ?? 'Inconnu'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Décision: ",
                      style:  TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(
                    text: decision['decision'] ?? 'Inconnu',
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Prochaine Audience: ",
                      style:  TextStyle(fontWeight: FontWeight.bold),
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
