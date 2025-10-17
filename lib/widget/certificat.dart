import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../db/base_sqlite.dart';

Future<void> makeRequest(BuildContext context) async {
  var logger = Logger(); // Instance de logger
  try {
    // Récupérer le nom de domaine depuis la base de données
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null) {
      logger.e("Erreur : Aucun nom de domaine trouvé dans la base de données.");
      return;
    }

    // Retirer le préfixe "http://" ou "https://"
    domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
    domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;

    // Vérifiez si le domaine est vide après traitement
    if (domainName.isEmpty) {
      logger.e("Erreur : Nom de domaine non valide.");
      return;
    }

    // Construire l'URL complète
    final url = 'https://$domainName/api/posts/';
   /// logger.i("URL complète : $url");

    // Créer un HttpClient personnalisé
    HttpClient client = HttpClient();

    // Effectuer la requête
    var request = await client.getUrl(Uri.parse(url));
    var response = await request.close();

    // Lire la réponse
    if (response.statusCode == 200) {
      String responseBody = await response.transform(utf8.decoder).join();
     /// logger.i("Réponse réussie : $responseBody");

      if (responseBody.contains('<html')) {
        logger.w("Erreur : La réponse est du HTML, vérifiez l'URL.");
      }
    } else {
      logger.e("Erreur : Code de réponse ${response.statusCode}");
    }
  } catch (e) {
    logger.e("Exception capturée : $e");

    if (e is SocketException) {
      logger.e("Erreur réseau : ${e.message}. Vérifiez votre connexion ou le domaine.");
    } else if (e is HandshakeException) {
      logger.e("Erreur de handshake SSL. Redirection...");
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed("/home");
      }
    }
  }
}
