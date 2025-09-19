import 'package:shared_preferences/shared_preferences.dart';  // Pour stocker les notifications envoyées
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:ejustice/db/base_sqlite.dart';


/// Cette fonction est utilisée pour vérifier les notifications déjà envoyées
Future<List<String>> getSentNotifications() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Récupère les notifications envoyées sous forme de liste de String (ID ou hash des notifications)
  return prefs.getStringList('sent_notifications') ?? [];
}

/// Fonction pour sauvegarder les notifications envoyées
Future<void> saveSentNotifications(List<String> sentNotifications) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Sauvegarde la liste des notifications envoyées
  await prefs.setStringList('sent_notifications', sentNotifications);
}

/// Fonction principale qui récupère et affiche les notifications
Future<void> fetchNotificationsAndShow(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  String? token = await DatabaseHelper().getToken();
  String? domainName = await DatabaseHelper().getDomainName();

  if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
    return;
  }

  try {
    // Nettoyer et formater le nom de domaine
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
        List<Map<String, dynamic>> notifications = List<Map<String, dynamic>>.from(decodedResponse['notifications']);

        // Filtrer les notifications non lues
        var unreadNotifications = notifications.where((notification) => notification['is_read'] == false).toList();

        // Obtenir les notifications déjà envoyées
        List<String> sentNotifications = await getSentNotifications();

        // Liste des notifications à afficher
        List<Map<String, String>> notificationData = [];

        for (var notification in unreadNotifications) {
          String notificationId = notification['id'].toString();  // Utiliser un identifiant unique pour la notification

          // Si cette notification n'a pas déjà été envoyée, l'ajouter à la liste des notifications à envoyer
          if (!sentNotifications.contains(notificationId)) {
            notificationData.add({
              'title': (notification['title'] ?? 'Notification').toString(),
              'message': (notification['message'] ?? 'No message available').toString(),
            });

            // Ajouter l'ID de la notification à la liste des notifications envoyées
            sentNotifications.add(notificationId);
          }
        }

        // Si des nouvelles notifications à afficher
        if (notificationData.isNotEmpty) {
          // Afficher les notifications
          await showGroupedNotifications(notificationData, flutterLocalNotificationsPlugin);

          // Sauvegarder les notifications envoyées
          await saveSentNotifications(sentNotifications);
        }
      }
    }
  } catch (e) {
    //print('Error fetching notifications: $e');
  }
}

/// Fonction pour afficher les notifications groupées
Future<void> showGroupedNotifications(List<Map<String, String>> notifications, FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  for (var notification in notifications) {
    await showNotification(flutterLocalNotificationsPlugin, notification['title']!, notification['message']!);
  }
}

/// Fonction pour afficher une notification individuelle
Future<void> showNotification(FlutterLocalNotificationsPlugin plugin, String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'channel_id', 'channel_name',
    importance: Importance.high, priority: Priority.high, showWhen: false,
    icon: null,  // Aucune icône par défaut
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await plugin.show(0, title, body, platformChannelSpecifics);
}
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Vérifiez si le service fonctionne déjà
  if (await service.isRunning()) return;

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: true, // Garder le mode foreground activé

    ),
    iosConfiguration: IosConfiguration(
      onBackground: onStart,
      autoStart: false,
    ),
  );

  service.startService();
}

Future<bool> onStart(ServiceInstance service) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Créer un canal de notification silencieux
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'silent_channel_id', // ID du canal
    'Silent Notifications', // Nom du canal
    description: 'Notifications for background service', // Description du canal
    importance: Importance.min, // Importance minimale (notification silencieuse)
    showBadge: false, // Ne pas afficher de badge
  );

  // Initialiser les notifications locales
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Créer le canal de notification
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Écouter les changements de connectivité
  Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    if (result == ConnectivityResult.wifi || result == ConnectivityResult.mobile) {
      fetchNotificationsAndShow(flutterLocalNotificationsPlugin);
    }
  });

  // Afficher les notifications immédiatement après le démarrage
  await fetchNotificationsAndShow(flutterLocalNotificationsPlugin);

  // Supprimer les notifications après 1 seconde
  await Future.delayed(const Duration(seconds: 1), () async {
    flutterLocalNotificationsPlugin.cancelAll(); // Annule toutes les notifications
  });

  // Écouter l'événement "removeNotification" pour enlever la notification
  service.on("removeNotification").listen((event) {
    flutterLocalNotificationsPlugin.cancelAll(); // Supprime les notifications
  });

  return true;
}

