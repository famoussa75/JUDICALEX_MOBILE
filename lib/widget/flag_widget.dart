import 'package:flutter/material.dart';

// Widget pour afficher le drapeau d'un pays
class FlagWidget extends StatelessWidget {
  final String country;

  const FlagWidget({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    String flagAsset = _getFlagAsset(country); // Obtenir le chemin du drapeau
    return Image.asset(
      flagAsset,
      width: 30, // Largeur de l'image du drapeau
      height: 20, // Hauteur de l'image du drapeau
    );
  }

  // Méthode pour obtenir le chemin du drapeau selon le pays
  String _getFlagAsset(String country) {
    switch (country) {
      case "Guinée":
        return 'images/guinee.png'; // Chemin de l'image du drapeau pour la Guinée
      case "senegal":
        return 'images/senegal.png'; // Chemin de l'image du drapeau pour la France
    // Ajoutez d'autres pays ici avec leurs chemins de drapeau respectifs
      default:
        return 'images/guinee.png'; // Drapeau par défaut si le pays n'est pas trouvé
    }
  }
}
