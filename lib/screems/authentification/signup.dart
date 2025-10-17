import 'dart:convert';
import 'dart:io'; // Pour File
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
                                  foregroundColor: showLoginForm ? const Color(0xFFDFB23D) : Colors.grey[200],
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
                      backgroundColor: const Color(0xFFDFB23D) , // Couleur de fond du bouton
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
                            Flexible(
                              fit: FlexFit.loose,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isAccepted = !_isAccepted;
                                    formFieldState.didChange(_isAccepted);
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (context) => _conditionsUtilisation(),
                                  );
                                },
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black, // Couleur normale pour le texte
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      TextSpan(text: "J'accepte les "),
                                      TextSpan(
                                        text: "conditions d'utilisation",
                                        style: TextStyle(
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4), // ← Espacement réduit
                              child: const Text(
                                "et",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Flexible( // ← Changé de Expanded à Flexible
                              fit: FlexFit.loose, // ← Permet au texte de prendre seulement l'espace nécessaire
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _politqueConfidentialite(),
                                  );
                                },
                                child: const Text(
                                  "la politique de confidentialité",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
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
                  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  [
                    GestureDetector(
                      onTap: () {
                        ///print("Connexion avec Google");
                      },
                      child: Column(
                        children: [
                          Image.asset(
                            "images/google.png",
                            height: 35,
                          ),
                        ],
                      ),
                    ),
                   /// Icon(Icons.g_mobiledata, color: Colors.red, size: 70),
                  const  SizedBox(width: 20),
                   const Icon(Icons.facebook, color: Colors.blue, size: 40),
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
                        style: TextStyle(color: Color(0xFFDFB23D) , fontWeight: FontWeight.bold),
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
              SnackBar(
                content: const Text(
                  " ✅Inscription réussie",
                  style: TextStyle(color: Colors.white), // texte en blanc
                ),
                backgroundColor: Colors.green, // fond vert
                behavior: SnackBarBehavior.floating, // optionnel : le snack flotte au lieu d'être collé en bas
                margin: const EdgeInsets.all(16), // optionnel : ajouter un peu de marge si flottant
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // coins arrondis
                ),
                duration: const Duration(seconds: 3), // durée affichage
              ),
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

  Widget _politqueConfidentialite() {
    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "POLITIQUE DE CONFIDENTIALITÉ ET DE PROTECTION DE VIE PRIVÉE",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFDFB23D) ,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
      content: const SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Internet est un outil extraordinaire. Il a le pouvoir de changer la manière dont nous vivons et nous constatons déjà ce potentiel. Avec quelques clics de souris, vous pouvez suivre les nouvelles, acheter des biens et services et communiquer avec des internautes venant de tous les coins du monde. Il est important pour JUDICALEX d'aider nos clients à garder leur vie privée lorsqu'ils bénéficient des avantages que l'internet offre.",
              ),
              SizedBox(height: 12),
              Text(
                "Pour protéger votre vie privée, JUDICALEX suit différents principes en accord avec les pratiques mondiales en matière de protection de la vie privée et des informations des clients.",
              ),
              SizedBox(height: 8),
              Text("❑ Nous ne vendrons ni ne donnerons votre nom, votre adresse, votre numéro de téléphone, votre adresse électronique, votre numéro de carte de crédit ou quelque autre information à aucune tierce partie."),
              Text("❑ Nous utiliserons des mesures de sécurité modernes pour protéger vos informations des utilisateurs non autorisés."),

              SizedBox(height: 16),
              Text(
                "INFORMATIONS PERSONNELLES",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Nous vous demanderons si nous avons besoin d'informations qui vous identifient personnellement (informations personnelles) ou qui nous permettent de vous contacter. Généralement, ces informations sont demandées lorsque vous créez un identifiant pour votre inscription sur www.judicalex-gn.org ou lorsque vous téléchargez un logiciel libre, participez à un concours, commandez un bulletin d'information électronique, ou adhérez à un site privilégié à accès limité. Nous utilisons vos informations personnelles à quatre (4) fins principales:",
              ),
              SizedBox(height: 8),
              Text("❑ rendre www.judicalex-gn.org facile à utiliser"),
              Text("❑ Vous aider à trouver plus facilement les logiciels, les services et les informations."),
              Text("❑ Nous aider à créer un contenu plus adéquat pour vous."),
              Text("❑ Pour vous informer des mises à jour de produits, des offres spéciales, des informations mises à jour et des autres nouveaux services provenant de JUDICALEX."),

              SizedBox(height: 16),
              Text(
                "CONSENTEMENT",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Vous pouvez naviguer librement sur www.judicalex-gn.org sans créer de compte ni fournir d'informations personnelles. Toutefois, certaines rubriques et services (consultation d'archives, décisions de justice, extraits RCCM, abonnements, newsletters spécialisées) nécessitent une inscription préalable.",
              ),
              SizedBox(height: 8),
              Text(
                "En vous inscrivant, vous avez la possibilité de choisir les types d'informations que vous souhaitez recevoir de Judicalex, notamment notre bulletin d'information juridique ou nos alertes thématiques. Si vous ne souhaitez pas être contacté(e) par courrier électronique, postal ou téléphone concernant nos publications ou services, vous pouvez exprimer ce choix au moment de votre inscription ou à tout moment par la suite.",
              ),
              SizedBox(height: 8),
              Text(
                "Judicalex ne transmettra jamais vos données personnelles à des tiers à des fins commerciales sans votre consentement exprès. Si vous refusez de recevoir des communications d'éventuels partenaires, vous pourrez l'indiquer dans vos préférences afin de ne recevoir que les informations émanant directement de Judicalex.",
              ),

              SizedBox(height: 16),
              Text(
                "ACCÈS",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Nous mettons à votre disposition des moyens pour vous assurer de la justesse de vos informations personnelles. Vous aurez la possibilité de revoir et de mettre à jour les informations à tout moment au centre des visiteurs. À cet endroit, vous avez la possibilité de :",
              ),
              SizedBox(height: 8),
              Text("❑ Voir et modifier les informations personnelles que vous nous avez déjà données."),
              Text("❑ Nous dire si vous souhaitez que nous vous envoyions des informations marketing ou si vous souhaitez que des tierces parties vous envoient leurs offres par la poste."),
              Text("❑ Vous inscrire au bulletin d'information électronique sur nos produits et services"),
              Text("❑ Vous inscrire. Une fois que vous serez inscrit, vous n'aurez plus à nous donner vos informations. Partout où vous irez sur judicalex-gn.org, vos informations vous suivront."),

              SizedBox(height: 16),
              Text(
                "SÉCURITÉ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "JUDICALEX a pris des mesures importantes pour assurer la sécurité de vos informations personnelles et s'assurer que votre choix quant à leur utilisation est respecté. Nous prenons des dispositions adéquates pour protéger vos données de la perte, de leur mauvaise utilisation, de l'accès non autorisé ou de la divulgation, de leur changement ou de leur destruction.",
              ),
              SizedBox(height: 8),
              Text(
                "Nous garantissons la sécurité de vos opérations de commerce électronique à cent pour cent (100 %). Lorsque vous passez votre commande ou accédez aux informations de votre compte personnel, vous utilisez un serveur sécurisé avec le logiciel SSL, qui crypte vos informations personnelles avant qu'elles ne soient envoyées par internet. SSL est l'une des technologies de cryptage les plus sécuritaires qui existent.",
              ),
              SizedBox(height: 8),
              Text(
                "JUDICALEX protège strictement la sécurité de vos informations personnelles et respecte vos choix quant à l'utilisation qui peut en être faite. Nous protégeons soigneusement vos données de toute perte, mauvaise utilisation, accès non autorisé ou de la divulgation, de la modification ou de la destruction.",
              ),
              SizedBox(height: 8),
              Text(
                "Vos informations personnelles ne seront jamais échangées avec les autres compagnies sans votre autorisation, sauf dans les conditions précisées ci-dessus. Au sein de notre compagnie, les données sont stockées dans un serveur protégé par un mot de passe avec un accès limité. Vos informations peuvent être stockées ou traitées en République de Guinée ou tout autre pays où JUDICALEX a ses filiales affiliées ou agents.",
              ),
              SizedBox(height: 8),
              Text(
                "Vous avez également une responsabilité très importante dans la protection de vos informations. Personne ne peut voir ni modifier vos informations personnelles si elle ne connaît pas votre nom d'utilisateur et votre mot de passe ; alors, ne les donnez à personne.",
              ),

              SizedBox(height: 16),
              Text(
                "APPLICATION",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Si pour quelque raison vous pensez que www.judicalex-gn.org n'a pas adhéré à ces principes, nous vous prions de le notifier à contact@judicalex-gn.org. Nous ferons alors de notre mieux pour déterminer et corriger le problème aussitôt. N'oubliez pas de mettre 'Protection de la vie privée' comme objet.",
              ),

              SizedBox(height: 16),
              Text(
                "COOKIES",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Notre site web peut utiliser des cookies pour améliorer votre expérience utilisateur. Vous avez la possibilité de configurer votre navigateur pour refuser tous les cookies ou pour vous alerter lorsqu'un cookie est envoyé. Veuillez noter que certaines parties de notre site peuvent ne pas fonctionner correctement sans les cookies.",
              ),

              SizedBox(height: 16),
              Text(
                "ENREGISTREMENT ÉLECTRONIQUE DES COMMANDES ET ABONNEMENTS",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Lorsque vous effectuez un achat sur www.judicalex-gn.org (abonnement, consultation d'une décision de justice ou d'un extrait RCCM), nous enregistrons électroniquement les informations liées à votre commande afin d'assurer son traitement et le suivi de vos accès.",
              ),
              SizedBox(height: 8),
              Text(
                "Si vous n'avez pas encore de compte utilisateur, un profil personnel est automatiquement créé à partir des informations fournies lors de votre première commande. Ce profil vous permet de consulter votre historique d'achats, de gérer vos abonnements et de mettre à jour vos données personnelles.",
              ),
              SizedBox(height: 8),
              Text(
                "À tout moment, vous pouvez accéder à votre espace utilisateur pour vérifier, corriger ou compléter vos informations personnelles, ainsi que gérer vos préférences de communication.",
              ),

              SizedBox(height: 16),
              Text(
                "PROFILS VISITEURS / ABONNÉS / CONTRIBUTEURS",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "L'accès au site www.judicalex-gn.org peut se faire selon différents statuts :",
              ),
              SizedBox(height: 8),
              Text(
                "1. Visiteurs non inscris",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Tout internaute peut consulter librement les contenus gratuits mis à disposition par Judicalex (articles d'actualité, brèves juridiques, extraits en libre accès). Ces visiteurs n'ont pas besoin de créer un compte.",
              ),
              SizedBox(height: 8),
              Text(
                "2. Visiteurs inscrits",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "En s'inscrivant via le formulaire en ligne, l'utilisateur crée un profil personnel et accède à un espace dédié. Ce compte gratuit permet notamment :",
              ),
              Text("● de recevoir les newsletters juridiques de Judicalex ;"),
              Text("● de commenter ou réagir aux articles (si la fonction est activée) ;"),
              Text("● de gérer ses préférences de communication."),
              SizedBox(height: 8),
              Text(
                "3. Abonnés (comptes payants)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Les visiteurs inscrits qui souscrivent à un abonnement ou achètent un document (décision de justice, extrait RCCM, article premium) deviennent « abonnés ». Ils bénéficient en plus :",
              ),
              Text("● d'un accès illimité ou ponctuel aux contenus payants ;"),
              Text("● de la consultation de leurs historiques d'achats et factures dans leur espace personnel ;"),
              Text("● de la possibilité de renouveler ou modifier leur abonnement en ligne."),
              SizedBox(height: 8),
              Text(
                "4. Contributeurs",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Judicalex accueille également des contributeurs (juristes, avocats, enseignants, journalistes spécialisés, institutions, ordres professionnels, ONG et associations…etc.) autorisés à publier du contenu. Leur compte leur permet :",
              ),
              Text("● de proposer des articles, brèves, analyses ou commentaires pour publication, sous réserve du droit pour Judicalex de les retirer lorsqu'ils ne respectent pas les normes fixées pas Judicalex ou sur ordre de l'autorité compétente ;"),
              Text("● de gérer leur profil auteur (nom, fonction, biographie, photo) ;"),
              Text("● d'accéder à certaines statistiques liées à leurs publications."),

              SizedBox(height: 16),
              Text(
                "UTILISATION DES INFORMATIONS PERSONNELLES",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Lorsque vous vous inscrivez chez nous, vous fournissez des informations sur vos contacts, dont votre nom et votre adresse courriel. Nous utilisons ces informations pour vous envoyer des nouvelles sur vos commandes, des questionnaires pour évaluer votre satisfaction par rapport à nos services et des annonces sur les nouveaux services spéciaux que nous offrons. Lorsque vous passez une commande chez nous, nous vous demandons votre numéro de carte de crédit et votre adresse de facturation. Nous n'utilisons ces informations que pour facturer les produits que vous commandez à ce moment-là. Nous conservons les informations sur votre facturation si jamais vous souhaitiez commander à nouveau chez nous ; mais nous n'utiliserons pas ces informations à nouveau sans votre autorisation.",
              ),

              SizedBox(height: 16),
              Text(
                "DIVULGATION DES INFORMATIONS",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Nous ne vendons, n'échangeons ou ne louons pas vos informations personnelles à des tiers, sauf si nous obtenons votre consentement ou si la loi l'exige. Cependant, nous pouvons partager vos informations avec des fournisseurs de services tiers qui nous aident à exploiter notre site web ou à mener nos activités, sous réserve de clauses de confidentialité.",
              ),
              SizedBox(height: 8),
              Text(
                "Judicalex peut divulguer vos informations, sans préavis, si de bonne foi, elle juge un tel acte nécessaire pour protéger et défendre ses droits ou la propriété de Judicalex et sa famille de site internet et agir dans une circonstance d'urgence pour assurer la sécurité personnelle de ses visiteurs, de ses sites et du public.",
              ),

              SizedBox(height: 16),
              Text(
                "CONTACT",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Si vous avez des questions concernant cette politique de confidentialité et de la protection de la vie privée, veuillez nous contacter à contact@judicalex.com",
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Fermer"),
        ),
      ],
    );
  }

  Widget _conditionsUtilisation() {
    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "CONDITIONS GÉNÉRALES D'UTILISATION",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width:double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFDFB23D) ,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const  Text(
                "Bienvenue sur le site www.judicalex-gn.org (« le Site »). Veuillez lire attentivement ces Conditions Générales d'Utilisation (« Conditions ») avant d'accéder au Site ou d'utiliser nos services.",
              ),
              const  SizedBox(height: 8),
              const Text(
                "En accédant ou en utilisant le Site, vous reconnaissez avoir pris connaissance des présentes Conditions et acceptez d'y être lié. Si vous n'acceptez pas ces Conditions, nous vous invitons à ne pas utiliser le Site.",
              ),

              const  SizedBox(height: 16),
              const  Text(
                "1. Utilisation du Site",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const  SizedBox(height: 8),
              const  Text(
                "1.1. Vous acceptez de fournir des informations exactes, complètes et à jour lors de votre utilisation du Site.",
              ),
              const  SizedBox(height: 4),
              const  Text(
                "1.2. Vous êtes responsable de la confidentialité de votre compte et de votre mot de passe, ainsi que des activités qui se produisent sous votre compte. Vous acceptez de nous informer immédiatement de toute utilisation non autorisée de votre compte.",
              ),

              const  SizedBox(height: 16),
              const  Text(
                "2. Propriété Intellectuelle",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const  SizedBox(height: 8),
              const  Text(
                "2.1. Le contenu du Site, y compris, mais sans s'y limiter, le texte, les graphiques, les images, les vidéos, les logos et les logiciels, est la propriété de Judicalex Sarlu et est protégé par des droits d'auteur et d'autres lois.",
              ),
              const  SizedBox(height: 4),
              const  Text(
                "2.2. Vous ne pouvez pas modifier, copier, distribuer, transmettre, afficher, exécuter, reproduire, publier, autoriser, créer des œuvres dérivées, transférer ou vendre toute information, logiciel, produit ou service obtenus à partir de ce Site.",
              ),

              const SizedBox(height: 16),
              const  Text(
                "3. Limitation de Responsabilité",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const  SizedBox(height: 8),
              const  Text(
                "3.1. judicalex-gn.org ne sera en aucun cas responsable de tout dommage direct, indirect, accessoire, spécial, consécutif ou punitif résultant de votre accès, utilisation ou incapacité à utiliser ce Site.",
              ),

              const SizedBox(height: 16),
              const  Text(
                "4. Modifications des Conditions",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const  Text(
                "judicalex-gn.org se réserve le droit de modifier ces Conditions à tout moment. Les modifications entrent en vigueur dès leur publication sur le Site. En continuant à utiliser le Site après de telles modifications, vous acceptez d'être lié par les Conditions modifiées.",
              ),

              const SizedBox(height: 16),
              const Text(
                "5. Résiliation – Interruption du Service",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                "5.1. La Société se réserve le droit d'interrompre le Service du Client si celui-ci constitue un danger pour la sécurité de la plate-forme (piratage, faille de sécurité, usage non conforme aux Conditions).",
              ),
              const SizedBox(height: 4),
              const Text(
                "5.2. judicalex-gn.org supprime les comptes inactifs dans les cas suivants : absence de connexion du Client à son compte pendant une durée d'une (01) année.",
              ),

              const SizedBox(height: 16),
              const Text(
                "6. Divers",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                "6.1. Si une stipulation des Conditions devient illégale ou inapplicable, cela n'affectera pas la validité des autres stipulations.",
              ),

              const SizedBox(height: 16),
              const Text(
                "7. Références",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                "7.1. Le Client accepte de figurer sur la liste des références clients de judicalex-gn.org (raison sociale et logos correspondants).",
              ),

              const  SizedBox(height: 16),
              const  Text(
                "8. Force Majeure",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                "8.1. judicalex-gn.org ne peut être tenue pour responsable de l'inexécution des Services en cas de force majeure telle que définie par l'article 1104 du Code civil guinéen.",
              ),

              const SizedBox(height: 16),
              const Text(
                "9. Droit Applicable",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                "9.1. Tout litige relatif aux Conditions sera soumis au droit guinéen.",
              ),

              const SizedBox(height: 16),
             const Text(
                "10. Règlement des différends",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
             const SizedBox(height: 8),
             const  Text(
                "10.1. En cas de litige, la partie lésée doit notifier l'autre partie par écrit. Les parties tenteront de résoudre le différend dans un délai d'un (1) mois. Passé ce délai, le litige pourra être soumis aux juridictions compétentes du ressort de la Cour d'appel de Conakry.",
              ),

              const SizedBox(height: 16),
              const Text(
                "11. Convention de Preuve",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            const SizedBox(height: 8),
             const Text(
                "11.1. Tous les documents et correspondances échangés électroniquement entre les parties lient les parties, y compris la signature numérique des présentes Conditions.",
              ),

             const SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Pour toute question concernant ces Conditions, veuillez nous contacter à ",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  GestureDetector(
                    onTap: () {
                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: 'contact@judicalex-gn.org',
                      );
                      launchUrl(emailLaunchUri);
                    },
                    child: const Text(
                      "contact@judicalex-gn.org",
                      style: TextStyle(
                        color: Color(0xFFDFB23D) ,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
                    ".",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Fermer"),
        ),
      ],
    );
  }

}

