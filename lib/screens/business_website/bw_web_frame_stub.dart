import 'package:flutter/widgets.dart';

/// Non-web stub — never used at runtime on mobile/desktop.
Widget buildBusinessWebsiteWebFrame({
  required String viewType,
  String? url,
  String? html,
  Map<String, String>? shopper,
  void Function(String orderId, {String? accessToken})? onTrackOrder,
}) {
  return const SizedBox.shrink();
}
