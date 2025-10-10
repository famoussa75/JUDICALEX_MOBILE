// lib/screems/audience/mesAffaire.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';
import '../API/api.mes_affaire.dart';

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
  bool isSearchActive = false;
  int? selectedIndex;

  var logger = Logger();

  @override
  void initState() {
    super.initState();
    fetchAffaires();
  }

  Future<void> fetchAffaires() async {
    if (!await MesAffaireApi.hasInternetConnection(context)) {
      setState(() => isLoading = false);
      return;
    }

    final data = await MesAffaireApi.fetchAffaires(context);
    setState(() {
      affairesData = data;
      filteredAffairesData = affairesData;
      isLoading = false;
    });
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredAffairesData = affairesData.where((affaire) {
        final objet = affaire['affaire']['objet']?.toString().toLowerCase() ?? '';
        final demandeur = affaire['affaire']['demandeurs']?.toString().toLowerCase() ?? '';
        final defendeurs = affaire['affaire']['defendeurs']?.toString().toLowerCase() ?? '';
        return objet.contains(query.toLowerCase()) ||
            demandeur.contains(query.toLowerCase()) ||
            defendeurs.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showAffaireDetailsDialog(int idAffaire) async {
    final data = await MesAffaireApi.fetchRoleDetailsDecision(context, idAffaire);
    final decisions = data['decisions'] ?? [];
    final affaire = data['affaire'];

    // 🔹 Charger les détails du rôle dès maintenant
    dynamic roleDetails;
    try {
      final roleId = affaire['role'];
      int page = 1;
      bool found = false;

      while (!found) {
        final newRoles = await MesAffaireApi.fetchPostsPage(context, page);
        if (newRoles.isEmpty) break;

        roleDetails = newRoles.firstWhere(
              (r) => r['id'] == roleId,
          orElse: () => null,
        );

        if (roleDetails != null) found = true;
        else page++;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        ///SnackBar(content: Text("Erreur lors du chargement du rôle: $e")),
       const  SnackBar(content: Text("Erreur lors du chargement du rôle:")),
      );
    }

    if (!context.mounted) return;

    setState(() => selectedIndex = null);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.2),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Center(
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (roleDetails != null) {
                          await Navigator.pushNamed(
                            context,
                            "/Decisions",
                            arguments: {'id': idAffaire, 'role': roleDetails},
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Aucun rôle correspondant trouvé.")),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "NUA : ${affaire['numAffaire']}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(color: Colors.black),
                              children: [
                                const TextSpan(
                                  text: "Objet: ",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                TextSpan(
                                  text: affaire['objet'] ?? 'Objet non précisé',
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
                            return _buildDecisionCard(decisions[index], index, decisions.length, roleDetails);
                          },
                        ),
                      )
                    else
                      const Center(child: Text("Aucune décision disponible.")),
                    const SizedBox(height: 10),
                    Center(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orangeAccent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Retour", style: TextStyle(color: Colors.orangeAccent)),
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
  }


  Widget _buildDecisionCard(Map<String, dynamic> decision, int index, int total, dynamic roleDetails) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (index > 0) const Icon(Icons.arrow_left, color: Colors.orangeAccent, size: 30),
              Text(
                "Décision ${index + 1}/$total",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent),
              ),
              if (index < total - 1)
                const Icon(Icons.arrow_right, color: Colors.orangeAccent, size: 30),
            ]),
            const Divider(),
            _buildInfo("Type", decision['typeDecision']),
            _buildInfo("Date", decision['dateDecision']),
            _buildInfo("Président", roleDetails?['president'] ?? 'Non défini'),
            _buildInfo("Greffier", roleDetails?['greffier'] ?? 'Non défini'),
            _buildInfo("Décision", decision['decision']),
            _buildInfo("Prochaine Audience", decision['prochaineAudience']),
          ],
        ),
      ),
    );
  }


  Widget _buildInfo(String label, String? value) {
    return RichText(
      text: TextSpan(style: const TextStyle(color: Colors.black), children: [
        TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: value ?? "Non précisé"),
      ]),maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

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
          leadingWidth: 140,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Image.asset(
              "images/judicalex-blanc.png",
              height: 80,
            ),
          ),
          title: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, "/NotificationPage");
              },
              splashRadius: 24,
              tooltip: "Notifications",
            ),
          ],
        ),
      ),
      drawer: const MyDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: updateSearchQuery,
              decoration: InputDecoration(
                labelText: 'Rechercher une affaire',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filteredAffairesData.isNotEmpty
                ? ListView.builder(
              itemCount: filteredAffairesData.length,
              itemBuilder: (context, index) {
                final affaire = filteredAffairesData[index]['affaire'];
                final idAffaire = affaire['id'];
                final bool isSelected = selectedIndex == index;

                return Card(
                  color: isSelected ? Colors.orangeAccent : Colors.white12,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: InkWell(
                    onTap: () {
                      setState(() => selectedIndex = index);
                      _showAffaireDetailsDialog(idAffaire);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("NUA : ${affaire['numAffaire']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54))
                              ]),
                          Text("Objet: ${affaire['objet'] ?? 'Non spécifié'}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent)),
                          const SizedBox(height: 6),
                          Text("Demandeur: ${affaire['demandeurs'] ?? 'Non spécifié'}",
                              style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.w500)),
                          Text("Défendeur: ${affaire['defendeurs'] ?? 'Non spécifié'}",
                              style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
                : const Center(
                child: Text("Aucune affaire disponible.",
                    style: TextStyle(fontSize: 16, color: Colors.grey))),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavigator(currentIndex: 2),
    );
  }
}
