import 'package:flutter/material.dart';

import 'choix.dart';

class PubSlider extends StatefulWidget {
 const PubSlider({super.key});
  @override
  PubSliderState createState() => PubSliderState();
}

class PubSliderState extends State<PubSlider> {
  bool showSecond = false; // par défaut on affiche le premier widget

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // fond bleu nuit global
      body: Center(
        child: showSecond ? instruction2(context) : instruction1(context),
      ),
    );
  }

  Widget instruction1(BuildContext context){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // coins arrondis
              ),
              clipBehavior: Clip.antiAlias, // pour que l'image respecte les coins arrondis
              child: Image.asset(
                "images/Lawyer-rafiki1.png",
                width: double.infinity,
                fit: BoxFit.cover, // ou BoxFit.contain selon ton besoin
              ),
            ),
          ),
        ),
        const  Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                "Comprendre vos droits Simplement",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height:20),
              Text(
                "Accédez à des ressources claires et fiables pour mieux comprendre vos droits et obligations au quotidien !",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF1e293b),
                side: const BorderSide(color: Colors.orange, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                setState(() {
                  showSecond = true; // 👉 passe au 2ème écran
                });
              },
              child: const Text(
                "Suivant",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// DEUXIÈME INSTRUCTION
  Widget instruction2(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              "images/Judge-amico1.png", // une autre image par exemple
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                "Suivez le droit en temps réel",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Explorez les textes légaux à jour et restez informé des évolutions juridiques en un clic !",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF1e293b),
                side: const BorderSide(color: Colors.orange, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                // 👉 navigation vers une autre page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Choix(),
                  ),
                );
              },
              child: const Text(
                "Terminer",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
