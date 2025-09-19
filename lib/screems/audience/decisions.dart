import 'dart:convert';
import 'package:ejustice/db/base_sqlite.dart';
import 'package:ejustice/widget/bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class Decisions extends StatefulWidget {
  const Decisions({super.key});

  @override
  State<Decisions> createState() => _DecisionsState();
}

class _DecisionsState extends State<Decisions> {
  Map<String, dynamic>? affaireDetails;


  @override
  void initState() {
    super.initState();

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

                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 En-tête affaire
                  Text(
                    "AFFAIRE N° : ${data['affaire']['id']}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Objet : ${data['affaire']['objet'] ?? 'Objet non précisé'}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),

                  ),
                  const SizedBox(height: 16),

                  // 🔹 Suivi de l'affaire
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
                  if (suivi.isNotEmpty) const SizedBox(height: 20),


                  const SizedBox(height: 12),

                  // 🔹 Liste des décisions
                  decisions.isNotEmpty
                      ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: decisions.length,
                    itemBuilder: (context, index) {
                      final decision = decisions[index];
                      return Card(
                        color: Colors.white12,

                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,


                            children: [
                              Text(
                                "Décision N°${index + 1} du ${decision['dateDecision'] ?? 'date inconnue'}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54,),
                              ),
                              const Divider(),
                              _buildDetailRow("Type", decision['typeDecision']),

                              _buildDetailRow("Président", decision['president']),
                              _buildDetailRow("Greffier(ère)", decision['greffier']),
                              _buildDetailRow("Décision", decision['decision'], maxLines: 2),
                              _buildDetailRow("Prochaine Audience", decision['prochaineAudience']),
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


// 🔹 Fonction utilitaire pour afficher un label + valeur
  Widget _buildDetailRow(String label, String? value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? "Non précisé"),
          ],
        ),
      ),
    );
  }

}
