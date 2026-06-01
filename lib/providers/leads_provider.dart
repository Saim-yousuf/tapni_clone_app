import 'package:flutter/material.dart';
import 'package:tapni_app/models/lead.dart';
import 'package:tapni_app/models/activity.dart';
import 'package:tapni_app/services/mock_data_service.dart';

class LeadsProvider extends ChangeNotifier {
  List<Lead> _leads = [];
  List<Activity> _activities = [];
  List<Map<String, dynamic>> _notifications = [];
  String _searchQuery = '';

  LeadsProvider() {
    _leads = MockDataService.getInitialLeads();
    _activities = MockDataService.getInitialActivities();
    _notifications = MockDataService.getMockNotifications();
  }

  List<Lead> get leads {
    if (_searchQuery.isEmpty) {
      return _leads;
    }
    final query = _searchQuery.toLowerCase();
    return _leads.where((lead) {
      return lead.name.toLowerCase().contains(query) ||
          lead.company.toLowerCase().contains(query) ||
          lead.email.toLowerCase().contains(query) ||
          lead.phone.contains(query);
    }).toList();
  }

  List<Activity> get activities => _activities;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotificationsCount =>
      _notifications.where((n) => n['isRead'] == false).length;

  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void addLead({
    required String name,
    required String email,
    required String phone,
    required String company,
  }) {
    final newLead = Lead(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      company: company,
      timestamp: DateTime.now(),
    );

    // Insert at the top of the list
    _leads.insert(0, newLead);

    // Add corresponding activity
    final newActivity = Activity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Lead Captured',
      description: '$name from $company was added',
      timestamp: DateTime.now(),
      type: ActivityType.lead,
    );
    _activities.insert(0, newActivity);

    // Add mock notification
    final newNotification = {
      'id': 'not_${DateTime.now().millisecondsSinceEpoch}',
      'title': '🤝 Contact Connection',
      'body': '$name from $company has been added as a lead.',
      'time': 'Just now',
      'isRead': false,
    };
    _notifications.insert(0, newNotification);

    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i]['isRead'] = true;
    }
    notifyListeners();
  }

  void toggleNotificationRead(String id) {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i]['id'] == id) {
        _notifications[i]['isRead'] = !_notifications[i]['isRead'];
        break;
      }
    }
    notifyListeners();
  }

  void clearNotification(String id) {
    _notifications.removeWhere((n) => n['id'] == id);
    notifyListeners();
  }
}
