import 'package:ejustice/widget/country_selector.dart';
import 'package:flutter/material.dart';

class Choix extends StatefulWidget {
  // Add a named 'key' parameter to the constructor
  const Choix({super.key});
  @override
  ChoixState createState() => ChoixState();
}

class ChoixState extends State<Choix> {
  bool _showContinueButton = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e293b),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(26.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image.asset(
                'images/judicalex-blanc.png',
                width: 250,
                height: 50,
                fit: BoxFit.cover,
              ),
              CountrySelectionWidget(
                onContinueButtonVisibilityChanged: (isVisible) {
                  setState(() {
                    _showContinueButton = isVisible;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Produit par SMARTYLEX SARLU",
                style: TextStyle(color: Colors.white),
              ),
              // Afficher le bouton "Continuer" si un pays est sélectionné
              if (_showContinueButton)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login'); // Redirection après sélection
                  },
                  child: const Text('Continuer'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
