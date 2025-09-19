import 'package:flutter/material.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';

class DomainProvider with ChangeNotifier {
  String _selectedDomain = '';

  String get selectedDomain => _selectedDomain;

  void setSelectedDomain(String domain) {
    _selectedDomain = domain;
    notifyListeners();
  }
}

class NotificationModel with ChangeNotifier {
  int _totalNotifications = 0;
  bool _showDot = true; // Par défaut, afficher le point de notification.

  // Getters
  int get totalNotifications => _totalNotifications;
  bool get showDot => _showDot;

  String get totalNotificationsText => _totalNotifications > 10 ? "10+" : _totalNotifications.toString();

  // Mettre à jour le nombre de notifications
  void setTotalNotifications(int count) {
    _totalNotifications = count;
    _showDot = false; // Masquer le point lorsque les notifications sont vues.
    FlutterAppBadgeControl.updateBadgeCount(_totalNotifications); // Mettre à jour le badge de l'icône
    notifyListeners();
  }
  // Réinitialiser l'état du point pour afficher à nouveau le badge
  void resetDot() {
    _showDot = true;
    notifyListeners();
  }


}





