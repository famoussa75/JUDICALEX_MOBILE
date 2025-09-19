import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityChecker extends StatefulWidget {
  final Widget child;
  const ConnectivityChecker({super.key, required this.child});

  @override
  State<ConnectivityChecker> createState() => _ConnectivityCheckerState();
}

class _ConnectivityCheckerState extends State<ConnectivityChecker> {
  late final Stream<ConnectivityResult> _connectivityStream;
  bool _checkedInitialConnection = false;
  bool _isConnected = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
      _checkedInitialConnection = true;
      _isInitialized = _isConnected; // Initialisation uniquement si connecté
    });
  }

  @override
  Widget build(BuildContext context) {
    // Affichage initial si la connexion est en cours de vérification
    if (!_checkedInitialConnection) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si l'application démarre sans connexion Internet
    if (!_isInitialized && !_isConnected) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 40, color: Colors.red),
              const SizedBox(height: 10),
              const Text(
                "Pas de connexion Internet",
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkInitialConnection,
                child: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    // Gestion dynamique de la connectivité après le démarrage
    return StreamBuilder<ConnectivityResult>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        final isCurrentlyConnected =
            snapshot.data != null && snapshot.data != ConnectivityResult.none;
        // Mise à jour uniquement après l'initialisation
        if (_isInitialized &&
            snapshot.connectionState == ConnectionState.active &&
            snapshot.hasData &&
            isCurrentlyConnected != _isConnected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _isConnected = isCurrentlyConnected;
            });
          });
        }

        // Affichage principal
        return Stack(
          children: [
            widget.child,
            if (_isInitialized && !_isConnected) _buildNoInternetBanner(),
          ],
        );
      },
    );
  }

  Widget _buildNoInternetBanner() {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0), // Espacement horizontal
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white70, // Couleur de fond
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6), // Couleur de l'ombre
                offset: const Offset(0, 4), // Décalage horizontal et vertical
                blurRadius: 8, // Rayon de flou
                spreadRadius: 3, // Rayon d'expansion
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min, // Ajuste la taille à son contenu
            children: [
              Icon(
                Icons.wifi_off, // Icône pour la déconnexion
                color:  Color(0xFF1e293b), // Couleur de l'icône
                size: 40.0, // Taille de l'icône\

              ),
              SizedBox(height: 10), // Espace entre l'icône et le texte
              Text(
                'Pas de connexion Internet. Veuillez vérifier votre connexion.',
                style: TextStyle(
                  color:  Color(0xFF1e293b),
                  fontSize: 20,
                  decoration: TextDecoration.none, // Supprime les soulignements
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
