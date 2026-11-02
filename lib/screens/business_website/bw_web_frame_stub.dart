import 'package:flutter/widgets.dart';
import 'package:tapni_app/screens/business_website/bw_flutter_commerce_bridge.dart';

/// Non-web stub — never used at runtime on mobile/desktop.
Widget buildBusinessWebsiteWebFrame({
  required String viewType,
  String? url,
  String? html,
  Map<String, String>? shopper,
  bool flutterApp = false,
  void Function(String orderId, {String? accessToken})? onTrackOrder,
  void Function(BwBridgeAddToCart payload)? onAddToCart,
  VoidCallback? onOpenCart,
}) {
  return const SizedBox.shrink();
}
