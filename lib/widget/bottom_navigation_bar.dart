import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'domain_provider.dart';

class CustomNavigator extends StatefulWidget {
  final int currentIndex; // Permet de définir l'onglet sélectionné par défaut
  const CustomNavigator({super.key, this.currentIndex = 0});

  @override
  CustomNavigatorState createState() => CustomNavigatorState();
}

class CustomNavigatorState extends State<CustomNavigator> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args.containsKey('currentIndex')) {
        setState(() {
          _currentIndex = args['currentIndex'];
        });
      }
    });
  }

  void onTabTapped(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
    switch (index) {
      case 0:
        Navigator.pushNamed(context, "/home", arguments: {'currentIndex': index});
        break;
      case 1:
        Navigator.pushNamed(context, "/Role", arguments: {'currentIndex': index});
        break;
      case 2:
        Navigator.pushNamed(context, "/MesAffaire", arguments: {'currentIndex': index});
        break;
      case 3:
        Navigator.pushNamed(context, "/OrdonnanceJugement", arguments: {'currentIndex': index});
        break;
        /*
      case 4:
        Navigator.pushNamed(context, "/NotificationPage", arguments: {'currentIndex': index});
        break;

         */
      case 5: // Drawer
        Scaffold.of(context).openDrawer();
        break;
    }
  }

  Widget buildNavItem({
    required int index,
    required IconData iconData,
    required String label,
    bool isMessage = false,

    bool isDrawer = false, // 👈 nouveau


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
              Icon(
                iconData,
                size: 26,
                color: isSelected ? const Color(0xFFDFB23D)  : Colors.white,
              ),
              if (isMessage)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Consumer<NotificationModel>(
                    builder: (context, notificationModel, child) {
                      if (notificationModel.showDot) {
                        return const CircleAvatar(
                          radius: 5,
                          backgroundColor: Colors.white,
                        );
                      } else if (notificationModel.totalNotifications > 0) {
                        return CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.green,
                          child: Text(
                            notificationModel.totalNotifications >= 10
                                ? '10+'
                                : notificationModel.totalNotifications.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
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
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFDFB23D) ,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(

      height: 60,
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => onTabTapped(0),
            child: buildNavItem(index: 0, iconData: Icons.home, label: "Accueil"),
          ),
          GestureDetector(
            onTap: () => onTabTapped(1),
            child: buildNavItem(index: 1, iconData: Icons.balance_sharp, label: "Rôles"),
          ),
          GestureDetector(
            onTap: () => onTabTapped(2),
            child: buildNavItem(index: 2, iconData: Icons.card_travel, label: "Mes Affaires"),
          ),
          /*
          GestureDetector(
            onTap: () => onTabTapped(3),
            child: buildNavItem(index: 3, iconData: Icons.gavel_sharp, label: "Decisions"),
          ),

          GestureDetector(
            onTap: () => onTabTapped(4),
            child: buildNavItem(index: 4, iconData: Icons.email_outlined, label: "Messages", isMessage: true),
          ),

           */

          GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 5; // 👈 marque le menu comme "sélectionné"
              });
              Scaffold.of(context).openDrawer(); // ouvre le Drawer
            },
            child: buildNavItem(
              index: 5,
              iconData: Icons.menu,
              label: "Autres",
              isDrawer: true,
            ),
          ),
        ],
      ),
    );
  }
}
