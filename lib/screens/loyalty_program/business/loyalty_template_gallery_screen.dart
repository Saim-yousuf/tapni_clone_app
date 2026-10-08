import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/loyalty_card_design.dart';
import 'package:tapni_app/models/published_loyalty_template.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_design_editor_screen.dart';
import 'package:tapni_app/utils/loyalty_template_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/official_community_tabs.dart';

/// Browse loyalty stamp-card templates (curated + community).
class LoyaltyTemplateGalleryScreen extends StatefulWidget {
  final RewardProgram? existing;

  const LoyaltyTemplateGalleryScreen({super.key, this.existing});

  @override
  State<LoyaltyTemplateGalleryScreen> createState() =>
      _LoyaltyTemplateGalleryScreenState();
}

class _LoyaltyTemplateGalleryScreenState
    extends State<LoyaltyTemplateGalleryScreen> {
  String? _category;
  int _segment = 0; // 0 curated, 1 community
  late final PageController _pageController;
  List<PublishedLoyaltyTemplate> _community = [];
  bool _loadingCommunity = false;

  List<LoyaltyTemplate> get _filtered =>
      LoyaltyTemplateCatalog.filter(category: _category);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectSegment(int index) {
    final current = _pageController.hasClients
        ? (_pageController.page ?? _segment.toDouble())
        : _segment.toDouble();
    if ((current - index).abs() < 0.01) return;
    setState(() => _segment = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (index == 1) _loadCommunity();
  }

  Future<void> _loadCommunity() async {
    setState(() => _loadingCommunity = true);
    final res = await RewardRepo().getCommunityTemplates(category: _category);
    if (!mounted) return;
    setState(() {
      _loadingCommunity = false;
      if (res.success && res.data != null) {
        final data = res.data;
        final list = data is Map && data['data'] != null
            ? data['data']
            : data;
        if (list is List) {
          _community = list
              .whereType<Map>()
              .map((e) => PublishedLoyaltyTemplate.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();
        } else {
          _community = [];
        }
      } else {
        _community = [];
      }
    });
  }

  void _openDesign(LoyaltyCardDesign design, {String? programId}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LoyaltyDesignEditorScreen(
          design: design,
          existingProgramId: programId ?? widget.existing?.id,
          existingProgram: widget.existing,
        ),
      ),
    );
    if (saved == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _openTemplate(LoyaltyTemplate template) {
    _openDesign(template.build());
  }

  Future<void> _openCommunity(PublishedLoyaltyTemplate t) async {
    final res = await RewardRepo().useLoyaltyTemplate(t.id);
    if (!mounted) return;
    LoyaltyCardDesign design = t.designCopy();
    if (res.success && res.data != null) {
      final raw = res.data is Map && res.data['design'] != null
          ? res.data
          : (res.data is Map && res.data['data'] != null
              ? res.data['data']
              : null);
      if (raw is Map && raw['design'] is Map) {
        design = LoyaltyCardDesign.fromJson(
          Map<String, dynamic>.from(raw['design'] as Map),
        );
      }
    }
    _openDesign(design);
  }

  void _startBlank() {
    _openDesign(LoyaltyCardDesign.blank());
  }

  void _onFilterChanged() {
    setState(() {});
    if (_segment == 1) _loadCommunity();
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(
                    title: context.l10n.template,
                    onBack: () => Navigator.pop(sheetContext),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, _) {
                      final page = _pageController.hasClients
                          ? (_pageController.page ?? _segment.toDouble())
                          : _segment.toDouble();
                      return OfficialCommunityTabs(
                        position: page.clamp(0.0, 1.0),
                        onChanged: (index) {
                          _selectSegment(index);
                          setSheet(() {});
                        },
                        officialLabel: context.l10n.official,
                        communityLabel: context.l10n.community,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferAr = Localizations.localeOf(context).languageCode == 'ar';
    final templates = _filtered;
    final filtersOn = _category != null || _segment == 1;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: context.l10n.template,
              trailing: CircleAssetButton(
                asset: 'assets/images/png/settings-sliders.png',
                iconSize: 18,
                badge: filtersOn,
                onTap: _openFilters,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: context.l10n.all,
                    selected: _category == null,
                    onTap: () {
                      _category = null;
                      _onFilterChanged();
                    },
                  ),
                  ...LoyaltyTemplateCatalog.categories.map((c) {
                    return _FilterChip(
                      label: preferAr
                          ? (c['nameAr'] ?? c['name']!)
                          : c['name']!,
                      selected: _category == c['id'],
                      onTap: () {
                        _category = c['id'];
                        _onFilterChanged();
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  if (_segment == index) return;
                  setState(() => _segment = index);
                  if (index == 1) _loadCommunity();
                },
                children: [
                  _CuratedGrid(
                    templates: templates,
                    preferAr: preferAr,
                    onOpen: _openTemplate,
                  ),
                  _CommunityGrid(
                    templates: _community,
                    loading: _loadingCommunity,
                    onOpen: _openCommunity,
                    onRefresh: _loadCommunity,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: PillButton(
                label: '${context.l10n.create} ${context.l10n.blank}',
                onPressed: _startBlank,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Colors.black : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? Colors.black : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                style: WaUi.body.copyWith(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF6B6B6B),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CuratedGrid extends StatelessWidget {
  final List<LoyaltyTemplate> templates;
  final bool preferAr;
  final void Function(LoyaltyTemplate) onOpen;

  const _CuratedGrid({
    required this.templates,
    required this.preferAr,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noLoyaltyTemplatesFound,
          style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemCount: templates.length,
      itemBuilder: (_, i) {
        final t = templates[i];
        return _NamedPreviewCard(
          name: t.displayName(preferAr),
          onTap: () => onOpen(t),
          child: LoyaltyCardDesignRenderer(
            design: t.build(),
            shadows: const [],
          ),
        );
      },
    );
  }
}

class _CommunityGrid extends StatelessWidget {
  final List<PublishedLoyaltyTemplate> templates;
  final bool loading;
  final void Function(PublishedLoyaltyTemplate) onOpen;
  final VoidCallback onRefresh;

  const _CommunityGrid({
    required this.templates,
    required this.loading,
    required this.onOpen,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && templates.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
      );
    }
    if (templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.noCommunityTemplatesYet,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: Colors.black,
      onRefresh: () async => onRefresh(),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        itemCount: templates.length,
        itemBuilder: (_, i) {
          final t = templates[i];
          return _NamedPreviewCard(
            name: t.name,
            onTap: () => onOpen(t),
            child: ColoredBox(
              color: designColorFromHex(t.previewColor),
              child: LoyaltyCardDesignRenderer(
                design: t.design,
                shadows: const [],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NamedPreviewCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final Widget child;

  const _NamedPreviewCard({
    required this.name,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ColoredBox(
                color: const Color(0xFFF4F4F6),
                child: child,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WaUi.body.copyWith(
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              decoration: TextDecoration.underline,
              decorationColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
