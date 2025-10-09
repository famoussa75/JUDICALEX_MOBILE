// api_news.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../db/base_sqlite.dart';

class NewsApi {
  var logger = Logger();

  Future<List<dynamic>> fetchPosts() async {
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      throw Exception('Nom de domaine non défini ou vide.');
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final apiUrl = 'https://$domainName/api/posts/';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        return jsonData;
      } else {
        throw Exception('Erreur lors de la récupération des données');
      }
    } catch (error) {
      logger.e('Erreur fetchPosts: $error');
      throw Exception('Erreur lors de la récupération des posts');
    }
  }

  Future<Map<String, dynamic>> fetchAds() async {
    try {
      String? domainName = await DatabaseHelper().getDomainName();
      if (domainName == null || domainName.isEmpty) {
        throw Exception('Nom de domaine non défini ou vide.');
      }

      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final apiUrl = Uri.https(domainName, "/api/ads/");
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        return {
          'headerAds': jsonData["header"] ?? [],
          'sidebarAds': jsonData["sidebar"] ?? []
        };
      } else {
        throw Exception('Erreur lors de la récupération des données');
      }
    } catch (e) {
      logger.e("Erreur fetchAds: $e");
      throw Exception('Erreur lors de la récupération des publicités');
    }
  }


  Future<bool> envoyerCommentaire(int userId, int postId, String comment) async {
    // 1️⃣ Récupérer le domaine
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      throw Exception("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
    }

    // 2️⃣ Récupérer le token de l'utilisateur
    String? token = await DatabaseHelper().getUserToken(userId.toString());
    if (token == null || token.isEmpty) {
      throw Exception("Aucun token trouvé. Veuillez vous reconnecter.");
    }

    try {
      // 3️⃣ Nettoyer le domaine
      domainName = domainName
          .replaceAll(RegExp(r'^(http://|https://)'), '')
          .replaceAll(RegExp(r'/+$'), '');

      // 4️⃣ Construire l'URL dynamique
      final url = Uri.parse('https://$domainName/api/posts/$postId/comments/');

      // 5️⃣ Créer le body
      final requestBody = {
        'user_id': userId,
        'post_id': postId,
        'content': comment,
      };

      // 6️⃣ Envoyer la requête POST
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token', // ✅ token dynamique
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print("URL: $url");
      print("Token: $token");
      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");

      // 7️⃣ Vérifier le status
      if (response.statusCode == 201 || response.statusCode == 200) {
        logger.i('✅ Commentaire envoyé avec succès');
        // 🔹 Mettre à jour automatiquement les posts après ajout
        await fetchPosts(); // Recharge la liste et met à jour postsNotifier
        return true;
      } else {
        logger.e('❌ Erreur ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      logger.e("⛔ Erreur lors de l'envoi du commentaire: $e");
      return false;
    }
  }


  Future<String> generateArticleUrl(String slug) async {
    String? domainName = await DatabaseHelper().getDomainName();

    if (domainName != null && domainName.endsWith('/')) {
      domainName = domainName.substring(0, domainName.length - 1);
    }
    return '$domainName/blog/post/$slug/';
  }
}