// custom_dialog.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:judicalex/db/base_sqlite.dart';
import 'package:provider/provider.dart';

import 'domain_provider.dart';

class CustomDialogBox extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;

  const CustomDialogBox({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // ferme la boîte
            onConfirm(); // exécute l’action passée
          },
          child: Text(
            confirmText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}


class NotificationFetcher {
  static bool hasShownSocketError = false;

  /// Appelle l’API pour récupérer les notifications et les stocker localement
  static Future<void> fetchAndSaveNotifications(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelper();
      String? token = await dbHelper.getToken();
      String? domainName = await dbHelper.getDomainName();

      if (token == null || domainName == null || token.isEmpty || domainName.isEmpty) {
        debugPrint("⚠️ Token ou domaine manquant");
        return;
      }

      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      if (domainName.endsWith('/')) {
        domainName = domainName.substring(0, domainName.length - 1);
      }

      final url = Uri.parse('https://$domainName/api/notifications/all/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedResponse is Map && decodedResponse.containsKey('notifications')) {
          final List<Map<String, dynamic>> fetchedNotifications =
          List<Map<String, dynamic>>.from(decodedResponse['notifications']);

          // Récupérer les notifications existantes
          final existingNotifications = await dbHelper.getNotifications();
          final existingIds =
          existingNotifications.map((e) => e['notif_id']).toSet();

          // Filtrer les nouvelles notifications
          final newNotifications = fetchedNotifications
              .where((notif) => !existingIds.contains(notif['id']))
              .toList();

          // Insérer les nouvelles dans SQLite
          for (var notif in newNotifications) {
            await dbHelper.insertNotification({
              'notif_id': notif['id'],
              'title': notif['title'] ?? 'Notification',
              'message': notif['message'] ?? 'Aucun message',
              'is_read': (notif['is_read'] is bool
                  ? (notif['is_read'] ? 1 : 0)
                  : notif['is_read']),
            });
          }

          // Mettre à jour le provider
          final unreadNotifications = fetchedNotifications
              .where((n) => (n['is_read'] is bool
              ? n['is_read'] == false
              : n['is_read'] == 0))
              .toList();

          Provider.of<NotificationModel>(context, listen: false)
              .setTotalNotifications(unreadNotifications.length);

          debugPrint("✅ Notifications mises à jour (${fetchedNotifications.length})");
        } else {
          debugPrint("⚠️ Réponse inattendue de l'API");
        }
      } else {
        debugPrint("❌ Erreur API (${response.statusCode})");
      }
    } on SocketException {
      if (!hasShownSocketError) {
        hasShownSocketError = true;
        debugPrint("📡 Pas de connexion Internet");
      }
    } catch (e) {
      debugPrint("❌ Erreur lors du fetch des notifications: $e");
    }
  }
}

