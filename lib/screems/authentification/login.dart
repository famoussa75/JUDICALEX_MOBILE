
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:judicalex/screems/authentification/signup.dart';
import 'package:provider/provider.dart';
import '../../db/base_sqlite.dart';
import '../../model/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../widget/user_provider.dart';


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool noteVisible = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Verrouille l'orientation en mode portrait
    SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
  }

  @override
  void dispose() {
    // Réinitialise l'orientation pour les autres pages
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
/*
  Future<void> _launchURL(BuildContext context, String url) async {
    if (!mounted) return;
    try {
      await FlutterWebBrowser.openWebPage(
        url: url,
        customTabsOptions: const     CustomTabsOptions(
          colorScheme: CustomTabsColorScheme.dark,
          toolbarColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : Impossible d\'ouvrir $url')),

      );
      _showErrorDialog(context);
    }
  }*/
  //Future<void> _launchURL(BuildContext context, String url) async    {
  //  final Uri uri = Uri.parse(url); // Convertir l'URL en Uri
   // try {
   //   if (await canLaunchUrl(uri)) {
   //     await launchUrl(
   //       uri,
   //       mode: LaunchMode.externalApplication,
   //     );
  //} else {
   //     throw 'Impossible d\'ouvrir $url';
   //   }
   //   } catch (e) {
  //     print('Erreur : $e');
  // Affiche une boîte de dialogue si l'URL ne peut pas être ouverte
   //   _showErrorDialog(context);
   // }
  //}

  bool showLoginForm = true; // 👈 par défaut on affiche connexion
  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Judicalex'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_reset,
                    color: Colors.orange,
                    size: 30,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mot de passe oublié',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text(
                'Pour réinitialiser votre mot de passe :',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              Text(
                '1. Ouvrez votre navigateur internet.\n'
                    '2. Rendez-vous sur "judicalex-gn.org".\n'
                    '3. Cliquez sur "Se connecter".\n'
                    '4. Sélectionnez "Mot de passe oublié".\n'
                    '5. Suivez les instructions affichées à l\'écran.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SingleChildScrollView( // permet le scroll si le clavier couvre l'écran
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Form(

            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                      'images/logojudicalex(1).png',
                        width: 200,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height:60),
                      /// TITRE
                      const Text(
                        "CONNEXION",
                        style: TextStyle(
                          fontFamily: "Jost",
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

                /// DESCRIPTION
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
                margin: const EdgeInsets.symmetric(horizontal: 20), // marge gauche/droite
                padding: const EdgeInsets.all(1), // petit padding autour du bouton
                decoration: BoxDecoration(
                  color: Colors.grey[200], // fond gris clair
                  borderRadius: BorderRadius.circular(8), // coins arrondis
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: showLoginForm ? Colors.white: Colors.orange,
                          foregroundColor: showLoginForm ? Colors.orange : Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            showLoginForm = true; // 👈 affiche connexion
                          });
                        },
                        child: const Text("Se connecter"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !showLoginForm ? Colors.white : Colors.grey[200],
                          foregroundColor: !showLoginForm ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          Provider.of<UserProvider>(context, listen: false).clearUser();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SignupPage()),
                          );
                          setState(() {
                            showLoginForm = false; // 👈 affiche inscription
                          });
                        },
                        child: const Text("S'inscrire"),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10,),

                /// EMAIL
                _buildTextField(
                  controller: emailController,
                  label: "Email",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      _showError("Veuillez entrer votre email.");
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                /// MOT DE PASSE
                _buildTextField(
                  controller: _passwordController,
                  label: "Mot de passe",
                  obscureText: noteVisible,
                  suffixIcon: IconButton(
                    icon: Icon(noteVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => noteVisible = !noteVisible),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      _showError("Veuillez entrer un mot de passe.");
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                /// BOUTON LOGIN
                _buildLoginButton(),
                const SizedBox(height: 25),

                /// OU avec séparateur
              const  Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
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

                /// ICONES SOCIAL LOGIN
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

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showErrorDialog(context), // 👈 appel de la méthode
                        child: const Text(
                          "Mot de passe oublié ?",
                          style: TextStyle(color: Colors.orange),
                        ),
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
  })
  {
    return SizedBox(
      height: 50,
      width: double.infinity,
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
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            _showError("Veuillez remplir le champ $label.");
            return "Ce champ est requis.";
          }
          return null;
        },

      ),
    );
  }
  Widget _buildLoginButton() {
    return Column(
      children: [
        _buildErrorMessage(), // Message d'erreur s'il existe
        SizedBox(
          height: 50,
          width: 250,
          child: ElevatedButton(
            onPressed: isLoading ? null : _login, // désactive pendant le chargement
            style: ElevatedButton.styleFrom(
              backgroundColor:  const Color(0xFFDFB23D),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // coins arrondis
              ),
            ),
            child: isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              "Se connecter",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? errorMessage; // Variable pour stocker le message d'erreur

  // Fonction de validation pour vérifier que les champs ne sont pas vides
  void _validateFields() {
    setState(() {
      // Vérifie si les champs sont vides et met à jour l'état de l'erreur global
      if ( emailController.text.isEmpty || _passwordController.text.isEmpty) {
        errorMessage = "Tous les champs sont obligatoires.";
      } else {
        errorMessage = null;
      }
    });
  }

// Afficher les erreurs globales
  Widget _buildErrorMessage() {
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }
    return Container(); // Aucun message d'erreur
  }


  void _showError(String message) {
    setState(() {
      errorMessage = message; // Afficher le message d'erreur
    });

    // Masquer le message après 8 secondes
    Future.delayed(const Duration(seconds: 8), () {
      setState(() {
        errorMessage = null; // Réinitialiser le message d'erreur
      });
    });
  }



  Future<void> _login() async {

    // Avant de tenter de se connecter, valide les champs
    _validateFields();

    // Si un champ est vide, afficher l'erreur et ne pas continuer
    if (errorMessage != null) {
      return; // Sortir de la méthode si une erreur est présente
    }
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      // Récupérer le nom de domaine depuis la base de données
      final String? domainName = await dbHelper.getDomainName();

      if (domainName == null) {
        _showError("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
        setState(() {
          isLoading = false;
        });
        return;
      }
      // Vérifiez si le nom de domaine est vide
      if (domainName.isEmpty) {
        _showError("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Afficher le nom du domaine dans la console
      //print("Nom du domaine : $domainName");
      // Construire l'URL API avec le nom de domaine
      final String apiUrl = "$domainName/api/signin/";
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': emailController.text.trim(),
            'password': _passwordController.text.trim(),
          }),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          var userData = data['user'];
          // Récupérer le token de l'autorisation
          String? token = data['token']; // Remplacez 'token' par la clé correcte selon votre API
          // Afficher le token dans la console
          print("data: $data");
          User user = User(
            id: userData['id'] ?? 0,
            first_name: userData['first_name'] ?? '',
            last_name: userData['last_name'] ?? '',
            username: userData['username'] ?? '',
            email: userData['email'] ?? '',
            password: _passwordController.text,
            isFirstLogin: userData['is_first_login'] == 1,
            photo: userData['photo'] ?? '',
            token: token, // Ajoutez le token ici
          );
          bool exists = await dbHelper.userExists(user.email);
          // You can set the user data here, as it doesn't directly affect the UI
          Provider.of<UserProvider>(context, listen: false).setUser(user);
          if (!exists) {
            await dbHelper.insertUser(user);
            if (user.isFirstLogin) {
              await dbHelper.updateFirstLogin(user);
            }
          } else {
            await dbHelper.insertOrUpdateUser(user); // Update existing user with the token
          }
          // Ensure the widget is still mounted before using BuildContext
          if (mounted) {
            Navigator.pushNamed(context, "/home"); // Navigate to home page
          }
        }
       else if (response.statusCode == 204) {
          _showError("Aucune donnée disponible."); // Pour aucune réponse
        } else if (response.statusCode == 400) {
          _showError("Erreur de requête : les données envoyées sont incorrectes. Vérifiez les champs et réessayez.");
        } else if (response.statusCode == 401) {
          _showError("Non autorisé. Veuillez vous reconnecter.");
        } else if (response.statusCode == 403) {
          _showError("Accès refusé. Vous n'avez pas les autorisations nécessaires.");
        } else if (response.statusCode == 404) {
          _showError("Aucune donnée disponible. Veuillez vérifier et renseigner correctement vos informations.");
        } else if (response.statusCode == 500) {
          _showError("Erreur serveur. Veuillez réessayer plus tard.");
        }
        else {
          _showError("Échec de la connexion. Veuillez vérifier vos informations.");
        }
      } catch (error) {
        _showError("Erreur lors de la connexion. Veuillez réessayer.");
        //print(error);
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
 // void _showError(String message) {
 //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
 // }

}

