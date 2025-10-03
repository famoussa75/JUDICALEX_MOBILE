import 'dart:async'; // Pour utiliser Future
import 'package:flutter/material.dart';
import 'package:judicalex/widget/user_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../db/base_sqlite.dart';
import '../model/user_model.dart';
import '../screems/authentification/login.dart';
import 'country_selector.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override MyDrawerState createState() => MyDrawerState();
}

class MyDrawerState extends State<MyDrawer> {
  String? domainName;

  String _currentSelected = "";

  @override
  void initState() {
    super.initState();
    _fetchDomainName(); // Récupérez le nom de domaine lors de l'initialisation
  }


  Future<void> _fetchDomainName() async {
    final dbHelper = DatabaseHelper();
    String? domain = await dbHelper.getDomainName();
    setState(() {
      domainName = domain; // Mettez à jour l'état avec le nom de domaine récupéré
    });
  }
  bool _showContinueButton = false;

  // Déclare cette variable dans ton State
  int? _selectedIndex; // null = aucun élément sélectionné

  var logger = Logger(); // Create a logger instance

  @override
  Widget build(BuildContext context) {
    // Récupérer l'utilisateur connecté depuis le UserProvider
    final user = Provider.of<UserProvider>(context).currentUser;

    return Drawer(
      backgroundColor: const Color(0xFF1e293b),
      child: Column(
        children: [
          // Header
          SizedBox(

            height: user == null ? 100 : 200,
            child: DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0XFF505B3D),

              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const SizedBox(height: 20),
                    if (user != null && user.photo.isNotEmpty && domainName != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(
                              user.photo.contains(domainName!)
                                  ? user.photo
                                  : '$domainName/${user.photo}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user.first_name} ${user.last_name}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  softWrap: true,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: const TextStyle(color: Colors.white),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Partie scrollable
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (user == null) ...[
                  CountrySelectionWidget(
                    onContinueButtonVisibilityChanged: (isVisible) {
                      if (!mounted) return;
                      setState(() {
                        _showContinueButton = isVisible;
                      });
                    },
                  ),
                  if (_showContinueButton)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Continuer'),
                    ),
                  ListTile(
                    title: const Text("Contactez - nous", style: TextStyle(fontSize: 16, color: Colors.white)),
                    leading: const Icon(Icons.phone, color: Colors.white),
                    selected: _selectedIndex == 0,
                    selectedTileColor: Colors.orangeAccent,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0; // change la sélection
                      });
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/Contact");
                    },
                  ),

                  ListTile(
                    title: const Text("Se connecter", style: TextStyle(fontSize: 16, color: Colors.white)),
                    leading: const Icon(Icons.login, color: Colors.white),
                    selected: _selectedIndex == 1,
                    selectedTileColor: Colors.orangeAccent,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/login");
                    },
                  ),
                ] else ...[
                  ListTile(
                    title: const Text("Liens", style: TextStyle(fontSize: 16, color: Colors.white)),
                    leading: const Icon(Icons.book, color: Colors.white),
                    selected: _selectedIndex == 5 && _currentSelected == "Liens",
                    selectedTileColor: Colors.orangeAccent,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                        _currentSelected = "Liens";
                      });
                      Navigator.pop(context);
                      Navigator.pushNamed(context,"/CodeCivil");
                    },
                  ),
                  ListTile(
                    title: const Text("Mon compte", style: TextStyle(fontSize: 16, color: Colors.white)),
                    leading: const Icon(Icons.edit, color: Colors.white),
                    selected: _selectedIndex == 5 && _currentSelected == "MyAccount",
                    selectedTileColor: Colors.orangeAccent,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                        _currentSelected = "MyAccount";
                      });
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/MyAccount");
                    },
                  ),
                  ListTile(
                    title: const Text("Profil", style: TextStyle(fontSize: 16, color: Colors.white)),
                    leading: const Icon(Icons.person, color: Colors.white),
                    selected: _selectedIndex == 5 && _currentSelected == "Profil",
                    selectedTileColor: Colors.orangeAccent,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                        _currentSelected = "Profil";
                      });
                      Navigator.pop(context);
                      Navigator.pushNamed(context,  "/Users");
                    },
                  ),
                  CountrySelectionWidget(
                    onContinueButtonVisibilityChanged: (isVisible) {
                      if (!mounted) return;
                      setState(() {
                        _showContinueButton = isVisible;
                      });
                    },
                  ),
                  if (_showContinueButton)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Continuer', style: TextStyle(fontSize: 16,color:Colors.orangeAccent)),
                    ),
                  ListTile(
                    title: const Text("Contactez - nous", style: TextStyle(fontSize: 16,color:Colors.white)),
                    leading: const Icon(Icons.phone, color: Colors.white),
                    selected: _selectedIndex == 4 && _currentSelected == "Contactez",
                    selectedTileColor: Colors.orangeAccent,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                        _currentSelected = "Contactez";
                      });
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/Contact");
                    },
                  ),
                  ListTile(
                    title: const Text("À propos de nous", style: TextStyle(fontSize: 16,color:Colors.white)),
                    leading: const Icon(Icons.info_outline, color: Colors.white),
                    selected: _selectedIndex == 5 && _currentSelected == "AboutUsPage",
                    selectedTileColor: Colors.orangeAccent,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                         _currentSelected = "AboutUsPage";
                      });
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/AboutUsPage");
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(height:4 ,),
          // Bouton déconnexion toujours en bas
          if (user != null)

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: GestureDetector(
                onTap: () => logout(user), // Action au clic
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: MediaQuery.of(context).size.width < 350 ? 12 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(8),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start, // centre le contenu

                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width < 350 ? 16 : 20,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width < 350 ? 5 : 8),
                      Text(
                        "Se Déconnecter",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width < 350 ? 12 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )


        ],
      ),
    );


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
