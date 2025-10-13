import 'dart:convert';
import 'dart:io'; // Pour File
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:provider/provider.dart';

import '../../db/base_sqlite.dart';
import '../../widget/user_provider.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  SignupPageState createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpassord = TextEditingController();
  File? _photo;
  bool _isLoading = false; // Indicateur de chargement
  bool noteVisible = true;

  bool showLoginForm = true; // 👈 par défaut on affiche connexion

  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // Centre les éléments verticalement
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, // Centre les éléments verticalement
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'images/logojudicalex(1).png',
                              width: 200,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 30),
                            const Text(
                              "INSCRIPTION",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.normal,
                                height: 1.0,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        child: const Text(
                          "Accédez à votre espace personnel pour suivre vos démarches, "
                              "enregistrer vos requêtes et profiter pleinement des services juridiques.",
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                        ),
                      ),
                        const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !showLoginForm ? Colors.white : Colors.grey[200],
                                  foregroundColor: !showLoginForm ? Colors.white : Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, "/login");
                                  setState(() {
                                    showLoginForm = false; // affiche login
                                  });
                                },
                                child: const Text("Se connecter"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: showLoginForm ? Colors.white : Colors.grey[200],
                                  foregroundColor: showLoginForm ? Colors.orange : Colors.grey[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    showLoginForm = true; // affiche inscription
                                  });
                                },
                                child: const Text("S'inscrire"),
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),

                // Champ Prénom
                _buildTextField(
                  controller: _prenomController,
                  label: "Prénom",

                  validator: (value) => value!.isEmpty ? "Champ requis" : null,

                ),

                // Champ Nom
                _buildTextField(
                  controller: _nomController,
                  label: "Nom",
                  validator: (value) => value!.isEmpty ? "Champ requis" : null,

                ),

                // Champ Nom d'utilisateur
                _buildTextField(
                  controller: _usernameController,
                  label: "Nom d'utilisateur",
                  validator: (value) => value!.isEmpty ? "Champ requis" : null,

                ),

                // Champ Email
                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  validator: (value) => value!.isEmpty ? "Champ requis" : null,

                ),

                // Champ Mot de passe
                _buildTextField(
                  controller: _passwordController,
                  label: "Mot de passe",
                  obscureText: noteVisible,
                  suffixIcon: IconButton(
                    icon: Icon(noteVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => noteVisible = !noteVisible),
                  ),
                  validator: validatePassword, // Intégration de la validation

                ),
                // Champ Confirmer le mot de passe
                _buildTextField(
                  controller: _confirmpassord,
                  label: "Confirmer le mot de passe",
                  obscureText: noteVisible,
                  validator: (value) {
                    if (value!.isEmpty) return "Champ requis";
                    if (value != _passwordController.text) return "Les mots de passe ne correspondent pas";
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Bouton pour sélectionner une photo
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // Couleur de fond du bouton
                      padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 18.0), // Padding interne
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0), // Coins arrondis
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min, // Ajuste la taille du bouton à son contenu
                      children: [
                        Icon(Icons.photo, size: 20,color: Colors.white,), // Icône pour indiquer l'action
                        SizedBox(width: 10), // Espace entre l'icône et le texte
                        Text(
                          "Sélectionner une photo",
                          style: TextStyle(fontSize: 16,color: Colors.white), // Taille de la police
                        ),
                      ],
                    ),
                  ),
                ),

                FormField<bool>(
                  initialValue: _isAccepted,
                  validator: (value) {
                    if (value != true) {
                      return "Vous devez accepter les conditions d’utilisation";
                    }
                    return null;
                  },
                  builder: (formFieldState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: formFieldState.value ?? false,
                              onChanged: (value) {
                                setState(() {
                                  _isAccepted = value ?? false;
                                  formFieldState.didChange(value);
                                });
                              },
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isAccepted = !_isAccepted;
                                    formFieldState.didChange(_isAccepted);
                                  });
                                },
                                child: const Text(
                                  "J’accepte les conditions d’utilisation",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (formFieldState.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              formFieldState.errorText!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                      ],
                    );
                  },
                ),


                const SizedBox(height: 20),
                // Bouton S'inscrire
                _isLoading
                    ?const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // coins arrondis
                      ),
                    ),
                  onPressed: _onSubmit,
                  child:const Text("S'inscrire"),
                ),
                const SizedBox(height:10,),
                /// OU avec séparateur
                const  Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children:  [
                      Expanded(
                        child: Divider(color: Colors.black, thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "OU",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.black, thickness: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  [
                    Icon(Icons.g_mobiledata, color: Colors.red, size: 70),
                    SizedBox(width: 20),
                    Icon(Icons.facebook, color: Colors.blue, size: 40),
                  ],
                ),
                const SizedBox(height: 20),

                /// LIEN INSCRIPTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Vous avez déjà un  compte ? ",style: TextStyle(fontWeight: FontWeight.bold),),
                    TextButton(
                      onPressed: () async {
                        Provider.of<UserProvider>(context, listen: false).clearUser();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const Login()),
                        );
                      },
                      child: const Text(
                        "Se connecter",
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,

  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 50, // Hauteur du champ de texte
        width: MediaQuery.of(context).size.width * 0.8, // Largeur de 80%
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 12, color: Colors.black),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(15),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.black),
            ),
            suffixIcon: suffixIcon,
          ),
          style: const TextStyle(fontSize: 12, color: Colors.black),
          validator: validator,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _photo = File(pickedFile.path);
      });
    }
  }

  // Validation personnalisée pour le mot de passe
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Le mot de passe est requis';
    if (value.length < 8) return 'Le mot de passe doit contenir au moins 8 caractères';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Le mot de passe doit comporter au moins une lettre majuscule';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Le mot de passe doit comporter au moins une lettre minuscule';
    return null;
  }


  Future<void> _onSubmit() async {
    // Récupérer le nom de domaine depuis la base de données
    final String? domainName = await dbHelper.getDomainName();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Commencer le chargement
      });

      try {
        var request = http.MultipartRequest('POST', Uri.parse('$domainName/api/signup/'));

        // Ajouter les champs de texte du formulaire
        request.fields['first_name'] = _prenomController.text;
        request.fields['last_name'] = _nomController.text;
        request.fields['username'] = _usernameController.text;
        request.fields['email'] = _emailController.text;
        request.fields['password'] = _passwordController.text;
        request.fields['confirm_password'] = _confirmpassord.text;

        // Ajouter la photo seulement si l'utilisateur en a sélectionné une
        if (_photo != null) {
          String extension = _photo!.path.split('.').last.toLowerCase();
          MediaType mediaType;

          switch (extension) {
            case 'jpg':
            case 'jpeg':
              mediaType = MediaType('image', 'jpeg');
              break;
            case 'png':
              mediaType = MediaType('image', 'png');
              break;
            case 'gif':
              mediaType = MediaType('image', 'gif');
              break;
            default:
              mediaType = MediaType('image', 'jpeg');
          }
          request.files.add(
            await http.MultipartFile.fromPath(
              'photo', // Le nom du champ sur le serveur
              _photo!.path,
              contentType: mediaType,
            ),
          );
        }
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();

        if (response.statusCode == 201) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) =>const Login()), // Remplacez Login par votre page de destination
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Inscription réussie ")),
            );
          }

          // Envoie de l'email de connexion réussie
          // Récupérer le prénom et le nom de famille
          String firstName = _prenomController.text;
          String lastName = _nomController.text;
          String email = _emailController.text;

          // Appeler la fonction d'envoi d'email avec prénom, nom et email
          await sendEmail(email, firstName, lastName);


          // Affiche l'email dans la console
          //print('Email de l\'utilisateur: ${_emailController.text}');

          // Vider les champs du formulaire
          _prenomController.clear();
          _nomController.clear();
          _usernameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _confirmpassord.clear();
          setState(() {
            _photo = null; // Réinitialiser la photo
          });

        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur lors de l'inscription: $responseBody")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // SnackBar(content: Text("Erreur: $e")),
            const SnackBar(content: Text("Erreur")),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false; // Arrêter le chargement
          });
        }
      }
    }
  }


  Future<void> sendEmail(String email, String firstName, String lastName) async {
    // Récupérer le nom de domaine depuis la base de données
    final String? domainName = await dbHelper.getDomainName();
    // Configuration SMTP
    String username = 'houmadifahad100@gmail.com';
    String appPassword = 'zcqhyxdiemxlihse'; // Utilisez le mot de passe d'application généré

    // Utilisez Gmail SMTP
    final smtpServer = gmail(username, appPassword);
    //final imageBytes = await rootBundle.load('assets/images/judicalex.jpg');
    //final base64Image = base64Encode(imageBytes.buffer.asUint8List());

    // Chargez l'image en base64
    final base64Image = await getImageBase64();

      // Création du message
      final message = Message()
        ..from = Address(username, 'Judicalex')
        ..recipients.add(email.trim()) // Utilise .trim() pour enlever les espaces
        //..attachments.add(FileAttachment(File('images/judicalex.jpg')))
        ..subject = 'Création de compte réussie'
        ..html = '''
          <html lang="">
            <body style="font-family: Arial, sans-serif; color: #333;">
              <!-- Bannière -->
              <div style=" padding: 20px; text-align: center;">
                <h1 style="color: #fff; font-size: 24px;">Bienvenue sur Judicalex</h1>
              </div>
        
              <!-- Corps du message -->
              <div style="text-align: center; margin: 20px;">
                <h2 style="color: #333;">Bonjour $firstName $lastName</h2>
                <img src="data:image/jpeg;base64,$base64Image" alt="Logo Judicalex" style="width: 100px; height: auto; margin-bottom: 10px;">
                <p style="font-size: 16px;">Nous sommes heureux de vous informer que votre compte a été créé avec succès.</p>
                <p style="font-size: 16px;">Vous pouvez maintenant accéder à notre application et profiter de tous les services offerts.</p>
              </div>
             <!-- Pied de page -->
            <div style="padding: 20px; text-align: center; font-size: 14px; color: #777;">
              <p>© 2024 Judicalex. Tous droits réservés.</p>
              <p style="margin: 0;">
                <a href="$domainName" style="display: inline-block; padding: 12px 25px; font-size: 16px; color: #007bff; text-decoration: none; border-radius: 5px;">
                  Cliquez ici pour accéder à notre site web
                </a>
              </p>
      </div>
            </body>
          </html>
        ''';

    //..text = 'Bonjour Nous sommes heureux de vous informer que votre compte a été créé avec succès. Vous pouvez maintenant accéder à notre application et profiter de tous les services offerts.';
    var logger = Logger();
    try {
      final sendReport = await send(message, smtpServer);
      logger.i('Email envoyé: $sendReport');
    } on MailerException catch (e) {
      for (var p in e.problems) {
        logger.e('Problème: ${p.code}: ${p.msg}');
      }
    }
  }

  Future<String> getImageBase64() async {
    final ByteData bytes = await rootBundle.load('images/banniere.png');
    final buffer = bytes.buffer;
    final base64Image = base64Encode(Uint8List.view(buffer));
    return base64Image;
  }

}

