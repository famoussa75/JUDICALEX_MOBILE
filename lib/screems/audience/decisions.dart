// lib/pages/decisions_page.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../API/api.decisions.dart';

class Decisions extends StatefulWidget {
  const Decisions({super.key});

  @override
  State<Decisions> createState() => _DecisionsState();
}

class _DecisionsState extends State<Decisions> {
  Map<String, dynamic>? role;
  final AffaireService _affaireService = AffaireService();
  final Logger logger = Logger();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    if (args != null) {
      role = args['role'];
     /// logger.i("📦 Rôle reçu : $role");
    }
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
          title: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset("images/judicalex-blanc.png", height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, "/NotificationPage"),
                ),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _affaireService.fetchAffaireDetails(idAffaire.toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Erreur: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final data = snapshot.data ?? {};
          if (data.isEmpty) {
            return const Center(child: Text("Aucune donnée disponible."));
          }

          final decisions = data['decisions'] ?? [];
          final suivi = data['is_suivi'] as List? ?? [];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildAffaireHeader(data, suivi),
                  const SizedBox(height: 20),
                  decisions.isNotEmpty
                      ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: decisions.length,
                    itemBuilder: (context, index) {
                      final decision = decisions[index];
                      return _buildDecisionCard(decision, index);
                    },
                  )
                      : const Text("Aucune décision disponible."),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🔹 En-tête de l'affaire
  Widget _buildAffaireHeader(Map<String, dynamic> data, List suivi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final double baseFontSize = screenWidth < 350
              ? 12
              : screenWidth < 600
              ? 15
              : 16;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (suivi.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.thumb_up, color: Colors.green),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Vous suivez cette affaire",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: baseFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _buildDetailRow("NUA", data['affaire']['numAffaire'], baseFontSize + 2),
              const SizedBox(height: 12),
              _buildDetailRow(
                "Parties",
                "${data['affaire']['demandeurs'] ?? 'N/A'} C/ ${data['affaire']['defendeurs'] ?? 'N/A'}",
                baseFontSize,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                "Objet",
                data['affaire']['objet'] ?? 'Objet non précisé',
                baseFontSize,
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔹 Une carte décision
  Widget _buildDecisionCard(Map decision, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.gavel, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text(
              "Décision N°${index + 1} du ${decision['dateDecision'] ?? 'date inconnue'}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ]),
          const SizedBox(height: 12),
          _buildTextRow("Type", decision['typeDecision']),
          _buildTextRow("Décision", decision['decision']),
          _buildTextRow("Prochaine Audience", decision['prochaineAudience']),
        ]),
      ),
    );
  }

  /// 🔹 Ligne de texte simple
  Widget _buildTextRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(

        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? "Non précisé"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, double fontSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.article_outlined, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "$label : ${value ?? 'Non précisé'}",
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
