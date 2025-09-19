import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ejustice/db/base_sqlite.dart';
///import 'package:ejustice/main.dart';
import 'package:ejustice/widget/domain_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';



class NotificationProvider with ChangeNotifier {
  int totalNotifications = 0;
  bool isLoading = false;
  bool showErrorOnce = false;
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> previousUnreadNotifications = [];
  Timer? _timer;

  // Méthode pour démarrer la récupération périodique des notifications
  void startFetchingNotifications(BuildContext context) {
    // Arrêtez tout Timer existant avant d'en créer un nouveau
    stopFetchingNotifications();
    // Exécute la méthode fetchnotifications toutes les 5 secondes
    _timer = Timer.periodic( const  Duration(seconds: 5), (timer) {
      fetchnotifications(context);

    });
  }

  // Méthode pour arrêter la récupération périodique des notifications
  void stopFetchingNotifications() {
    _timer?.cancel();
    _timer = null;
  }


  // Nettoyage des ressources lorsque le provider est détruit
  @override
  void dispose() {
    stopFetchingNotifications();
    super.dispose();
  }



  // Méthode pour récupérer les notifications
  Future<void> fetchnotifications(BuildContext context) async {

   // print("fetchnotifications appelée à ${DateTime.now()}"); // Ajout de log

    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    // Si le token ou le domaine est invalide, on arrête la récupération des notifications
    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      if (!showErrorOnce) {
        showErrorOnce = true;
      }
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Format du nom de domaine
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;
      final url = Uri.parse('https://$domainName/api/notifications/all/');

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      });

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

        if (decodedResponse is Map && decodedResponse.containsKey('notifications')) {
          notifications = List<Map<String, dynamic>>.from(decodedResponse['notifications']);

          // Filtrer les notifications non lues
          var unreadNotifications = notifications.where((notification) => notification['is_read'] == false).toList();


          // Liste des notifications à afficher
          List<Map<String, String>> notificationData = [];

          // Si de nouvelles notifications non lues existent, on les met à jour
          if (unreadNotifications.length > previousUnreadNotifications.length) {
            // On limite le nombre de notifications à 10+ si supérieur à 10
            int totalCount = unreadNotifications.length > 10 ? 10 : unreadNotifications.length;

            previousUnreadNotifications = unreadNotifications;

            // Afficher les notifications groupées si besoin
            List<Map<String, String>> notificationData = unreadNotifications.map((notification) {
              return {
                'title': (notification['title'] ?? 'Notification').toString(),
                'message': (notification['message'] ?? 'No message available').toString(),
              };
            }).toList();
           // await showGroupedNotifications(notificationData, flutterLocalNotificationsPlugin);

            // Mettre à jour le NotificationModel avec le nombre de notifications non lues
            final notificationModel = Provider.of<NotificationModel>(context, listen: false);
            notificationModel.setTotalNotifications(totalCount); // Met à jour avec le nombre limité ou 10+
          }


          // Mise à jour de l'état
          isLoading = false;
          showErrorOnce = false;
          notifyListeners();
          // Simulons la récupération des notifications non lues
          await Future.delayed(Duration(seconds: 2));

          // Si des nouvelles notifications à afficher
          if (notificationData.isNotEmpty) {
            // Afficher les notifications
            ///await showGroupedNotifications(notificationData, flutterLocalNotificationsPlugin);
          }
        } else {
          showError("The response doesn't contain notifications.");
        }
      } else {
        handleHttpErrors(response.statusCode);
      }
    } on SocketException {
      //showError("No internet connection. Please check your network.");
    } on FormatException {
      showError("Format error. The server response is invalid.");
    } on TimeoutException {
      showError("Request timeout. Please try again.");
    } catch (e) {
      showError("An unexpected error occurred: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  void updateNotifications(int count) {
    totalNotifications = count > 10 ? 10 : count;
    notifyListeners();
  }



  // Error handler for HTTP errors
  void handleHttpErrors(int statusCode) {
    if (statusCode == 401) {
      showError("Unauthorized access. Please check your authentication token.");
    } else if (statusCode == 404) {
      showError("API not found. Please check the URL.");
    } else {
      showError("Unexpected error.");
    }
  }

  void showError(String message) {
    // Afficher un message d'erreur
    print(message);
  }

}




