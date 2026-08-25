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
import 'package:tapni_app/widgets/country_picker_sheet.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';
import 'package:tapni_app/widgets/official_community_tabs.dart';
import 'package:tapni_app/widgets/wa_chats_widgets.dart';

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

  List<InvitationTemplate> get _filtered =>
      InvitationTemplateCatalog.filter(
        countryCode: _country,
        category: _category,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommunity();
    });
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

  @override
  Widget build(BuildContext context) {
    final templates = _filtered;
    final provider = context.watch<InvitationProvider>();
    final community = provider.communityTemplates;
    final featured = InvitationTemplateCatalog.featuredCountryCodes;
    final selectedInfo = _country == null ? null : _countryInfo(_country!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.l10n.chooseATemplate),
        actions: [
          TextButton(
            onPressed: _startBlank,
            child: Text(context.l10n.blank)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: OfficialCommunityTabs(
              index: _segment,
              onChanged: (index) {
                if (_segment == index) return;
                setState(() => _segment = index);
                if (_segment == 1) _loadCommunity();
              },
              officialLabel: context.l10n.official,
              communityLabel: context.l10n.community,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(context.l10n.country, style: WaUi.label),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: [
                WaPillFilterChip(
                  label: context.l10n.all,
                  selected: _country == null,
                  selectedColor: WaUi.chipBg,
                  onTap: () {
                    _country = null;
                    _onFilterChanged();
                  },
                ),
                if (selectedInfo != null &&
                    !featured.contains(_country))
                  WaPillFilterChip(
                    label: selectedInfo['name']!,
                    selected: true,
                    selectedColor: WaUi.chipBg,
                    leading: Text(
                      selectedInfo['flag']!,
                      style: const TextStyle(fontSize: 14, height: 1),
                    ),
                    onTap: _pickCountry,
                  ),
                ...featured.map((code) {
                  final c = _countryInfo(code);
                  if (c == null) return const SizedBox.shrink();
                  return WaPillFilterChip(
                    label: c['name']!,
                    selected: _country == code,
                    selectedColor: WaUi.chipBg,
                    leading: Text(
                      c['flag']!,
                      style: const TextStyle(fontSize: 14, height: 1),
                    ),
                    onTap: () {
                      _country = code;
                      _onFilterChanged();
                    },
                  );
                }),
                WaPillFilterChip(
                  label: context.l10n.seeAll,
                  selected: false,
                  selectedColor: WaUi.chipBg,
                  leading: const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: WaUi.secondaryText,
                  ),
                  onTap: _pickCountry,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(context.l10n.categoryLabel, style: WaUi.label),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: [
                WaPillFilterChip(
                  label: context.l10n.all,
                  selected: _category == null,
                  selectedColor: WaUi.chipBg,
                  onTap: () {
                    _category = null;
                    _onFilterChanged();
                  },
                ),
                ...InvitationTemplateCatalog.categories.map((c) {
                  return WaPillFilterChip(
                    label: c['name']!,
                    selected: _category == c['id'],
                    selectedColor: WaUi.chipBg,
                    onTap: () {
                      _category = c['id'];
                      _onFilterChanged();
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _segment == 0
                  ? '${templates.length} templates'
                  : '${community.length} community templates',
              style: WaUi.listSubtitle,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.98, end: 1.0)
                        .animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_segment),
                child: _segment == 0
                    ? _OfficialGrid(
                        templates: templates,
                        onOpen: _openTemplate,
                        onBlank: _startBlank,
                      )
                    : _CommunityGrid(
                        templates: community,
                        loading: provider.loadingCommunity,
                        onOpen: _openCommunity,
                        onRefresh: _loadCommunity,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficialGrid extends StatelessWidget {
  final List<InvitationTemplate> templates;
  final void Function(InvitationTemplate) onOpen;
  final VoidCallback onBlank;

  const _OfficialGrid({
    required this.templates,
    required this.onOpen,
    required this.onBlank,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: WaUi.secondaryText),
            const SizedBox(height: 8),
            Text(context.l10n.noTemplatesForFilter, style: WaUi.listSubtitle),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onBlank,
              child: Text(context.l10n.startFromBlank),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
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
      return const Center(child: CircularProgressIndicator());
    }
    if (templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 48, color: WaUi.secondaryText),
              const SizedBox(height: 8),
              Text(
                context.l10n.noCommunityTemplatesYet,
                style: WaUi.sectionHeader,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.designAndPublishHint,
                style: WaUi.listSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRefresh,
                child: Text(context.l10n.refresh),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.58,
        ),
        itemCount: templates.length,
        itemBuilder: (context, i) {
          final t = templates[i];
          return _CommunityCard(template: t, onTap: () => onOpen(t));
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
    final design = template.build();
    final accent = invitationColorFromHex(template.accentColor);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InvitationDesignRenderer(
              design: design,
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            template.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: WaUi.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${template.countryCode} · ${template.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: WaUi.secondaryText,
                  ),
                ),
              ),
              if (template.rtl)
                Text(
                  context.l10n.rtl,
                  style: const TextStyle(
                    fontSize: 10,
                    color: WaUi.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final PublishedInvitationTemplate template;
  final VoidCallback onTap;

  const _CommunityCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InvitationDesignRenderer(
              design: template.design,
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            template.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: WaUi.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.templateByPublisherUses(
              template.publisher.displayName,
              template.useCount,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: WaUi.secondaryText),
          ),
        ],
      ),
    );
  }
}
