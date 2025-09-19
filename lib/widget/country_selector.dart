import 'package:ejustice/db/base_sqlite.dart';
import 'package:ejustice/widget/domain_provider.dart';
import 'package:ejustice/widget/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


// Modèle de pays
class Country {
  final String pays;
  String nomDomaine; // Nom de domaine est maintenant modifiable
  bool selected; // Propriété pour indiquer si le pays est sélectionné

  Country({required this.pays, required this.nomDomaine, this.selected = false});

  Map<String, dynamic> toMap() {
    return {
      'pays': pays,
      'nom_domain': nomDomaine,
      'selected': selected ? 1 : 0, // Convertir bool en int
    };
  }
}

class CountrySelectionWidget extends StatefulWidget {
  final Function(bool) onContinueButtonVisibilityChanged;
  final double fontSize; // Paramètre pour la taille de la police


  const CountrySelectionWidget({super.key, required this.onContinueButtonVisibilityChanged,this.fontSize = 18,});

  @override
  CountrySelectionWidgetState createState() => CountrySelectionWidgetState();
}

class CountrySelectionWidgetState extends State<CountrySelectionWidget> {


  final List<Country> countries = [
    Country(pays: "Guinée", nomDomaine: "https://judicalex-gn.org/"),
    // Ajoutez d'autres pays ici
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedCountry(); // Charger les données enregistrées au démarrage
  }

  Future<void> _loadSavedCountry() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Country> savedCountries = await dbHelper.getAllCountries();

    if (savedCountries.isNotEmpty) {
      setState(() {
        for (var country in countries) {
          country.selected =
            savedCountries.any((savedCountry) => savedCountry.pays ==
            country.pays);
        }

        // Mettre à jour le domaine sélectionné dans le provider
        Country? selectedCountry = countries.firstWhere((c) => c.selected,
            orElse: () => countries[0]);
        Provider.of<DomainProvider>(context, listen: false).setSelectedDomain(
            selectedCountry.nomDomaine);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
// Control this flag based on some logic
    return Container( // Ajouter un Container ici pour la décoration
      decoration: BoxDecoration(
        color:const  Color(0xFF1e293b), // Couleur de fond pour le Container
        borderRadius: BorderRadius.circular(5), // Bordures arrondies
        border: Border.all( // 🔹 bordure
          color: Colors.white, // couleur de la bordure
          width: 2,             // épaisseur
        ),
      ),
      child: ExpansionTile(
        title: const Row(
          children: [
             Icon(
              Icons.flag, // Choisissez l'icône que vous souhaitez
              color: Colors.white, // Couleur de l'icône
            ),
             SizedBox(width: 8), // Espacement entre l'icône et le texte
             Text(
              "Choisissez votre pays ",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white, // Couleur du texte
              ),
            ),
          ],
        ),
        children: countries.map((country) {
          return Container( // Ajoutez un Container ici pour chaque pays
            decoration: BoxDecoration(
              color: const Color(0xFF1e293b), // Couleur de fond pour le Container
              borderRadius: BorderRadius.circular(5), // Bordures arrondies
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // Position de l'ombre
                ),
              ],
            ),
            child: ListTile(
              title: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Center(
                  child: Row(
                    children: [
                      // Ajoutez le widget FlagWidget pour afficher le drapeau
                      FlagWidget(country: country.pays), // Afficher le drapeau du pays
                      const SizedBox(width: 10), // Espace entre le drapeau et le texte
                      // Ajoutez l'icône si le pays est sélectionné
                      Text(
                        country.pays,
                        style: TextStyle(
                          fontSize: 18,
                          color: country.selected ? Colors.orangeAccent : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width:50),
                      if (country.selected)
                       const Icon(
                          Icons.check_circle, // Utilisez l'icône de validation
                          color: Colors.green, // Choisissez une couleur pour l'icône
                        ),

                    ],
                  ),
                ),
              ),
              onTap: () async {
                setState(() {
                  for (var c in countries) {
                    c.selected = false;
                  }
                  country.selected = true;
                  widget.onContinueButtonVisibilityChanged(true);
                });

                DatabaseHelper dbHelper = DatabaseHelper();
                Country? existingCountry = await dbHelper.getCountryByName(country.pays);
                if (existingCountry != null) {
                  await dbHelper.deleteCountry(existingCountry.pays);
                }

                await dbHelper.insertCountry(Country(
                  pays: country.pays,
                  nomDomaine: country.nomDomaine,
                  selected: true,
                ));

                // Check if the widget is still mounted before accessing the context
                if (context.mounted) {
                  Provider.of<DomainProvider>(context, listen: false)
                      .setSelectedDomain(country.nomDomaine);
                }
              },
            ),
          );
        }).toList(),
      ),
    );

  }
}
