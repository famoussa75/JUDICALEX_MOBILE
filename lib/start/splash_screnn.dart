import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqlite_api.dart';

import '../db/base_sqlite.dart';
import '../model/user_model.dart';
import '../widget/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen ({super.key});
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateUser();
  }

  // Instanciez DatabaseHelper
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<void> _navigateUser() async {


    await Future.delayed(const Duration(seconds: 3));

    final Database db = await dbHelper.database;
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch');

    final Map<String, dynamic>? user = await _getExistingUser(db);


    // Vérifiez si le widget est toujours monté avant d'utiliser le context
    if (!mounted) return;

    if (isFirstLaunch == null || isFirstLaunch) {
      await prefs.setBool('isFirstLaunch', false);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/PubSlider');
      }
    } else {
      if (user != null) {
        // Mettez à jour UserProvider avec l'utilisateur actuel
        Provider.of<UserProvider>(context, listen: false).setUser(
          User(
            id: user['id'],
            username: user['username'],
            email: user['email'],
            token: user['token'],
            first_name: user['first_name'],
            photo: user['photo'],
            last_name: user['last_name'],
            isFirstLogin: user['is_first_login'] == 1,
            password: user['password'],
          ),
        );

        // Redirigez vers la page principale
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    }
  }

// Méthode pour récupérer un utilisateur existant dans la table "users"
  Future<Map<String, dynamic>?> _getExistingUser(Database db) async {
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: 'is_first_login = ?',
      whereArgs: [0],
      limit: 1,
    );

    return users.isNotEmpty ? users.first : null;
  }


// Fonction pour vérifier si la table est vide
  Future<bool> isDataCountryEmpty(Database db) async {
    final List<Map<String, dynamic>> results = await db.rawQuery('SELECT COUNT(*) as count FROM data_country');
    return results.isNotEmpty && results[0]['count'] == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e293b),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            const SizedBox(height: 100),
            const Spacer(),
            SizedBox(
              width: 200,
              child: Image.asset("images/judicalex-blanc.png"), // Assurez-vous que l'image est dans le dossier assets
            ),
            const Spacer(),
            const CircularProgressIndicator(), // Animation de chargement
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
