
import 'package:flutter/material.dart';

import 'package:flutter_web_browser/flutter_web_browser.dart';

import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';

class CodeCivil extends StatefulWidget {
  const CodeCivil({super.key});
  @override
  State<CodeCivil> createState() => _CodeCivilState();
}

class _CodeCivilState extends State<CodeCivil> {
  Future<void> _launchURL(String url) async {
    try {
      await FlutterWebBrowser.openWebPage(
        url: url,
        customTabsOptions: const  CustomTabsOptions(
          colorScheme: CustomTabsColorScheme.dark,
          toolbarColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : Impossible d\'ouvrir $url')),
      );
    }
  }

  int? _expandedIndex;

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height:20,),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Marges pour éviter que l'ombre soit collée aux bords
                decoration: BoxDecoration(
                  color: _expandedIndex == 0 ? Colors.orange.shade100 : Colors.white, // ✅ change couleur SEULEMENT pour cet index
                  border: Border.all( // 🔹 bordure
                    color: Colors.black, // couleur de la bordure
                    width: 2,             // épaisseur
                  ),
                  borderRadius: BorderRadius.circular(10), // Coins arrondis pour une meilleure esthétique
                ),
                child: ExpansionTile(
                  title: const Text("Jurisprudence",style: TextStyle(color: Colors.black,fontSize:22)),
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedIndex = expanded ? 0 : null;
                    });
                  },
                  children: [
                    ListTile(
                      leading: Image.asset(
                        'images/ohada.jpg',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("OHADA", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async {
                        await _launchURL('https://www.ohada.com/');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/legifrance.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("Legifrance", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async {
                        await _launchURL('https://www.legifrance.gouv.fr/');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/lexisnexis.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("Lexisnexis", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async {
                        await _launchURL('https://www.lexisnexis.com/en-us');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/juricaf.jpeg',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("Juricaf", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async {
                        await _launchURL('https://juricaf.org/');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/dalloz.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("Dalloz", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async {
                        await _launchURL('https://www.dalloz.fr/');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/doctrine.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("Doctrine", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async {
                        await _launchURL('https://www.doctrine.fr/');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/lexbase.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("Lexbase Afrique", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async {
                        await _launchURL('https://www.lexbase-afrique.com/');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/lexbase.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("lexbase-freemium", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async {
                        await _launchURL('https://www.lexbase.fr/');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/juriafrica.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("juriafrica", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async {
                        await _launchURL('https://www.juriafrica.com/actualites/');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/legifrance.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("Legiafrica", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async {
                        await _launchURL('https://www.legiafrica.com/');
                      },
                    ),
                  ],
                ),
              ),
              Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                color: _expandedIndex == 1 ? Colors.orange.shade100 : Colors.white, // ✅ change couleur SEULEMENT pour cet index
                borderRadius: BorderRadius.circular(10), // Coins arrondis
                border: Border.all( // 🔹 bordure
                  color: Colors.black, // couleur de la bordure
                  width: 2,             // épaisseur
                ),
              ),
              child: ExpansionTile(
                title: const Text(
                  "Publication Juridiques",
                  style: TextStyle(color: Colors.black, fontSize: 22),
                ),
                onExpansionChanged: (expanded) {
                  setState(() {
                    _expandedIndex = expanded ? 1 : null;
                  });
                },
                children: [
                  ListTile(
                    leading: Image.asset(
                      'images/village_justice.png',
                      height: 50,
                      width: 50,
                      fit: BoxFit.contain,
                    ),
                    title: const Text(
                      "Village-justice",
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                    onTap: () async {
                      await _launchURL('https://www.village-justice.com/articles/index.php');
                    },
                  ),
                ],
              ),
            ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10,horizontal: 15),
                decoration: BoxDecoration(
                  color: _expandedIndex == 2 ? Colors.orange.shade100 : Colors.white, // ✅ change couleur SEULEMENT pour cet index
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all( // 🔹 bordure
                    color: Colors.black, // couleur de la bordure
                    width: 2,             // épaisseur
                  ),
                ),

                child: ExpansionTile(
                  title: const Text("codes",style: TextStyle(color: Colors.black,fontSize:22)),
                  collapsedTextColor: Colors.white,  // 🔹 couleur du texte quand fermé
                  textColor: Colors.black,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedIndex = expanded ? 2 : null;
                    });
                  },


                  children: [
                    ListTile(
                      title: const Text("Secrétariat général du gouvernement  ", style: TextStyle(color: Colors.black,fontSize:15)),
                      leading: Image.asset(
                        'images/sgg.gov.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      onTap: () async {
                        await _launchURL('https://www.sgg.gov.gn/');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/coursupreme.jpeg',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title: const Text("cour supreme", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async{
                        await _launchURL('https://coursupreme.org.gn/en/');
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/tribunalcc.jpeg',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      title:const Text("Tribunal de Commerce de Conakry", style: TextStyle(color: Colors.black,fontSize:15)),
                      onTap: () async{
                        const url = 'https://www.tc-conakry.gov.gn/';
                        await _launchURL(url);
                      },
                    )
                  ],
                ),
              ),
              // Ajoutez d'autres sections d'accordéon si nécessaire
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(child: CustomNavigator(currentIndex: 5)),
    );
  }
}
