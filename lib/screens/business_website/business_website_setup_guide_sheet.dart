import 'package:flutter/material.dart';
import 'package:tapni_app/screens/business_website/business_presence_ui.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Opens the go-live guide as a full screen.
/// Pass [websiteType] when known; omit to let the user pick a type first.
Future<void> showBusinessWebsiteSetupGuide(
  BuildContext context, {
  String? websiteType,
}) {
  return Navigator.of(context).push<void>(
    AppPageRoute(
      builder: (_) => BusinessWebsiteSetupGuideScreen(
        initialWebsiteType: websiteType,
      ),
    ),
  );
}

class _GuideStep {
  final String title;
  final String body;
  final String where;

  const _GuideStep({
    required this.title,
    required this.body,
    required this.where,
  });
}

class _SiteType {
  final String id;
  final String label;
  final String blurb;
  final IconData icon;

  const _SiteType({
    required this.id,
    required this.label,
    required this.blurb,
    required this.icon,
  });
}

const _kSiteTypes = <_SiteType>[
  _SiteType(
    id: 'menu',
    label: 'Menu',
    blurb: 'Items customers can order',
    icon: Icons.restaurant_menu_outlined,
  ),
  _SiteType(
    id: 'service',
    label: 'Services',
    blurb: 'Offerings customers can book',
    icon: Icons.design_services_outlined,
  ),
  _SiteType(
    id: 'products',
    label: 'Products',
    blurb: 'Products or bookable listings',
    icon: Icons.inventory_2_outlined,
  ),
  _SiteType(
    id: 'portfolio',
    label: 'Portfolio',
    blurb: 'Work you want to showcase',
    icon: Icons.photo_library_outlined,
  ),
];

class BusinessWebsiteSetupGuideScreen extends StatefulWidget {
  final String? initialWebsiteType;

  const BusinessWebsiteSetupGuideScreen({
    super.key,
    this.initialWebsiteType,
  });

  @override
  State<BusinessWebsiteSetupGuideScreen> createState() =>
      _BusinessWebsiteSetupGuideScreenState();
}

class _BusinessWebsiteSetupGuideScreenState
    extends State<BusinessWebsiteSetupGuideScreen> {
  late String? _type;

  @override
  void initState() {
    super.initState();
    final raw = (widget.initialWebsiteType ?? '').trim().toLowerCase();
    _type = switch (raw) {
      'service' || 'services' => 'service',
      'products' || 'product' => 'products',
      'portfolio' => 'portfolio',
      'menu' || 'catalog' => 'menu',
      _ => null,
    };
  }

  String get _typeLabel {
    switch (_type) {
      case 'service':
        return 'Services';
      case 'products':
        return 'Products';
      case 'portfolio':
        return 'Portfolio';
      case 'menu':
        return 'Menu';
      default:
        return 'website';
    }
  }

  String get _itemWord {
    switch (_type) {
      case 'service':
        return 'services';
      case 'products':
        return 'products';
      case 'portfolio':
        return 'items';
      case 'menu':
      default:
        return 'items';
    }
  }

  List<_GuideStep> get _steps {
    final t = _type;
    if (t == null) return const [];

    final steps = <_GuideStep>[
      const _GuideStep(
        title: 'Finish your profile',
        body:
            'Your name, photo, cover, and bio appear on the public site. Keep them clear.',
        where: 'Profile',
      ),
      _GuideStep(
        title: 'Create the $_typeLabel website',
        body:
            'Add this website type from your profile, choose a template, then create.',
        where: 'Profile → Add link',
      ),
      _GuideStep(
        title: 'Add your $_itemWord',
        body:
            'Add photos, prices, and short descriptions so the site feels complete.',
        where: '$_typeLabel tab',
      ),
    ];

    if (t == 'service' || t == 'products' || t == 'menu') {
      steps.add(
        const _GuideStep(
          title: 'Set booking resources if needed',
          body:
              'If customers pick a person, room, or table, add those resources so booking works.',
          where: 'Business Suite → Rooms & tables / Team',
        ),
      );
    }

    steps.addAll(const [
      _GuideStep(
        title: 'Customize the look',
        body: 'Choose a theme color and headline that match your brand.',
        where: 'Settings → Customize Website',
      ),
      _GuideStep(
        title: 'Publish',
        body: 'Turn Status on, preview once, then share your public link.',
        where: 'Settings → Status / Live Preview',
      ),
    ]);

    return steps;
  }

  void _onBack() {
    if (_type != null && widget.initialWebsiteType == null) {
      setState(() => _type = null);
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final picking = _type == null;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: BwUi.pageBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(
              title: picking ? 'Setup guide' : 'Go live',
              onBack: _onBack,
            ),
            Expanded(
              child: picking
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        const Text(
                          'Choose your website type',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.15,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You’ll get a short checklist for that site — nothing extra.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: AuthUi.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._kSiteTypes.map((site) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => setState(() => _type = site.id),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    16,
                                    12,
                                    16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: BwUi.cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: BwUi.iconTileBg,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          site.icon,
                                          color: Colors.black,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              site.label,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              site.blurb,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AuthUi.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.black45,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            children: [
                              Text(
                                '$_typeLabel checklist',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Follow these steps in order. Each chip shows where to tap.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: AuthUi.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 22),
                              ...List.generate(_steps.length, (i) {
                                final step = _steps[i];
                                final isLast = i == _steps.length - 1;
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                color: Colors.black,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${i + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            if (!isLast)
                                              Expanded(
                                                child: Container(
                                                  width: 2,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                                  color: const Color(0xFFE8E8ED),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            bottom: isLast ? 0 : 22,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.fromLTRB(
                                              14,
                                              14,
                                              14,
                                              14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: BwUi.cardBorder,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  step.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  step.body,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    height: 1.45,
                                                    fontWeight: FontWeight.w500,
                                                    color: AuthUi.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: BwUi.pageBg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      999,
                                                    ),
                                                    border: Border.all(
                                                      color: BwUi.cardBorder,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    step.where,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
                          child: SizedBox(
                            width: double.infinity,
                            child: AuthPrimaryPillButton(
                              label: 'Got it',
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
