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
  bool _isLoggingOut = false; // 👈 Déclare cette variable dans ton State
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
            width: double.infinity,
            height: user == null ? 100 : 210,
            child: Container(
              decoration: const BoxDecoration(
                ///color:Color(0xFFDFB23D),
                color: Colors.white
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10,),
                    SizedBox(
                      child: Image.asset(
                        "images/judicalex.jpg",
                        height: 40,
                      ),
                    ),
                    const SizedBox(height: 40),
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
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  softWrap: true,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: const TextStyle(color: Colors.black),
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
                  ListTile(
                    title: const Text("Contactez - nous", style: TextStyle(fontSize: 16, color: Colors.white)),
                    leading: const Icon(Icons.phone, color: Colors.white),
                    selected: _selectedIndex == 0,
                    selectedTileColor: const Color(0xFFDFB23D),
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
                    selectedTileColor: const Color(0xFFDFB23D),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/login");
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
                      child: const Text('Continuer', style: TextStyle(fontSize: 16,color: Color(0xFFDFB23D))),
                    ),
                ] else ...[
                  ListTile(
                    title: const Text("Liens", style: TextStyle(fontSize: 16, color: Colors.white)),
                    leading: const Icon(Icons.book, color: Colors.white),
                    selected: _selectedIndex == 5 && _currentSelected == "Liens",
                    selectedTileColor: const Color(0xFFDFB23D),
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
                    selectedTileColor: const Color(0xFFDFB23D),
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
                    selectedTileColor: const Color(0xFFDFB23D),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                        _currentSelected = "Profil";
                      });
                      Navigator.pop(context);
                      Navigator.pushNamed(context,  "/Users");
                    },
                  ),
                  ListTile(
                    title: const Text("Contactez - nous", style: TextStyle(fontSize: 16,color:Colors.white)),
                    leading: const Icon(Icons.phone, color: Colors.white),
                    selected: _selectedIndex == 4 && _currentSelected == "Contactez",
                    selectedTileColor: const Color(0xFFDFB23D),
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
                    selectedTileColor: const Color(0xFFDFB23D),
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
              child: const Text('Continuer', style: TextStyle(fontSize: 16,color: Color(0xFFDFB23D))),
            ),
          const Divider(height:4,),
          // Bouton déconnexion toujours en bas
          if (user != null)
            SafeArea(
              minimum: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: _isLoggingOut
                      ? null
                      : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirmer la déconnexion"),
                        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Annuler"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Se déconnecter", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      logout(user);
                    }
                  },
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoggingOut) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Déconnexion...",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ] else ...[
                          Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: MediaQuery.of(context).size.width < 350 ? 16 : 20,
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width < 350 ? 5 : 8),
                          const Text(
                            "Se Déconnecter",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            )

        ],
      ),
    );


  }
  Future<void> logout(User user) async {
    setState(() => _isLoggingOut = true); // 👈 On affiche le loader

    final response = await http.post(
      Uri.parse('$domainName/api/signout/'),
    );

    if (response.statusCode == 200) {
      logger.i('User logged out successfully');

      if (!mounted) return;

      await Provider.of<UserProvider>(context, listen: false).logout();
      await DatabaseHelper().deleterUser(user.id);
      logger.i('User removed from local database.');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
              (Route<dynamic> route) => false,
        );
      }
    } else {
      logger.e('Failed to log out: ${response.statusCode}');
    }

    if (mounted) setState(() => _isLoggingOut = false); // 👈 On cache le loader
  }
}
