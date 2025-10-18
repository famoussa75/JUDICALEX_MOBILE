// lib/pages/decisions_page.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../db/base_sqlite.dart';
import '../../widget/notifications.dart';
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

  late Future<Map<String, dynamic>> _affaireFuture; // ✅ Future stocké une seule fois

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // On initialise le Future uniquement si pas encore fait
    if (role == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        role = args['role'];
        final idAffaire = args['id'];
        _affaireFuture = _affaireService.fetchAffaireDetails(idAffaire.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF1e293b),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset("images/judicalex-blanc1.png", height: 32),
              Align(
                alignment: Alignment.centerRight,
                child:  IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  splashRadius: 24,
                  tooltip: "Notifications",
                  onPressed: () async {
                    try {
                      // 🔄 Actualiser d'abord les notifications depuis ton API
                      await NotificationFetcher.fetchAndSaveNotifications(context);

                      // 📥 Puis récupérer les notifications stockées localement
                      final notifications = await DatabaseHelper().getNotifications();

                      if (!context.mounted) return;

                      // 🪟 Afficher la boîte de dialogue
                      showDialog(
                        context: context,
                        builder: (context) => CustomDialogBox(
                          title: "Notifications récentes",
                          message: notifications.isEmpty
                              ? "Aucune notification disponible."
                              : notifications
                              .take(3) // Affiche les 3 plus récentes
                              .map((n) => "• ${n['message']}")
                              .join("\n\n"),
                          confirmText: "Tout voir",
                          onConfirm: () {
                            Navigator.pop(context); // Fermer la boîte avant de naviguer
                            Navigator.pushNamed(context, "/NotificationPage");
                          },
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      // 🚨 En cas d’erreur, afficher une boîte d’erreur simple
                      showDialog(
                        context: context,
                        builder: (context) => CustomDialogBox(
                          title: "Erreur",
                          message: "Impossible de charger les notifications : $e",
                          confirmText: "OK",
                          onConfirm: () => Navigator.pop(context),
                        ),
                      );
                    }
                  },
                )
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _affaireFuture, // ✅ On réutilise le même future, pas de recharge
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

  /// ✅ Boîte de dialogue notifications sans rechargement
  Future<void> _showNotificationsDialog() async {
    final notifications = await DatabaseHelper().getNotifications();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => CustomDialogBox(
        title: "Notifications récentes",
        message: notifications.isEmpty
            ? "Aucune notification disponible."
            : notifications
            .take(3)
            .map((n) => "• ${n['message']}")
            .join("\n\n"),
        confirmText: "Tout voir",
        onConfirm: () {
          Navigator.pop(context); // ferme la boîte
          Navigator.pushNamed(context, "/NotificationPage");
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
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
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
