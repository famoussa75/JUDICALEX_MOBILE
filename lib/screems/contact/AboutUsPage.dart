
import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  // Les contrôleurs pour capturer les entrées utilisateur
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  String selectedSubject = "Choisissez un sujet";  // Valeur par défaut du titre
  bool isSubjectSelected = false; // Variable pour savoir si un sujet a été sélectionné
  bool isExpanded = false;  // Variable pour gérer l'état de l'ExpansionTile

  bool isLoading = false;

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
              "images/judicalex-blanc.png",
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
        child:Column(
          children: [
            _aboutUsPageStateAbout3(),
            _aboutUsPageStateAbout1(),
            //_aboutUsPageStateAbout2(),
          ],
        )
      ),
      bottomNavigationBar: const CustomNavigator(currentIndex: 5),
    );
  }


  Widget _aboutUsPageStateAbout1() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1e293b),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40), // marge en haut
          const Text(
            "Notre Équipe",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Rencontrez notre équipe d'intervenants",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),          // ✅ Liste horizontale des membres
          Container(
            height: 400,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    height: 350,
                    width: 350,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage("images/equipe1.jpg"),
                        fit: BoxFit.cover, // ✅ pour remplir l’image
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12), // un peu d’espace autour du texte
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.5), // ✅ fond semi-transparent
                      ),
                      child:const Column(
                        mainAxisAlignment: MainAxisAlignment.end, // ✅ texte en bas
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mamadou Diallo",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Juriste-Conseil | Spécialiste en droit des affaires",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Avec plus de 10 ans d'expérience dans le conseil juridique , Me Sylla accompagne entreprises et particuliers dans leurs démarches légales",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 350,
                    width: 350,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage("images/equipe1.jpg"),
                        fit: BoxFit.cover, // ✅ pour remplir l’image
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12), // un peu d’espace autour du texte
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.5), // ✅ fond semi-transparent
                      ),
                      child:const Column(
                        mainAxisAlignment: MainAxisAlignment.end, // ✅ texte en bas
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mamadou Diallo",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Juriste-Conseil | Spécialiste en droit des affaires",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Avec plus de 10 ans d'expérience dans le conseil juridique , Me Sylla accompagne entreprises et particuliers dans leurs démarches légales",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 350,
                    width: 350,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage("images/equipe1.jpg"),
                        fit: BoxFit.cover, // ✅ pour remplir l’image
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12), // un peu d’espace autour du texte
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.5), // ✅ fond semi-transparent
                      ),
                      child:const Column(
                        mainAxisAlignment: MainAxisAlignment.end, // ✅ texte en bas
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:  [
                          Text(
                            "Mamadou Diallo",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Juriste-Conseil | Spécialiste en droit des affaires",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Avec plus de 10 ans d'expérience dans le conseil juridique , Me Sylla accompagne entreprises et particuliers dans leurs démarches légales",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 350,
                    width: 350,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage("images/equipe1.jpg"),
                        fit: BoxFit.cover, // ✅ pour remplir l’image
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12), // un peu d’espace autour du texte
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.5), // ✅ fond semi-transparent
                      ),
                      child:const Column(
                        mainAxisAlignment: MainAxisAlignment.end, // ✅ texte en bas
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mamadou Diallo",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Juriste-Conseil | Spécialiste en droit des affaires",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Avec plus de 10 ans d'expérience dans le conseil juridique , Me Sylla accompagne entreprises et particuliers dans leurs démarches légales",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )

        ],
      ),
    );
  }


  Widget _aboutUsPageStateAbout2(){
    return SizedBox(
      child: Padding(
          padding: const EdgeInsets.all(11.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20,),
                const Text("Nos Partenaires",
                  style:  TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20,),
                Container(
                  height: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // espace égal entre les images
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: AssetImage("images/ASK.png"),
                              fit: BoxFit.contain, // 🔹 ajuste l'image sans la couper
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: AssetImage("images/APIP.png"),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: AssetImage("images/TC.png"),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: AssetImage("images/CNG.png"),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              /*
                const SizedBox(height:20),
                Container(
                  padding: const EdgeInsets.all(12), // un peu d’espace intérieur
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b), // fond bleu nuit
                    borderRadius: BorderRadius.circular(14), // coins arrondis si tu veux
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10,),
                      const Text("Aves-vous une question ?",
                        style:  TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20,),
                      const Text("Contactez nous en clic ! ",
                        style:  TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20,),


                      // champs pour le nom
                      TextField(
                        controller: nomController,
                        style: const TextStyle(color: Colors.black), // texte en noir
                        decoration: InputDecoration(
                          label: const Text(
                            "Nom",
                            style: TextStyle(color: Colors.black), // label en noir
                          ),
                          filled: true,
                          fillColor: Colors.white, // fond blanc
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20,),
                      // champs pour le nom
                      TextField(
                        style: const TextStyle(color: Colors.black), // texte en noir
                        controller: prenomController,
                        decoration: InputDecoration(
                            label: const Text("Prenom",style: TextStyle(color: Colors.black )), // label en noir),
                            filled: true,
                            fillColor: Colors.white, // fond blanc
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            )
                        ),
                      ),
                      const SizedBox(height: 20,),
                      // champs pour le nom
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.black), // texte en noir
                        decoration: InputDecoration(
                            label: const Text("Email", style: TextStyle(color: Colors.black )),
                            filled: true,
                            fillColor: Colors.white, // fond blanc
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            )
                        ),
                      ),

                      const SizedBox(height: 20,),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black54, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            splashColor: Colors.grey.shade200,
                          ),
                          child: ExpansionTile(
                            key: ValueKey(isExpanded), // ✅ force rebuild quand isExpanded change
                            iconColor: Colors.black,
                            collapsedIconColor: Colors.black,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            childrenPadding: const EdgeInsets.symmetric(horizontal:10, vertical: 8),

                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedSubject.isEmpty ? "Choisissez un sujet" : selectedSubject,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSubjectSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                              ],
                            ),

                            initiallyExpanded: isExpanded,
                            onExpansionChanged: (bool expanding) {
                              setState(() {
                                isExpanded = expanding;
                              });
                            },

                            children: [
                              ListTile(
                                title: const Text("Information", style: TextStyle(color: Colors.black)),
                                onTap: () {
                                  setState(() {
                                    selectedSubject = "Information";
                                    isSubjectSelected = true;
                                    isExpanded = false; // ✅ referme après choix
                                  });
                                },
                              ),
                              ListTile(
                                title: const Text("Rôle d'audience", style: TextStyle(color: Colors.black)),
                                onTap: () {
                                  setState(() {
                                    selectedSubject = "Rôle d'audience";
                                    isSubjectSelected = true;
                                    isExpanded = false;
                                  });
                                },
                              ),
                              ListTile(
                                title: const Text("Modes de courrier", style: TextStyle(color: Colors.black)),
                                onTap: () {
                                  setState(() {
                                    selectedSubject = "Modes de courrier";
                                    isSubjectSelected = true;
                                    isExpanded = false;
                                  });
                                },
                              ),
                              ListTile(
                                title: const Text("Entrepreneuriat", style: TextStyle(color: Colors.black)),
                                onTap: () {
                                  setState(() {
                                    selectedSubject = "Entrepreneuriat";
                                    isSubjectSelected = true;
                                    isExpanded = false;
                                  });
                                },
                              ),
                              ListTile(
                                title: const Text("Emplois", style: TextStyle(color: Colors.black)),
                                onTap: () {
                                  setState(() {
                                    selectedSubject = "Emplois";
                                    isSubjectSelected = true;
                                    isExpanded = false;
                                  });
                                },
                              ),
                              ListTile(
                                title: const Text("Autre", style: TextStyle(color: Colors.black)),
                                onTap: () {
                                  setState(() {
                                    selectedSubject = "Autre";
                                    isSubjectSelected = true;
                                    isExpanded = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // champs pour le nom
                      TextField(
                        controller: messageController,
                        maxLines: 5, // pour un champ de message plus grand
                        style: const TextStyle(color: Colors.black), // texte noir
                        decoration: InputDecoration(
                          labelText: "Message",
                          labelStyle: const TextStyle(color: Colors.black), // label lisible
                          filled: true,
                          fillColor: Colors.grey[100], // fond gris clair
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), // coins arrondis
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // espacement interne
                        ),
                      ),

                      const SizedBox(height: 20,),
                      // Bouton pour envoyer
                      SizedBox(
                        width: double.infinity, // prend toute la largeur disponible
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange, // fond orange
                            foregroundColor: Colors.black,   // texte noir
                            padding: const EdgeInsets.symmetric(vertical: 14), // hauteur du bouton
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // arrondi moderne
                            ),
                            elevation: 4, // petite ombre élégante
                          ),
                          onPressed: () async {
                            setState(() {
                              isLoading = true; // ✅ démarre l'indicateur
                            });

                            final nom = nomController.text.trim();
                            final prenom = prenomController.text.trim();
                            final email = emailController.text.trim();
                            final subject = selectedSubject ?? "";
                            final message = messageController.text.trim();

                            if (nom.isEmpty || prenom.isEmpty || email.isEmpty || subject.isEmpty || message.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tous les champs sont obligatoires.')),
                              );
                              setState(() {
                                isLoading = false; // arrêt de l'indicateur
                              });
                              return;
                            }

                            String username = 'houmadifahad100@gmail.com';
                            String appPassword = 'zcqhyxdiemxlihse';
                            final smtpServer = gmail(username, appPassword);

                            final mailMessage = Message()
                              ..from = Address(username, 'Nom de votre Application')
                              ..recipients.add('houmadifahad100@gmail.com')
                              ..subject = subject
                              ..text = 'Nom: $nom\nPrénom: $prenom\nE-mail: $email\n\nSujet: $subject\n\nMessage:\n$message ';

                            try {
                              if (!mounted) return;
                              await send(mailMessage, smtpServer);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Message envoyé par $nom $prenom ✅')),
                              );

                              // Nettoyage des champs (on supprime subjectController.clear())
                              nomController.clear();
                              prenomController.clear();
                              emailController.clear();
                              messageController.clear();

                              setState(() {
                                selectedSubject = ""; // reset sujet choisi
                                isLoading = false; // arrêt de l'indicateur
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erreur lors de l\'envoi du message ❌')),
                              );
                              setState(() {
                                isLoading = false; // arrêt de l'indicateur
                              });
                            }
                          },
                          child: isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                              : const Text(
                            'Envoyer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16, // un peu plus lisible
                            ),
                          ),
                        ),
                      ),


                    ],
                  ),
                ),
                const SizedBox(height: 20,),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Plus d'informations ",
                      style:  TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20,),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.black54,
                          size: 40, // taille de l'icône
                        ),
                        SizedBox(width: 12), // espacement entre l'icône et le texte
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:  [
                              Text(
                                "Localisation",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4), // petit espace entre les deux lignes
                              Text(
                                "Matam, Conakry,République de Guinée",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.phone,
                          color: Colors.black54,
                          size: 40, // taille de l'icône
                        ),
                        SizedBox(width: 12), // espacement entre l'icône et le texte
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:  [
                              Text(
                                "Téléphone",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4), // petit espace entre les deux lignes
                              Text(
                                "(+224) 628 55 47 61",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.mail,
                          color: Colors.black54,
                          size: 40, // taille de l'icône
                        ),
                        SizedBox(width: 12), // espacement entre l'icône et le texte
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:  [
                              Text(
                                "Email",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4), // petit espace entre les deux lignes
                              Text(
                                "contact@smartylex.com",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )


                  ],
                ),
                const SizedBox(height: 20,),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b), // fond bleu nuit
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Première colonne : image
                          Container(
                            width: 160,
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: const DecorationImage(
                                image: AssetImage("images/nimba.jpg"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Deuxième colonne : texte
                          const  Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Vous avez un cabinet d'avocats ?",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Facilitez la gestion administrative de votre cabinet avec SMARTYLEX.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Visitez notre site web pour en savoir plus.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16), // espace entre texte et bouton

                      // Bouton qui prend toute la largeur
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF1e293b), // fond bleu nuit
                            side: const BorderSide(color: Colors.orange, width: 2), // bordure orange
                            padding: const EdgeInsets.symmetric(vertical: 14), // hauteur du bouton
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14), // coins arrondis
                            ),
                          ),
                          onPressed: () async {
                            await _launchURL('https://smartylex.com/');
                          },
                          child: const Text(
                            "Cliquez ici !",
                            style: TextStyle(
                              color: Colors.orange, // texte orange
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )

                    ],
                  ),
                )

               */
              ]
          )
      ),
    );
 }

  Widget _aboutUsPageStateAbout3() {
    return Container(
      width: double.infinity,
      color:  Colors.white12,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // coins arrondis

              ),
              clipBehavior: Clip.antiAlias, // pour que l'image respecte les coins arrondis
              child: Image.asset(
                "images/droit.png",
                width: double.infinity,
                fit: BoxFit.cover, // ou BoxFit.contain selon ton besoin
              ),
            ),
          ),

          Padding(
              padding: const EdgeInsets.all(20),
            child:Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                const SizedBox(height: 10),
                const Text(
                  "A Propos de nous",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20,),
                const Text(
                  "Bienvenue chez Judicalex, votre partenaire de confiance pour l’accès à l’information juridique et au droit. "
                      "Notre mission est de rendre le cadre légal plus accessible et compréhensible pour tous, en offrant des outils modernes et des ressources essentielles pour maîtriser vos droits et obligations.\n\n"

                      "Avec une présence en Guinée à travers notre filiale Judicalex-GN, nous nous engageons à accompagner les citoyens, les professionnels du droit et les institutions locales en leur fournissant des informations juridiques fiables et actualisées. "
                      "Notre plateforme rassemble des textes légaux, des analyses, et des mises à jour sur les évolutions du droit, afin de faciliter une meilleure compréhension et application des règles juridiques.\n\n"

                      "Chez Judicalex, nous croyons que l’accès au droit est un levier puissant pour l’autonomisation, la justice et le développement. "
                      "Ensemble, construisons un avenir où chacun peut naviguer dans l’univers juridique avec confiance.",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20,),
                const Text(
                  "Notre Mission",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20,),
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.personal_video, size: 50,),
                      SizedBox(height: 10),
                      Text("Informer et éduquer", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),),
                       SizedBox(height: 10),
                      Text("Fournir des resources judiques claires, fiables et accessibles à tous, que vous "
                          "soyez citoyen, professionnel ou étudiant", style: TextStyle(fontSize: 14, color: Colors.black87,),),
                    ],
                  ),
                ),
              const SizedBox(height:20,),
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.groups, size: 50,),
                      SizedBox(height: 10),
                      Text("Simplifier le droit", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),),
                      SizedBox(height: 10),
                      Text("Rendre les texts légaux et leurs implications compréhensibles, afin de permettre à chacun de faire valoire ses droit et de respecter ses obligations ", style: TextStyle(fontSize: 14, color: Colors.black87,),),
                    ],
                  ),
                ),
                const SizedBox(height:20,),
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.gavel_rounded, size: 50,),
                      SizedBox(height: 10),
                      Text("Accompagner nos communautés", style: TextStyle(fontSize:18, color: Colors.black, fontWeight: FontWeight.bold),),
                      SizedBox(height: 10),
                      Text("Aves notre filiale judicaliex-GN en Guinée, nous adaptons nos services aux besions lovaux pour soutenir les citoyens et les acteurs juridiques dans leurs démarches quotidiennes."
                          "soyez citoyen, professionnel ou étudiant", style: TextStyle(fontSize: 14, color: Colors.black87,),),
                    ],
                  ),
                ),

              ],
            ),
          )
        ],
      ),
    );
  }

}
