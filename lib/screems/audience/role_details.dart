import 'dart:convert';  // For jsonDecode
import 'dart:ui';
import 'package:ejustice/db/base_sqlite.dart';
import 'package:ejustice/widget/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RolesDetail extends StatefulWidget {
  const RolesDetail({super.key});

  @override
  State<RolesDetail> createState() => RolesDetailState();
}

class RolesDetailState extends State<RolesDetail> {
  List<dynamic>? roleDetails; // To hold the fetched role details
  bool isLoading = true; // To show loading state
  String errorMessage = ''; // To hold any error messages
  bool isLoadingMore = false;

  Map<String, dynamic> role = {};
  List<dynamic>? affaireSuivis; // To hold the fetched role details
 // List<Map<String, dynamic>> affaireSuivis = []; // Déclarez ici


  List<bool> isCheckedList = []; // Initialiser la variable pour l'état de la case à cocher

  String? juridiction; // Variable pour la juridiction
  String? roleId; // Variable pour l'ID du rôle
  String? detailRoleId;

  @override
  void initState() {
    super.initState();
    loadFollowedAffairs(); // Load followed affairs when the widget initializes
    setState(() {
     // fetchRoleDetails(roleId!); // Utilisez 'roleId!' pour passer la valeur non-nullable
    });
  }

  @override
  void dispose() {
    super.dispose();

  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the role ID from route arguments
    final String roleId = ModalRoute
        .of(context)!
        .settings
        .arguments as String;
    // Call the method to fetch role details
    fetchRoleDetails(roleId);
  }

  int? selectedIndex;

  bool selectAll = false; // 🔹 false = rien sélectionné, true = tout sélectionné


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF1e293b),
          iconTheme: const IconThemeData(color: Colors.white),
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          automaticallyImplyLeading: true, // affiche bien le menu hamburger
          title: Stack(
            alignment: Alignment.center,
            children: [
              // ✅ Logo centré
              Image.asset(
                "images/judicalex-blanc.png",
                height: 32,
              ),

              // ✅ Icône notification alignée à droite
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, "/NotificationPage");
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : Column(
        children: [
          // Gardez seulement le Expanded avec ListView
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                // Premier SizedBox (détails du rôle)
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: role != null
                                ? Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const[
                                 BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  // Votre contenu existant pour les détails du rôle
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        if (role['juridiction_name'] != null && role['juridiction_name']!.isNotEmpty)
                                          Text(
                                            '${role['juridiction_name']}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.black54),
                                          ),
                                        if (role['section'] != null && role['section']!.isNotEmpty)
                                          Text(
                                            '${role['section']}',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black54),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Lignes label/valeur
                                  Row(
                                    children: [
                                      const Expanded(
                                        flex: 1,
                                        child: Text(
                                          "Type Audience :",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          role['typeAudience'] ?? 'N/A',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Expanded(
                                        flex: 1,
                                        child: Text(
                                          "Date :",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          role['dateEnreg'] ?? 'N/A',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (role['juge'] != null && role['juge']!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Expanded(
                                          flex: 1,
                                          child: Text(
                                            "Juge :",
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            role['juge']!,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (role['president'] != null && role['president']!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Expanded(
                                          flex: 1,
                                          child: Text(
                                            "Président :",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            role['president']!,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (role['greffier'] != null && role['greffier']!.isNotEmpty)
                                    Row(
                                      children: [
                                        const Expanded(
                                          flex: 1,
                                          child: Text(
                                            "Greffier :",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            role['greffier']!,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            )
                                : const Center(
                              child: Text('Chargement des détails...'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), /// padding ajouté
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        // 🔹 Bouton Tout suivre
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[400],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: const Icon(Icons.check, color: Colors.white, size: 18),
                            label: const Text(
                              " Sélectionner tout",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              setState(() {
                                for (int i = 0; i < isCheckedList.length; i++) {
                                  isCheckedList[i] = true; /// coche toutes les cases
                                }
                                selectAll = true; /// marque que tout est sélectionné
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12), /// espace entre les deux boutons
                        /// Bouton Tout ne plus suivre
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: const Icon(Icons.close, color: Colors.white, size: 18),
                            label: const Text(
                              "Déselectionner",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              setState(() {
                                for (int i = 0; i < isCheckedList.length; i++) {
                                  isCheckedList[i] = false; // décoche toutes les cases
                                }
                                selectAll = false; // marque que rien n'est sélectionné
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Liste des détails
                roleDetails != null && roleDetails!.isNotEmpty
                    ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: roleDetails!.length,
                  itemBuilder: (context, index) {
                    final item = roleDetails![index];
                    return buildDetailRow(item, index);
                  },
                )
                    : const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Aucune information disponible pour le moment')),
                ),

              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  ///Bouton Suivre
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isCheckedList.contains(true)
                          ? () async {
                        final userProvider = Provider.of<UserProvider>(context, listen: false);

                        // Récupérer tous les ID des affaires cochées
                        List<String> idAffaires = [];
                        for (int i = 0; i < isCheckedList.length; i++) {
                          if (isCheckedList[i]) {
                            idAffaires.add(roleDetails?[i]['id']?.toString() ?? 'N/A');
                          }
                        }

                        // Vérifiez que la liste d'ID n'est pas vide
                        if (idAffaires.isNotEmpty) {
                          String? jurisdiction = role['juridiction']?.toString();
                          String? roleId = role['id']?.toString();
                          String? userId = userProvider.currentUser?.id.toString();

                          if (jurisdiction != null && userId != null) {
                            bool success = await suivreAffaire(
                              context,
                              idAffaires,
                              jurisdiction,
                              roleId,
                              userId,
                            );
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.white70,
                                  content: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      SizedBox(width: 10),
                                      Text(
                                        'Félicitation! Vous suivez désormais ces affaires.',
                                        style: TextStyle(color: Colors.black54, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              await Future.delayed(const Duration(seconds: 2));
                              if (mounted && roleId != null) {
                                setState(() {
                                  fetchRoleDetails(roleId);
                                });
                              }
                            }
                          } else if (mounted) {
                            _showError("Aucune affaire ou juridiction disponible pour la sélection effectuée.");
                          }
                        }
                      }
                          : null,
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text("Suivre"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  /// Bouton Ne plus suivre
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isCheckedList.contains(true)
                          ? () async {
                        final userProvider = Provider.of<UserProvider>(context, listen: false);

                        List<String> idAffaires = [];
                        for (int i = 0; i < isCheckedList.length; i++) {
                          if (isCheckedList[i]) {
                            idAffaires.add(roleDetails?[i]['id']?.toString() ?? 'N/A');
                          }
                        }

                        if (idAffaires.isNotEmpty) {
                          String? jurisdiction = role['juridiction']?.toString();
                          String? roleId = role['id']?.toString();
                          String? userId = userProvider.currentUser?.id.toString();

                          if (jurisdiction != null && userId != null) {
                            bool success = await nePasSuivre(
                              context,
                              idAffaires,
                              jurisdiction,
                              roleId,
                              userId,
                            );
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.white70,
                                  content: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.close_sharp, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text(
                                        'Vous ne suivez plus ces affaires.',
                                        style: TextStyle(color: Colors.black54, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              await Future.delayed(const Duration(seconds: 2));
                              if (mounted && roleId != null) {
                                setState(() {
                                  fetchRoleDetails(roleId);
                                });
                              }
                            }
                          } else if (mounted) {
                            _showError("Aucune affaire ou juridiction disponible pour la sélection effectuée.");
                          }
                        }
                      }
                          : null,
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text("Ne plus suivre"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
     // bottomNavigationBar: const CustomNavigator(currentIndex: 1),
    );
  }
  // Fonction pour suivre un élément
  void suivre(int index) {
    setState(() {
      isCheckedList[index] = true; // Marquer comme suivi
    });
  }
  Widget buildDetailRow(Map<String, dynamic> item, int index) {
    String idAffaire = item['id']?.toString() ?? 'N/A'; // Récupération de l'ID de roleDetails
    String numOrdre = item['numOrdre']?.toString() ?? 'N/A';
    String demandeurs = item['demandeurs'] ?? 'N/A';
    String defendeurs = item['defendeurs'] ?? 'N/A';
    String objet = item['objet'] ?? 'N/A';

    // Vérifier si l'affaire est déjà suivie
    bool alreadyFollowed = affaireSuivis!.any((affaire) {
      String idSuivre = affaire['affaire']?.toString() ?? 'N/A'; // Récupération de l'ID d'affaireSuivis
      return idAffaire == idSuivre; // Vérifier si les IDs correspondent
    });
    // Initialize the isCheckedList for each row
    if (isCheckedList.length <= index) {
      isCheckedList.add(false); // Ensure we have a value for this index
    }

    final bool isSelected = selectedIndex == index || isCheckedList[index];


    return Card(
      color: isSelected ? Colors.orangeAccent : Colors.white12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: InkWell(
          onTap: () {
            setState(() {
              selectedIndex = index; // sélectionne uniquement cette carte
            });
            _showAffaireDetailsDialog(idAffaire);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'N°: $numOrdre',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            alreadyFollowed ? 'Déjà suivi' : '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: alreadyFollowed ? Colors.green : Colors.red,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isCheckedList[index],
                    activeColor: Colors.orange,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (bool? value) {
                      setState(() {
                        isCheckedList[index] = value ?? false;
                        selectAll = !isCheckedList.contains(false);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Demandeurs: $demandeurs', style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 4),
              Text('Défendeurs: $defendeurs', style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 4),
              Text('Objet: $objet', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );



  }






  Future<void> fetchRoleDetails(String roleId) async {
    if (!mounted) return;
    // Récupérer le token
    String? token = await DatabaseHelper().getToken();
    if (token == null || token.isEmpty) {
      _showError("Le token d'authentification est manquant. Veuillez vous reconnecter pour continuer.");
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      return;
    }

    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      _showError(
          "Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
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

      final url = Uri.parse('https://$domainName/api/role/$roleId/');
      final response = await http.get(
          url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $token', // Ajoutez le token ici
        },
      );
      //print('$token');

      // Mettez à jour l'URL de l'API pour inclure le roleId
      // final response = await http.get(Uri.parse('https://judicalex-gn.org/api/role/$roleId/'));

      if (response.statusCode == 200) {
        // Décoder le corps de la réponse
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        //Afficher toutes les données du rôle dans la console
        //print('Données récupérées pour le rôle: ${data['role']}');
        //Afficher toutes les données du rôle dans la console
        //print('Données récupérées pour le affaireSuivis: ${data['affaireSuivis']}');

        if(!mounted) return;
        setState(() {
          juridiction = data['juridiction']; // Stocker la juridiction
          this.roleId = roleId; // Stocker l'ID du rôle
          role = data ['role'];
          roleDetails = data['detailRole']; // Ajustez cette ligne si votre structure de données est différente
          affaireSuivis = data['affaireSuivis'];
          isLoading = false; // Mettre à jour l'état de chargement
          // Initialiser isCheckedList pour correspondre à la longueur de roleDetails
          isCheckedList = List<bool>.filled(roleDetails!.length, false);

        });
        // Afficher les données dans la console pour le débogage
       // print('Données récupérées pour la juridiction: $juridiction');
       // print('ID du rôle: $roleId');
       // print(data['affaireSuivis']);
      } else {
        if (!mounted) return;
        // Si le serveur ne retourne pas une réponse 200 OK, gérer l'erreur
        setState(() {
          errorMessage = 'Impossible de charger les détails du rôle. Veuillez réessayer.';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) return;
      setState(() {
        errorMessage = 'Une erreur est survenue. Nous vous prions de bien vouloir réessayer.';
        isLoading = false; // Mettre à jour l'état de chargement en cas d'erreur
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message))); // Afficher un message d'erreur
  }

  Future<bool> suivreAffaire(
      BuildContext context, List<String> idAffaires, String juridiction, String? roleId, String? userId) async {

    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      _showError("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
      return false;
    }

    domainName = domainName.replaceAll(RegExp(r'^(http://|https://)'), '').replaceAll(RegExp(r'/+$'), '');

    if (userId == null) {
      _showError("Aucun utilisateur connecté. Veuillez vous connecter.");
      return false;
    }

    String? token = await DatabaseHelper().getUserToken(userId);
    if (token == null) {
      _showError("Aucun token trouvé. Veuillez vérifier votre connexion et réessayer.");
      return false;
    }

    try {
      final url = Uri.parse('https://$domainName/api/suivre-affaire/');
      //print('URL de requête : $url');

      final requestBody = {
        "selected": idAffaires, // Envoyer la liste complète d'ID
        "account_id": userId,
        "juridiction_id": juridiction,
      };
    //  print('Données envoyées : ${json.encode(requestBody)}');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
       // print("Affaires suivies avec succès sur le serveur. Réponse : ${response.body}");
        return true;
      } else {
       // _showError('Échec de la mise à jour des affaires. Statut: ${response.statusCode}, message : ${response.body}');
        _showError('La mise à jour des affaires a échoué. Veuillez réessayer plus tard.');
        return false;
      }
    } catch (e) {
      _showError('Une erreur est survenue ');
      return false;
    }
  }
  Future<bool> nePasSuivre(
      BuildContext context, List<String> idAffaires, String juridiction, String? roleId, String? userId) async {
    String? domainName = await DatabaseHelper().getDomainName();
    if (domainName == null || domainName.isEmpty) {
      _showError("Aucun nom de domaine trouvé. Veuillez vérifier votre configuration.");
      return false;
    }
    domainName = domainName.replaceAll(RegExp(r'^(http://|https://)'), '').replaceAll(RegExp(r'/+$'), '');
    if (userId == null) {
      _showError("Aucun utilisateur connecté. Veuillez vous connecter.");
      return false;
    }
    String? token = await DatabaseHelper().getUserToken(userId);
    if (token == null) {
      _showError("Aucun token trouvé. Veuillez vérifier votre connexion et réessayer.");
      return false;
    }
    try {
      final url = Uri.parse('https://$domainName/api/ne-pas-suivre-affaire/');
      //print('URL de requête : $url');
      final requestBody = {
        "selected": idAffaires, // Envoyer la liste complète d'ID
        "account_id": userId,
        "juridiction_id": juridiction,
      };
     // print('Données envoyées : ${json.encode(requestBody)}');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        //print("Vous ne suivez plus ces affaires. . Réponse : ${response.body}");
        return true;
      } else {
       // _showError('Échec de la mise à jour des affaires. Statut: ${response.statusCode}, message : ${response.body}');
        _showError('Échec de la mise à jour des affaires.');
        return false;
      }
    } catch (e) {
      _showError('Une erreur est survenue : $e');
      return false;
    }
  }

  Future<void> loadFollowedAffairs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? followedAffairs = prefs.getStringList('followedAffairs');
    if (followedAffairs != null) {
      isCheckedList = List<bool>.filled(roleDetails?.length ?? 0, false);
      for (String id in followedAffairs) {
        int index = roleDetails?.indexWhere((element) => element['id'].toString() == id) ?? -1;
        if (index != -1) {
          isCheckedList[index] = true; // Mark as followed
        }
      }
    }
    setState(() {});
  }

  Future<Map<String, dynamic>> fetchRoleDetailsDecision(String idAffaire) async {
    String? token = await DatabaseHelper().getToken();
    String? domainName = await DatabaseHelper().getDomainName();

    if (token == null || token.isEmpty || domainName == null || domainName.isEmpty) {
      _showError("Erreur d'authentification ou configuration.");
      return {};
    }

    try {

      // Retirer le préfixe "http://" ou "https://"
      domainName = domainName.replaceAll(RegExp(r'^https?://'), '');
      domainName = domainName.endsWith('/') ? domainName.substring(0, domainName.length - 1) : domainName;

      final url = Uri.parse('https://$domainName/api/affaire/$idAffaire/');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      });

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



  void _showAffaireDetailsDialog(String idAffaire) async {
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
        barrierColor: Colors.black.withOpacity(0.2), // un léger voile en plus du flou
        pageBuilder: (context, anim1, anim2) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), /// flou appliqué
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
                      GestureDetector(
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            "/Decisions",
                            arguments: {'id': idAffaire},
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AFFAIRE N° : ${data['affaire']['id']}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: "Objet: ",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: data['affaire']['objet'] ?? 'Objet non précisé',
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
                              return _buildDecisionCard(decisions[index], index, decisions.length);
                            },
                          ),
                        )
                      else
                        const Center(child: Text("Aucune décision disponible.")),

                      const SizedBox(height: 10),
                      Center(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orangeAccent, width: 1.5), // ✅ couleur & épaisseur de la bordure
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // ✅ coins arrondis
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          child: const Text(
                            "Retour",
                            style: TextStyle(color: Colors.orangeAccent), // ✅ couleur du texte
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


  Widget _buildDecisionCard(Map<String, dynamic> decision, int index, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("Décision ${index + 1}/$total",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
            ),
            const Divider(),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const  WidgetSpan(
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
                  const  WidgetSpan(
                    child: Text(
                      "Date: ",
                      style:  TextStyle(fontWeight: FontWeight.bold),
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
                  const  WidgetSpan(
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
                  const  WidgetSpan(
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
                  TextSpan(
                    text: decision['decision'] ?? 'Inconnu',
                  ),
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
                  TextSpan(text: decision['prochaineAudience'] ?? 'Non précisé'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

