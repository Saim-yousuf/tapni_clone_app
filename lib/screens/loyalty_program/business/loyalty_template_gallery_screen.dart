import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/loyalty_card_design.dart';
import 'package:tapni_app/models/published_loyalty_template.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_design_editor_screen.dart';
import 'package:tapni_app/utils/loyalty_template_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';

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
  List<PublishedLoyaltyTemplate> _community = [];
  bool _loadingCommunity = false;

  List<LoyaltyTemplate> get _filtered =>
      LoyaltyTemplateCatalog.filter(category: _category);

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final preferAr = Localizations.localeOf(context).languageCode == 'ar';
    final templates = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text(
          context.l10n.chooseATemplate,
          style: WaUi.sectionHeader,
        ),
        actions: [
          TextButton(
            onPressed: _startBlank,
            child: Text(context.l10n.blank),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text(context.l10n.official),
                  icon: const Icon(Icons.star_outline, size: 16),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text(context.l10n.community),
                  icon: const Icon(Icons.people_outline, size: 16),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (s) {
                setState(() => _segment = s.first);
                if (_segment == 1) _loadCommunity();
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _Chip(
                  label: context.l10n.all,
                  selected: _category == null,
                  onTap: () {
                    _category = null;
                    _onFilterChanged();
                  },
                ),
                ...LoyaltyTemplateCatalog.categories.map((c) {
                  return _Chip(
                    label: preferAr ? (c['nameAr'] ?? c['name']!) : c['name']!,
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
          const SizedBox(height: 12),
          Expanded(
            child: _segment == 0
                ? _buildCurated(templates, preferAr)
                : _buildCommunity(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurated(List<LoyaltyTemplate> templates, bool preferAr) {
    if (templates.isEmpty) {
      return Center(child: Text(context.l10n.noLoyaltyTemplatesFound));
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
      itemBuilder: (_, i) {
        final t = templates[i];
        final design = t.build();
        return GestureDetector(
          onTap: () => _openTemplate(t),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LoyaltyCardDesignRenderer(
                  design: design,
                  borderRadius: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.displayName(preferAr),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WaUi.label.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunity() {
    if (_loadingCommunity) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_community.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.noCommunityTemplatesYet,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(color: WaUi.secondaryText),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.58,
      ),
      itemCount: _community.length,
      itemBuilder: (_, i) {
        final t = _community[i];
        return GestureDetector(
          onTap: () => _openCommunity(t),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: designColorFromHex(t.previewColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LoyaltyCardDesignRenderer(
                    design: t.design,
                    borderRadius: 14,
                    shadows: const [],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WaUi.label.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                t.publisher.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WaUi.caption.copyWith(color: WaUi.secondaryText),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: WaUi.chipSelected,
        backgroundColor: WaUi.surface,
        side: BorderSide(color: WaUi.chipBorder),
        labelStyle: WaUi.label.copyWith(
          color: WaUi.primaryText,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
