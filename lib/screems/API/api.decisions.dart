// lib/services/affaire_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../db/base_sqlite.dart';


class AffaireService {
  final Logger logger = Logger();

  /// 🔹 Récupère les détails d'une affaire par son ID
  Future<Map<String, dynamic>> fetchAffaireDetails(String idAffaire) async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      logger.e("Erreur d'authentification ou configuration.");
      return {};
    }

    try {
      // Nettoyage du nom de domaine
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final url = Uri.parse('https://$domainName/api/affaire/$idAffaire/');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ///logger.i("✅ Affaire récupérée : $data");
        return data;
      } else {
        logger.e("❌ Erreur ${response.statusCode} : ${response.body}");
        return {};
      }
    } catch (e) {
      logger.e("Erreur réseau : $e");
      return {};
    }
  }
}
