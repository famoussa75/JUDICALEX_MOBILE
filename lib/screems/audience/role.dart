
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../db/base_sqlite.dart';
import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';
import '../../widget/user_provider.dart';

class Role extends StatefulWidget {
  const Role({super.key});
  @override
  State<Role> createState() => _RoleState();
}

class _RoleState extends State<Role> {
  bool isLoggedIn = false; // Changez cette variable en fonction de l'état de connexion de l'utilisateur
  Map<String, dynamic>? roleDetails; // Declare roleDetails as a nullable map

  List roles = [];
  List filteredRole = []; // Liste filtrée pour afficher les résultats
  Map<int, String> juridictionMap = {};
  int totalPages = 0; // Total des pages pour la pagination
  int currentPage = 1; // Ajout de currentPage ici

  List<dynamic> filteredByRoleDates = [];

  ScrollController scrollController = ScrollController();
  String searchPresident = ''; // Variable pour stocker le texte de recherche

  bool isLoading = true;
  bool isLoadingMore = false;
  final bool _isExpanded = false; // Track the state of the ExpansionTile

  bool _showYearsContainer = false; // Gère l'affichage du conteneur

  String _currentTitle ="Années"; // Titre de l'années

  @override
  void initState() {
    super.initState();
    fetchAllRolesWithQuery(''); // Chargement initial sans filtre
    fetchPosts(isInitialLoad: true);
    //checkConnectivity();
    // Ajouter un listener au contrôleur de défilement pour détecter la fin de la liste
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent && !isLoadingMore) {
        _loadNextPage(); // Charger plus de données quand on arrive à la fin de la liste
      }
    });
  }

  void _showLogin() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Connexion requise"),
            content: const Text("Veuillez vous connecter pour accéder à cette fonctionnalité."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue
                },
                child: const Text("Annuler"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue
                  Navigator.pushNamed(context, "/login"); // Remplacez "/login" par votre route de connexion
                },
                child: const Text("Se connecter"),
              ),
            ],
          );
        }
    );
  }

  Future<void> fetchRoleDetails(String roleId) async {
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      _showError("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      return;
    }
    // Affichez l'ID dans la console
    //print('Fetching details for role ID: $roleId');
    try {
      // Récupérer le token
      String? token = await DatabaseHelper().getToken();
      if (token == null || token.isEmpty) {
        _showError("Token d'authentification manquant. Veuillez vous reconnecter.");
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
        return;
      }
      // Retirer le préfixe "http://" ou "https://"
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;

      // Construire l'URL pour l'API de mise à jour du compte
      // final String url = 'https://$domainName/api/account/update/${user.id}/';
      final  url = Uri.parse('https://$domainName/api/role/$roleId/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token', // Ajoutez le token ici
        },
      );
      //print('$token');
      //print('sldfjlsd: $url');

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON
        setState(() {
          roleDetails = jsonDecode(response.body); // Convert the response to a Dart object
        });
      }else {
        // Ensure widget is mounted before showing SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load role details')),
          );
        }
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
      }
    }
  }

  DateTime? selectedDate1;
  DateTime? selectedDate2;
  DateTime?  selectedUniqueDate;

  String? selectedYear; // La variable pour stocker l'année sélectionnée

  String? _selectedYear;// Variable pour suivre l'année sélectionnée

  List<dynamic> _allRoles = []; // Stockage des rôles récupérés

  // Méthode de récupération des rôles avec une requête de recherche
  Future<void> fetchAllRolesWithQuery(String query) async {
    int currentPage = 1;
    bool moreData = true;
    _allRoles = []; // Réinitialiser les rôles à chaque nouvelle requête

    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName != null) {
      // Retirer le préfixe "http://" ou "https://"

      if (!domainName.startsWith('http://') && !domainName.startsWith('https://')) {
        domainName = 'https://$domainName';
      }
      // S'assurer que le domaine ne termine pas par un slash
      domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;

      setState(() {
        isSearching = true;
      });

      while (moreData) {

        final url = Uri.parse('$domainName/api/roles/?page=$currentPage&search=$query/');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final jsonResponse = utf8.decode(response.bodyBytes);
          final decodedResponse = jsonDecode(jsonResponse);
          final List<dynamic> rolesData = decodedResponse['roles']['results'];

          if (rolesData.isEmpty) {
            moreData = false;
          } else {
            _allRoles.addAll(rolesData);
            currentPage++;

            //print("Page $currentPage - Données accumulées de _allRoles :");
            //print(_allRoles);
          }
        } else {
          // _showError("Erreur lors de la récupération des données.");
          moreData = false;
        }
      }


      setState(() {
        filteredRole = _allRoles; // Initialement tous les rôles sont affichés
        isSearching = false;
      });
    } else {
      _showError("Nom de domaine invalide.");
      setState(() {
        isSearching = false;
      });
    }
  }

  bool isSearching = false; // Indique si une recherche est en cours
  bool isFiltering = false; // Indique qu'une recherche est en cours
  bool isSearchActive = false;

  // Fonction principale de recherche
  Future<void> searchRoles(String query, {bool filterByPresidentOnly = false}) async {
    if (_allRoles.isEmpty) {
      await fetchAllRolesWithQuery(query);
    }
    _filterRoles(query, filterByPresidentOnly: filterByPresidentOnly);
  }

  Future<void> _filterRoles(String query, {bool filterByPresidentOnly = false}) async {
    setState(() {
      isSearchActive = query.isNotEmpty; // Active ou désactive la recherche
      isSearching = true;
      isFiltering = isSearchActive;
    });

    if (query.isEmpty && selectedDate1 == null && selectedDate2 == null && selectedUniqueDate == null) {
      setState(() {
        filteredRole = _allRoles; // Réinitialiser pour montrer tous les rôles si le champ est vide
        isSearchActive = false;
        isSearching = false;
        isFiltering = false;
      });
      return;
    }

    //print('Contenu de _allRoles : $_allRoles'); // Affiche les données dans la console pour vérification
    // Vérifiez si les filtres de dates sont actifs
    //final bool dateFilterActive = selectedDate1 == null && selectedDate2 == null;
    //final bool uniqueDateFilterActive = selectedUniqueDate == null;

    List<dynamic> searchResults = _allRoles.where((role) {

      final section = (role['section']?.toLowerCase() ?? '');
      final president = (role['president']?.toLowerCase() ?? '');
      final dateEnreg = (role['dateEnreg'] ?? '');
      final searchLower = query.toLowerCase();
      bool matchesText = section.contains(searchLower) ||
          president.contains(searchLower) ||
          dateEnreg.contains(searchLower);
      if (filterByPresidentOnly) {
        matchesText = president.contains(searchLower);
      }
      // Vérifier si la date est dans la plage sélectionnée
      bool matchesDate = true;
      if (selectedDate1 != null || selectedDate2 != null) {
        if (role.containsKey('dateEnreg') && role['dateEnreg'].isNotEmpty) {
          try {
            final DateTime affaireDate = DateTime.parse(role['dateEnreg']);
            if (selectedDate1 != null && selectedDate2 != null) {
              matchesDate = (affaireDate.isAfter(selectedDate1!) && affaireDate.isBefore(selectedDate2!)) ||
                  affaireDate.isAtSameMomentAs(selectedDate1!) || affaireDate.isAtSameMomentAs(selectedDate2!);
            } else if (selectedDate1 != null) {
              matchesDate = affaireDate.isAfter(selectedDate1!) || affaireDate.isAtSameMomentAs(selectedDate1!);
            } else if (selectedDate2 != null) {
              matchesDate = affaireDate.isBefore(selectedDate2!) || affaireDate.isAtSameMomentAs(selectedDate2!);
            }
          } catch (e) {
            //print("Erreur de parsing de la date dans matchesDate : $e");
            matchesDate = false;
          }
        } else {
          matchesDate = false; // Ignorer si 'dateEnreg' est vide
        }
      }

      // Vérifier si la date correspond à une date unique
      bool matchesUniqueDate = true;
      if (selectedUniqueDate != null) {
        if (role.containsKey('dateEnreg') && role['dateEnreg'].isNotEmpty) {
          try {
            final DateTime affaireDate = DateTime.parse(role['dateEnreg']);
            matchesUniqueDate = affaireDate.isAtSameMomentAs(selectedUniqueDate!);
          } catch (e) {
            //print("Erreur de parsing de la date dans matchesUniqueDate : $e");
            matchesUniqueDate = false;
          }
        } else {
          matchesUniqueDate = false; // Ignorer si 'dateEnreg' est vide
        }
      }
      return matchesText && matchesDate && matchesUniqueDate;
    }).toList();

    // Affichage des dates uniquement dans la console
    List<String> dates = [];
    for (var role in searchResults) {
      final dateEnreg = role['dateEnreg'];
      if (dateEnreg != null && dateEnreg.isNotEmpty) {
        dates.add(dateEnreg);
      }
    }

    // Affichage des dates dans la console
    //print('Dates filtrées : $dates');

    setState(() {
      filteredByRoleDates = searchResults; // Enregistrer les données filtrées
      filteredRole = searchResults;
      isLoading = false;
      isSearching = false;
      isFiltering = false;
    });
  }


  Future<void> _selectDate(BuildContext context, int dateField) async {
    setState(() {
      isLoading = true;
    });

    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (picked != null) {
        setState(() {
          if (dateField == 1) {
            selectedDate1 = picked;
            //print("Date 1 sélectionnée : $selectedDate1");
          } else if (dateField == 2) {
            selectedDate2 = picked;
            // print("Date 2 sélectionnée : $selectedDate2");
          } else if (dateField == 3) {
            selectedUniqueDate = picked;
            // print("Date unique sélectionnée : $selectedUniqueDate");
          }
        });

        await _filterRoles('');
      }
    } catch (e) {
      // print("Erreur lors de la sélection de la date : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _filterByPresident(String query) async {
    setState(() {
      isSearchActive = query.isNotEmpty; // Active ou désactive la recherche
      isSearching = true;
      isFiltering = isSearchActive;
    });

    if (query.isEmpty) {
      setState(() {
        filteredRole = _allRoles; // Réinitialiser pour montrer tous les rôles si le champ est vide
        isSearchActive = false;
        isSearching = false;
        isFiltering = false;
      });
      return;
    }
    // print('Contenu de _allRoles : $_allRoles'); // Affiche les données dans la console pour vérification
    List<dynamic> searchResults = _allRoles.where((role) {
      // final section = (role['section']?.toLowerCase() ?? '');
      final president = (role['president']?.toLowerCase() ?? '');
      // final dateEnreg = (role['dateEnreg'] ?? '');
      final searchLower = query.toLowerCase();
      bool matchesText = president.contains(searchLower) ;
      return matchesText;
    }).toList();
    setState(() {
      filteredRole = searchResults;
      isLoading = false;
      isSearching = false;
      isFiltering = false;
    });
  }

  void _filterByYear(String year, {bool rest = false}) {
    setState(() {
      if (rest) {
        _selectedYear = null;
        filteredRole = _allRoles; // Réinitialiser pour montrer tous les rôles
        _currentTitle = "Années";
      } else {
        _selectedYear = year; // Mettre à jour l'année sélectionnée
        // Filtrer les résultats par année
        filteredRole = _allRoles.where((role) {
          final dateEnreg = role['dateEnreg'] ?? '';
          return dateEnreg.startsWith(year); // Vérifie si la date commence par l'année sélectionnée
        }).toList();
      }
    });
  }


  void resetFilter() {
    setState(() {
      // Réinitialisez la liste filtrée
      filteredRole = roles;
    });
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
      _showError("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      return;
    }

    // Vérifiez la connectivité Internet
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showError("Pas de connexion Internet. Veuillez vérifier votre réseau.");
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      return;
    }

    // Vérification de la connectivité Internet
    final connectivityStatus = await Connectivity().checkConnectivity(); // Renamed the variable
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
      domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;

      // Ajouter le préfixe "https://"
      final url = Uri.parse('https://$domainName/api/roles/?page=$currentPage');

      // Effectuer la requête HTTP
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = utf8.decode(response.bodyBytes);
        final decodedResponse = jsonDecode(jsonResponse);
        // print(decodedResponse); // Imprimez la réponse pour vérifier sa structure
        if (decodedResponse is Map<String, dynamic> && decodedResponse.containsKey('roles')) {
          final rolesData = decodedResponse['roles'];
          if (rolesData is Map<String, dynamic> && rolesData.containsKey('results')) {
            List<dynamic> newRoles = rolesData['results']; // Assurez-vous que c'est bien une liste
            int totalItems = rolesData['total_items'] ?? 0;
            int itemsPerPage = rolesData['items_per_page'] ?? 10;
            totalPages = (totalItems / itemsPerPage).ceil();
            //print(totalPages);
            if (mounted) { // Check if the widget is still mounted
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
            throw Exception('Les données des rôles sont dans un format incorrect. Veuillez vérifier les données.');
          }
        } else {
          throw Exception('Une erreur s\'est produite lors de la récupération des données.');
        }
      } else {
        //throw Exception('Erreur lors de la récupération des données: ${response.statusCode}');
        throw Exception('Erreur lors de la récupération des données');
      }
    }
    on SocketException{
      //print('Erreur résau : Probléme de connexion ');
      throw Exception('Erreur résau : Probléme de connexion ');
    }
    on HttpException{
      // print('Erreur Http :Verifiez l\'url');
      throw Exception('Erreur Http :Verifiez l\'url');
    }
    on FormatException{
      //print('Erreur de format : URL  mal formée');
      throw Exception('Erreur de format : URL  mal formée');
    }
    catch (error) {
      // print(error); // Imprimez l'erreur pour la débogage
      //_showError("Erreur lors de la récupération des données.");
      // Handle errors
      if (mounted) {  // Check if the widget is still mounted
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
          content:const  Text('Pas de connexion Internet. Veuillez vérifier votre réseau.'),
          actions: [
            TextButton(
              child:const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _loadNextPage() {
    // Vérifie si la page actuelle est la dernière ou si le chargement est déjà en cours
    if (currentPage > totalPages && isLoadingMore) {
      // Si toutes les pages sont chargées, afficher un message ou arrêter le chargement supplémentaire
      //print('Aucune nouvelle page à charger ou chargement déjà en cours.');
      setState(() {
        isLoadingMore = false; // Désactiver le chargement supplémentaire
      });
    } else {
      // Sinon, continuer à charger la page suivante
      setState(() {
        currentPage++; // Incrémenter currentPage
        isLoadingMore = true; // Marquer le début du chargement de la page suivante
      });
      fetchPosts(); // Charger la prochaine page
    }
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); // Afficher un message d'erreur
  }
  // État pour gérer l'affichage du container
  Map<int, bool> expandedStates = {}; // Déclaration de expandedStates

  bool isExpanded = false;

  // Déclare un booléen dans ton State
  bool _isSelected = false;
  int? selectedIndex; // 🔹 index du rôle sélectionné


  @override
  Widget build(BuildContext context) {
    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final user = Provider.of<UserProvider>(context).currentUser;
    return Scaffold(
      resizeToAvoidBottomInset: true, // Permet de redimensionner lorsque le clavier apparaît
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
      body: isLoading
          ?const Center(child: CircularProgressIndicator()) // Afficher un indicateur de chargement
          : Column(
        children: [
          // La barre de recherche
          if (!isExpanded)
          // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(9.0),
              child: TextField(
                onChanged: (value) => _filterRoles(value),
                decoration: InputDecoration(
                  hintText: "Rechercher ",
                  prefixIcon:const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:const BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          // Icône pour afficher/masquer le contenu, placée juste en dessous de la barre de recherche
          // const SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Ajoute du padding autour du Row
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                      if (!isExpanded) {
                        filteredRole = roles;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpanded ? Icons.filter_alt : Icons.filter_alt_off,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpanded ? 'Masquer les filtres' : 'Affiner la recherche',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10), // Espacement entre les boutons
                if (!isExpanded)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showYearsContainer = !_showYearsContainer;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentTitle),
                        const SizedBox(width: 8),
                        Icon(
                          _showYearsContainer
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Conteneur des années
          // const SizedBox(height:10,),
          if (_showYearsContainer)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight, // Aligner le conteneur à droite
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal:30.0), // Espacement horizontal
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds:300), // Animation fluide
                        width: MediaQuery.of(context).size.width * 0.36, // Adaptable à l'écran
                        height: _isExpanded ? 130 : 130, // Hauteur dynamique
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white24, // Couleur de fond pour rendre l'ombre visible
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black54.withOpacity(0.1), // Couleur de l'ombre avec opacité
                              blurRadius: 10, // Rayon de flou pour l'ombre
                              spreadRadius: 5, // Écartement de l'ombre
                              offset: const Offset(0, 9), // Décalage horizontal et vertical
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0), // Padding autour du contenu
                            child: Column(
                              children: (() {
                                Set<String> uniqueYears = {};
                                for (var role in _allRoles) {
                                  final year = role['dateEnreg']?.split('-')[0] ?? '';
                                  if (year.isNotEmpty) {
                                    uniqueYears.add(year);
                                  }
                                }
                                List<String> sortedYears = uniqueYears.toList()..sort();
                                sortedYears.insert(0, "----");

                                return sortedYears.isNotEmpty
                                    ? sortedYears.map((year) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (year == "----") {
                                          _selectedYear = null;
                                          _currentTitle = "Années";
                                          _showYearsContainer = false;
                                          resetFilter();
                                        } else {
                                          _selectedYear = year;
                                          _currentTitle = year;
                                          _showYearsContainer = false;
                                          _filterByYear(year);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (_selectedYear == year)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 18,
                                            ),
                                          const SizedBox(width: 10),
                                          Text(
                                            year == "----" ? "Tous" : year,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: _selectedYear == year
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: _selectedYear == year
                                                  ? Colors.green
                                                  : Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList()
                                    : [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'Aucune donnée',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ),
                                ];
                              })(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          //const SizedBox(height: 10,),
          // Afficher le conteneur en bas de la barre de recherche et de l'icône
          if (isExpanded)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[200],
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // Réinitialisez les dates sélectionnées
                            selectedDate1 = null;
                            selectedDate2 = null;
                            selectedUniqueDate = null;
                            // Réinitialisez la liste filtrée
                            filteredRole = roles;
                          });
                        },
                        child:const Row(
                          children: [Text("Réinitialiser les champs")],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Champ de recherche
                      SizedBox(
                        width: 340,
                        height: 50,
                        child: TextFormField(
                          onChanged: (value) {
                            setState(() {
                              searchPresident = value;
                              _filterByPresident(value);
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Rechercher par président",
                            prefixIcon:const Icon(Icons.search, color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Champ de date unique
                      SizedBox(
                        width: 340,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _selectDate(context,3),
                          child: AbsorbPointer(
                            child: Stack(
                              children: [
                                // Champ de texte avec date ou texte d'instruction
                                TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: selectedUniqueDate != null
                                        ? "${selectedUniqueDate!.day}/${selectedUniqueDate!.month}/${selectedUniqueDate!.year}"
                                        : "Veuillez sélectionner une date",
                                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                // Si le chargement est en cours, afficher un indicateur de chargement
                                if (isLoading)
                                  const   Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                      strokeWidth: 2, // Modifier la taille du cercle
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          color: Colors.grey[200],
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Du"),
                                  Flexible(
                                    child: GestureDetector(
                                      onTap: () => _selectDate(context, 1),
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            hintText: selectedDate1 != null
                                                ? "${selectedDate1!.day}/${selectedDate1!.month}/${selectedDate1!.year}"
                                                : "Date",
                                            prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text("Au"),
                                  Flexible(
                                    child: GestureDetector(
                                      onTap: () => _selectDate(context, 2),
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            hintText: selectedDate2 != null
                                                ? "${selectedDate2!.day}/${selectedDate2!.month}/${selectedDate2!.year}"
                                                : "Date",
                                            prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
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
              ),
            ),
          //const SizedBox(height:9,),
          // La suite du contenu
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding:const EdgeInsets.all(8.0),
              itemCount: filteredRole.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredRole.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final role = filteredRole[index];

                // 🔹 Vérifie si c’est l’élément sélectionné
                final bool isSelected = selectedIndex == index;
                // Puis dans le Card
                return Card(
                  color: isSelected ? Colors.orangeAccent : Colors.white12,
                  child: InkWell(
                    onTap: () async {
                      setState(() {
                        selectedIndex = index; // sélectionne uniquement l’élément cliqué
                      });

                      if (user == null) {
                        _showLogin();
                      } else {
                        final roleId = role['id'].toString();
                        if (roleId.isNotEmpty) {
                          try {
                            await fetchRoleDetails(roleId);
                            if (roleDetails != null) {
                              // 🔹 On attend le retour de la navigation
                              await Navigator.pushNamed(
                                context,
                                "/Role_Details",
                                arguments: roleId,
                              );

                              // 🔹 Quand on revient, on réinitialise la sélection
                              setState(() {
                                selectedIndex = null;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Les détails du rôle ne sont pas disponibles pour le moment.')),
                              );
                            }
                          } catch (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Une erreur s’est produite lors de la récupération des informations.')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ID de rôle introuvable.')),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth > 600 ? 16.0 : 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.balance_sharp, size: 50, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${role['juridiction_name'] ?? 'inconnue'} - ${role['dateEnreg'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 12 : 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1e293b),
                                  ),
                                  softWrap: true,
                                ),
                                SizedBox(height: screenWidth > 600 ? 10 : 4),
                                Text(
                                  "Président(e): ${role['president'] ?? ''}",
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 12 : 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                Text(
                                  role['section'] ?? '',
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 12 : 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (screenWidth > 400)
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth > 600 ? 16 : 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.black : Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${role['total_affaire'] ?? 'Inconnu'} Affaires',
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 13 : 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );

              },
            ),
          )
        ],
      ),
      bottomNavigationBar:const SafeArea(child: CustomNavigator(currentIndex: 1)),
    );
  }
}