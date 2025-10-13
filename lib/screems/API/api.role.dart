/*
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../db/base_sqlite.dart';

class RoleApi {
  // Méthode pour récupérer les détails d'un rôle
  Future<Map<String, dynamic>?> fetchRoleDetails(String roleId) async {
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      throw Exception("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
    }

    try {
      String? token = await DatabaseHelper().getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Token d'authentification manquant. Veuillez vous reconnecter.");
      }

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
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du chargement des détails du rôle: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Méthode pour récupérer tous les rôles avec recherche
  Future<List<dynamic>> fetchAllRolesWithQuery(String query) async {
    int currentPage = 1;
    bool moreData = true;
    List<dynamic> allRoles = [];

    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      throw Exception("Nom de domaine invalide.");
    }

    if (!domainName.startsWith('http://') && !domainName.startsWith('https://')) {
      domainName = 'https://$domainName';
    }

    domainName = domainName.endsWith('/')
        ? domainName.substring(0, domainName.length - 1)
        : domainName;

    while (moreData) {
      final url = Uri.parse('$domainName/api/roles/?page=$currentPage&search=$query/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = utf8.decode(response.bodyBytes);
        final decodedResponse = jsonDecode(jsonResponse);
        final List<dynamic> rolesData = decodedResponse['roles']['results'];

        if (rolesData.isEmpty) {
          moreData = false;
        } else {
          allRoles.addAll(rolesData);
          currentPage++;
        }
      } else {
       /// throw Exception("Erreur lors de la récupération des données.");
      }
    }

    return allRoles;
  }

  // Méthode pour récupérer les rôles avec pagination
  Future<Map<String, dynamic>> fetchRoles({int page = 1}) async {
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      throw Exception("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
    }

    // Vérifier la connectivité Internet
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception("Pas de connexion Internet. Veuillez vérifier votre réseau.");
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final url = Uri.parse('https://$domainName/api/roles/?page=$page');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = utf8.decode(response.bodyBytes);
        final decodedResponse = jsonDecode(jsonResponse);

        if (decodedResponse is Map<String, dynamic> && decodedResponse.containsKey('roles')) {
          final rolesData = decodedResponse['roles'];
          if (rolesData is Map<String, dynamic> && rolesData.containsKey('results')) {
            List<dynamic> newRoles = rolesData['results'];
            int totalItems = rolesData['total_items'] ?? 0;
            int itemsPerPage = rolesData['items_per_page'] ?? 10;
            int totalPages = (totalItems / itemsPerPage).ceil();

            return {
              'roles': newRoles,
              'totalPages': totalPages,
              'currentPage': page
            };
          } else {
            throw Exception('Les données des rôles sont dans un format incorrect.');
          }
        } else {
          throw Exception('Une erreur s\'est produite lors de la récupération des données.');
        }
      } else {
        throw Exception('Erreur lors de la récupération des données: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Erreur réseau : Problème de connexion');
    } on HttpException {
      throw Exception('Erreur HTTP : Vérifiez l\'URL');
    } on FormatException {
      throw Exception('Erreur de format : URL mal formée');
    } catch (error) {
      throw Exception('Erreur lors de la récupération des données: $error');
    }
  }
}

 */