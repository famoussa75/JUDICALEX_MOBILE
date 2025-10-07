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
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      throw Exception("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
    }

    String? token = await DatabaseHelper().getToken();

    print("🔐 TOKEN RÉCUPÉRÉ : $token");
    print("📝 Longueur du token : ${token?.length} caractères");

    if (token == null || token.isEmpty) {
      throw Exception("Aucun token trouvé. Veuillez vérifier votre connexion et réessayer.");
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^(http://|https://)'), '').replaceAll(RegExp(r'/+$'), '');
      final url = Uri.parse('https://$domainName/api/commentaires/');

      final requestBody = {
        "user_id": userId,
        "post_id": postId,
        "content": comment,
      };

      print("🌐 URL de la requête : $url");
      print("📦 Corps de la requête : $requestBody");


      // Préparer les headers
      Map<String, String> headers = {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      print("📡 Statut de la réponse : ${response.statusCode}");
      print("📨 Corps de la réponse : ${response.body}");
      print("🔧 Headers de la réponse : ${response.headers}");

      if (response.statusCode == 201) {
        print("✅ Commentaire envoyé avec succès");
        return true;
      } else if (response.statusCode == 403) {
        // Essayer sans le token CSRF ou avec une approche différente
        print("🔄 Tentative sans CSRF token...");
        final response2 = await http.post(
          url,
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        );

        if (response2.statusCode == 201) {
          print("✅ Commentaire envoyé avec succès (sans CSRF)");
          return true;
        } else {
          print("❌ Échec même sans CSRF: ${response2.statusCode}");
          throw Exception('Erreur d\'autorisation. Veuillez vous reconnecter.');
        }
      } else {
        throw Exception('L\'envoi du commentaire a échoué. Statut: ${response.statusCode}');
      }
    } catch (e) {
      print("⛔ Erreur catch : $e");
      throw Exception('Une erreur est survenue lors de l\'envoi du commentaire.');
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