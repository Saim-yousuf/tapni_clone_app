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
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/attendance/employee/employee_invitations_screen.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_loyalty_home_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/screens/subscription_screen.dart';
import 'package:tapni_app/utils/preference_helper.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      await _showLocalNotification(message);
      _refreshInAppState(message.data);
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
        return 'account';
      case 'employee_invitation':
        return 'account';
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
    _routeNotification(message.data);
    _refreshInAppState(message.data);
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
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
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
      Provider.of<LeadsProvider>(context, listen: false)
          .fetchCatalogOrderNotifications(
        isBusinessUser: profileProvider.isProUser,
      );
    }

    if (type == 'subscription') {
      Provider.of<SubscriptionProvider>(context, listen: false)
          .checkSubscriptionStatus();
    }
  }
}
