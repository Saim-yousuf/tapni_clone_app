import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/screens/business_website/business_presence_ui.dart';
import 'package:tapni_app/screens/business_website/business_website_settings_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_webview_screen.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/business_features.dart';
import 'package:tapni_app/utils/catalog_helper.dart' show catalogTypesMatch;
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/app_toast.dart';

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

  BusinessWebsiteCatalog? _catalog;
  WebsiteCategory? _category;
  WebsiteSubcategory? _subcategory;
  WebsiteTemplateSummary? _template;

  String get _websiteType => widget.websiteType;

  /// Explicit or empty — never invent a type for write-back.
  String get _resolvedBusinessType =>
      normalizeBusinessType(widget.businessType);

  @override
  void initState() {
    super.initState();
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
      // Hide categories / subcategories that have no template for this type.
      var subs = parsed.subcategories
          .where((s) => typedSubIds.contains(s.id))
          .toList();
      var cats = parsed.categories
          .where((c) => typedCatIds.contains(c.id))
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
          subs = subs.where((s) => matchedIds.contains(s.categoryId)).toList();
          final subIds = subs.map((s) => s.id).toSet();
          filtered = BusinessWebsiteCatalog(
            categories: cats,
            subcategories: subs,
            templates: typed
                .where((t) => subIds.contains(t.subcategoryId))
                .toList(),
          );
        }
      }

      filtered ??= BusinessWebsiteCatalog(
        categories: cats,
        subcategories: subs,
        templates: typed,
      );
    }
    setState(() {
      _catalog = filtered ?? parsed;
      _loading = false;
    });
    _applyKnownBusinessTypeDefaults();
  }

  /// Skip Retail/Hospitality picker when businessType already resolves it.
  void _applyKnownBusinessTypeDefaults() {
    final catalog = _catalog;
    if (catalog == null) return;
    if (_websiteType != 'products') return;
    if (_resolvedBusinessType != 'products' &&
        _resolvedBusinessType != 'stay') {
      return;
    }

    final cats = catalog.categories;
    if (cats.isEmpty) return;

    WebsiteCategory? category = _category;
    if (category == null) {
      if (cats.length == 1) {
        category = cats.first;
      } else {
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
    }
    if (category == null) return;

    final subs = catalog.subcategories
        .where((s) => s.categoryId == category!.id)
        .toList();
    WebsiteSubcategory? subcategory = _subcategory;
    if (subcategory == null && subs.length == 1) {
      subcategory = subs.first;
    }

    setState(() {
      _category = category;
      _subcategory = subcategory;
      // Skip category (and subcategory when unambiguous) → template style.
      if (subcategory != null) {
        _step = 2;
      } else {
        _step = 1;
      }
    });
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

  String get _ctaLabel {
    if (_step == 2) return 'Use Template';
    return 'Continue';
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _category != null;
      case 1:
        return _subcategory != null;
      case 2:
        return _template != null;
      default:
        return false;
    }
  }

  Future<void> _onContinue() async {
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }
    await _create();
  }

  Future<void> _previewTemplateSample(WebsiteTemplateSummary template) async {
    final res = await _repo.previewTemplateSample(
      templateId: template.id,
      asJson: true,
    );
    if (!mounted) return;
    if (!res.success) {
      showAppToast(
            context,
            res.message ?? 'Could not open sample',
            kind: AppToastKind.error,
          );
      return;
    }
    final preview = _repo.parsePreview(res.data);
    if (preview == null || preview.html.isEmpty) {
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

  bool get _businessTypeLocksCategory =>
      _websiteType == 'products' &&
      (_resolvedBusinessType == 'products' ||
          _resolvedBusinessType == 'stay');

  void _onBack() {
    if (_step > 0) {
      // Don't re-expose Retail/Hospitality when businessType already decided it.
      final minStep = _businessTypeLocksCategory && _category != null ? 1 : 0;
      final next = _step - 1;
      if (next < minStep) {
        Navigator.of(context).pop();
        return;
      }
      setState(() => _step = next);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BwPresenceScaffold(
      title: _title,
      onBack: _onBack,
      belowTitle: BwProgressBar(step: _step),
      bottom: BwBottomCta(
        label: _ctaLabel,
        loading: _creating,
        onPressed: _canContinue && !_creating ? _onContinue : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _loadCatalog)
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
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
        Text(
          'Choose a category for your $_typeLabel',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.15,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your profile name, bio, photo, and cover are used on the site.',
          style: TextStyle(fontSize: 15, color: AuthUi.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 28),
        const BwFieldLabel('Category'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return BwSelectCard(
              label: cat.name,
              icon: BwUi.categoryIcon(cat.name),
              selected: _category?.id == cat.id,
              onTap: () => setState(() {
                _category = cat;
                _subcategory = null;
                _template = null;
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypeStep() {
    final subs = _subsForCategory;
    final known = _resolvedBusinessType.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          known
              ? 'Pick a niche for your templates'
              : 'What type of business is this?',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.15,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _category?.name ?? '',
          style: const TextStyle(fontSize: 15, color: AuthUi.textSecondary),
        ),
        const SizedBox(height: 24),
        if (subs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text(
              'No business types for this category yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AuthUi.textSecondary),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final sub = subs[index];
              return BwSelectCard(
                label: sub.name,
                icon: BwUi.categoryIcon(sub.name),
                selected: _subcategory?.id == sub.id,
                onTap: () => setState(() {
                  _subcategory = sub;
                  _template = null;
                }),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStyleStep() {
    final templates = _templatesForSelection;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text(
          'Choose Style',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.15,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick a template. You can customize content and colors later.',
          style: TextStyle(fontSize: 15, color: AuthUi.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 24),
        if (templates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              _subcategory == null
                  ? 'Select a business type to see templates.'
                  : 'No templates for ${_subcategory!.name} yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AuthUi.textSecondary),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: templates.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) {
              final t = templates[index];
              final selected = _template?.id == t.id;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? Colors.black : BwUi.cardBorder,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _template = t),
                        child: t.thumbnail.isNotEmpty
                            ? Image.network(
                                t.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _thumbFallback(),
                              )
                            : _thumbFallback(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _template = t),
                            child: Text(
                              t.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _previewTemplateSample(t),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    side: const BorderSide(
                                      color: BwUi.cardBorder,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sample',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () =>
                                      setState(() => _template = t),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: selected
                                        ? Colors.black
                                        : const Color(0xFF111111),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: Text(
                                    selected ? 'Selected' : 'Select',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _thumbFallback() {
    return Container(
      color: BwUi.iconTileBg,
      child: const Center(
        child: Icon(Icons.web_asset, size: 36, color: Colors.black54),
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
