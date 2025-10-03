

import 'package:flutter/material.dart';
import 'dart:io'; // Importer pour accéder à File
import 'package:path_provider/path_provider.dart';

import '../../db/base_sqlite.dart';
import '../../model/user_model.dart'; // Pour obtenir le répertoire local

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<User> userList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUsers();
  }

  Future<void> _getUsers() async {
    List<User> users = await dbHelper.getAllUsers();
    setState(() {
      userList = users;
      isLoading = false; // Chargement terminé
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liste des Utilisateurs")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userList.isEmpty
          ? const Center(child: Text("Aucun utilisateur trouvé"))
          : ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) {
          String? photoPath = userList[index].photo;
          String fullPhotoUrl = photoPath != null && photoPath.startsWith('https')
              ? photoPath
              : 'https://judicalex-gn.org/$photoPath'; // Compléter l'URL si partiel

          return ListTile(
            leading: Stack(
              children: [
                FutureBuilder<ImageProvider<Object>>(
                  future: _getBackgroundImage(fullPhotoUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey, // Couleur de fond si l'image est manquante
                      );
                    } else if (snapshot.hasError) {
                      return const CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage('images/user.png'), // Image par défaut
                      );
                    } else {
                      return CircleAvatar(
                        radius: 30,
                        backgroundImage: snapshot.data, // L'image est chargée avec succès
                        backgroundColor: Colors.grey,
                      );
                    }
                  },
                ),
              ],
            ),
            title: Text(
              '${userList[index].first_name ?? 'Prénom inconnu'} ${userList[index].last_name ?? 'Nom inconnu'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text('Email: ${userList[index].email ?? 'Email non fourni'}'),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.perm_identity_sharp, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text('id: ${userList[index].id ?? 'ID non fourni'}'),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text('Nom d\'utilisateur: ${userList[index].username ?? 'Nom d\'utilisateur inconnu'}'),
                  ],
                ), Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text('token: ${userList[index].token ?? 'token'}'),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.lock, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text('Mot de passe: ${userList[index].password ?? 'Mot de passe non fourni'}'),
                  ],
                ),

              ],
            ),
            contentPadding: const EdgeInsets.all(10),
            isThreeLine: true,
          );
        },
      ),
    );
  }

  Future<ImageProvider<Object>> _getBackgroundImage(String? fullPhotoUrl) async {
    if (fullPhotoUrl != null && fullPhotoUrl.isNotEmpty) {
      if (fullPhotoUrl.startsWith('https://')) {
        // Charger l'image depuis l'URL complète
        return NetworkImage(fullPhotoUrl);
      } else {
        // Charger l'image locale si elle existe
        try {
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/${fullPhotoUrl.replaceAll('//', '/')}';
          final file = File(filePath);

          if (await file.exists()) {
            return FileImage(file); // Image locale
          } else {
            print('Fichier non trouvé : $filePath');
          }
        } catch (e) {
          print('Erreur lors du chargement de l\'image : $fullPhotoUrl. Erreur : $e');
        }
      }
    }
    // Image par défaut si aucune image n'est trouvée
    return const AssetImage('images/user.png');
  }
}
