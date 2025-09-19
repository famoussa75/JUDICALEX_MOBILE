import 'dart:io';
import 'package:ejustice/db/base_sqlite.dart';
import 'package:ejustice/screems/audience/ordonnance_jugement.dart';
//import 'package:ejustice/screems/audience/role_details.dart';
import 'package:ejustice/screems/audience/role.dart';
import 'package:ejustice/screems/audience/decisions.dart';
import 'package:ejustice/screems/audience/mes_affaire.dart';
import 'package:ejustice/screems/audience/role_details.dart';
import 'package:ejustice/screems/authentification/signup.dart';
import 'package:ejustice/screems/authentification/login.dart';
import 'package:ejustice/screems/contact/AboutUsPage.dart';
import 'package:ejustice/screems/contact/contact.dart';
import 'package:ejustice/screems/liens/lien.dart';
import 'package:ejustice/screems/news/news.dart';
import 'package:ejustice/screems/news/news.detail.dart';
import 'package:ejustice/screems/notifications/flutter_local_notifications.dart';
import 'package:ejustice/screems/notifications/notification.dart';
import 'package:ejustice/start/choix.dart';
import 'package:ejustice/start/pub_slide.dart';
import 'package:ejustice/start/splash_screnn.dart';
import 'package:ejustice/screems/profiles/account.dart';
import 'package:ejustice/screems/profiles/profile.dart';
import 'package:ejustice/widget/connectivity_checker.dart';
import 'package:ejustice/widget/domain_provider.dart';
import 'package:ejustice/widget/user_provider.dart';
import 'package:ejustice/widget/certificat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'screems/notifications/background_service.dart';


// Instance de FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}



// Fonction d'initialisation des notifications
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidInitializationSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher'); // Icône par défaut

  const InitializationSettings initializationSettings =
  InitializationSettings(android: androidInitializationSettings);

  // Initialiser les notifications avec un callback global pour les notifications sélectionnées
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      // Gérer la sélection d'une notification ici
      final String? payload = notificationResponse.payload;
      if (payload != null) {
        navigatorKey.currentState?.pushNamed('/NotificationPage', arguments: payload);
      }
    },
  );
}



/*
Future<void> showGroupedNotifications(List<Map<String, String>> notifications, FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  const String groupKey = 'com.example.notification.GROUP_KEY'; // Clé pour le groupe
  const String groupChannelId = 'group_channel_id'; // ID du canal pour le groupe
  const String groupChannelName = 'Grouped Notifications'; // Nom du canal
  const String groupChannelDescription = 'Notifications grouped by category'; // Description du canal

  // Affichage des notifications individuelles dans le groupe
  for (int i = 0; i < notifications.length; i++) {
    final notification = notifications[i];
    String title = notification['title'] ?? 'Notification';
    String body = notification['message'] ?? 'No message available';

    AndroidNotificationDetails androidNotificationDetails = const AndroidNotificationDetails(
      groupChannelId,
      groupChannelName,
      channelDescription: groupChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      groupKey: groupKey, // Clé de groupe partagée
    );
    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      i + 1, // Identifiant unique pour chaque notification
      title,
      body,
      notificationDetails,
      payload: 'notification_$i', // Passer le payload correctement
    );
  }

  // Déterminer le texte résumé basé sur le nombre de notifications
  String summaryText;
  if (notifications.length > 10) {
    summaryText = 'Vous avez plus de 10 notifications';
  } else {
    summaryText = 'Cliquez pour afficher toutes les notifications';
  }

  // Créer la notification principale (résumé) qui affiche le groupe
  AndroidNotificationDetails summaryAndroidNotificationDetails = AndroidNotificationDetails(
    groupChannelId,
    groupChannelName,
    channelDescription: groupChannelDescription,
    styleInformation: InboxStyleInformation(
      notifications.map((notification) => notification['title'] ?? 'Notification').toList(),
      contentTitle: 'Vous avez plusieurs notifications',
      summaryText: summaryText, // Utiliser le texte résumé modifié
    ),
    importance: Importance.high,
    priority: Priority.high,
    groupKey: groupKey, // Clé du groupe pour la notification principale
    setAsGroupSummary: true, // Définir comme notification de résumé du groupe
  );

  NotificationDetails summaryNotificationDetails = NotificationDetails(android: summaryAndroidNotificationDetails);

  await flutterLocalNotificationsPlugin.show(
    0, // Identifiant unique pour la notification principale
    'Notifications groupées',
    summaryText, // Afficher le résumé dynamique
    summaryNotificationDetails,
    payload: 'summary_notification', // Passer le payload ici
  );
}
 */
Future<void> loadCertificate() async {
  var logger = Logger(); // Create a logger instance

  try {
    // Charger le certificat CA
    final ByteData bytes = await rootBundle.load('assets/certificat.pem');
    final List<int> list = bytes.buffer.asUint8List();

    // Créer un SecurityContext avec le certificat
    SecurityContext contextCert = SecurityContext.defaultContext;
    contextCert.setTrustedCertificatesBytes(list);
  } catch (e) {
    logger.e("Erreur lors du chargement du certificat: $e");
  }
}

// Simuler l'ajout d'une nouvelle notification
void onNewNotification() {
  final notificationModel = NotificationModel();
  final newCount = notificationModel.totalNotifications + 1;
  notificationModel.setTotalNotifications(newCount);
}


void main() async {
  // Assurez-vous que les widgets sont initialisés avant de faire des appels asynchrones
  WidgetsFlutterBinding.ensureInitialized();

  // Demander la permission avant d'initialiser les notifications
  ///await requestNotificationPermission();

  /// background Servie
  ///await initializeService();
  ///await initializeNotifications();

  // Initialiser la base de données
  final dbHelper = DatabaseHelper();
  await dbHelper.database; // Cela va créer la base de données si elle n'existe pas encore
  // Chargez le certificat CA avant de démarrer l'application
  await loadCertificate ();
  // Exécutez l'application après l'initialisation de la base de données


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => DomainProvider()),
        ChangeNotifierProvider(create: (_) => NotificationModel()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),// Ajoutez le NotificationProvider
        // Ajoutez d'autres providers ici si nécessaire

      ],
      child: const MyApp(),
    ),
  );

}

class MyApp extends StatefulWidget {

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  String? domainName;
  // Declare the variable to hold the number of elements
  int numberOfElements = 330;

  @override
  void initState() {
    super.initState();
    _loadDomainName();
    _fetchNotifications();
  }


  Future<void> _fetchNotifications() async {
    // Appel de la méthode fetchnotifications
    await Provider.of<NotificationProvider>(context, listen: false).fetchnotifications(context);
  }




  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Judicalex-gn',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        bottomNavigationBarTheme:const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1e293b), // Cette couleur peut prendre le pas sur votre couleur de fond
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        "/home":(context) => const News(),
        "/Detail":(context) =>Newsdetail(post:ModalRoute.of(context)!.settings.arguments,),// Route de détail
        "/login":(context) =>const Login(),
        "/signup":(context) =>const SignupPage(),
        "/SplashScreen":(context) =>const SplashScreen(),
        "/PubSlider":(context) =>const PubSlider(),
        "/Users":(context) =>const Users(),
        "/MyAccount":(context)=>const MyAccount(),
        "/Role":(context) =>const Role(),
        "/CodeCivil":(context) =>const CodeCivil(),
        "/choix":(context) =>const Choix(),
        //"/User":(context) =>UserListScreen(),
        "/Role_Details":(context) => const RolesDetail(),
        "/MesAffaire":(context) =>const MesAffaire(),
        "/Decisions":(context) =>const Decisions(),
        //"/List":(context) =>UserListScreen(),
        "/Contact":(context) => const Contact(),
        "/NotificationPage":(context) => const NotificationPage(),
        "/OrdonnanceJugement":(context) => const OrdonnanceJugement(),
        "/AboutUsPage":(context) => const AboutUsPage(),
      },
      initialRoute: "/SplashScreen",
      //initialRoute: "/login",
      builder: (context, child) {
        // Wrap child with ConnectivityChecker
        return ConnectivityChecker(child: child ?? const SizedBox.shrink());
      },
    );
  }

  Future<void> _loadDomainName() async {
    final dbHelper = DatabaseHelper(); // Créez une instance de DatabaseHelper
    String? domain = await dbHelper.getDomainName(); // Récupérez le nom de domaine
    // Vérifiez si le widget est toujours monté
    if (!mounted) return;
    setState(() {
      domainName = domain; // Mettez à jour l'état
    });

    // Assurez-vous que le nom de domaine est valide avant d'appeler makeRequest
    if (domainName != null) {
      await makeRequest(context); // Passez le nom de domaine à la méthode
    }
  }
}

