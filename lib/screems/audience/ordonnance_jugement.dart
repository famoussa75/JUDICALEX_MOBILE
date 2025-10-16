import 'package:flutter/material.dart';
import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';

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
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, "/NotificationPage");
              },
            ),
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
