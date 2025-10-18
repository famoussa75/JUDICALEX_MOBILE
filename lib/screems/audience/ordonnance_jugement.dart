import 'package:flutter/material.dart';
import '../../db/base_sqlite.dart';
import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';
import '../../widget/notifications.dart';

class OrdonnanceJugement extends StatelessWidget {
  const OrdonnanceJugement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
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
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "images/judicalex-blanc1.png",
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
          ],
        ),
      ),
      body:const Center(
        child:  Row(
          children: [
            Icon(Icons.gavel_sharp, color: Colors.brown, size: 30), // Marteau du juge

          ],
        )
      ),
      bottomNavigationBar: const  SafeArea(child: CustomNavigator(currentIndex: 3)),
    );
  }
}
