import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../db/base_sqlite.dart';
import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';

class MesAffaire extends StatefulWidget {
  const MesAffaire({super.key});

  @override
  State<MesAffaire> createState() => MesAffaireState();
}

class MesAffaireState extends State<MesAffaire> {
  List<dynamic> affairesData = [];
  List<dynamic> filteredAffairesData = [];
  String searchQuery = '';
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isSearchActive = false;
  int currentPage = 1; // Ajout de currentPage ici
  List filteredRole = [];
  List roles = [];

  Map<String, dynamic> role = {};

  @override
  void initState() {
    super.initState();
    fetchAffaires();
  }

  Future<void> fetchAffaires() async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null ||
        token.isEmpty ||
        domainName == null ||
        domainName.isEmpty) {
      _showError("Erreur d'authentification ou configuration.");
      setState(() {
        isLoading = false; // Arrêter le chargement en cas d'erreur
      });
      return;
    }

    try {
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final url = Uri.parse('https://$domainName/api/mes-affaires-suivies/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          affairesData = data; // Mettre à jour les données
          filteredAffairesData = affairesData; // Initialiser la liste filtrée
          isLoading = false; // Arrêter l'indicateur de chargement
        });
        print(data);
      } else {
        setState(() {
          isLoading =
              false; // Arrêter l'indicateur de chargement en cas d'erreur
        });
        _showError('Erreur lors de la récupération des détails.');
      }
    } catch (e) {
      setState(() {
        isLoading =
            false; // Arrêter l'indicateur de chargement en cas d'exception
      });
      _showError('Erreur');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  var logger = Logger(); // Create a logger instance

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredAffairesData = affairesData.where((affaire) {
        final objet =
            affaire['affaire']['objet']?.toString().toLowerCase() ?? '';
        final demandeur =
            affaire['affaire']['demandeurs']?.toString().toLowerCase() ?? '';
        final defendeurs =
            affaire['affaire']['defendeurs']?.toString().toLowerCase() ?? '';
        return objet.contains(query.toLowerCase()) ||
            demandeur.contains(query.toLowerCase()) ||
            defendeurs.contains(query.toLowerCase());
      }).toList();
    });
  }

  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, "/NotificationPage");
              },
            ),
          ],
        ),
      ),
      drawer: const MyDrawer(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Indicateur de chargement
          : Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: updateSearchQuery,
                    decoration: InputDecoration(
                      labelText: 'Rechercher une affaire',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                // Liste des affaires filtrées
                Expanded(
                  child: filteredAffairesData.isNotEmpty
                      ? ListView.builder(
                          itemCount: filteredAffairesData.length,
                          itemBuilder: (context, index) {
                            final affaire =
                                filteredAffairesData[index]['affaire'];
                            final idAffaire = affaire['id'];

                            final bool isSelected = selectedIndex == index;

                            return Card(
                              color: isSelected
                                  ? Colors.orangeAccent
                                  : Colors.white12,
                              margin: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 16.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedIndex =
                                        index; // sélectionne uniquement cette carte
                                  });
                                  _showAffaireDetailsDialog(idAffaire);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "NUA : ${affaire['numAffaire']}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "Objet: ${affaire['objet'] ?? 'Non spécifié'}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Demandeur: ${affaire['demandeurs'] ?? 'Non spécifié'}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "Défendeur: ${affaire['defendeurs'] ?? 'Non spécifié'}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            "Aucune affaire disponible.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                ),
              ],
            ),
      bottomNavigationBar: const CustomNavigator(currentIndex: 2),
    );
  }

  Future<Map<String, dynamic>> fetchRoleDetailsDecision(int idAffaire) async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null ||
        token.isEmpty ||
        domainName == null ||
        domainName.isEmpty) {
      _showError("Erreur d'authentification ou configuration.");
      return {};
    }

    try {
      // Retirer le préfixe "http://" ou "https://"
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      final url = Uri.parse('https://$domainName/api/affaire/$idAffaire/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        _showError('Erreur lors de la récupération des détails.');
        return {};
      }
    } catch (e) {
      // _showError('Erreur: $e');
      _showError('Erreur');
      return {};
    }
  }

  void _showAffaireDetailsDialog(int idAffaire) async {
    try {
      final data = await fetchRoleDetailsDecision(idAffaire);
      final decisions = data['decisions'] ?? [];
      setState(() {
        selectedIndex = null;
      });
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(
          0.2,
        ), // un léger voile en plus du flou
        pageBuilder: (context, anim1, anim2) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Center(
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Un seul GestureDetector pour gérer le clic
                      GestureDetector(
                        onTap: () async {
                          setState(() {
                            isLoading = true; // afficher l'indicateur
                          });

                          try {
                            final roleId = data['affaire']['role']; // int
                            final idAffaire = data['affaire']['id'];
                            print("🟢 ID rôle : $roleId, ID affaire : $idAffaire");

                            // Charger les rôles depuis l'API
                            await fetchPosts(isInitialLoad: true);

                            final roleDetails = roles.firstWhere(
                                  (r) => r['id'] == roleId,
                              orElse: () => null,
                            );

                            if (roleDetails != null) {
                              print("📦 Infos rôle récupérées : $roleDetails");

                              // 🔹 Vérifier que le widget est toujours monté
                              if (!mounted) return;

                              await Navigator.pushNamed(
                                context,
                                "/Decisions",
                                arguments: {
                                  'id': idAffaire,
                                  'role': roleDetails,
                                },
                              );
                            } else {
                              print("⚠️ Impossible de récupérer les informations du rôle.");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Impossible de récupérer les informations du rôle.")),
                              );
                            }
                          } catch (e) {
                            print("Erreur: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Erreur: ")),
                            );
                          } finally {
                            // Masquer l'indicateur de chargement
                            if (mounted) {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },


                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "NUA : ${data['affaire']['numAffaire']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: "Objet: ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        data['affaire']['objet'] ??
                                        'Objet non précisé',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (decisions.isNotEmpty)
                        Expanded(
                          child: PageView.builder(
                            itemCount: decisions.length,
                            itemBuilder: (context, index) {
                              return _buildDecisionCard(
                                decisions[index],
                                index,
                                decisions.length,
                              );
                            },
                          ),
                        )
                      else
                        const Center(
                          child: Text("Aucune décision disponible."),
                        ),

                      const SizedBox(height: 10),
                      Center(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.orangeAccent,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          child: const Text(
                            "Retour",
                            style: TextStyle(color: Colors.orangeAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des détails")),
      );
    }
  }

  Widget _buildDecisionCard(
    Map<String, dynamic> decision,
    int index,
    int total,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Décision ${index + 1}/$total",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
            const Divider(),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Type: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)), // espace
                  TextSpan(text: decision['typeDecision'] ?? 'Non spécifié'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Date: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['dateDecision'] ?? 'Non précisé'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Président: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['president'] ?? 'Inconnu'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Greffier: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['greffier'] ?? 'Inconnu'),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Décision: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: decision['decision'] ?? 'Inconnu'),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const WidgetSpan(
                    child: Text(
                      "Prochaine Audience: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(
                    text: decision['prochaineAudience'] ?? 'Non précisé',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchPosts({bool isInitialLoad = false}) async {
    if (isSearchActive) {
      // Ne pas charger de nouvelles données si une recherche est en cours
      //isLoading = false;
      isLoadingMore = false;
      return;
    }
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      _showError(
        "Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.",
      );
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      return;
    }

    // Vérifiez la connectivité Internet
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // _showError("Pas de connexion Internet. Veuillez vérifier votre réseau.");
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      return;
    }

    // Vérification de la connectivité Internet
    final connectivityStatus = await Connectivity()
        .checkConnectivity(); // Renamed the variable
    if (connectivityStatus == ConnectivityResult.none) {
      // Affichez un message ou widget de connexion
      _showConnectionErrorWidget(); // Cette fonction peut afficher un widget spécifique de connexion
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      return;
    }

    try {
      // Retirer le préfixe "http://" ou "https://"
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/')
          ? domainName.substring(0, domainName.length - 1)
          : domainName;

      // Ajouter le préfixe "https://"
      final url = Uri.parse('https://$domainName/api/roles/?page=$currentPage');

      // Effectuer la requête HTTP
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = utf8.decode(response.bodyBytes);
        final decodedResponse = jsonDecode(jsonResponse);
        // print(decodedResponse); // Imprimez la réponse pour vérifier sa structure
        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse.containsKey('roles')) {
          final rolesData = decodedResponse['roles'];
          if (rolesData is Map<String, dynamic> &&
              rolesData.containsKey('results')) {
            List<dynamic> newRoles =
                rolesData['results']; // Assurez-vous que c'est bien une liste
            print(rolesData);
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                if (isInitialLoad) {
                  roles = newRoles;
                } else {
                  roles.addAll(newRoles);
                }
                if (!isSearchActive) {
                  filteredRole = roles;
                  isLoading = false;
                  isLoadingMore = false;
                }
                isLoading = false;
                isLoadingMore = false;
              });
            }
          } else {
            throw Exception(
              'Les données des rôles sont dans un format incorrect. Veuillez vérifier les données.',
            );
          }
        } else {
          throw Exception(
            'Une erreur s\'est produite lors de la récupération des données.',
          );
        }
      } else {
        //throw Exception('Erreur lors de la récupération des données: ${response.statusCode}');
        throw Exception('Erreur lors de la récupération des données');
      }
    } on SocketException {
      //print('Erreur résau : Probléme de connexion ');
      throw Exception('Erreur résau : Probléme de connexion ');
    } on HttpException {
      // print('Erreur Http :Verifiez l\'url');
      throw Exception('Erreur Http :Verifiez l\'url');
    } on FormatException {
      //print('Erreur de format : URL  mal formée');
      throw Exception('Erreur de format : URL  mal formée');
    } catch (error) {
      // print(error); // Imprimez l'erreur pour la débogage
      //_showError("Erreur lors de la récupération des données.");
      // Handle errors
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  // Fonction qui montre un widget ou un message d'erreur de connexion
  void _showConnectionErrorWidget() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connexion Internet'),
          content: const Text(
            'Pas de connexion Internet. Veuillez vérifier votre réseau.',
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}
