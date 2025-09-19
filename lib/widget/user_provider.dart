import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import '../../model/user_model.dart'; // Assurez-vous que le chemin est correct
import 'package:http/http.dart' as http; // Pour les requêtes HTTP

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  String? domain;

  User? get currentUser => _currentUser;

  void setUser(User user) {
    _currentUser = user;
    notifyListeners(); // Notify listeners about the change
  }


  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null; // Réinitialiser l'utilisateur localement
    notifyListeners();
  }


  // Méthode pour récupérer les informations de l'utilisateur et du domaine via une API
  Future<void> fetchUserAndDomain() async {
    var logger = Logger(); // Create a logger instance
    try {
      // Faites une requête réelle à votre API pour récupérer l'utilisateur et le domaine
      final response = await http.get(Uri.parse('https://api.com/user-details'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Mettre à jour l'utilisateur à partir des données JSON
        setUser(User.fromMap(data['user']));  // Remplacement de fromJson par fromMap
        domain = data['domain']; // Domaine récupéré depuis l'API

        // Notifier les auditeurs après la mise à jour
        notifyListeners();
      } else {
        throw Exception('Erreur lors de la récupération des données utilisateur');
      }
    } catch (error) {
      logger.e('Erreur lors de la récupération de l\'utilisateur : $error');
    }
  }

}

