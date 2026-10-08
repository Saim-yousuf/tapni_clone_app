import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/contacts_sync_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/services/contacts_sync_service.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/phone_utils.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/links_widget.dart';

/// Onboarding quick-add. Fields come only from admin link templates
/// (same catalog as the Links sheet) — never hardcoded platforms.
class QuickAddLinksScreen extends StatefulWidget {
  const QuickAddLinksScreen({super.key});

  @override
  State<QuickAddLinksScreen> createState() => _QuickAddLinksScreenState();
}

class _QuickField {
  _QuickField({
    required this.keyId,
    required this.label,
    required this.hint,
    required this.controller,
    required this.templateId,
    this.logoUrl,
    this.assetPath,
    this.keyboardType,
    this.fieldType = 'url',
  });

  final String keyId;
  final String label;
  final String hint;
  final TextEditingController controller;
  final String templateId;
  String? logoUrl;
  String? assetPath;
  TextInputType? keyboardType;
  String fieldType;
}

class _QuickAddLinksScreenState extends State<QuickAddLinksScreen> {
  final List<_QuickField> _fields = [];
  bool _saving = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    for (final f in _fields) {
      f.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.linkCatalog.isEmpty) {
      await profileProvider.fetchLinkCatalog();
    }
    if (!mounted) return;
    _buildFieldsFromCatalog(profileProvider);
    _prefill(profileProvider);
    setState(() => _ready = true);
  }

  /// Simple text-entry templates only (same source as Links sheet).
  bool _isQuickAddTemplate(LinkTemplate template) {
    if (template.id.trim().isEmpty) return false;
    if (template.actionType != 'link') return false;
    switch (template.fieldType) {
      case 'username':
      case 'phone':
      case 'url':
      case 'email':
        return true;
      default:
        return false;
    }
  }

  List<LinkTemplate> _templatesForQuickAdd(ProfileProvider provider) {
    final all = <LinkTemplate>[];
    final seen = <String>{};
    for (final category in provider.linkCatalog) {
      for (final template in category.templates) {
        if (!_isQuickAddTemplate(template)) continue;
        if (!seen.add(template.id)) continue;
        all.add(template);
      }
    }

    final featured = all.where((t) => t.isFeatured).toList();
    final source = featured.isNotEmpty ? featured : all;
    source.sort((a, b) {
      final byFeatured = (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
      if (byFeatured != 0) return byFeatured;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return source;
  }

  String? _assetForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('whatsapp')) {
      return SocialLink.getAssetPath(SocialPlatform.whatsApp);
    }
    if (lower.contains('instagram')) {
      return SocialLink.getAssetPath(SocialPlatform.instagram);
    }
    if (lower.contains('tiktok')) {
      return SocialLink.getAssetPath(SocialPlatform.tiktok);
    }
    if (lower.contains('snapchat')) {
      return SocialLink.getAssetPath(SocialPlatform.snapchat);
    }
    if (lower.contains('linkedin')) {
      return SocialLink.getAssetPath(SocialPlatform.linkedIn);
    }
    if (lower.contains('email')) {
      return SocialLink.getAssetPath(SocialPlatform.email);
    }
    return null;
  }

  void _buildFieldsFromCatalog(ProfileProvider provider) {
    for (final f in _fields) {
      f.controller.dispose();
    }
    _fields.clear();

    for (final template in _templatesForQuickAdd(provider)) {
      _fields.add(
        _QuickField(
          keyId: template.id,
          label: template.label,
          hint: template.fieldLabel.isNotEmpty
              ? template.fieldLabel
              : template.label,
          controller: TextEditingController(),
          templateId: template.id,
          logoUrl: template.logo.isNotEmpty ? template.logo : null,
          assetPath: _assetForLabel(template.label),
          keyboardType: template.fieldType == 'phone'
              ? TextInputType.phone
              : template.fieldType == 'email'
                  ? TextInputType.emailAddress
                  : template.fieldType == 'url'
                      ? TextInputType.url
                      : TextInputType.text,
          fieldType: template.fieldType,
        ),
      );
    }
  }

  void _prefill(ProfileProvider provider) {
    for (final field in _fields) {
      if (field.controller.text.trim().isNotEmpty) continue;
      for (final link in provider.profile.socialLinks) {
        if (_fieldMatchesLink(field, link)) {
          field.controller.text = link.value;
          break;
        }
      }
    }
  }

  bool _fieldMatchesLink(_QuickField field, SocialLink link) {
    if (field.templateId.isNotEmpty && link.templateId == field.templateId) {
      return true;
    }
    final a = field.label.toLowerCase();
    final b = link.platformName.toLowerCase();
    return a.isNotEmpty && (a == b || b.contains(a) || a.contains(b));
  }

  void _removeField(int index) {
    if (index < 0 || index >= _fields.length) return;
    final field = _fields.removeAt(index);
    field.controller.dispose();
    setState(() {});
  }

  Future<void> _openAddMore() async {
    final provider = context.read<ProfileProvider>();
    await LinkSheet().showAddLinkBottomSheet(context, provider);
    if (!mounted) return;
    _syncExtraFieldsFromProfile(provider);
  }

  void _syncExtraFieldsFromProfile(ProfileProvider provider) {
    var changed = false;
    for (final link in provider.profile.socialLinks) {
      if (link.isGalleryLink || link.isDocumentLink || link.isCatalogLink) {
        continue;
      }
      final already = _fields.any((f) => _fieldMatchesLink(f, link));
      if (already) {
        final field = _fields.firstWhere((f) => _fieldMatchesLink(f, link));
        if (field.controller.text.trim().isEmpty && link.value.isNotEmpty) {
          field.controller.text = link.value;
          changed = true;
        }
        continue;
      }

      LinkTemplate? template;
      final tid = link.templateId?.trim() ?? '';
      if (tid.isNotEmpty) {
        for (final category in provider.linkCatalog) {
          for (final t in category.templates) {
            if (t.id == tid) {
              template = t;
              break;
            }
          }
          if (template != null) break;
        }
      }
      // Only show entries backed by a real admin template.
      if (template == null || !_isQuickAddTemplate(template)) continue;

      _fields.add(
        _QuickField(
          keyId: 'extra_${template.id}_${_fields.length}',
          label: template.label,
          hint: template.fieldLabel.isNotEmpty
              ? template.fieldLabel
              : template.label,
          controller: TextEditingController(text: link.value),
          templateId: template.id,
          logoUrl: link.logoUrl ??
              (template.logo.isNotEmpty ? template.logo : null),
          assetPath: _assetForLabel(template.label),
          keyboardType: template.fieldType == 'phone'
              ? TextInputType.phone
              : TextInputType.text,
          fieldType: template.fieldType,
        ),
      );
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  String _cleanUsername(String raw) {
    var value = raw.trim();
    if (value.startsWith('@')) value = value.substring(1).trim();
    return value;
  }

  void _goToContactsSync() {
    if (!ContactsSyncService.isFeatureEnabled) {
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(
        builder: (_) => const ContactsSyncScreen(isOnboarding: true),
      ),
      (_) => false,
    );
  }

  SocialLink? _buildLink({
    required _QuickField field,
    required String value,
    required ProfileProvider provider,
    SocialLink? existing,
  }) {
    LinkTemplate? template;
    for (final category in provider.linkCatalog) {
      for (final t in category.templates) {
        if (t.id == field.templateId) {
          template = t;
          break;
        }
      }
      if (template != null) break;
    }
    if (template == null || template.id.trim().isEmpty) return null;

    return SocialLink(
      id: existing?.id ??
          '${DateTime.now().millisecondsSinceEpoch}_${field.keyId}',
      platform: SocialPlatform.wave,
      templateId: template.id,
      customLabel: template.label,
      fieldLabel: template.fieldLabel,
      fieldType: template.fieldType,
      actionType: template.actionType,
      logoUrl: template.logo,
      value: value,
      isActive: true,
      isPublic: existing?.isPublic ?? true,
    );
  }

  Future<void> _handleContinue() async {
    if (_saving) return;

    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.linkCatalog.isEmpty) {
      await profileProvider.fetchLinkCatalog();
    }

    final prepared = <({_QuickField field, String value})>[];
    for (final field in _fields) {
      var raw = field.controller.text.trim();
      if (raw.isEmpty) continue;
      if (field.fieldType == 'phone' ||
          field.keyboardType == TextInputType.phone) {
        final normalized = PhoneUtils.normalize(raw);
        raw = normalized.isNotEmpty ? normalized : raw;
      } else if (field.fieldType != 'url' && field.fieldType != 'email') {
        raw = _cleanUsername(raw);
      }
      if (raw.isEmpty) continue;
      prepared.add((field: field, value: raw));
    }

    if (prepared.isEmpty) {
      _goToContactsSync();
      return;
    }

    final links = List<SocialLink>.from(profileProvider.profile.socialLinks);
    for (final item in prepared) {
      final existingIndex =
          links.indexWhere((link) => _fieldMatchesLink(item.field, link));
      final existing = existingIndex >= 0 ? links[existingIndex] : null;
      final next = _buildLink(
        field: item.field,
        value: item.value,
        provider: profileProvider,
        existing: existing,
      );
      if (next == null) continue;
      if (existingIndex >= 0) {
        links[existingIndex] = next;
      } else {
        links.add(next);
      }
    }

    setState(() => _saving = true);
    try {
      final response = await profileProvider.updateLinks(
        links: links,
        context: context,
      );
      if (!mounted) return;
      if (!response.success) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }
      _goToContactsSync();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  TextStyle _text(
    AuthScale m, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AuthUi.textPrimary,
    double height = 1.2,
  }) {
    return AppFonts.textStyle(
      fontSize: m.s(size),
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AuthUi.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthAppBarTitle(
              l10n.quickAddLinksTitle,
              showBack: true,
              allCaps: false,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: !_ready
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AuthUi.textPrimary,
                      ),
                    )
                  : SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        m.padH,
                        0,
                        m.padH,
                        m.v(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: m.v(41)),
                          Text(
                            l10n.quickAddLinksSubtitle,
                            textAlign: TextAlign.center,
                            style: _text(
                              m,
                              size: AuthUi.bodySize,
                              color: AuthUi.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: m.v(41)),
                          if (_fields.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: m.v(12)),
                              child: Text(
                                'No quick links yet. Use Add more links, or skip and add them later from Links.',
                                textAlign: TextAlign.center,
                                style: _text(
                                  m,
                                  size: AuthUi.bodySize,
                                  color: AuthUi.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            )
                          else
                            for (var i = 0; i < _fields.length; i++) ...[
                              if (i > 0) SizedBox(height: m.v(12)),
                              _LinkField(
                                controller: _fields[i].controller,
                                hintText: _fields[i].hint,
                                assetPath: _fields[i].assetPath,
                                logoUrl: _fields[i].logoUrl,
                                keyboardType: _fields[i].keyboardType,
                                enabled: !_saving,
                                scale: m,
                                onRemove:
                                    _saving ? null : () => _removeField(i),
                              ),
                            ],
                          SizedBox(height: m.v(16)),
                          _AddMoreLinksButton(
                            enabled: !_saving,
                            onTap: _openAddMore,
                            scale: m,
                            label: l10n.addLink2,
                          ),
                        ],
                      ),
                    ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: keyboardOpen
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            m.padH,
                            m.v(8),
                            m.padH,
                            m.v(4),
                          ),
                          child: AuthPrimaryPillButton(
                            label: l10n.next,
                            loading: _saving,
                            onPressed: _saving ? null : _handleContinue,
                          ),
                        ),
                        TextButton(
                          onPressed: _saving ? null : _goToContactsSync,
                          child: Text(
                            l10n.skip,
                            style: _text(
                              m,
                              size: 15,
                              weight: FontWeight.w700,
                              color: AuthUi.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: m.v(8) + (bottom > 0 ? 0 : m.v(4)),
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

class _AddMoreLinksButton extends StatelessWidget {
  const _AddMoreLinksButton({
    required this.enabled,
    required this.onTap,
    required this.scale,
    required this.label,
  });

  final bool enabled;
  final VoidCallback onTap;
  final AuthScale scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    final m = scale;
    final radius = m.s(16);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            height: m.s(48),
            padding: EdgeInsets.symmetric(horizontal: m.s(18)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: AuthUi.textPrimary,
                width: AuthUi.outlineBorderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AuthUi.iconPlus,
                  width: m.s(18),
                  height: m.s(18),
                  color: AuthUi.textPrimary,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.add,
                    size: m.s(20),
                    color: AuthUi.textPrimary,
                  ),
                ),
                SizedBox(width: m.s(8)),
                Text(
                  label,
                  style: AppFonts.textStyle(
                    fontSize: m.s(16),
                    fontWeight: FontWeight.w700,
                    color: AuthUi.textPrimary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.controller,
    required this.hintText,
    required this.scale,
    this.assetPath,
    this.logoUrl,
    this.keyboardType,
    this.enabled = true,
    this.onRemove,
  });

  final TextEditingController controller;
  final String hintText;
  final AuthScale scale;
  final String? assetPath;
  final String? logoUrl;
  final TextInputType? keyboardType;
  final bool enabled;
  final VoidCallback? onRemove;

  static const _fill = Color(0xFFF5F5F5);
  static const _stroke = Color(0xFFE5E7EB);
  static const _hint = Color(0xFF6B7280);

  Widget _iconTile(double size, double radius) {
    final network = logoUrl?.trim() ?? '';
    final path = assetPath;

    Widget image;
    if (network.startsWith('http://') || network.startsWith('https://')) {
      image = Image.network(
        network,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetOrFallback(size, path),
      );
    } else {
      image = _assetOrFallback(size, path);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _stroke, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }

  Widget _assetOrFallback(double size, String? path) {
    if (path != null && path.isNotEmpty) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackIcon(size),
      );
    }
    return _fallbackIcon(size);
  }

  Widget _fallbackIcon(double size) {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Icon(
          Icons.link,
          size: size * 0.55,
          color: AuthUi.textMuted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = scale;
    final radius = m.s(16);
    final iconSize = m.s(32);
    final iconRadius = m.s(8);
    final clearSize = m.s(20);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: m.s(54),
            decoration: BoxDecoration(
              color: _fill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: _stroke, width: 1),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              textInputAction: TextInputAction.next,
              scrollPadding: EdgeInsets.only(bottom: m.s(120)),
              style: AppFonts.textStyle(
                fontSize: m.s(15),
                fontWeight: FontWeight.w600,
                color: AuthUi.textPrimary,
                height: 1.2,
              ),
              cursorColor: AuthUi.textPrimary,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppFonts.textStyle(
                  fontSize: m.s(15),
                  fontWeight: FontWeight.w400,
                  color: _hint,
                  height: 1.2,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: m.s(12)),
                  child: _iconTile(iconSize, iconRadius),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: m.s(56),
                  minHeight: iconSize,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: m.s(12),
                  vertical: m.s(14),
                ),
                isDense: true,
              ),
            ),
          ),
        ),
        SizedBox(width: m.s(8)),
        SizedBox(
          width: m.s(36),
          height: m.s(54),
          child: IconButton(
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.close,
              size: clearSize,
              color: _hint,
            ),
          ),
        ),
      ],
    );
  }
}
