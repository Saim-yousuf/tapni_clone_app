import 'package:flutter/material.dart';
import 'package:tapni_app/screens/subscription_screen.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';

/// Opens the payment-ready subscription checkout (mock now, Stripe later).
class SubcriptionSheet {
  static void show(BuildContext context) {
    Navigator.of(context).push(
      AppPageRoute(builder: (_) => SubscriptionScreen()),
    );
  }
}

/// Legacy entry — closes any sheet and opens [SubscriptionScreen].
class ProUpgradeSheet extends StatefulWidget {
  const ProUpgradeSheet({Key? key}) : super(key: key);

  @override
  State<ProUpgradeSheet> createState() => _ProUpgradeSheetState();
}

class _ProUpgradeSheetState extends State<ProUpgradeSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rootNav = Navigator.of(context, rootNavigator: true);
      // Close bottom sheet / overlay if this widget was presented that way.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      rootNav.push(AppPageRoute(builder: (_) => SubscriptionScreen()));
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
