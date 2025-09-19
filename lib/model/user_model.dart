class User {
  final int id;
  final String first_name;
  final String last_name;
  final String username;
  final String email;
  final String password;
   String photo;
  final bool isFirstLogin;
  String? token; // Nouveau champ nullable


  User({
    required this.id,
    required this.first_name,
    required this.last_name,
    required this.username,
    required this.email,
    required this.password,
    required this.photo,
    required this.isFirstLogin,
    this.token, // Initialisation du champ nullable
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': first_name,
      'last_name': last_name,
      'username': username,
      'email': email,
      'password': password,
      'photo': photo,
      'is_first_login': isFirstLogin ? 1 : 0,
      'token': token, // Ajout de la colonne token
    };
  }
// Méthode pour créer une copie de l'utilisateur avec des valeurs mises à jour
  User copyWith({
    String? last_name,
    String? first_name,
    String? username,
    String? email,
    String? password,
    String? photo,
    bool? isFirstLogin,
    String? token,
  }) {
    return User(
      id: id,
      last_name: last_name ?? this.last_name,
      first_name: first_name ?? this.first_name,
      username: username ?? this.username,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      password: password ?? this.password,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      token: token ?? this.token, // Copie du token si nécessaire
    );
  }

  // Modèle User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      first_name: map['first_name'],
      last_name: map['last_name'],
      email: map['email'],
      username: map['username'],
      password: map['password'],
      photo: map['photo'], // Extraire l'image de la map
      isFirstLogin: map['is_first_login'] == 1, // Assurez-vous que ceci est bien récupéré
      token: map['token'], // Extraction du token depuis JSON
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0, // Valeur par défaut si null
      first_name: json['first_name'] ?? '', // Valeur par défaut si null
      last_name: json['last_name'] ?? '', // Valeur par défaut si null
      email: json['email'] ?? '', // Valeur par défaut si null
      username: json['username'] ?? '', // Valeur par défaut si null
      password: json['password'] ?? '', // Valeur par défaut si null
      photo: json['photo'] ?? '', // Valeur par défaut si null
      isFirstLogin: json['is_first_login'] == 1,
      token: json['token'] ?? '', // Extraction du token depuis JSON
    );
  }



}
