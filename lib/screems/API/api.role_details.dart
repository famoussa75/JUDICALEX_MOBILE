// api_role_detail.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../db/base_sqlite.dart';

class RoleDetailApi {
  // Méthode pour récupérer les détails du rôle
  Future<Map<String, dynamic>> fetchRoleDetails(String roleId) async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty) {
      throw Exception("Le token d'authentification est manquant. Veuillez vous reconnecter pour continuer.");
    }

    if (domainName == null || domainName.isEmpty) {
      throw Exception("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final url = Uri.parse('https://$domainName/api/role/$roleId/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Impossible de charger les détails du rôle. Veuillez réessayer.');
      }
    } catch (e) {
      throw Exception('Une erreur est survenue. Nous vous prions de bien vouloir réessayer.');
    }
  }

  // Méthode pour suivre une affaire
  Future<bool> suivreAffaire(
      List<String> idAffaires,
      String juridiction,
      String? userId
      ) async {
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      throw Exception("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
    }

    if (userId == null) {
      throw Exception("Aucun utilisateur connecté. Veuillez vous connecter.");
    }

    String? token = await DatabaseHelper().getUserToken(userId);
    if (token == null) {
      throw Exception("Aucun token trouvé. Veuillez vérifier votre connexion et réessayer.");
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^(http://|https://)'), '').replaceAll(RegExp(r'/+$'), '');
      final url = Uri.parse('https://$domainName/api/suivre-affaire/');

      final requestBody = {
        "selected": idAffaires,
        "account_id": userId,
        "juridiction_id": juridiction,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('La mise à jour des affaires a échoué. Veuillez réessayer plus tard.');
      }
    } catch (e) {
      throw Exception('Une erreur est survenue lors du suivi des affaires.');
    }
  }

  // Méthode pour ne plus suivre une affaire
  Future<bool> nePasSuivre(
      List<String> idAffaires,
      String juridiction,
      String? userId
      ) async {
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      throw Exception("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
    }

    if (userId == null) {
      throw Exception("Aucun utilisateur connecté. Veuillez vous connecter.");
    }

    String? token = await DatabaseHelper().getUserToken(userId);
    if (token == null) {
      throw Exception("Aucun token trouvé. Veuillez vérifier votre connexion et réessayer.");
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^(http://|https://)'), '').replaceAll(RegExp(r'/+$'), '');
      final url = Uri.parse('https://$domainName/api/ne-pas-suivre-affaire/');

      final requestBody = {
        "selected": idAffaires,
        "account_id": userId,
        "juridiction_id": juridiction,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Échec de la mise à jour des affaires.');
      }
    } catch (e) {
      throw Exception('Une erreur est survenue lors de l\'arrêt du suivi des affaires.');
    }
  }

  // Méthode pour récupérer les détails des décisions d'une affaire
  Future<Map<String, dynamic>> fetchRoleDetailsDecision(String idAffaire) async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      throw Exception("Erreur d'authentification ou configuration.");
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final url = Uri.parse('https://$domainName/api/affaire/$idAffaire/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Erreur lors de la récupération des détails.');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des détails de décision.');
    }
  }

  // Méthode pour charger les affaires suivies depuis les préférences partagées
  Future<List<String>> loadFollowedAffairs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? followedAffairs = prefs.getStringList('followedAffairs');
    return followedAffairs ?? [];
  }
}