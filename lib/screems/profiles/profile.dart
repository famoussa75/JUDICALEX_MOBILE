
import 'package:ejustice/db/base_sqlite.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:ejustice/widget/user_provider.dart';
import 'package:ejustice/widget/drawer.dart';
import '../../model/user_model.dart';
import '../../widget/bottom_navigation_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../authentification/login.dart';


class Users extends StatefulWidget {
  const Users({super.key});
  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  String? domainName;
  List<dynamic> affairesData = [];
  List<dynamic> filteredAffairesData = [];
  bool isLoading = true;
  int numberOfAffaires = 0; // Variable pour stocker le nombre d'affaires


  String? profilePhotoPath;
  var logger = Logger(); // Create a logger instance


  @override
  void initState() {
    super.initState();
    _loadDomainName();
    fetchAffaires(); // Charger les affaires au démarrage
  }


  Future<void> _loadDomainName() async {
    final dbHelper = DatabaseHelper(); // Créez une instance de DatabaseHelper
    String? domain = await dbHelper.getDomainName(); // Récupérez le nom de domaine
    setState(() {
      domainName = domain; // Mettez à jour l'état
    });
  }

  Future<void> fetchAffaires() async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
     //_showError("Erreur d'authentification ou configuration.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;

      final url = Uri.parse('https://$domainName/api/mes-affaires-suivies/');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          affairesData = data;
          filteredAffairesData = affairesData;
          numberOfAffaires = affairesData.length; // Mettre à jour le nombre d'affaires
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showError('Erreur lors de la récupération des détails.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Erreur');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }





  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
      drawer: const MyDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF1e293b),
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          automaticallyImplyLeading: true,
          leadingWidth: 140, // 👈 augmente la largeur réservée à gauche
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "images/judicalex-blanc.png",
              height: 80, // 👈 tu peux tester 80 ou 100
            ),
          ),
          title: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, "/NotificationPage");
              },
            ),
          ],
        ),
      ),
      body: user == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centre le Column
          children: [
            Icon(Icons.info, size: 48), // Remplacez par l'icône de votre choix
             SizedBox(height: 8), // Espacement entre l'icône et le texte
             Text(
              "L'accès à ces informations est réservé aux utilisateurs connectés. Veuillez vous connecter pour continuer.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center, // Centre le texte
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Afficher la photo de l'utilisateur
            if (user.photo.isNotEmpty && domainName != null) // Vérifiez si l'utilisateur et le domaine ne sont pas nuls
              CircleAvatar(
                radius: 60, // Ajustez la taille du cercle
                backgroundImage: NetworkImage(
                    user.photo.contains(domainName!) // Utilisez le point d'exclamation pour indiquer que domainName est non nul
                        ? user.photo // Si l'URL contient déjà le domaine, l'utiliser telle quelle
                        : '$domainName/${user.photo}' // Sinon, ajouter le domaine à l'URL
                ),
              )
            else
              const Icon(Icons.person, size: 30), // Icône par défaut si pas de photo
            const SizedBox(height: 20),
            Row(
               mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.last_name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 5),
                Text(
                  user.first_name,
                  style: const TextStyle(fontSize: 24,fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              user.email,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e293b), // 🔹 Bleu foncé
                        borderRadius: BorderRadius.circular(8), // coins arrondis
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Affaire(s) Suivi (s) ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Bloc avec la ligne + le nombre d’affaires
                          Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                height: 20,
                                width: 1,
                                color: Colors.white,
                              ),
                              Text(
                                "$numberOfAffaires",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
           const SizedBox(height: 20,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                children: [
                  // 🔹 Première ligne
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, "/MyAccount"); // 🔹 Redirection vers la page account
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue),
                              SizedBox(width: 10),
                              Text(
                                "Modifier mon profil",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 🔹 Deuxième ligne
                  GestureDetector(
                    onTap: () => _updatePassword(user), // action au clic
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 🔹 Icône + Texte à gauche
                          Row(
                            children: [
                              Icon(Icons.lock, color: Colors.orange),
                              SizedBox(width: 10),
                              Text(
                                "Modifier le Mot de Passe",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),

                          // 🔹 Icône de droite
                          Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),



                ],
              ),
            ),


            const SizedBox(height: 20),
            const Padding(
             padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Préférences",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                children: [
                  // 🔹 Première ligne
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children:  [
                            Icon(Icons.settings, color: Colors.blue),
                            SizedBox(width: 10),
                            Text(
                              "Paramètres",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () {
                      logout(user); // 🔹 Action de déconnexion
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child:const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.logout, color: Colors.blue),
                               SizedBox(width: 10),
                               Text(
                                "Se déconnecter",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                           Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  )

                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomNavigator(currentIndex: 5),
    );
  }

  Future<void> _updatePassword(User user) async {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Modifier le Mot de Passe"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: "Nouveau Mot de Passe"),
                obscureText: true,
              ),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(labelText: "Confirmer le Mot de Passe"),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Vérifier que les champs ne sont pas vides
                if (newPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Les champs de mot de passe ne peuvent pas être vides.")),
                  );
                  return;
                }
                // Utiliser la validation personnalisée pour vérifier le mot de passe
                final String? passwordError = validatePassword(newPasswordController.text);
                if (passwordError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(passwordError)),
                  );
                  return;
                }

                // Vérifier que les mots de passe correspondent
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Les mots de passe ne correspondent pas.")),
                  );
                  return;
                }

                // Appeler l'API pour mettre à jour le mot de passe
                final bool success = await _updateAccountApi(user, newPassword: newPasswordController.text);
                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mot de passe mis à jour avec succès.")),
                    );
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Fermer la boîte de dialogue
                  }

                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Erreur lors de la mise à jour du mot de passe.")),
                    );
                  }

                }
              },
              child: const Text("Sauvegarder"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _updateAccountApi(User user, {String? newPassword, bool updatePhotoOnly = true}) async {
    String? domainName = await DatabaseHelper().getDomainName();

    // Perform the check asynchronously if needed
    if (domainName == null || domainName.isEmpty) {
      // Ensure the widget is still mounted before interacting with the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Le nom de domaine est manquant ou invalide.")),
        );
      }
      return false; // Invalid domain name
    }

    // Supprimer les protocoles http:// ou https:// du nom de domaine
    domainName = domainName.replaceAll(RegExp(r'^https?://'), '');

    // Construire l'URL pour l'API de mise à jour du compte
    final String url = 'https://$domainName/api/account/update/${user.id}/';

    final request = http.MultipartRequest('PUT', Uri.parse(url))
      ..headers['Authorization'] = 'Bearer YOUR_ACCESS_TOKEN'; // Remplacez par votre vrai token d'accès

    // Ajouter les champs pour la mise à jour, incluant le mot de passe si fourni
    final Map<String, dynamic> body = {
      'last_name': user.last_name,
      'first_name': user.first_name ,
      'username': user.username ,
      'email': user.email,
    };

    // Si un nouveau mot de passe est fourni, l'ajouter
    if (newPassword != null && newPassword.isNotEmpty) {
      body['password'] = newPassword;
      body['confirm_password'] = newPassword;
    }

    // Ajouter les champs au corps de la requête
    request.fields.addAll(body.map((key, value) => MapEntry(key, value.toString())));

    // Si vous mettez à jour uniquement la photo, ajoutez le fichier photo
    if (updatePhotoOnly && profilePhotoPath != null) {
      final file = await http.MultipartFile.fromPath('photo', profilePhotoPath!);
      request.files.add(file);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Ensure the widget is still mounted before showing a SnackBar or performing UI updates
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Informations mises à jour avec succès.")),
          );
          return true; // Mise à jour réussie
        } else {
          logger.e('Erreur serveur: ${response.statusCode} - ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur serveur")),
          );
          return false; // Mise à jour échouée
        }
      }
    } catch (error) {
      // Ensure the widget is still mounted before showing a SnackBar or performing UI updates
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion")),
        );
      }
      return false; // Erreur de connexion
    }
    return false; // Default return if an error occurs before the conditions
  }

  // Validation personnalisée pour le mot de passe
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    } else if (value.length < 8) {
      return 'Le mot de passe doit comporter au moins 8 caractères';
    } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une lettre majuscule';
    }
    return null;
  }


  Future<void> logout(User user) async {
    // Appel API pour déconnexion
    final response = await http.post(
      Uri.parse('$domainName/api/signout/'),
    );

    if (response.statusCode == 200) {
      logger.i('User logged out successfully');

      if(!mounted) return;
      // Retirer les données de l'utilisateur de l'état de l'application
      await Provider.of<UserProvider>(context, listen: false).logout();


      // Assurez-vous que le widget est toujours monté avant d'utiliser le contexte
      if (mounted) {
        // Rediriger vers la page de connexion et retirer toutes les routes précédentes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()), // Remplacez `Login()` par votre widget de page de connexion
              (Route<dynamic> route) => false, // Retirer toutes les autres routes
        );
      }
    } else {
      logger.e('Failed to log out: ${response.statusCode}');
    }
  }


}
