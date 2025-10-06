import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../db/base_sqlite.dart';

class Decisions extends StatefulWidget {
  const Decisions({super.key});

  @override
  State<Decisions> createState() => _DecisionsState();
}

class _DecisionsState extends State<Decisions> {
  Map<String, dynamic>? affaireDetails;
  Map<String, dynamic>? role;


  @override
  void initState() {
    super.initState();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🔹 Récupérer les arguments passés depuis Navigator.pushNamed
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    if (args != null) {
      role = args['role'];
      print("📦 Rôle reçu : $role");
    }
  }



  Future<Map<String, dynamic>> fetchRoleDetails(String idAffaire) async {
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print("dibbe $data"); // ✅ Affiche les données dans la console
        return data;
      }
      else {
        _showError('Erreur lors de la récupération des détails.');
        return {};
      }
    } catch (e) {

     // _showError('Erreur: $e');
      _showError('Erreur');
      return {};
    }
  }



  var logger = Logger(); // Create a logger instance

  void _showError(String message) {
    logger.e('Erreur: $message');
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final idAffaire = args['id'];

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
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchRoleDetails(idAffaire.toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur: ${snapshot.error}",
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Aucune donnée disponible.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final data = snapshot.data!;
          final decisions = data['decisions'] ?? [];
          final suivi = data['is_suivi'] as List;

          return SingleChildScrollView(
            child: Padding(

              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (suivi.isNotEmpty)
                            const  Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children:  [
                                Icon(Icons.thumb_up, color: Colors.green),
                                SizedBox(width: 6),
                                Text(
                                  "Vous suivez cette affaire",
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20,),
                          // 🔹 NUA
                          Row(
                            children: [
                              const Icon(Icons.article_outlined, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(
                                "NUA : ${data['affaire']['numAffaire']}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 🔹 Parties
                          Row(
                            children: [
                              const Icon(Icons.people_outline, color: Colors.orangeAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Parties : ${data['affaire']['demandeurs'] ?? 'N/A'} C/ ${data['affaire']['defendeurs'] ?? 'N/A'}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 🔹 Objet
                          Row(
                            children: [
                              const Icon(Icons.subject_outlined, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Objet : ${data['affaire']['objet'] ?? 'Objet non précisé'}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ),
                  if (suivi.isNotEmpty) const SizedBox(height: 20),
                  // 🔹 Liste des décisions
                  decisions.isNotEmpty
                      ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: decisions.length,
                    itemBuilder: (context, index) {
                      final decision = decisions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 En-tête décision
                              Row(
                                children: [
                                  const Icon(Icons.gavel, color: Colors.deepOrange),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Décision N°${index + 1} du ${decision['dateDecision'] ?? 'date inconnue'}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // 🔹 Rôle
                              _buildDetailRow("Président", role?['president'] ?? "Non précisé"),
                              _buildDetailRow("Greffier(ère)", role?['greffier'] ?? "Non précisé"),
                              const SizedBox(height: 8),
                              // 🔹 Détails de la décision
                              _buildDetailRow("Type", decision['typeDecision'] ?? "Non précisé"),
                              _buildDetailRow("Décision", decision['decision'] ?? "Non précisé", maxLines: 2),
                              _buildDetailRow("Prochaine Audience", decision['prochaineAudience'] ?? "Non précisé"),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                      : const Center(
                    child: Text(
                      "Aucune décision disponible.",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },

      ),
     // bottomNavigationBar: const CustomNavigator(currentIndex: 1),
    );
  }


  Widget _buildDetailRow(
      String label,
      String? leftValue, {
        String? rightValue,
        String separator = ' / ',
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: leftValue ?? "Non précisé"),
            if (rightValue != null && rightValue.isNotEmpty)
              TextSpan(text: "$separator${rightValue}"),
          ],
        ),
      ),
    );
  }


}
