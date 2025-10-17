// lib/screems/audience/api.mesAffaire.dart
import 'dart:convert';
///import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../db/base_sqlite.dart';
import 'package:flutter/material.dart';

class MesAffaireApi {
  // --- Récupération des affaires suivies ---
  static Future<List<dynamic>> fetchAffaires(BuildContext context) async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      _showError(context, "Erreur d'authentification ou configuration.");
      return [];
    }

    try {
      domainName = _cleanDomain(domainName);
      final url = Uri.parse('https://$domainName/api/mes-affaires-suivies/');

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
        _showError(context, 'Erreur lors de la récupération des détails.');
        return [];
      }
    } catch (e) {
      _showError(context, 'Erreur de connexion');
      return [];
    }
  }

  // --- Récupération des détails d’une affaire spécifique ---
  static Future<Map<String, dynamic>> fetchRoleDetailsDecision(
      BuildContext context, int idAffaire) async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      _showError(context, "Erreur d'authentification ou configuration.");
      return {};
    }

    try {
      domainName = _cleanDomain(domainName);
      final url = Uri.parse('https://$domainName/api/affaire/$idAffaire/');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      });

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        _showError(context, 'Erreur lors de la récupération des détails.');
        return {};
      }
    } catch (e) {
      _showError(context, 'Erreur de chargement.');
      return {};
    }
  }

  // --- Récupération des rôles paginés ---
  static Future<List<dynamic>> fetchPostsPage(BuildContext context, int page) async {
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) return [];

    domainName = _cleanDomain(domainName);
    final url = Uri.parse('https://$domainName/api/roles/?page=$page');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = utf8.decode(response.bodyBytes);
        final decodedResponse = jsonDecode(jsonResponse);

        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse.containsKey('roles')) {
          final rolesData = decodedResponse['roles'];
          if (rolesData is Map<String, dynamic> &&
              rolesData.containsKey('results')) {
            return List<dynamic>.from(rolesData['results']);
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération de la page $page : $e");
    }
    return [];
  }

  // --- Vérifie la connexion Internet ---
  static Future<bool> hasInternetConnection(BuildContext context) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showError(context, "Pas de connexion Internet.");
      return false;
    }
    return true;
  }

  // --- Fonctions utilitaires internes ---
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _cleanDomain(String domain) {
    domain = domain.replaceAll(RegExp(r'^https?://'), '');
    return domain.endsWith('/') ? domain.substring(0, domain.length - 1) : domain;
  }
}
