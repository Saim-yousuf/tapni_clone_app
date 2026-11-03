import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/business_feature_repo.dart';
import 'package:tapni_app/utils/business_features.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

/// Explore / activate / deactivate optional business features.
///
/// Explore and Manage use the same API snapshot (`/business/features`) so
/// activation rules stay canonical with the backend TYPE_FEATURE_MAP.
class BusinessFeaturesScreen extends StatefulWidget {
  const BusinessFeaturesScreen({super.key, this.manageOnly = false});

  final bool manageOnly;

  @override
  State<BusinessFeaturesScreen> createState() => _BusinessFeaturesScreenState();
}

class _BusinessFeaturesScreenState extends State<BusinessFeaturesScreen> {
  final _repo = BusinessFeatureRepo();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _features = {};
  String _businessType = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.getMyFeatures();
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message?.trim().isNotEmpty == true
            ? res.message
            : 'Could not load features';
      });
      return;
    }
    final data = BusinessFeatureRepo.unwrapPayload(res);
    final featuresRaw = data['features'];
    final features = <String, dynamic>{};
    if (featuresRaw is Map) {
      featuresRaw.forEach((k, v) {
        features[k.toString()] = v;
      });
    }
    setState(() {
      _loading = false;
      _businessType = data['businessType']?.toString() ?? '';
      _features = features;
    });
    await context.read<ProfileProvider>().fetchProfile();
  }

  Future<void> _activate(String key) async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await _repo.activate(key);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      showSnackBar(
        context,
        res.message?.trim().isNotEmpty == true
            ? res.message!
            : 'Could not activate feature',
        isError: true,
      );
      return;
    }
    await _load();
    if (!mounted) return;
    await context.read<ProfileProvider>().fetchProfile();
  }

  Future<void> _deactivate(String key) async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await _repo.deactivate(key);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      showSnackBar(
        context,
        res.message?.trim().isNotEmpty == true
            ? res.message!
            : 'Could not deactivate feature',
        isError: true,
      );
      return;
    }
    await _load();
    if (!mounted) return;
    await context.read<ProfileProvider>().fetchProfile();
  }

  void _onTap({
    required String key,
    required String state,
    required bool isDefault,
    required String reason,
  }) {
    switch (state) {
      case 'locked':
        showSnackBar(
          context,
          reason.isNotEmpty
              ? reason
              : 'Requires Business Pro subscription',
        );
        return;
      case 'unsupported':
        // Treated as activatable under open-access Feature Hub.
        _activate(key);
        return;
      case 'enabled':
        if (isDefault) {
          showSnackBar(
            context,
            'Included with ${businessTypeLabel(_businessType)} and cannot be turned off.',
          );
          return;
        }
        _deactivate(key);
        return;
      case 'available':
        _activate(key);
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.manageOnly ? 'Active Features' : 'Feature Settings';
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(title: title),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    WaSectionHeader(
                      '${businessTypeLabel(_businessType)} tools',
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        widget.manageOnly
                            ? 'Optional features you turned on. Included tools for your type cannot be removed here.'
                            : 'Every tool is available for ${businessTypeLabel(_businessType)}. '
                                'Defaults stay on; activate optionals when you need them. '
                                'Pro may be required for some modules.',
                        style: WaUi.body.copyWith(
                          fontSize: 13,
                          color: BarqodyChrome.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ),
                    ..._buildRows(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    final entries = _features.entries.toList();
    entries.sort((a, b) {
      final sa = (a.value is Map ? a.value['state'] : '')?.toString() ?? '';
      final sb = (b.value is Map ? b.value['state'] : '')?.toString() ?? '';
      int rank(String s) {
        switch (s) {
          case 'enabled':
            return 0;
          case 'available':
            return 1;
          case 'locked':
            return 2;
          case 'unsupported':
            return 3;
          default:
            return 4;
        }
      }

      final c = rank(sa).compareTo(rank(sb));
      if (c != 0) return c;
      return a.key.compareTo(b.key);
    });

    final rows = <Widget>[];
    for (final e in entries) {
      final meta = e.value is Map
          ? Map<String, dynamic>.from(e.value as Map)
          : <String, dynamic>{};
      var state = meta['state']?.toString() ?? 'available';
      // Open access across business types — never hide as type-unsupported.
      if (state == 'unsupported') state = 'available';
      final isDefault = meta['isDefault'] == true;
      final reason = meta['reason']?.toString() ?? '';

      // Manage Active: optional enabled only (defaults are always on).
      if (widget.manageOnly) {
        if (state != 'enabled' || isDefault) continue;
      }

      final title = meta['title']?.toString() ??
          kFeatureMeta[e.key]?['title'] ??
          e.key;
      final description = meta['description']?.toString() ??
          kFeatureMeta[e.key]?['description'] ??
          '';

      late final String statusLine;
      switch (state) {
        case 'enabled':
          statusLine = isDefault
              ? 'Included — cannot be turned off'
              : 'Active — tap to deactivate';
          break;
        case 'available':
          statusLine = 'Available — tap to activate';
          break;
        case 'locked':
          statusLine = reason.isNotEmpty
              ? reason
              : 'Requires Business Pro subscription';
          break;
        case 'unsupported':
          statusLine = 'Available — tap to activate';
          break;
        default:
          statusLine = description;
      }

      final subtitle = description.isEmpty
          ? statusLine
          : '$description\n$statusLine';

      rows.add(
        WaToolsListTile(
          icon: _iconFor(e.key),
          title: title,
          subtitle: subtitle,
          onTap: () => _onTap(
            key: e.key,
            state: state,
            isDefault: isDefault,
            reason: reason,
          ),
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.manageOnly
                ? 'No optional features activated yet.'
                : 'No features to show for ${businessTypeLabel(_businessType)}.',
          ),
        ),
      );
    }
    return rows;
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'loyalty':
        return Icons.stars_outlined;
      case 'offers':
        return Icons.local_offer_outlined;
      case 'ads':
        return Icons.campaign_outlined;
      case 'staff':
      case 'team':
        return Icons.groups_outlined;
      case 'rooms':
        return Icons.meeting_room_outlined;
      case 'stay_bookings':
        return Icons.hotel_outlined;
      case 'calendar':
        return Icons.event_available_outlined;
      case 'orders':
        return Icons.receipt_long_outlined;
      case 'earnings':
        return Icons.account_balance_wallet_outlined;
      case 'pos':
        return Icons.point_of_sale_outlined;
      case 'website':
        return Icons.language_outlined;
      case 'menu':
        return Icons.restaurant_menu_outlined;
      case 'products':
        return Icons.inventory_2_outlined;
      case 'services':
        return Icons.handshake_outlined;
      case 'portfolio':
        return Icons.photo_library_outlined;
      case 'pickup':
        return Icons.storefront_outlined;
      case 'delivery':
        return Icons.delivery_dining_outlined;
      default:
        return Icons.extension_outlined;
    }
  }
}
