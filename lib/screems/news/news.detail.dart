import 'package:flutter/material.dart';

class Newsdetail extends StatelessWidget {
  final dynamic post;
  const Newsdetail({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        iconTheme: const  IconThemeData(color:Colors.white),
        centerTitle: true,
        title: const Text("Détails",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.white),), // Afficher le titre dans l'AppBar
        toolbarHeight: 60,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post['title'] ?? 'Pas de titre ',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 10),
            // Affichage de l'image si elle existe (en dessous de la description)
            post['image'] != null
                ? Image.network(
              post['image'], // URL de l'image
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover, // Adapter l'image au conteneur
            )
                : Container(), // Si aucune image n'est fournie
            const SizedBox(height: 10,),
            Text(
              post['content'] ?? 'Pas de description',
              style: const  TextStyle(fontSize: 16, color: Colors.black54),
            ),

          ],
        ),
      ),
    );
  }
}
