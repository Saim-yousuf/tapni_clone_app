import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/business_feature_repo.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/screens/booking/bookable_resources_screen.dart';
import 'package:tapni_app/screens/business_profile_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_settings_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_setup_screen.dart';
import 'package:tapni_app/utils/business_features.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/wa_tools_widgets.dart';

/// Guided setup with **server-computed** completion (not visit-based).
class BusinessSetupChecklistScreen extends StatefulWidget {
  const BusinessSetupChecklistScreen({super.key});

  @override
  State<BusinessSetupChecklistScreen> createState() =>
      _BusinessSetupChecklistScreenState();
}

class _BusinessSetupChecklistScreenState
    extends State<BusinessSetupChecklistScreen> {
  final _repo = BusinessFeatureRepo();
  bool _loading = true;
  String? _error;
  String _businessType = '';
  List<_SetupStepVm> _steps = [];
  int _done = 0;
  int _total = 0;

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
    final res = await _repo.getSetupStatus();
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message?.trim().isNotEmpty == true
            ? res.message
            : 'Could not load setup status';
      });
      return;
    }
    final data = BusinessFeatureRepo.unwrapPayload(res);
    final stepsRaw = data['steps'] as List<dynamic>? ?? [];
    final progress = data['progress'] is Map
        ? Map<String, dynamic>.from(data['progress'] as Map)
        : <String, dynamic>{};
    setState(() {
      _loading = false;
      _businessType = data['businessType']?.toString() ?? '';
      _done = (progress['done'] as num?)?.toInt() ?? 0;
      _total = (progress['total'] as num?)?.toInt() ?? 0;
      _steps = stepsRaw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return _SetupStepVm(
          id: m['id']?.toString() ?? '',
          title: m['title']?.toString() ?? '',
          optional: m['optional'] == true,
          completed: m['completed'] == true,
        );
      }).toList();
    });
    await context.read<ProfileProvider>().fetchProfile();
  }

  Future<void> _skip() async {
    await context.read<ProfileProvider>().patchProfileFields({
      'setupProgress': {
        'skippedAt': DateTime.now().toIso8601String(),
      },
    });
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _chooseBusinessKind() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetDragHandle(),
                const SizedBox(height: 12),
                Text(
                  'What kind of products business is this?',
                  style: WaUi.toolsTitleOf(size: 18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stay / Hotel uses rooms and night bookings. Ecommerce uses cart checkout without stay dates.',
                  style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Products / Ecommerce'),
                  subtitle: const Text('Catalog, cart, and orders'),
                  onTap: () => Navigator.pop(ctx, 'products'),
                ),
                ListTile(
                  leading: const Icon(Icons.hotel_outlined),
                  title: const Text('Stay / Hotel'),
                  subtitle: const Text('Rooms, availability, stay bookings'),
                  onTap: () => Navigator.pop(ctx, 'stay'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    final res = await _repo.setBusinessType(choice, resetFeatures: false);
    if (!mounted) return;
    if (!res.success) {
      showSnackBar(
        context,
        res.message?.trim().isNotEmpty == true
            ? res.message!
            : 'Could not update business type',
        isError: true,
      );
      return;
    }
    await _load();
  }

  /// Open existing website hub, or create-flow only when none exists yet.
  Future<void> _openWebsiteHub(String websiteType) async {
    final websiteRepo = BusinessWebsiteRepo();
    final res = await websiteRepo.getMine(websiteType: websiteType);
    if (!mounted) return;
    final website = res.success ? websiteRepo.parseWebsite(res.data) : null;
    if (website != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              BusinessWebsiteSettingsScreen(initialWebsite: website),
        ),
      );
      return;
    }
    final explicit = normalizeBusinessType(_businessType);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessWebsiteSetupScreen(
          websiteType: websiteType,
          businessType: explicit.isEmpty ? null : explicit,
        ),
      ),
    );
  }

  Future<void> _openStep(_SetupStepVm step) async {
    if (step.id == 'business_kind') {
      await _chooseBusinessKind();
      return;
    }
    final websiteType = websiteTypeForBusinessType(_businessType);
    switch (step.id) {
      case 'profile':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
        );
        break;
      case 'website':
      case 'sections':
      case 'items':
      case 'availability':
      case 'fulfillment':
      case 'publish':
        await _openWebsiteHub(websiteType);
        break;
      case 'rooms':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BookableResourcesScreen(
              allowedTypes: ['room'],
              title: 'Rooms',
            ),
          ),
        );
        break;
      case 'staff':
        showSnackBar(
          context,
          'Enable specialists from Team Attendance → bookable toggle.',
        );
        break;
      default:
        break;
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total == 0 ? 0.0 : _done / _total;
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Business Setup'),
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
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '${businessTypeLabel(_businessType)} · '
                  '$_done of $_total required complete',
                  style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E5EA),
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    for (final step in _steps)
                      WaToolsListTile(
                        icon: step.completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        title: step.title,
                        subtitle: step.optional
                            ? 'Optional'
                            : (step.completed ? 'Completed' : 'Not completed'),
                        onTap: () => _openStep(step),
                      ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: OutlinedButton(
                        onPressed: _skip,
                        child: const Text('Skip for now'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Text(
                        'Skip closes this checklist. It does not mark steps complete.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetupStepVm {
  final String id;
  final String title;
  final bool optional;
  final bool completed;

  const _SetupStepVm({
    required this.id,
    required this.title,
    required this.optional,
    required this.completed,
  });
}
