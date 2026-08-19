import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/firebase_options.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/attendance/employee/employee_invitations_screen.dart';
import 'package:tapni_app/screens/invitations/invitation_detail_screen.dart';
import 'package:tapni_app/screens/invitations/invitations_home_screen.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_loyalty_home_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/screens/subscription_screen.dart';
import 'package:tapni_app/screens/notifications_screen.dart';
import 'package:tapni_app/services/account_storage.dart';
import 'package:tapni_app/services/device_session_guard.dart';
import 'package:tapni_app/utils/preference_helper.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SharedPrefHelper.getInstance();
  await SharedPrefHelper.reload();

  final type = message.data['type']?.toString() ?? '';
  final action = message.data['action']?.toString() ?? '';
  if (type != 'device_session' || action != 'logged_out') return;

  final sessionId = message.data['deviceSessionId']?.toString() ?? '';
  final activeSession = SharedPrefHelper.getString(
    SharedPrefHelper.utils.activeDeviceSessionId,
  );
  if (sessionId.isNotEmpty &&
      activeSession.isNotEmpty &&
      sessionId != activeSession) {
    return;
  }

  await SharedPrefHelper.putBool(
    SharedPrefHelper.utils.pendingRemoteLogout,
    true,
  );
  if (sessionId.isNotEmpty) {
    await SharedPrefHelper.putString(
      SharedPrefHelper.utils.pendingRemoteLogoutSessionId,
      sessionId,
    );
  }

  // Clear local session so app cannot continue authenticated offline.
  final active = AccountStorage.getActiveAccount();
  if (active != null) {
    await AccountStorage.removeActive();
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final AuthRepo _authRepo = AuthRepo();

  static bool _initialized = false;
  static String? _currentToken;
  static VoidCallback? onOrderNotification;

  static const _channels = {
    'orders': (
      id: 'orders',
      name: 'Order Notifications',
      description: 'New orders and status updates',
    ),
    'leads': (
      id: 'leads',
      name: 'Leads & Scans',
      description: 'Card scans and contact exchanges',
    ),
    'loyalty': (
      id: 'loyalty',
      name: 'Loyalty Rewards',
      description: 'Stamp updates and reward completions',
    ),
    'account': (
      id: 'account',
      name: 'Account',
      description: 'Subscription updates and employee invitations',
    ),
    'invitations': (
      id: 'invitations',
      name: 'Invitations',
      description: 'Event invitations from contacts',
    ),
  };

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('PushNotificationService: Firebase init failed — $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _setupLocalNotifications();
    await _configureForegroundPresentation();
    _listenForMessages();
    await _syncTokenWithBackend();

    _messaging.onTokenRefresh.listen((token) async {
      _currentToken = token;
      await _syncTokenWithBackend(forceToken: token);
    });

    _initialized = true;
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  static Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handlePayload(payload);
        }
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      for (final channel in _channels.values) {
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            channel.id,
            channel.name,
            description: channel.description,
            importance: Importance.high,
          ),
        );
      }
    }
  }

  static Future<void> _configureForegroundPresentation() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static void _listenForMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      final data = message.data;
      if (data['type']?.toString() == 'device_session' &&
          data['action']?.toString() == 'logged_out') {
        await DeviceSessionGuard.instance.handlePushLogout(
          deviceSessionId: data['deviceSessionId']?.toString(),
        );
        return;
      }
      await _showLocalNotification(message);
      _refreshInAppState(data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        Future.delayed(const Duration(milliseconds: 800), () {
          _handleMessage(message);
        });
      }
    });
  }

  static Future<void> syncTokenWithBackend() => _syncTokenWithBackend();

  static Future<void> removeTokenFromBackend() async {
    final token = _currentToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    final authToken = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    if (authToken.isEmpty) return;

    await _authRepo.removeFcmToken(token: token);
    _currentToken = null;
  }

  static Future<void> _syncTokenWithBackend({String? forceToken}) async {
    final authToken = SharedPrefHelper.getString(
      SharedPrefHelper.utils.authorizedToken,
    );
    if (authToken.isEmpty) return;

    try {
      final token = forceToken ?? await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      _currentToken = token;
      await _authRepo.saveFcmToken(
        token: token,
        platform: Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : 'unknown',
      );
    } catch (e) {
      debugPrint('PushNotificationService: token sync failed — $e');
    }
  }

  static String _channelIdForType(String? type) {
    switch (type) {
      case 'profile_scan':
      case 'contact_exchange':
        return 'leads';
      case 'subscription':
      case 'employee_invitation':
      case 'follow_request':
      case 'follow_accepted':
        return 'account';
      case 'event_invitation':
        return 'invitations';
      case 'loyalty_stamp':
        return 'loyalty';
      case 'catalog_order':
      default:
        return 'orders';
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final channelId = _channelIdForType(data['type']?.toString());
    final channel = _channels[channelId] ?? _channels['orders']!;
    final payload = jsonEncode(data);

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  static void _handlePayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _routeNotification(data);
    } catch (e) {
      debugPrint('PushNotificationService: invalid payload — $e');
    }
  }

  static void _handleMessage(RemoteMessage message) {
    final data = message.data;
    if (data['type']?.toString() == 'device_session' &&
        data['action']?.toString() == 'logged_out') {
      DeviceSessionGuard.instance.handlePushLogout(
        deviceSessionId: data['deviceSessionId']?.toString(),
      );
      return;
    }
    _routeNotification(data);
    _refreshInAppState(data);
  }

  static void _routeNotification(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'catalog_order':
        final orderId = data['orderId']?.toString();
        if (orderId == null || orderId.isEmpty) return;
        final isBusinessView = data['isBusinessView']?.toString() == 'true';
        _openOrderDetail(context, orderId, isBusinessView);
      case 'profile_scan':
        _openMainShell(context, 'Explore');
      case 'contact_exchange':
        _openMainShell(context, 'Contacts');
      case 'subscription':
        _openSubscriptionScreen(context);
      case 'loyalty_stamp':
        _openLoyaltyHome(context);
      case 'employee_invitation':
        _openEmployeeInvitations(context);
      case 'event_invitation':
        _openEventInvitation(context, data['invitationId']?.toString());
      case 'follow_request':
      case 'follow_accepted':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      default:
        break;
    }
  }

  static void _openOrderDetail(
    BuildContext context,
    String orderId,
    bool isBusinessView,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: orderId,
          isBusinessView: isBusinessView,
        ),
      ),
    );
  }

  static void _openMainShell(BuildContext context, String page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainShell(currentPage: page)),
      (route) => false,
    );
  }

  static void _openSubscriptionScreen(BuildContext context) {
    Provider.of<SubscriptionProvider>(context, listen: false)
        .checkSubscriptionStatus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) =>  SubscriptionScreen()),
    );
  }

  static void _openLoyaltyHome(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CustomerLoyaltyHomeScreen()),
    );
  }

  static void _openEmployeeInvitations(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmployeeInvitationsScreen()),
    );
  }

  static void _openEventInvitation(BuildContext context, String? invitationId) {
    if (invitationId != null && invitationId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InvitationDetailScreen(invitationId: invitationId),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InvitationsHomeScreen()),
    );
  }

  static void _refreshInAppState(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (type == 'catalog_order') {
      onOrderNotification?.call();
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (type == 'catalog_order') {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      Provider.of<LeadsProvider>(context, listen: false).refreshNotifications(
        isBusinessUser: profileProvider.isProUser,
      );
    }

    if (type == 'employee_invitation') {
      Provider.of<LeadsProvider>(context, listen: false)
          .fetchEmployeeInvitationNotifications();
    }

    if (type == 'event_invitation') {
      Provider.of<InvitationProvider>(context, listen: false)
          .fetchReceivedQuiet();
      Provider.of<LeadsProvider>(context, listen: false)
          .fetchEventInvitationNotifications();
    }

    if (type == 'follow_request' || type == 'follow_accepted') {
      Provider.of<LeadsProvider>(context, listen: false)
          .fetchFollowNotifications();
    }

    if (type == 'subscription') {
      Provider.of<SubscriptionProvider>(context, listen: false)
          .checkSubscriptionStatus();
    }
  }
}
