import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/screens/business_website/business_presence_ui.dart';
import 'package:tapni_app/screens/business_website/business_website_customize_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_hours_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_ordering_screen.dart';
import 'package:tapni_app/screens/business_website/business_website_setup_guide_sheet.dart';
import 'package:tapni_app/screens/business_website/business_website_setup_screen.dart'
    show catalogTypeFromWebsiteType;
import 'package:tapni_app/screens/business_website/business_website_webview_screen.dart';
import 'package:tapni_app/screens/orders/orders_list_screen.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/catalog_helper.dart' show catalogTypesMatch;
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/menu_catalog_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tapni_app/widgets/app_toast.dart';

// ignore_for_file: deprecated_member_use

/// Typed website hub — Menu (catalog) + Settings.
class BusinessWebsiteSettingsScreen extends StatefulWidget {
  final BusinessWebsite? initialWebsite;
  final LinkTemplate? linkTemplate;

  const BusinessWebsiteSettingsScreen({
    super.key,
    this.initialWebsite,
    this.linkTemplate,
  });

  @override
  State<BusinessWebsiteSettingsScreen> createState() =>
      _BusinessWebsiteSettingsScreenState();
}

class _BusinessWebsiteSettingsScreenState
    extends State<BusinessWebsiteSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = BusinessWebsiteRepo();

  late TabController _tabs;
  BusinessWebsite? _website;
  BusinessWebsiteCatalog? _catalog;

  bool _loading = true;
  bool _togglingStatus = false;
  String? _error;
  int _menuReloadToken = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _website = widget.initialWebsite;
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final type = widget.initialWebsite?.websiteType;
    final id = widget.initialWebsite?.id;
    final mineRes = await _repo.getMine(
      websiteType: type,
      websiteId: id,
    );
    if (!mounted) return;
    if (!mineRes.success) {
      setState(() {
        _loading = false;
        _error = mineRes.message ?? 'Could not load website';
      });
      return;
    }

    final website = _repo.parseWebsite(mineRes.data) ?? widget.initialWebsite;
    if (website == null) {
      setState(() {
        _loading = false;
        _error = 'No business website yet';
      });
      return;
    }

    final catalogRes = await _repo.getCatalog(websiteType: website.websiteType);
    if (!mounted) return;

    setState(() {
      _website = website;
      _catalog =
          catalogRes.success ? _repo.parseCatalog(catalogRes.data) : null;
      _loading = false;
      _menuReloadToken++;
    });
  }

  Future<void> _syncProfileLink(BusinessWebsite website) async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    await provider.addBusinessWebsiteLink(
      template: widget.linkTemplate,
      publicUrl: website.resolvedPublicUrl,
      context: context,
      websiteType: website.websiteType,
      catalogType: website.catalogType,
      // Draft / unpublished must not appear on public profiles.
      isPublic: website.isPublished,
    );
  }

  String get _tabMenuLabel {
    switch (_website?.websiteType) {
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

  String get _catalogLabel {
    switch (_website?.websiteType) {
      case 'service':
        return 'Services';
      case 'products':
        return 'Products';
      case 'portfolio':
        return 'Portfolio';
      case 'menu':
      default:
        return widget.linkTemplate?.label.isNotEmpty == true
            ? widget.linkTemplate!.label
            : 'Menu';
    }
  }

  String get _typeNoun {
    switch (_website?.websiteType) {
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

  /// Same rules as website render: inventory for this catalog type only.
  /// Never borrow menu/products/services items for another type.
  SocialLink? _resolveCatalogInventoryLink({
    required List<SocialLink> links,
    required String catalogType,
    String catalogLinkId = '',
  }) {
    SocialLink? bestOf(Iterable<SocialLink> candidates) {
      SocialLink? best;
      for (final link in candidates) {
        if (!link.isCatalogLink) continue;
        if (!catalogTypesMatch(link.catalogType, catalogType)) continue;
        final count = link.catalogItems?.length ?? 0;
        final bestCount = best?.catalogItems?.length ?? -1;
        if (best == null || count > bestCount) best = link;
      }
      return best;
    }

    SocialLink? byId;
    if (catalogLinkId.isNotEmpty) {
      for (final link in links) {
        if (link.id == catalogLinkId &&
            link.isCatalogLink &&
            catalogTypesMatch(link.catalogType, catalogType)) {
          byId = link;
          break;
        }
      }
    }

    final byType = bestOf(links);

    final byIdCount = byId?.catalogItems?.length ?? 0;
    final byTypeCount = byType?.catalogItems?.length ?? 0;
    if (byType != null && byTypeCount > byIdCount) return byType;
    if (byId != null) return byId;
    return byType;
  }

  Future<void> _rebindCatalogAfterSave() async {
    final website = _website;
    if (website == null || !mounted) return;
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final catalogType = catalogTypeFromWebsiteType(website.websiteType);
    final linked = _resolveCatalogInventoryLink(
      links: provider.profile.socialLinks,
      catalogType: catalogType,
      catalogLinkId: website.catalogLinkId,
    );
    // Bind only same-type inventory; clear stale cross-type ids (e.g. menu → portfolio).
    final nextId = linked?.id ?? '';
    if (nextId != website.catalogLinkId) {
      final res = await _repo.updateWebsite(
        {'catalogLinkId': nextId},
        websiteId: website.id,
        websiteType: website.websiteType,
      );
      if (!mounted) return;
      final updated = res.success ? _repo.parseWebsite(res.data) : null;
      if (updated != null) setState(() => _website = updated);
    }
    setState(() => _menuReloadToken++);
  }

  Future<void> _preview() async {
    final website = _website;
    if (website == null) return;

    if (website.isPublished) {
      await Navigator.of(context).push(
        AppPageRoute(
          builder: (_) => BusinessWebsiteWebViewScreen(
            url: website.resolvedPublicUrl,
            title: 'Live Preview',
            previewMode: true,
          ),
        ),
      );
      return;
    }

    final res = await _repo.previewMine(
      websiteId: website.id,
      websiteType: website.websiteType,
    );
    if (!mounted) return;
    if (!res.success) {
      showAppToast(
            context,
            res.message ?? 'Could not load preview',
            kind: AppToastKind.error,
          );
      return;
    }
    final preview = _repo.parsePreview(res.data);
    if (preview == null || preview.html.isEmpty) {
      showAppToast(
            context,
            'Preview was empty',
            kind: AppToastKind.warning,
          );
      return;
    }
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => BusinessWebsiteWebViewScreen(
          html: preview.html,
          title: 'Live Preview',
          previewMode: true,
        ),
      ),
    );
  }

  Future<void> _sharePublicLink() async {
    final website = _website;
    if (website == null) return;
    if (!website.isPublished) {
      final publish = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Publish to share'),
          content: const Text(
            'Turn Status on so anyone with the link can open it in a browser.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Publish & share'),
            ),
          ],
        ),
      );
      if (publish != true) return;
      await _setPublished(true);
      if (!mounted || _website?.isPublished != true) return;
    }
    final name = Provider.of<ProfileProvider>(context, listen: false)
            .profile
            .businessName
            ?.trim()
            .isNotEmpty ==
        true
        ? Provider.of<ProfileProvider>(context, listen: false)
            .profile
            .businessName!
        : Provider.of<ProfileProvider>(context, listen: false).profile.name;
    await Share.share(
      'Visit $name: ${_website!.resolvedPublicUrl}',
      subject: name,
    );
  }

  Future<void> _openInBrowser() async {
    final website = _website;
    if (website == null) return;
    if (!website.isPublished) {
      showAppToast(
            context,
            'Turn Status on so the public link works in any browser',
            kind: AppToastKind.info,
          );
      return;
    }
    final uri = Uri.tryParse(website.resolvedPublicUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool get _isMenuSite =>
      (_website?.websiteType ?? widget.initialWebsite?.websiteType ?? 'menu')
          .toLowerCase() ==
      'menu';

  int _activeMenuItemCount() {
    final website = _website;
    if (website == null || !mounted) return 0;
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final linked = _resolveCatalogInventoryLink(
      links: provider.profile.socialLinks,
      catalogType: catalogTypeFromWebsiteType(website.websiteType),
      catalogLinkId: website.catalogLinkId,
    );
    final items = linked?.catalogItems ?? const [];
    return items
        .where((i) => i.isActive && i.name.trim().isNotEmpty)
        .length;
  }

  Future<void> _setPublished(bool published) async {
    if (_togglingStatus) return;
    if (published && _isMenuSite && _activeMenuItemCount() < 1) {
      showAppToast(
        context,
        'Add menu items before publishing your website.',
        kind: AppToastKind.warning,
      );
      return;
    }
    setState(() => _togglingStatus = true);
    final res = await _repo.updateWebsite(
      {'status': published ? 'published' : 'unpublished'},
      websiteId: _website?.id,
      websiteType: _website?.websiteType,
    );
    if (!mounted) return;
    setState(() => _togglingStatus = false);
    if (!res.success) {
      showAppToast(
            context,
            res.message ?? 'Could not update status',
            kind: AppToastKind.error,
          );
      return;
    }
    final website = _repo.parseWebsite(res.data);
    if (website != null) {
      setState(() => _website = website);
      await _syncProfileLink(website);
    }
  }

  Future<void> _setOrdersPaused(bool paused) async {
    final website = _website;
    if (website == null) return;
    final next = website.ordering.copyWith(ordersPaused: paused);
    final res = await _repo.updateWebsite(
      {'ordering': next.toJson()},
      websiteId: website.id,
      websiteType: website.websiteType,
    );
    if (!mounted) return;
    if (!res.success) {
      showAppToast(
        context,
        res.message ?? 'Could not update pause',
        kind: AppToastKind.error,
      );
      return;
    }
    final updated = _repo.parseWebsite(res.data);
    setState(() {
      _website = updated ?? website.copyWith(ordering: next);
    });
  }

  Future<void> _openHours() async {
    final website = _website;
    if (website == null) return;
    final result = await Navigator.of(context).push<BusinessWebsite>(
      AppPageRoute(
        builder: (_) => BusinessWebsiteHoursScreen(website: website),
      ),
    );
    if (result != null && mounted) {
      setState(() => _website = result);
    }
  }

  Future<void> _openOrdering() async {
    final website = _website;
    if (website == null) return;
    final result = await Navigator.of(context).push<BusinessWebsite>(
      AppPageRoute(
        builder: (_) => BusinessWebsiteOrderingScreen(website: website),
      ),
    );
    if (result != null && mounted) {
      setState(() => _website = result);
    }
  }

  void _openOrdersInbox() {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => const OrdersListScreen(isBusinessView: true),
      ),
    );
  }

  Future<void> _deleteWebsite() async {
    final website = _website;
    if (website == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $_tabMenuLabel?'),
        content: Text(
          'If you delete this, your $_typeNoun website, all items, categories, '
          'and template settings will be permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete everything',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final res = await _repo.deleteWebsite(
      websiteId: website.id,
      websiteType: website.websiteType,
    );
    if (!mounted) return;
    if (!res.success) {
      showAppToast(
            context,
            res.message ?? 'Could not delete website',
            kind: AppToastKind.error,
          );
      return;
    }

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final catalogType = catalogTypeFromWebsiteType(website.websiteType);
    // Remove website tile + any leftover catalog inventory of this type.
    final cleaned = provider.profile.socialLinks
        .where(
          (link) => !(
              (link.isBusinessWebsiteLink || link.isCatalogLink) &&
              catalogTypesMatch(link.catalogType, catalogType)),
        )
        .toList();
    if (cleaned.length != provider.profile.socialLinks.length) {
      await provider.updateLinks(links: cleaned, context: context);
    }
    if (!mounted) return;
    showAppToast(
          context,
          '$_tabMenuLabel deleted',
          kind: AppToastKind.success,
        );
    Navigator.of(context).pop();
  }

  String? _templateDefaultThemeColor(BusinessWebsite website) {
    final catalog = _catalog;
    if (catalog != null) {
      for (final t in catalog.templates) {
        if (t.id == website.templateId && t.defaultThemeColor.isNotEmpty) {
          return t.defaultThemeColor;
        }
      }
    }
    return website.design.themeColor;
  }

  Future<void> _openCustomize() async {
    final website = _website;
    if (website == null) return;
    final updated = await Navigator.of(context).push<BusinessWebsite>(
      AppPageRoute(
        builder: (_) => BusinessWebsiteCustomizeScreen(
          website: website,
          templateDefaultThemeColor: _templateDefaultThemeColor(website),
        ),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() => _website = updated);
    } else {
      // Reload in case preview-only session left no pop value but save happened.
      final res = await _repo.getMine(
        websiteType: website.websiteType,
        websiteId: website.id,
      );
      if (!mounted) return;
      final fresh = res.success ? _repo.parseWebsite(res.data) : null;
      if (fresh != null) setState(() => _website = fresh);
    }
  }

  Future<void> _changeTemplate() async {
    final catalog = _catalog;
    final website = _website;
    if (catalog == null || website == null) return;

    // Only templates for this site's subcategory (never other categories).
    var templates = catalog.templates
        .where((t) => t.templateType == website.websiteType)
        .toList();
    final subId = website.subcategoryId;
    if (subId != null && subId.isNotEmpty) {
      templates =
          templates.where((t) => t.subcategoryId == subId).toList();
    } else {
      final catId = website.categoryId;
      if (catId != null && catId.isNotEmpty) {
        templates =
            templates.where((t) => t.categoryId == catId).toList();
      }
    }
    if (templates.isEmpty) {
      showAppToast(
            context,
            'No templates for this business type',
            kind: AppToastKind.info,
          );
      return;
    }

    final selected = await Navigator.of(context).push<WebsiteTemplateSummary>(
      AppPageRoute(
        builder: (_) => _TemplateChooserScreen(
          templates: templates,
          currentTemplateId: website.templateId,
          typeLabel: _tabMenuLabel,
          onPreviewSample: _previewTemplateSample,
        ),
      ),
    );
    if (selected == null || selected.id == website.templateId) return;

    final res = await _repo.updateWebsite(
      {'templateId': selected.id},
      websiteId: website.id,
      websiteType: website.websiteType,
    );
    if (!mounted) return;
    if (!res.success) {
      showAppToast(
            context,
            res.message ?? 'Could not switch template',
            kind: AppToastKind.error,
          );
      return;
    }
    final updated = _repo.parseWebsite(res.data);
    if (updated != null) setState(() => _website = updated);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwUi.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Business Presence',
              onBack: () => Navigator.of(context).pop(),
            ),
            _buildTabs(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AuthUi.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AuthPrimaryPillButton(
                                  label: 'Retry',
                                  onPressed: _loadAll,
                                ),
                              ],
                            ),
                          ),
                        )
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            _buildMenuTab(),
                            _buildSettingsTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabs,
        labelColor: Colors.black,
        unselectedLabelColor: const Color(0xFF9CA3AF),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        indicatorColor: Colors.black,
        indicatorWeight: 3,
        tabs: [
          Tab(text: _tabMenuLabel),
          const Tab(text: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    final website = _website;
    if (website == null) return const SizedBox.shrink();
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final catalogType = catalogTypeFromWebsiteType(website.websiteType);
    final existing = _resolveCatalogInventoryLink(
      links: provider.profile.socialLinks,
      catalogType: catalogType,
      catalogLinkId: website.catalogLinkId,
    );

    return MenuCatalogSheet(
      key: ValueKey('menu-tab-$_menuReloadToken-${existing?.id ?? 'new'}'),
      catalogLabel: _catalogLabel,
      catalogType: catalogType,
      provider: provider,
      existingLink: existing,
      template: widget.linkTemplate,
      embedded: true,
      onSaved: () {
        _rebindCatalogAfterSave();
      },
    );
  }

  Future<void> _openSetupGuide() {
    return showBusinessWebsiteSetupGuide(
      context,
      websiteType: _website?.websiteType ?? 'menu',
      openAudience: GuideAudience.business,
    );
  }

  Widget _buildSettingsTab() {
    final w = _website!;
    final isPublic = w.isPublished;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: _openSetupGuide,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BwUi.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: BwUi.iconTileBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.route_outlined,
                      color: Colors.black,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business guide',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'How this website works — go live, catalog, orders, stamps',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: AuthUi.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.black54),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Public when on · private when off',
                          style: TextStyle(
                            fontSize: 13,
                            color: AuthUi.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_togglingStatus)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  else
                    Switch.adaptive(
                      value: isPublic,
                      activeColor: Colors.black,
                      onChanged: (v) => _setPublished(v),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: BwUi.cardBorder),
            _rowTile(
              title: 'Customize Website',
              subtitle: 'Theme color, headline & branding',
              onTap: _openCustomize,
            ),
            const Divider(height: 1, color: BwUi.cardBorder),
            _rowTile(
              title: 'Template',
              subtitle: w.templateName ?? 'Choose a template',
              onTap: _changeTemplate,
            ),
            const Divider(height: 1, color: BwUi.cardBorder),
            _rowTile(
              title: 'Public URL',
              subtitle: w.displayHostPath,
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: w.resolvedPublicUrl),
                );
                if (!mounted) return;
                showAppToast(
                      context,
                      'Public URL copied',
                      kind: AppToastKind.success,
                    );
              },
            ),
          ],
        ),
        if (_isMenuSite) ...[
          const SizedBox(height: 16),
          _sectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pause orders',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            w.ordering.ordersPaused
                                ? 'Browsing OK · place order blocked'
                                : 'Accepting orders',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AuthUi.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: w.ordering.ordersPaused,
                      activeColor: Colors.black,
                      onChanged: _setOrdersPaused,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: BwUi.cardBorder),
              _rowTile(
                title: 'Hours',
                subtitle: 'Weekly open / closed times',
                onTap: _openHours,
              ),
              const Divider(height: 1, color: BwUi.cardBorder),
              _rowTile(
                title: 'Ordering',
                subtitle: 'Pickup, delivery, fees & areas',
                onTap: _openOrdering,
              ),
              const Divider(height: 1, color: BwUi.cardBorder),
              _rowTile(
                title: 'Orders',
                subtitle: 'Open your order inbox',
                onTap: _openOrdersInbox,
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _sectionCard(
          children: [
            _rowTile(
              title: 'Live Preview',
              subtitle: 'Open the site inside the app',
              onTap: _preview,
            ),
            const Divider(height: 1, color: BwUi.cardBorder),
            _rowTile(
              title: _isMenuSite ? 'Share menu' : 'Share link',
              subtitle: 'Send your public URL',
              onTap: _sharePublicLink,
            ),
            const Divider(height: 1, color: BwUi.cardBorder),
            _rowTile(
              title: 'Open browser',
              subtitle: 'Open the public link externally',
              onTap: _openInBrowser,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          children: [
            _rowTile(
              title: 'Delete $_tabMenuLabel',
              subtitle: 'Removes website, items & template',
              titleColor: const Color(0xFFE53935),
              onTap: _deleteWebsite,
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BwUi.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _rowTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AuthUi.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}

/// Full-screen template grid — same feel as first-time create “Choose style”.
class _TemplateChooserScreen extends StatefulWidget {
  final List<WebsiteTemplateSummary> templates;
  final String? currentTemplateId;
  final String typeLabel;
  final Future<void> Function(WebsiteTemplateSummary template) onPreviewSample;

  const _TemplateChooserScreen({
    required this.templates,
    required this.currentTemplateId,
    required this.typeLabel,
    required this.onPreviewSample,
  });

  @override
  State<_TemplateChooserScreen> createState() => _TemplateChooserScreenState();
}

class _TemplateChooserScreenState extends State<_TemplateChooserScreen> {
  WebsiteTemplateSummary? _selected;
  bool _blockSelect = false;

  @override
  void initState() {
    super.initState();
    for (final t in widget.templates) {
      if (t.id == widget.currentTemplateId) {
        _selected = t;
        break;
      }
    }
  }

  Future<void> _openSample(WebsiteTemplateSummary template) async {
    _blockSelect = true;
    try {
      await widget.onPreviewSample(template);
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) _blockSelect = false;
    }
  }

  void _selectTemplate(WebsiteTemplateSummary template) {
    if (_blockSelect) return;
    setState(() => _selected = template);
  }

  @override
  Widget build(BuildContext context) {
    return BwPresenceScaffold(
      title: 'Choose style',
      onBack: () => Navigator.of(context).pop(),
      bottom: BwBottomCta(
        label: 'Use Template',
        onPressed: _selected == null
            ? null
            : () => Navigator.of(context).pop(_selected),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Choose Style',
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
            'Pick a ${widget.typeLabel.toLowerCase()} template.',
            style: const TextStyle(
              fontSize: 15,
              color: AuthUi.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.templates.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) {
              final t = widget.templates[index];
              final selected = _selected?.id == t.id;
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
                        onTap: () => _selectTemplate(t),
                        child: t.thumbnail.isNotEmpty
                            ? Image.network(
                                t.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: BwUi.iconTileBg,
                                  child: const Icon(
                                    Icons.web_asset,
                                    color: Colors.black45,
                                  ),
                                ),
                              )
                            : Container(
                                color: BwUi.iconTileBg,
                                child: const Icon(
                                  Icons.web_asset,
                                  color: Colors.black45,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _openSample(t),
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
                                  onPressed: () => _selectTemplate(t),
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
      ),
    );
  }
}
