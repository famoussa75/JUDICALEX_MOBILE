
import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import '../../widget/bottom_navigation_bar.dart';
import '../../widget/drawer.dart';

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



                    // Champ pour le nom
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Nom *",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nomController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: "Entrez votre nom",
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Champ pour le prénom
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Prénom *",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: prenomController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: "Entrez votre prénom",
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Champ pour l'email
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Email *",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "exemple@email.com",
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Sélection du sujet
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sujet *",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.grey[300],
                              splashColor: Colors.grey[200],
                            ),
                            child: ExpansionTile(
                              key: ValueKey(isExpanded),
                              iconColor: Colors.black,
                              collapsedIconColor: Colors.black,
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              childrenPadding: const EdgeInsets.only(bottom: 8),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedSubject.isEmpty ? "Sélectionnez un sujet" : selectedSubject,
                                      style: TextStyle(
                                        color: selectedSubject.isEmpty ? Colors.black54 : Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isSubjectSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
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
                                _buildSubjectOption("Information"),
                                _buildSubjectOption("Rôle d'audience"),
                                _buildSubjectOption("Modes de courrier"),
                                _buildSubjectOption("Entrepreneuriat"),
                                _buildSubjectOption("Emplois"),
                                _buildSubjectOption("Autre"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Champ pour le message
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Message *",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: messageController,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: "Décrivez votre demande...",
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ],
                    ),


                    const SizedBox(height: 20,),
                    // Bouton pour envoyer
                    SizedBox(
                      width: double.infinity, // prend toute la largeur disponible
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:const Color(0xFFDFB23D), // fond orange
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
                            ..from = Address(username, 'JUDICALEX')
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
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(10),
                decoration:  BoxDecoration(
                  gradient:const LinearGradient(
                      colors:[
                        Color(0xFF1e293b),
                        Colors.white
                      ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Plus d'information",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.white),)
                  ],
                ),
              ),
              const SizedBox(height: 20,),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

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
                              "Adresse",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4), // petit espace entre les deux lignes
                            Text(
                              "Cité Plaza Platinum, Immeuble 1, 3ème étage, Kipé, Conakry",
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
                              "(+224) 613 87 08 92 / (+224) 613 94 15 50",
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
                              "contact@judicalex-gn.com",
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
                                  color: Color(0xFFDFB23D),
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
                          side: const BorderSide(color: Color(0xFFDFB23D), width: 2), // bordure orange
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
                            color: Color(0xFFDFB23D), // texte orange
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
      bottomNavigationBar: const SafeArea(child: CustomNavigator(currentIndex: 5)),
    );
  }

   Widget _buildSubjectOption(String subject) {
     return ListTile(
       title: Text(
         subject,
         style: const TextStyle(
           color: Colors.black,
           fontSize: 15,
         ),
       ),
       onTap: () {
         setState(() {
           selectedSubject = subject;
           isSubjectSelected = true;
           isExpanded = false;
         });
       },
     );
   }
}