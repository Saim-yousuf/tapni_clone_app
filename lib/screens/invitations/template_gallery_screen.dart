import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/invitation_design.dart';
import 'package:tapni_app/models/published_invitation_template.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/screens/invitations/invitation_design_editor_screen.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/utils/invitation_template_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/country_picker_sheet.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';

/// Browse invitation templates by country and category (Canva-style start).
class TemplateGalleryScreen extends StatefulWidget {
  const TemplateGalleryScreen({super.key});

  @override
  State<TemplateGalleryScreen> createState() => _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends State<TemplateGalleryScreen> {
  String? _country;
  String? _category;
  int _segment = 0; // 0 = curated, 1 = community
  late final PageController _pageController;

  List<InvitationTemplate> get _filtered =>
      InvitationTemplateCatalog.filter(
        countryCode: _country,
        category: _category,
      );

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommunity();
    });
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

  void _loadCommunity() {
    context.read<InvitationProvider>().fetchCommunityTemplates(
          country: _country,
          category: _category,
        );
  }

  void _openTemplate(InvitationTemplate template) {
    final design = template.build();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvitationDesignEditorScreen(design: design),
      ),
    );
  }

  Future<void> _openCommunity(PublishedInvitationTemplate t) async {
    final provider = context.read<InvitationProvider>();
    final design = await provider.useCommunityTemplate(t.id, context: context);
    if (!mounted) return;
    final toEdit = design ?? t.designCopy();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvitationDesignEditorScreen(design: toEdit),
      ),
    );
  }

  void _startBlank() {
    final design = InvitationDesign.blank(
      countryCode: _country ?? 'US',
      category: _category ?? 'other',
      locale: InvitationTemplateCatalog.defaultLocaleForCountry(_country),
      rtl: InvitationTemplateCatalog.isRtlCountry(_country),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvitationDesignEditorScreen(design: design),
      ),
    );
  }

  void _onFilterChanged() {
    setState(() {});
    if (_segment == 1) _loadCommunity();
  }

  Future<void> _pickCountry() async {
    final selected = await showCountryPickerSheet(
      context,
      selectedIso: _country,
    );
    if (!mounted || selected == null) return;
    _country = selected.iso.toUpperCase();
    _onFilterChanged();
  }

  Map<String, String>? _countryInfo(String code) {
    final upper = code.toUpperCase();
    for (final c in InvitationTemplateCatalog.countries) {
      if (c['code'] == upper) return c;
    }
    for (final dial in kCountryDialCodes) {
      if (dial.iso.toUpperCase() == upper) {
        return {
          'code': dial.iso.toUpperCase(),
          'name': dial.name,
          'flag': dial.flagEmoji,
        };
      }
    }
    return null;
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            return _TemplateFilterSheet(
              segment: _segment,
              country: _country,
              countryInfo: _country == null ? null : _countryInfo(_country!),
              featured: InvitationTemplateCatalog.featuredCountryCodes,
              infoFor: _countryInfo,
              onSegment: (index) {
                _selectSegment(index);
                setSheet(() {});
              },
              onCountry: (code) {
                _country = code;
                _onFilterChanged();
                setSheet(() {});
              },
              onSeeAll: () async {
                await _pickCountry();
                if (sheetContext.mounted) setSheet(() {});
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = _filtered;
    final provider = context.watch<InvitationProvider>();
    final community = provider.communityTemplates;
    final filtersOn = _country != null || _segment == 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: context.l10n.template,
              trailing: Tooltip(
                message: context.l10n.country,
                child: CircleAssetButton(
                  asset: 'assets/images/png/settings-sliders.png',
                  iconSize: 18,
                  badge: filtersOn,
                  onTap: _openFilters,
                ),
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
                  ...InvitationTemplateCatalog.categories.map((c) {
                    return _FilterChip(
                      label: c['name']!,
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
                  _OfficialGrid(
                    templates: templates,
                    onOpen: _openTemplate,
                  ),
                  _CommunityGrid(
                    templates: community,
                    loading: provider.loadingCommunity,
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

class _OfficialGrid extends StatelessWidget {
  final List<InvitationTemplate> templates;
  final void Function(InvitationTemplate) onOpen;

  const _OfficialGrid({
    required this.templates,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            context.l10n.noTemplatesForFilter,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: 15,
              color: BarqodyChrome.secondaryText,
            ),
          ),
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
      itemBuilder: (context, i) {
        final t = templates[i];
        return _TemplateCard(template: t, onTap: () => onOpen(t));
      },
    );
  }
}

class _CommunityGrid extends StatelessWidget {
  final List<PublishedInvitationTemplate> templates;
  final bool loading;
  final void Function(PublishedInvitationTemplate) onOpen;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.noCommunityTemplatesYet,
                style: WaUi.toolsTitleOf(
                  size: 18,
                  weight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.designAndPublishHint,
                style: WaUi.body.copyWith(
                  fontSize: 14,
                  color: BarqodyChrome.secondaryText,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRefresh,
                child: Text(
                  context.l10n.refresh,
                  style: WaUi.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: Colors.black,
      backgroundColor: Colors.white,
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
        itemBuilder: (context, i) {
          final t = templates[i];
          return _NamedPreviewCard(
            name: t.name,
            onTap: () => onOpen(t),
            child: InvitationDesignRenderer(
              design: t.design,
              shadows: const [],
            ),
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final InvitationTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _NamedPreviewCard(
      name: template.name,
      onTap: onTap,
      child: InvitationDesignRenderer(
        design: template.build(),
        shadows: const [],
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
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateFilterSheet extends StatelessWidget {
  final int segment;
  final String? country;
  final Map<String, String>? countryInfo;
  final List<String> featured;
  final Map<String, String>? Function(String code) infoFor;
  final ValueChanged<int> onSegment;
  final ValueChanged<String?> onCountry;
  final VoidCallback onSeeAll;

  const _TemplateFilterSheet({
    required this.segment,
    required this.country,
    required this.countryInfo,
    required this.featured,
    required this.infoFor,
    required this.onSegment,
    required this.onCountry,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetDragHandle()),
            const SizedBox(height: 18),
            _SourceTabs(
              segment: segment,
              officialLabel: context.l10n.official,
              communityLabel: context.l10n.community,
              onChanged: onSegment,
            ),
            const SizedBox(height: 22),
            Text(
              context.l10n.country,
              style: WaUi.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: context.l10n.all,
                    selected: country == null,
                    onTap: () => onCountry(null),
                  ),
                  if (countryInfo != null && !featured.contains(country))
                    _FilterChip(
                      label: '${countryInfo!['flag']}  ${countryInfo!['name']}',
                      selected: true,
                      onTap: onSeeAll,
                    ),
                  ...featured.map((code) {
                    final c = infoFor(code);
                    if (c == null) return const SizedBox.shrink();
                    return _FilterChip(
                      label: '${c['flag']}  ${c['name']}',
                      selected: country == code,
                      onTap: () => onCountry(code),
                    );
                  }),
                  _FilterChip(
                    label: context.l10n.seeAll,
                    selected: false,
                    onTap: onSeeAll,
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

class _SourceTabs extends StatelessWidget {
  final int segment;
  final String officialLabel;
  final String communityLabel;
  final ValueChanged<int> onChanged;

  const _SourceTabs({
    required this.segment,
    required this.officialLabel,
    required this.communityLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _SourceTab(
            label: officialLabel,
            selected: segment == 0,
            onTap: () => onChanged(0),
          ),
          _SourceTab(
            label: communityLabel,
            selected: segment == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SourceTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SourceTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WaUi.body.copyWith(
              fontSize: 15,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }
}
