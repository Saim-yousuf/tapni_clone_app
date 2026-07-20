import 'package:flutter/material.dart';
import 'package:tapni_app/models/lead.dart';
import 'package:tapni_app/models/contact_category.dart';
import 'package:tapni_app/models/activity.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/repository/invitation_repo.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/utils/catalog_helper.dart';

class LeadsProvider extends ChangeNotifier {
  final AuthRepo _authRepo = AuthRepo();
  final CatalogRepo _catalogRepo = CatalogRepo();
  final AttendanceRepo _attendanceRepo = AttendanceRepo();
  final InvitationRepo _invitationRepo = InvitationRepo();

  List<Lead> _leads = [];
  List<ContactCategory> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _activeCategoryId; // null means 'All'

  // Filter States
  String _activeSource = 'All';
  String _sortBy = 'Creation Date';
  String _sortOrder = 'Descending';
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _activeMarkers = [];

  // ── Notifications (local mock state) ────────────────────────────────────────
  final List<Map<String, dynamic>> _notifications = [];

  // ── Activities (local mock state) ───────────────────────────────────────────
  final List<Activity> _activities = [];

  // ── Filtered leads ──────────────────────────────────────────────────────────
  List<Lead> get allLeads => List.unmodifiable(_leads);

  List<Lead> get leads {
    List<Lead> filtered = _leads;

    // Filter by Source
    if (_activeSource != 'All') {
      if (_activeSource == 'Manually') {
        filtered = filtered.where((l) => l.contactUser == null).toList();
      } else if (_activeSource == 'Scan') {
        filtered = filtered.where((l) => l.contactUser != null).toList();
      } else {
        filtered = []; // Direct, Form
      }
    }

    // Filter by Date Range
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((l) {
        return l.timestamp.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
               l.timestamp.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by Category/Markers
    if (_activeMarkers.isNotEmpty) {
      filtered = filtered.where((l) => l.category != null && _activeMarkers.contains(l.category!.id)).toList();
    } else if (_activeCategoryId != null) {
      filtered = filtered.where((l) => l.category?.id == _activeCategoryId).toList();
    }

    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (l) =>
                l.displayName.toLowerCase().contains(q) ||
                l.displayEmail.toLowerCase().contains(q) ||
                l.displayPhone.toLowerCase().contains(q) ||
                l.displayCompany.toLowerCase().contains(q),
          )
          .toList();
    }

    // Sorting
    filtered.sort((a, b) {
      int cmp = 0;
      if (_sortBy == 'Full Name') {
        cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else {
        cmp = a.timestamp.compareTo(b.timestamp);
      }
      return _sortOrder == 'Descending' ? -cmp : cmp;
    });

    return filtered;
  }

  List<ContactCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get activeCategoryId => _activeCategoryId;

  // Filter Getters
  String get activeSource => _activeSource;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  List<String> get activeMarkers => _activeMarkers;

  // ── Notifications getters ───────────────────────────────────────────────────
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotificationsCount =>
      _notifications.where((n) => n['isRead'] == false).length;

  // ── Activities getter ────────────────────────────────────────────────────────
  List<Activity> get activities => _activities;

  LeadsProvider() {
    fetchCategories();
    fetchLeads();
  }

  // ── Search / Filter ──────────────────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setActiveCategory(String? categoryId) {
    _activeCategoryId = categoryId;
    _activeMarkers = categoryId == null ? [] : [categoryId];
    notifyListeners();
  }

  void applyFilters({
    required String source,
    required String sortBy,
    required String sortOrder,
    DateTime? startDate,
    DateTime? endDate,
    required List<String> activeMarkers,
  }) {
    _activeSource = source;
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    _startDate = startDate;
    _endDate = endDate;
    _activeMarkers = activeMarkers;
    
    // Sync with chip active category if exactly one marker is selected
    if (activeMarkers.length == 1) {
      _activeCategoryId = activeMarkers.first;
    } else if (activeMarkers.isEmpty) {
      _activeCategoryId = null;
    }

    notifyListeners();
  }

  void resetFilters() {
    _activeSource = 'All';
    _sortBy = 'Creation Date';
    _sortOrder = 'Descending';
    _startDate = null;
    _endDate = null;
    _activeMarkers = [];
    _activeCategoryId = null;
    notifyListeners();
  }

  // ── Fetch Categories ─────────────────────────────────────────────────────────
  Future<void> fetchCategories() async {
    try {
      final res = await _authRepo.getContactCategories();
      if (res.success && res.data is Map) {
        final List data = (res.data as Map)['categories'] ?? [];
        _categories = data.map((e) => ContactCategory.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  // ── Fetch Leads ──────────────────────────────────────────────────────────────
  Future<void> fetchLeads() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _authRepo.getContacts();
      if (res.success && res.data is Map) {
        final List data = (res.data as Map)['contacts'] ?? [];
        _leads = data.map((e) => Lead.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching leads: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Clear Data on Logout ───────────────────────────────────────────────────
  void clearData() {
    _leads.clear();
    _categories.clear();
    _notifications.clear();
    _activities.clear();
    _activeSource = 'All';
    _sortBy = 'Creation Date';
    _sortOrder = 'Descending';
    _startDate = null;
    _endDate = null;
    _activeMarkers = [];
    _activeCategoryId = null;
    _searchQuery = '';
    notifyListeners();
  }

  // ── Add manual contact ───────────────────────────────────────────────────────
  Future<bool> addLead({
    required String name,
    required String email,
    required String phone,
    required String company,
    String jobTitle = '',
    String website = '',
    String note = '',
    String address = '',
  }) async {
    try {
      final res = await _authRepo.addManualContact(
        name: name,
        email: email,
        phone: phone,
        company: company,
        jobTitle: jobTitle,
        website: website,
        note: note,
        address: address,
      );
      if (res.success && res.data is Map) {
        final data = (res.data as Map)['contact'];
        if (data != null) {
          _leads.insert(0, Lead.fromJson(data));
          _addActivity(
            title: 'New Contact Added',
            description: 'You added $name to your contacts.',
            type: ActivityType.lead,
          );
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error adding lead: $e");
    }
    return false;
  }

  // ── Add scanned contact ──────────────────────────────────────────────────────
  Future<bool> addScannedContact(String username) async {
    try {
      final res = await _authRepo.addScannedContact(username: username);
      if (res.success && res.data is Map) {
        final data = (res.data as Map)['contact'];
        if (data != null) {
          final lead = Lead.fromJson(data);
          // Avoid duplicates
          if (!_leads.any((l) => l.id == lead.id)) {
            _leads.insert(0, lead);
            _addActivity(
              title: 'Contact Scanned',
              description: '${lead.name} was added via QR scan.',
              type: ActivityType.scan,
            );
            notifyListeners();
          }
          return true;
        }
        // "Already in contacts" still returns 200
        return true;
      }
    } catch (e) {
      debugPrint("Error adding scanned contact: $e");
    }
    return false;
  }

  // ── Update contact ───────────────────────────────────────────────────────────
  Future<bool> updateLead(String id, Map<String, dynamic> data) async {
    try {
      final res = await _authRepo.updateContact(id: id, data: data);
      if (res.success && res.data is Map) {
        final updatedData = (res.data as Map)['contact'];
        if (updatedData != null) {
          final index = _leads.indexWhere((l) => l.id == id);
          if (index != -1) {
            _leads[index] = Lead.fromJson(updatedData);
            notifyListeners();
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint("Error updating lead: $e");
    }
    return false;
  }

  // ── Delete contact ───────────────────────────────────────────────────────────
  Future<bool> deleteLead(String id) async {
    try {
      final res = await _authRepo.deleteContact(id);
      if (res.success) {
        _leads.removeWhere((l) => l.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting lead: $e");
    }
    return false;
  }

  // ── Create category ──────────────────────────────────────────────────────────
  Future<bool> createCategory(String name, String color) async {
    try {
      final res = await _authRepo.createContactCategory(
        name: name,
        color: color,
      );
      if (res.success && res.data is Map) {
        final data = (res.data as Map)['category'];
        if (data != null) {
          _categories.insert(0, ContactCategory.fromJson(data));
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error creating category: $e");
    }
    return false;
  }

  // ── Delete category ──────────────────────────────────────────────────────────
  Future<bool> deleteCategory(String id) async {
    try {
      final res = await _authRepo.deleteContactCategory(id);
      if (res.success) {
        _categories.removeWhere((c) => c.id == id);

        // Clear category from leads locally
        for (int i = 0; i < _leads.length; i++) {
          if (_leads[i].category?.id == id) {
            _leads[i] = _leads[i].copyWith(category: null);
          }
        }

        if (_activeCategoryId == id) {
          _activeCategoryId = null;
        }

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting category: $e");
    }
    return false;
  }

  // ── Notifications management ─────────────────────────────────────────────────
  Future<void> refreshNotifications({required bool isBusinessUser}) async {
    await fetchEmployeeInvitationNotifications();
    await fetchEventInvitationNotifications();
    if (isBusinessUser) {
      await fetchCatalogOrderNotifications(isBusinessUser: true);
    }
  }

  Future<void> fetchEmployeeInvitationNotifications() async {
    try {
      final res = await _attendanceRepo.getMyInvitations();
      if (!res.success) return;

      _notifications.removeWhere((n) => n['type'] == 'employee_invitation');

      final invitations = parseAttendanceList(
        res.data,
        AttendanceEmployee.fromJson,
      );

      for (final invitation in invitations) {
        _notifications.add({
          'id': invitation.id,
          'type': 'employee_invitation',
          'title': 'Employee Invitation',
          'body':
              '${invitation.business.displayName} invited you to join their team',
          'time': 'Just now',
          'isRead': false,
        });
      }

      _sortNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching employee invitations: $e');
    }
  }

  Future<void> fetchEventInvitationNotifications() async {
    try {
      final res = await _invitationRepo.getReceived();
      if (!res.success || res.data == null) return;

      _notifications.removeWhere((n) => n['type'] == 'event_invitation');

      final data = res.data;
      final list = data is Map<String, dynamic> && data['data'] != null
          ? data['data']
          : data;

      if (list is! List) return;

      for (final item in list.whereType<Map<String, dynamic>>()) {
        final invitation = EventInvitation.fromJson(item);
        _notifications.add({
          'id': invitation.id,
          'type': 'event_invitation',
          'title': invitation.title,
          'body':
              '${invitation.sender.displayName} invited you · ${invitation.typeDisplay}',
          'time': invitation.createdAt != null ? 'Recently' : 'Just now',
          'isRead': false,
        });
      }

      _sortNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching event invitations: $e');
    }
  }

  void _sortNotifications() {
    _notifications.sort((a, b) {
      if (a['isRead'] == b['isRead']) return 0;
      return (a['isRead'] as bool) ? 1 : -1;
    });
  }

  Future<void> fetchCatalogOrderNotifications({required bool isBusinessUser}) async {
    if (!isBusinessUser) return;

    try {
      final orders = await _catalogRepo.getBusinessOrders();

      _notifications.removeWhere((n) => n['type'] == 'catalog_order');

      for (final order in orders) {
        _notifications.add({
          'id': order.id,
          'type': 'catalog_order',
          'title': CatalogHelper.orderTitleForType(order.catalogType),
          'body': '${order.customerName} ordered: ${order.itemsSummary}',
          'time': _formatOrderTime(order.createdAt?.toIso8601String()),
          'isRead': order.isRead,
        });
      }

      _sortNotifications();

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching catalog orders: $e');
    }
  }

  String _formatOrderTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Just now';
    }
  }

  void markAllNotificationsAsRead() {
    for (final n in _notifications) {
      n['isRead'] = true;
    }
    _catalogRepo.markAllOrdersRead();
    notifyListeners();
  }

  void clearNotification(String id) {
    final item = _notifications.firstWhere(
      (n) => n['id'] == id,
      orElse: () => {},
    );
    if (item['type'] == 'catalog_order') {
      _catalogRepo.markOrderRead(id);
    }
    _notifications.removeWhere((n) => n['id'] == id);
    notifyListeners();
  }

  void toggleNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      final wasRead = _notifications[idx]['isRead'] as bool;
      _notifications[idx]['isRead'] = !wasRead;
      if (!wasRead && _notifications[idx]['type'] == 'catalog_order') {
        _catalogRepo.markOrderRead(id);
      }
      notifyListeners();
    }
  }

  void addNotification({
    required String title,
    required String body,
    String? time,
  }) {
    _notifications.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'time': time ?? 'Just now',
      'isRead': false,
    });
    notifyListeners();
  }

  // ── Activities management ────────────────────────────────────────────────────
  void _addActivity({
    required String title,
    required String description,
    required ActivityType type,
  }) {
    _activities.insert(
      0,
      Activity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        timestamp: DateTime.now(),
        type: type,
      ),
    );
    if (_activities.length > 20) {
      _activities.removeLast();
    }
  }
}