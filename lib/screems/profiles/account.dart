
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../db/base_sqlite.dart';
import '../../model/user_model.dart';
import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';
import '../../widget/user_provider.dart';
import '../authentification/login.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({super.key});

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();
  String? profilePhotoPath;
  String? domainName;

  var logger = Logger(); // Create a logger instance

  @override
  void initState() {
    super.initState();
    _fetchDomainName();
    _loadDomainName(); // Charger le nom de domaine au démarrage
  }

  Future<void> _loadDomainName() async {
    final dbHelper = DatabaseHelper(); // Créez une instance de DatabaseHelper
    String? domain = await dbHelper.getDomainName(); // Récupérez le nom de domaine
    setState(() {
      domainName = domain; // Mettez à jour l'état
    });
  }


  Future<void> _fetchDomainName() async {
    String? name = await dbHelper.getDomainName();
    setState(() {
      domainName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
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
            padding: const EdgeInsets.only(left: 8.0),
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
      drawer:const MyDrawer(),
      body: user == null
          ? const Center(child: Text("Veuillez vous connecter pour continuer.", style: TextStyle(fontSize: 18)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(user), // Utiliser le sélecteur d'image
                child: Stack(
                  alignment: Alignment.bottomRight, // Position de l'icône en bas à droite
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user.photo.isNotEmpty
                          ? NetworkImage(
                          user.photo.contains(domainName ?? 'https://judicalex-gn.org/') // Utiliser le nom de domaine s'il est défini
                              ? user.photo // Si l'URL contient déjà le domaine, l'utiliser telle quelle
                              : '${domainName ?? 'https://judicalex-gn.org'}/${user.photo}' // Sinon, ajouter le domaine à l'URL
                      )
                          : null, // Pas de photo, donc pas d'image
                      child: (user.photo.isEmpty)
                          ? const Icon(Icons.person, size: 50, color: Colors.grey) // Afficher une icône par défaut
                          : null, // Pas d'icône si l'image est présente
                    ),
                    // Icône de la caméra, affichée en bas à droite du CircleAvatar
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4), // Espacement autour de l'icône
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white, // Fond blanc pour l'icône
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 4,
                              offset: const Offset(0, 2), // Ombre sous l'icône
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt, // Icône de la caméra
                          size: 20, // Taille de l'icône de la caméra
                          color: Colors.blue, // Couleur de l'icône
                        ),
                      ),
                    ),
                  ],
                ),

              ),
            ),
              const SizedBox(height: 20),
              _buildUserInfoTile("Nom", user.last_name, () => _editField(context, 'Nom', user.last_name)),
              _buildUserInfoTile("Prénom", user.first_name, () => _editField(context, 'Prenom', user.first_name)),
              _buildUserInfoTile("Nom d'utilisateur", user.username, () => _editField(context, 'Username', user.username)),
             // _buildUserInfoTile("Email", user.email, () => _editField(context, 'Email', user.email)),
            const Divider(),
            const Text("Sécurité", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            /*
            _buildUserInfoTileEmail("Email", user.email, () => _editField(context, 'Email', user.email), email:user.email),

             */
            const SizedBox(height: 10,),
            GestureDetector(
              onTap: () => _updatePassword(user), // action au clic
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2, horizontal:6),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
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
                        Icon(Icons.lock, color:  Color(0xFFDFB23D)),
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
            const Divider(),
            const SizedBox(height:20),
            LayoutBuilder(
              builder: (context, constraints) {
                // Get screen width to adjust spacing and font sizes based on device size
                //final screenWidth = MediaQuery.of(context).size.width;

                return Container(
                  width: double.infinity, // Utilise toute la largeur disponible
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 10, // Espace horizontal entre les boutons
                    runSpacing: 10, // Espace vertical entre les boutons s'ils débordent
                    alignment: WrapAlignment.center, // Centre les boutons
                    children: [
                      // Bouton "Se déconnecter"
                      ElevatedButton(
                        onPressed: () {
                          logout(user); // Méthode de déconnexion
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 350 ? 8 : 16,
                            vertical: 10,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.blue,
                              size: MediaQuery.of(context).size.width < 350 ? 16 : 20,
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width < 350 ? 3 : 5),
                            Text(
                              "Se déconnecter",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: MediaQuery.of(context).size.width < 350 ? 10 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bouton "Supprimer mon compte"
                      ElevatedButton(
                        onPressed: () {
                          deleteUser(user); // Méthode de suppression
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 350 ? 8 : 16,
                            vertical: 10,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: MediaQuery.of(context).size.width < 350 ? 16 : 20,
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width < 350 ? 3 : 5),
                            Text(
                              "Supprimer mon compte",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: MediaQuery.of(context).size.width < 350 ? 10 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

              },
            )

          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(child: CustomNavigator(currentIndex: 5)),
    );
  }

  // Widget pour afficher une ligne d'information utilisateur modifiable
  Widget _buildUserInfoTile(String title, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal:6),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🔹 Titre + Valeur alignés à gauche
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            // 🔹 Icône edit à droite
            const Icon(
              Icons.edit,
              color:  Color(0xFFDFB23D),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> sendCodeByEmail(String email, String code) async {
    String username = 'houmadifahad100@gmail.com';
    String appPassword = 'zcqhyxdiemxlihse'; // Utilisez le mot de passe d'application généré

    final smtpServer = gmail(username, appPassword);

    final message = Message()
      ..from = Address(username, 'Judicalex')
      ..recipients.add(email)
      ..subject = 'Code de confirmation'
      ..text = 'Voici votre code de confirmation : $code';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email envoyé à $email: $sendReport');
    } on MailerException catch (e) {
      print('Erreur lors de l’envoi de l’email : $e');
    }
  }


  Widget _buildUserInfoTileEmail(String title, String value, VoidCallback onTap, {required String email}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () async {
          final code = (1000 + Random().nextInt(9000)).toString();

          // 🔹 Afficher un indicateur de chargement
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );

          try {
            // Envoyer le code par email
            await sendCodeByEmail(email, code);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de l’envoi de l’email: $e')),
            );
          } finally {
            Navigator.of(context).pop(); // Fermer le loading
          }

          // Boîte de dialogue pour entrer le code
          final enteredCode = await showDialog<String>(
            context: context,
            builder: (context) {
              String inputCode = '';
              return AlertDialog(
                title: const Text('Confirmation par email'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Un code de confirmation a été envoyé à votre email.'),
                    TextField(
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      onChanged: (value) => inputCode = value,
                      decoration: const InputDecoration(
                        hintText: 'Entrez le code',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, inputCode),
                    child: const Text('Confirmer'),
                  ),
                ],
              );
            },
          );

          // Vérifier le code
          if (enteredCode != null && enteredCode == code) {
            onTap();
          } else if (enteredCode != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code incorrect')),
            );
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.email, color: Color(0xFFDFB23D)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      value,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }



  Future<void> _editField(BuildContext context, String field, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Modifier votre $field",
            style:const  TextStyle(
              fontFamily: 'Roboto', // Nom de la police
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: field),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () async {
                // Capture the context before any async operations
                final currentContext = context;

                // Call the update function
                await _updateUserField(currentContext, field, controller.text);

                // Ensure the widget is still mounted before popping the context
                if (currentContext.mounted) {
                  Navigator.of(currentContext).pop();
                }
              },
              child: const Text("Sauvegarder"),
            ),

          ],
        );
      },
    );
  }

  Future<void> _updateUserField(BuildContext context, String field, String newValue) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    User user = userProvider.currentUser!;

    // Check if new value differs from the current value
    bool updated = false;
    switch (field) {
      case 'Nom':
        if (user.last_name != newValue) {
          user = user.copyWith(last_name: newValue);
          updated = true;
        }
        break;
      case 'Prenom':
        if (user.first_name != newValue) {
          user = user.copyWith(first_name: newValue);
          updated = true;
        }
        break;
      case 'Username':
        if (user.username != newValue) {
          user = user.copyWith(username: newValue);
          updated = true;
        }
        break;
      case 'Email':
        if (user.email != newValue) {
          user = user.copyWith(email: newValue);
          updated = true;
        }
        break;
    }

    if (!updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune modification apportée.")),
      );
      return; // Early return if no updates were made
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Mise à jour..."),
            ],
          ),
        );
      },
    );

    // Update user in the backend
    bool updateSuccess = await _updateAccountApi(user, updatePhotoOnly: false); // Send all fields to server
    // Ensure the widget is still mounted before calling pop
    if (context.mounted) {
      Navigator.of(context).pop(); // Close the loading dialog
    }
   // Navigator.of(context).pop(); // Close loading dialog

    if (updateSuccess) {
      await dbHelper.updateUser(user); // Update SQLite
      userProvider.setUser(user); // Update provider
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Informations mises à jour avec succès.")),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Échec de la mise à jour des informations.")),
        );
      }
    }
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


  Future<void> _pickImage(User user) async {
    // Afficher la boîte de dialogue de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Mise à jour..."),
            ],
          ),
        );
      },
    );

    // Use pickImage instead of getImage
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profilePhotoPath = pickedFile.path; // Enregistre le chemin de l'image localement
      });

      // Envoyer l'image au serveur et mettre à jour l'utilisateur avec la nouvelle URL de la photo
      bool isUpdated = await _updateAccountApi(user, updatePhotoOnly: true);

      if (isUpdated) {
        // Récupérer les nouvelles informations de l'utilisateur après la mise à jour
        User? updatedUser = await _fetchUserDetails(user.id);
        if (updatedUser != null) {
          setState(() {
            user.photo = updatedUser.photo; // Mettez à jour l'objet utilisateur avec l'URL distante
          });

        }
      } else {
        // Assurez-vous que le widget est toujours monté avant de montrer un message d'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Échec de la mise à jour de la photo de profil.")),
          );
        }
      }
    } else {
      // Assurez-vous que le widget est toujours monté avant de montrer un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucune image sélectionnée.")),
        );
      }
    }

    // Fermer la boîte de dialogue de chargement, assurez-vous que le widget est monté
    if (mounted) {
      Navigator.of(context).pop(); // Ferme la boîte de dialogue de chargement
    }
  }


  Future<User?> _fetchUserDetails(int userId) async {
    String? domainName = await DatabaseHelper().getDomainName();

    if (domainName == null || domainName.isEmpty) {
      // Ensure the widget is still mounted before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Le nom de domaine est manquant ou invalide.")),
        );
      }
      return null;
    }

    // Retirer le préfixe "http://" ou "https://"
    domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
    domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;

    final String url = 'https://$domainName/api/account/get-user/$userId/';
    logger.e('URL récupérée : $url');

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
      });
      if (response.statusCode == 200) {
        final userJson = json.decode(response.body);
        String photoPath = userJson['photo'];

        if (photoPath.isEmpty) {
          logger.e("Le chemin de la photo est vide ou invalide.");
          return null;
        }

        // Si le chemin contient déjà "http", cela signifie qu'il s'agit d'une URL complète
        if (!photoPath.startsWith('http')) {
          // Si le chemin commence par "/", on le retire
          if (photoPath.startsWith('/')) {
            photoPath = photoPath.substring(1);
          }

          // Construire l'URL complète de la photo
          photoPath = 'https://$domainName/$photoPath';
          // Éliminer les doubles slashes dans l'URL
          photoPath = photoPath.replaceAll(RegExp(r'([^:]\/)\/+'), r'\1');
        }


        //print('Nouvelle photo URL: $photoPath');
        userJson['photo'] = photoPath;


        return User.fromJson(userJson);

      } else {
        //print('Erreur serveur: ${response.statusCode} - ${response.body}');
        logger.e('Erreur serveur');
        return null;
      }
    } catch (error) {
      // Check if the widget is still mounted before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion")),
        );
      }
      return null;
    }
  }


  Future<void> deleteUser(User user) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:const Text('Confirmation de Suppression'),
          content:const Text('Êtes-vous sûr de vouloir supprimer ce compte ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child:const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Confirm
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirm) {
      final response = await http.delete(
        Uri.parse('$domainName/api/account/delete/${user.id}/'),
      );

      if (response.statusCode == 200) {
        logger.i('User deleted successfully');

        // Check if the widget is still mounted before using context
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login'); // Redirect to login
        }
      } else {
        logger.e('Failed to delete user: ${response.statusCode}');
      }
    }
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
