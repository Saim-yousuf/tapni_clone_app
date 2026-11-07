import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/screens/business_website/business_presence_ui.dart';
import 'package:tapni_app/screens/business_website/business_website_settings_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_webview_screen.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/business_features.dart';
import 'package:tapni_app/utils/catalog_helper.dart' show catalogTypesMatch;
import 'package:tapni_app/utils/release_features.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/app_toast.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Maps Links catalogType → websiteType.
String websiteTypeFromCatalogType(String? catalogType) {
  switch ((catalogType ?? 'menu').toLowerCase().trim()) {
    case 'services':
    case 'service':
      return 'service';
    case 'products':
    case 'product':
      return 'products';
    case 'portfolio':
      return 'portfolio';
    case 'catalog':
    case 'menu':
    default:
      return 'menu';
  }
}

String catalogTypeFromWebsiteType(String websiteType) {
  switch (websiteType) {
    case 'service':
      return 'services';
    case 'products':
      return 'products';
    case 'portfolio':
      return 'portfolio';
    case 'menu':
    default:
      return 'menu';
  }
}

/// Setup: category → subcategory → template (filtered by [websiteType]).
/// Name, bio, logo, and cover always come from the BarQody profile.
///
/// When [businessType] is already known (`products` / `stay`), Retail vs
/// Hospitality website categories are filtered / auto-selected so My Website
/// does not re-ask the registration choice. Never writes businessType here.
class BusinessWebsiteSetupScreen extends StatefulWidget {
  final LinkTemplate? linkTemplate;
  final String websiteType;

  /// User capability pack: restaurant|products|services|stay|portfolio.
  /// Independent of [websiteType] (menu|products|service|portfolio).
  final String? businessType;

  const BusinessWebsiteSetupScreen({
    super.key,
    this.linkTemplate,
    this.websiteType = 'menu',
    this.businessType,
  });

  @override
  State<BusinessWebsiteSetupScreen> createState() =>
      _BusinessWebsiteSetupScreenState();
}

class _BusinessWebsiteSetupScreenState
    extends State<BusinessWebsiteSetupScreen> {
  final _repo = BusinessWebsiteRepo();

  int _step = 0;
  bool _loading = true;
  bool _creating = false;
  String? _error;
  /// True when category was auto-picked (known business type / single option).
  bool _categoryStepSkipped = false;
  /// True when niche/subcategory was auto-picked (only one option).
  bool _subcategoryStepSkipped = false;

  BusinessWebsiteCatalog? _catalog;
  WebsiteCategory? _category;
  WebsiteSubcategory? _subcategory;
  WebsiteTemplateSummary? _template;

  /// Blocks row select after closing sample (ghost tap on the list item).
  bool _blockTemplateSelect = false;

  String get _websiteType => widget.websiteType;

  /// Explicit or empty — never invent a type for write-back.
  String get _resolvedBusinessType =>
      normalizeBusinessType(widget.businessType);

  @override
  void initState() {
    super.initState();
    if (!ReleaseFeatures.canOpenPublicWebsiteType(_websiteType)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return;
    }
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.getCatalog(websiteType: _websiteType);
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load catalog';
      });
      return;
    }
    final parsed = _repo.parseCatalog(res.data);
    BusinessWebsiteCatalog? filtered;
    if (parsed != null) {
      // Only this websiteType — never fall back to other types.
      final typed = parsed.templates
          .where((t) => t.templateType == _websiteType)
          .toList();
      final typedSubIds = typed
          .map((t) => t.subcategoryId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      final typedCatIds = typed
          .map((t) => t.categoryId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      // Categories that actually have templates for this website type.
      var cats = parsed.categories
          .where((c) => typedCatIds.contains(c.id))
          .toList();

      // Niches: menu keeps every subcategory under those categories so the
      // niche step still appears (Cafe / Restaurant / …) even if only one
      // niche currently has a template. Other types stay template-gated.
      var subs = _websiteType == 'menu'
          ? parsed.subcategories
              .where((s) => cats.any((c) => c.id == s.categoryId))
              .toList()
          : parsed.subcategories
              .where((s) => typedSubIds.contains(s.id))
              .toList();

      // Products websiteType serves both Products and Stay packs.
      // When businessType is known, keep only the matching industry category.
      if (_websiteType == 'products' &&
          (_resolvedBusinessType == 'products' ||
              _resolvedBusinessType == 'stay')) {
        final matched = cats
            .where(
              (c) => websiteCategoryMatchesBusinessType(
                c.name,
                _resolvedBusinessType,
              ),
            )
            .toList();
        if (matched.isNotEmpty) {
          final matchedIds = matched.map((c) => c.id).toSet();
          cats = matched;
          subs = parsed.subcategories
              .where((s) => matchedIds.contains(s.categoryId))
              .toList();
          filtered = BusinessWebsiteCatalog(
            categories: cats,
            subcategories: subs,
            templates: typed,
          );
        }
      }

      filtered ??= BusinessWebsiteCatalog(
        categories: cats,
        subcategories: subs,
        templates: typed,
      );
    }

    final catalog = filtered ?? parsed;
    // Resolve skips before first paint so progress never flashes 3 steps.
    final defaults = _resolveKnownBusinessTypeDefaults(catalog);
    final noTemplates = (catalog?.templates.isEmpty ?? true);
    final noCategories = (catalog?.categories.isEmpty ?? true);

    setState(() {
      _catalog = catalog;
      if (defaults != null) {
        _category = defaults.category;
        _subcategory = defaults.subcategory;
        _categoryStepSkipped = true;
        _subcategoryStepSkipped = defaults.skipSubcategory;
        _step = defaults.skipSubcategory ? 2 : 1;
      } else if (noCategories || noTemplates) {
        // Empty catalog must not strand on a blank category picker.
        _category = null;
        _subcategory = null;
        _categoryStepSkipped = true;
        _subcategoryStepSkipped = true;
        _step = 2;
        _error = noTemplates
            ? 'No $_typeLabel templates are available yet. Add templates in admin, then try again.'
            : null;
      } else {
        _category = null;
        _subcategory = null;
        _categoryStepSkipped = false;
        _subcategoryStepSkipped = false;
        _step = 0;
      }
      _template = null;
      _loading = false;
    });
  }

  /// Auto-pick category / niche when unambiguous. Null = show step 0.
  _SetupDefaults? _resolveKnownBusinessTypeDefaults(
    BusinessWebsiteCatalog? catalog,
  ) {
    if (catalog == null) return null;

    final cats = catalog.categories;
    if (cats.isEmpty) return null;

    WebsiteCategory? category;
    if (cats.length == 1) {
      category = cats.first;
    } else if (_resolvedBusinessType.isNotEmpty) {
      final matched = cats
          .where(
            (c) => websiteCategoryMatchesBusinessType(
              c.name,
              _resolvedBusinessType,
            ),
          )
          .toList();
      if (matched.length == 1) category = matched.first;
    }
    if (category == null) return null;

    final shouldSkipCategory = cats.length == 1 ||
        (_resolvedBusinessType.isNotEmpty &&
            websiteCategoryMatchesBusinessType(
              category.name,
              _resolvedBusinessType,
            ));
    if (!shouldSkipCategory) return null;

    // Always show niche step — never auto-skip to style when category is known.
    // (One template under Restaurant used to hide Cafe / Ice Cream entirely.)
    return _SetupDefaults(
      category: category,
      subcategory: null,
      skipSubcategory: false,
    );
  }

  /// Internal steps that are still shown to the user.
  List<int> get _visibleSteps {
    final steps = <int>[];
    if (!_categoryStepSkipped) steps.add(0);
    if (!_subcategoryStepSkipped) steps.add(1);
    steps.add(2); // style is always shown
    return steps;
  }

  int get _progressTotal => _visibleSteps.length;

  int get _progressStep {
    final idx = _visibleSteps.indexOf(_step);
    return idx < 0 ? 0 : idx;
  }

  int get _minStep {
    if (_subcategoryStepSkipped) return 2;
    if (_categoryStepSkipped) return 1;
    return 0;
  }

  List<WebsiteSubcategory> get _subsForCategory {
    final cat = _category;
    final catalog = _catalog;
    if (cat == null || catalog == null) return const [];
    return catalog.subcategories.where((s) => s.categoryId == cat.id).toList();
  }

  /// Strict: only templates assigned to the selected subcategory.
  List<WebsiteTemplateSummary> get _templatesForSelection {
    final catalog = _catalog;
    final sub = _subcategory;
    if (catalog == null || sub == null) return const [];
    return catalog.templates
        .where((t) => t.subcategoryId == sub.id)
        .toList();
  }

  String get _typeLabel {
    switch (_websiteType) {
      case 'service':
        return 'Services';
      case 'products':
        return 'Products';
      case 'portfolio':
        return 'Portfolio';
      case 'menu':
      default:
        return 'Menu';
    }
  }

  String get _title {
    switch (_step) {
      case 0:
        return 'Create $_typeLabel';
      case 1:
        // Website pack niche — not User.businessType re-selection.
        return _resolvedBusinessType.isNotEmpty ? 'Choose niche' : 'Business type';
      case 2:
        return 'Choose style';
      default:
        return 'Create $_typeLabel';
    }
  }

  Future<void> _goNextStep() async {
    if (_creating) return;
    final visible = _visibleSteps;
    final idx = visible.indexOf(_step);
    final nextIdx = idx < 0 ? 0 : idx + 1;
    if (nextIdx < visible.length) {
      // Brief beat so select animation is visible before the step swap.
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted || _creating) return;
      setState(() => _step = visible[nextIdx]);
      return;
    }
    await _create();
  }

  Future<void> _pickAndAdvance(VoidCallback applySelection) async {
    if (_creating || _blockTemplateSelect) return;
    HapticFeedback.selectionClick();
    setState(applySelection);
    await _goNextStep();
  }

  Future<void> _previewTemplateSample(WebsiteTemplateSummary template) async {
    // View sample must never select / advance the template step.
    _blockTemplateSelect = true;
    final res = await _repo.previewTemplateSample(
      templateId: template.id,
      asJson: true,
    );
    if (!mounted) return;
    if (!res.success) {
      _blockTemplateSelect = false;
      showAppToast(
            context,
            res.message ?? 'Could not open sample',
            kind: AppToastKind.error,
          );
      return;
    }
    final preview = _repo.parsePreview(res.data);
    if (preview == null || preview.html.isEmpty) {
      _blockTemplateSelect = false;
      showAppToast(
            context,
            'Sample preview was empty',
            kind: AppToastKind.warning,
          );
      return;
    }
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => BusinessWebsiteWebViewScreen(
          html: preview.html,
          title: '${template.name} sample',
          previewMode: true,
          sampleDemoPreview: true,
        ),
      ),
    );
    if (!mounted) return;
    // Absorb residual tap that would otherwise hit the row InkWell.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) _blockTemplateSelect = false;
  }

  Future<void> _create() async {
    final category = _category;
    final subcategory = _subcategory;
    final template = _template;
    if (category == null || subcategory == null || template == null) return;

    setState(() => _creating = true);
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final catalogType = catalogTypeFromWebsiteType(_websiteType);

    // Prefer an existing catalog link of this type so items stay in one place.
    String? catalogLinkId;
    for (final link in provider.profile.socialLinks) {
      if (link.isCatalogLink &&
          catalogTypesMatch(link.catalogType, catalogType) &&
          link.id.isNotEmpty) {
        catalogLinkId = link.id;
        break;
      }
    }

    // Name / description come from profile on the server (not asked here).
    final res = await _repo.createWebsite(
      categoryId: category.id,
      subcategoryId: subcategory.id,
      templateId: template.id,
      websiteType: _websiteType,
      catalogLinkId: catalogLinkId,
    );
    if (!mounted) return;
    setState(() => _creating = false);

    if (!res.success) {
      showAppToast(
            context,
            res.message ?? 'Could not create website',
            kind: AppToastKind.error,
          );
      return;
    }

    final website = _repo.parseWebsite(res.data);
    if (website == null) {
      showAppToast(
            context,
            'Website created but failed to load',
            kind: AppToastKind.error,
          );
      return;
    }

    await provider.addBusinessWebsiteLink(
      template: widget.linkTemplate,
      publicUrl: website.resolvedPublicUrl,
      context: context,
      websiteType: _websiteType,
      catalogType: catalogType,
      // New sites start as draft — hide from public profile until published.
      isPublic: website.isPublished,
    );
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      AppPageRoute(
        builder: (_) => BusinessWebsiteSettingsScreen(
          initialWebsite: website,
          linkTemplate: widget.linkTemplate,
        ),
      ),
    );
  }

  void _onBack() {
    if (_step > _minStep) {
      // Jump back only across visible steps (skip auto-filled ones).
      final visible = _visibleSteps;
      final idx = visible.indexOf(_step);
      if (idx <= 0) {
        Navigator.of(context).pop();
        return;
      }
      setState(() => _step = visible[idx - 1]);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BwPresenceScaffold(
      title: _title,
      onBack: _onBack,
      belowTitle: (_loading || _creating)
          ? null
          : BwProgressBar(
              step: _progressStep,
              total: _progressTotal,
            ),
      body: _loading || _creating
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _loadCatalog)
              : AppContentSwitcher(
                  duration: AppMotion.content,
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      'setup-step-$_step-$_progressTotal',
                    ),
                    child: _buildStep(),
                  ),
                ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildCreateStep();
      case 1:
        return _buildTypeStep();
      case 2:
        return _buildStyleStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCreateStep() {
    final categories = _catalog?.categories ?? const <WebsiteCategory>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        AppAppear(
          index: 0,
          child: Text(
            'Choose a category for your $_typeLabel',
            style: WaUi.toolsTitleOf(
              size: 26,
              weight: FontWeight.w700,
              color: AuthUi.textPrimary,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppAppear(
          index: 1,
          child: Text(
            'Your profile name, bio, photo, and cover are used on the site.',
            style: WaUi.body.copyWith(
              fontSize: 14,
              color: AuthUi.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          AppAppear(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'No categories with $_typeLabel templates yet.',
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(color: AuthUi.textSecondary),
              ),
            ),
          )
        else
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
            AppAppear(
              index: i + 2,
              maxStagger: 12,
              child: _OptionRow(
                label: categories[i].name,
                icon: BwUi.categoryIcon(categories[i].name),
                selected: _category?.id == categories[i].id,
                onTap: () => _pickAndAdvance(() {
                  _category = categories[i];
                  _subcategory = null;
                  _template = null;
                }),
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildTypeStep() {
    final subs = _subsForCategory;
    final known = _resolvedBusinessType.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        AppAppear(
          index: 0,
          child: Text(
            known
                ? 'Pick a niche for your templates'
                : 'What type of business is this?',
            style: WaUi.toolsTitleOf(
              size: 26,
              weight: FontWeight.w700,
              color: AuthUi.textPrimary,
              height: 1.2,
            ),
          ),
        ),
        if ((_category?.name ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          AppAppear(
            index: 1,
            child: Text(
              _category!.name,
              style: WaUi.body.copyWith(
                fontSize: 14,
                color: AuthUi.textSecondary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (subs.isEmpty)
          AppAppear(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'No business types for this category yet.',
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(color: AuthUi.textSecondary),
              ),
            ),
          )
        else
          for (var i = 0; i < subs.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
            AppAppear(
              index: i + 2,
              maxStagger: 12,
              child: _OptionRow(
                label: subs[i].name,
                icon: BwUi.categoryIcon(subs[i].name),
                selected: _subcategory?.id == subs[i].id,
                onTap: () => _pickAndAdvance(() {
                  _subcategory = subs[i];
                  _template = null;
                }),
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildStyleStep() {
    final templates = _templatesForSelection;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        AppAppear(
          index: 0,
          child: Text(
            'Choose Style',
            style: WaUi.toolsTitleOf(
              size: 26,
              weight: FontWeight.w700,
              color: AuthUi.textPrimary,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppAppear(
          index: 1,
          child: Text(
            'Pick a template. You can customize content and colors later.',
            style: WaUi.body.copyWith(
              fontSize: 14,
              color: AuthUi.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (templates.isEmpty)
          AppAppear(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                (_catalog?.templates.isEmpty ?? true)
                    ? 'No $_typeLabel templates are available yet.'
                    : _subcategory == null
                        ? 'Select a business type to see templates.'
                        : 'No templates for ${_subcategory!.name} yet.',
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(color: AuthUi.textSecondary),
              ),
            ),
          )
        else
          for (var i = 0; i < templates.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE8E8E8),
              ),
            AppAppear(
              index: i + 2,
              maxStagger: 10,
              child: _TemplateRow(
                template: templates[i],
                selected: _template?.id == templates[i].id,
                onSelect: () => _pickAndAdvance(() {
                  _template = templates[i];
                }),
                onSample: () => _previewTemplateSample(templates[i]),
              ),
            ),
          ],
      ],
    );
  }
}

class _SetupDefaults {
  final WebsiteCategory category;
  final WebsiteSubcategory? subcategory;
  final bool skipSubcategory;

  const _SetupDefaults({
    required this.category,
    required this.subcategory,
    required this.skipSubcategory,
  });
}

class _OptionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.content,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.content,
              curve: AppMotion.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? Colors.black : BarqodyChrome.searchBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AuthUi.textPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: WaUi.body.copyWith(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AuthUi.textPrimary,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: AppMotion.content,
              switchInCurve: AppMotion.easeOut,
              switchOutCurve: AppMotion.easeIn,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                key: ValueKey(selected),
                size: 24,
                color: selected ? Colors.black : BarqodyChrome.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  final WebsiteTemplateSummary template;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onSample;

  const _TemplateRow({
    required this.template,
    required this.selected,
    required this.onSelect,
    required this.onSample,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = AnimatedScale(
      scale: selected ? 1.05 : 1,
      duration: AppMotion.content,
      curve: AppMotion.easeOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 56,
          height: 72,
          child: template.thumbnail.isNotEmpty
              ? Image.network(
                  template.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFFF2F2F7),
                    child: Icon(Icons.web_asset, color: Colors.black54),
                  ),
                )
              : const ColoredBox(
                  color: Color(0xFFF2F2F7),
                  child: Icon(Icons.web_asset, color: Colors.black54),
                ),
        ),
      ),
    );

    final check = AnimatedSwitcher(
      duration: AppMotion.content,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeIn,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        key: ValueKey(selected),
        size: 24,
        color: selected ? Colors.black : BarqodyChrome.secondaryText,
      ),
    );

    return AnimatedContainer(
      duration: AppMotion.content,
      curve: AppMotion.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: selected
            ? Colors.black.withValues(alpha: 0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSelect,
              borderRadius: BorderRadius.circular(12),
              child: thumb,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSelect,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              template.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WaUi.body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AuthUi.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          check,
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                TextButton(
                  onPressed: onSample,
                  style: TextButton.styleFrom(
                    foregroundColor: AuthUi.textSecondary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    'View sample',
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AuthUi.textSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: AuthUi.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AuthUi.textSecondary),
            ),
            const SizedBox(height: 16),
            AuthPrimaryPillButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
