import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'NavigationProvider.dart';
import 'domain_provider.dart';


class CustomNavigator extends StatefulWidget {
  final int currentIndex;
  const CustomNavigator({super.key, this.currentIndex = 0});

  @override
  CustomNavigatorState createState() => CustomNavigatorState();
}

class CustomNavigatorState extends State<CustomNavigator> with RouteAware {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Appelé quand on revient sur cette page
  @override
  void didPopNext() {
    _updateIndexFromRoute();
  }

  void _updateIndexFromRoute() {
    final routeName = ModalRoute.of(context)?.settings.name ?? '/home';
    setState(() {
      switch (routeName) {
        case '/home':
          _currentIndex = 0;
          break;
        case '/Role':
          _currentIndex = 1;
          break;
        case '/MesAffaire':
          _currentIndex = 2;
          break;
        case '/OrdonnanceJugement':
          _currentIndex = 3;
          break;
        default:
          _currentIndex = 0;
      }
    });
  }

  void onTabTapped(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, "/home");
        break;
      case 1:
        Navigator.pushReplacementNamed(context, "/Role");
        break;
      case 2:
        Navigator.pushReplacementNamed(context, "/MesAffaire");
        break;
      case 3:
        Navigator.pushReplacementNamed(context, "/OrdonnanceJugement");
        break;
      case 5:
        Scaffold.of(context).openDrawer();
        break;
    }
  }

  Widget buildNavItem({
    required int index,
    required IconData iconData,
    required String label,
    bool isMessage = false,
    bool isDrawer = false,
  }) {
    final bool isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.9) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(iconData, size: 26, color: isSelected ? const Color(0xFFDFB23D) : Colors.white),
              if (isMessage)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Consumer<NotificationModel>(
                    builder: (context, notificationModel, child) {
                      if (notificationModel.showDot) {
                        return const CircleAvatar(radius: 5, backgroundColor: Colors.white);
                      } else if (notificationModel.totalNotifications > 0) {
                        return CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.green,
                          child: Text(
                            notificationModel.totalNotifications >= 10
                                ? '10+'
                                : notificationModel.totalNotifications.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 8),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Color(0xFFDFB23D), fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Si on est pas sur l'onglet accueil, revenir à l'accueil
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          Navigator.pushReplacementNamed(context, "/home");
          return false; // empêche la fermeture de l'app
        }
        // Si on est déjà sur l'accueil, quitter l'app (ou mettre false pour rien faire)
        return true;
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(onTap: () => onTabTapped(0), child: buildNavItem(index: 0, iconData: Icons.home, label: "Accueil")),
            GestureDetector(onTap: () => onTabTapped(1), child: buildNavItem(index: 1, iconData: Icons.balance_sharp, label: "Rôles")),
            GestureDetector(onTap: () => onTabTapped(2), child: buildNavItem(index: 2, iconData: Icons.card_travel, label: "Mes Affaires")),
            GestureDetector(
              onTap: () {
                setState(() => _currentIndex = 5);
                Scaffold.of(context).openDrawer();
              },
              child: buildNavItem(index: 5, iconData: Icons.menu, label: "Autres", isDrawer: true),
            ),
          ],
        ),
      ),
    );
  }
}
