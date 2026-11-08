// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as dom;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:tapni_app/screens/business_website/bw_flutter_commerce_bridge.dart';

/// Flutter Web iframe host for business website preview / public URL.
Widget buildBusinessWebsiteWebFrame({
  required String viewType,
  String? url,
  String? html,
  Map<String, String>? shopper,
  bool flutterApp = false,
  void Function(String orderId, {String? accessToken})? onTrackOrder,
  void Function(BwBridgeAddToCart payload)? onAddToCart,
  void Function(BwBridgeAdjustCartQty payload)? onAdjustCartQty,
  VoidCallback? onOpenCart,
  VoidCallback? onCloseWebsite,
  void Function(bool enabled)? onImmersiveNav,
}) {
  final htmlContent = html;
  final pageUrl = url;
  final trackOrder = onTrackOrder;
  final addToCart = onAddToCart;
  final adjustCartQty = onAdjustCartQty;
  final openCart = onOpenCart;
  final closeWebsite = onCloseWebsite;
  final immersiveNav = onImmersiveNav;
  final injectFlutter = flutterApp;
  final shopperPayload = shopper == null || shopper.isEmpty
      ? null
      : Map<String, String>.from(shopper);

  Map<String, dynamic>? _asMessageMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  // Parent ↔ iframe bridge (track order + shopper handshake + commerce).
  dom.window.onMessage.listen((event) {
    final data = _asMessageMap(event.data);
    if (data == null) return;
    if (data['source'] != 'barqody') return;

    if (data['action'] == 'trackOrder') {
      if (trackOrder == null) return;
      final orderId = data['orderId']?.toString().trim() ?? '';
      if (orderId.isEmpty) return;
      final token = data['token']?.toString().trim();
      trackOrder(
        orderId,
        accessToken: (token == null || token.isEmpty) ? null : token,
      );
      return;
    }

    if (data['action'] == 'openCart') {
      openCart?.call();
      return;
    }

    if (data['action'] == 'closeWebsite' || data['action'] == 'close') {
      closeWebsite?.call();
      return;
    }

    if (data['action'] == 'immersiveNav') {
      immersiveNav?.call(data['enabled'] != false);
      return;
    }

    if (data['action'] == 'addToCart' || data['action'] == 'configureItem') {
      final parsed = BwFlutterCommerceBridge.parseAddToCart(data);
      if (parsed != null) addToCart?.call(parsed);
      return;
    }

    if (data['action'] == 'adjustCartQty') {
      final parsed = BwFlutterCommerceBridge.parseAdjustCartQty(data);
      if (parsed != null) adjustCartQty?.call(parsed);
      return;
    }

    // Site script asks for JWT once its listener is ready.
    if (data['action'] == 'requestShopper') {
      final s = shopperPayload;
      if (s == null || s.isEmpty) return;
      final source = event.source;
      if (source is! dom.WindowBase) return;
      try {
        source.postMessage(
          jsonEncode({
            'source': 'barqody',
            'action': 'setShopper',
            'shopper': s,
          }),
          '*',
        );
      } catch (_) {}
    }
  });

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = dom.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'fullscreen';

    void pushShopper() {
      final s = shopperPayload;
      if (s == null || s.isEmpty) return;
      final win = iframe.contentWindow;
      if (win == null) return;
      try {
        win.postMessage(
          jsonEncode({
            'source': 'barqody',
            'action': 'setShopper',
            'shopper': s,
          }),
          '*',
        );
      } catch (_) {}
    }

    void pushFlutterFlag() {
      if (!injectFlutter) return;
      final win = iframe.contentWindow;
      if (win == null) return;
      try {
        win.postMessage(
          jsonEncode({
            'source': 'barqody',
            'action': 'setFlutterApp',
            'value': true,
          }),
          '*',
        );
      } catch (_) {}
    }

    iframe.onLoad.listen((_) {
      pushFlutterFlag();
      pushShopper();
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        pushFlutterFlag();
        pushShopper();
      });
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        pushFlutterFlag();
        pushShopper();
      });
      Future<void>.delayed(const Duration(milliseconds: 1600), () {
        pushFlutterFlag();
        pushShopper();
      });
    });

    final content = htmlContent?.trim() ?? '';
    final target = pageUrl?.trim() ?? '';
    if (content.isNotEmpty) {
      iframe.srcdoc = content;
    } else if (target.isNotEmpty) {
      iframe.src = target;
    }
    return iframe;
  });

  return HtmlElementView(viewType: viewType);
}
