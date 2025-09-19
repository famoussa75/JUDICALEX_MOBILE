import 'package:ejustice/widget/bottom_navigation_bar.dart';
import 'package:ejustice/widget/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class Contact extends StatefulWidget {
   const Contact({super.key});

  @override
  State<Contact> createState() => _ContactState();
}

class _ContactState extends State<Contact> {
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
        child: Padding(
            padding: const EdgeInsets.all(11.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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


            ]
          )
        ),
      ),
      bottomNavigationBar: const CustomNavigator(currentIndex: 5),
    );
  }
}