import 'package:ejustice/model/user_model.dart';
import 'package:ejustice/widget/country_selector.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Singleton pattern to ensure only one instance of DatabaseHelper exists
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'judicalex.db');
    //print('Database path: $path');

    return openDatabase(
      path,
      version: 14, // Augmentez la version ici
      onCreate: _createDb,
      onUpgrade: _onUpgrade, // Assurez-vous d'appeler _onUpgrade lors des mises à jour de version
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // This method is called when the database is created for the first time
    await db.execute(''' 
    CREATE TABLE users(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name TEXT,
      last_name TEXT,
      username TEXT,
      email TEXT UNIQUE,
      password TEXT,
      photo TEXT,
      is_first_login INTEGER DEFAULT 1,
      token TEXT
    )
  ''');
    // Créer la table data_country
    await db.execute(''' 
      CREATE TABLE data_country(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pays TEXT,
        nom_domain TEXT UNIQUE,
        selected INTEGER DEFAULT 0
      )
     
    ''');
    // Table notifications
    await db.execute('''
    CREATE TABLE notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      notif_id INTEGER UNIQUE,
      title TEXT,
      message TEXT,
      is_read INTEGER
    )
  ''');
  }


  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 11) {  // Ajoutez cette condition pour la nouvelle colonne
      await addTokenColumn(db); // Appel à addTokenColumn pour ajouter la colonne
    }

    if (oldVersion < 11) {  // Conserver le reste du code de mise à jour existant
      await db.execute('DROP TABLE IF EXISTS data_country');
      await db.execute('DROP TABLE IF EXISTS users_temp');

      await db.execute('''
      CREATE TABLE users_temp(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT,
        last_name TEXT,
        username TEXT,
        email TEXT UNIQUE,
        password TEXT,
        photo TEXT,
        is_first_login INTEGER DEFAULT 1,
        token TEXT
      )
    ''');

      await db.execute('''
      CREATE TABLE data_country(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pays TEXT,
        nom_domain TEXT UNIQUE,
        selected INTEGER DEFAULT 0
      )
    ''');

      // Copier les données de l'ancienne table vers la nouvelle table
      await db.execute('''
      INSERT INTO users_temp (id, first_name, last_name, username, email, password, photo, is_first_login,token)
      SELECT id, first_name, last_name, username, email, password, photo, is_first_login,token FROM users
    ''');

      await db.execute('DROP TABLE users');
      await db.execute('ALTER TABLE users_temp RENAME TO users');
    }
  }

// Méthode pour ajouter la colonne token
  Future<void> addTokenColumn(Database db) async {
    await db.execute('ALTER TABLE users_temp ADD COLUMN token TEXT');
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertCountry(Country country) async {
    final db = await database;
    await db.insert(
      'data_country',
      country.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<bool> userExists(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  Future<void> updateFirstLogin(User user) async {
    final db = await database;
    await db.update(
      'users',
      {'is_first_login': 0},
      where: 'email = ?',
      whereArgs: [user.email],
    );
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(), // Convert the user object to a Map
      where: 'email = ?',
      whereArgs: [user.email], // Using email as the unique identifier
    );
  }

  Future<int> updatePassword(int id, String newPassword) async {
    final db = await database; // Get the database
    return await db.update(
      'users', // Replace with your table name
      {'password': newPassword}, // Update the password
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleterUser(int userId) async{
    final db = await database;
    await db.delete(
      'users',
      where: 'id =?',
      whereArgs: [userId]
    );
  }


  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');

    // Convert the List<Map<String, dynamic>> to a List<User>
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]); // Use the factory constructor here
    });
  }

  Future<List<Country>> getAllCountries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('data_country');

    return List.generate(maps.length, (i) {
      return Country(
        pays: maps[i]['pays'],
        nomDomaine: maps[i]['nom_domain'],
        selected: maps[i]['selected'] == 1, // Convertir int en bool
      );
    });
  }

  Future<String?> getDomainName() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('data_country', where: 'selected = ?', whereArgs: [1]);

    if (maps.isNotEmpty) {
      return maps.first['nom_domain']; // Retourne le nom de domaine du pays sélectionné
    }

    return null; // Si aucune donnée
  }


  // Suppression d'un pays de la base de données
  Future<void> deleteCountry(String pays) async {
    final db = await database;

    await db.delete(
      'data_country',
      where: 'pays = ?',
      whereArgs: [pays],
    );
  }

  Future<void> updateCountry(Country country) async {
    final db = await database;
    await db.update(
      'data_country',
      country.toMap(),
      where: 'pays = ?',
      whereArgs: [country.pays],
    );
  }

  Future<Country?> getCountryByName(String pays) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'data_country',
      where: 'pays = ?',
      whereArgs: [pays],
    );

    if (maps.isNotEmpty) {
      return Country(
        pays: maps[0]['pays'],
        nomDomaine: maps[0]['nom_domain'],
      );
    }
    return null;
  }

  Future<bool> isDataCountryEmpty(Database db) async {
    final List<Map<String, dynamic>> results = await db.rawQuery('SELECT COUNT(*) as count FROM data_country');
    return results.isNotEmpty && results[0]['count'] == 0;
  }

  Future<void> insertOrUpdateUser(User user) async {
    final db = await database; // Assurez-vous d'avoir la connexion à la base de données

    await db.insert(
      'users',
      user.toMap(), // Assurez-vous que votre User a une méthode toMap()
      conflictAlgorithm: ConflictAlgorithm.replace, // Remplacez l'utilisateur existant
    );
  }



  Future<String?> getUserId() async {
    // Implement logic to retrieve user ID from your storage (e.g., SharedPreferences, database)
    // Example:
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId'); // Assurez-vous que l'ID de l'utilisateur est stocké ici
  }

  Future<String?> getUserToken(String userId) async {
    final db = await database;
    //print('Récupération du token pour l\'utilisateur ID: $userId');

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
    //  print('Token trouvé : ${maps.first['token']}');
      return maps.first['token'];
    }

   // print('Aucun token trouvé pour l\'utilisateur ID: $userId');
    return null;
  }

  Future<String?> getToken() async {
    final db = await database; // Assurez-vous d'avoir une connexion à la base de données
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first['token'] as String?;
    }
    return null;
  }

  Future<Database> initializeDB() async {
    String path = join(await getDatabasesPath(), 'notifications.db');
    return openDatabase(
      path,
      onCreate: (database, version) async {
        await database.execute(
            '''
        CREATE TABLE notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          notif_id INTEGER UNIQUE,  -- id qui vient de l’API
          title TEXT,
          message TEXT,
          is_read INTEGER
        )
        '''
        );
      },
      version: 1,
    );
  }

  Future<int> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;

    // Vérifier si notif existe déjà via son notif_id
    final existing = await db.query(
      'notifications',
      where: 'notif_id = ?',
      whereArgs: [notification['notif_id']],
    );
    if (existing.isNotEmpty) {
      // Déjà en base, on ignore
      return 0;
    }
    // Sinon on insère
    return await db.insert('notifications', notification,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Récupérer toutes les notifications (ou seulement les non lues)
  Future<List<Map<String, dynamic>>> getNotifications({bool onlyUnread = false}) async {
    final db = await _initDatabase(); // ou database si tu as un getter
    String whereClause = onlyUnread ? 'WHERE is_read = 0' : '';
    return await db.rawQuery('SELECT * FROM notifications $whereClause ORDER BY id DESC');
  }

  Future<void> markAsRead(int notifId) async {
    final db = await _initDatabase(); // ou await database si tu as un getter
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'notif_id = ?',
      whereArgs: [notifId],
    );
  }


}

