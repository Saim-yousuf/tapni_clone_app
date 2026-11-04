import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations.dart';
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
    this.isExtra = false,
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
  final bool isExtra;
}

class _QuickAddLinksScreenState extends State<QuickAddLinksScreen> {
  static const _maxInitialFields = 5;
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final List<_QuickField> _fields = [];
  final Map<String, String> _fieldErrors = {};

  bool _saving = false;
  bool _ready = false;
  bool _catalogFailed = false;
  String? _saveError;

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
    setState(() {
      _ready = false;
      _catalogFailed = false;
    });

    final profileProvider = context.read<ProfileProvider>();
    try {
      if (profileProvider.linkCatalog.isEmpty) {
        await profileProvider.fetchLinkCatalog();
      }
      if (!mounted) return;
      if (profileProvider.linkCatalog.isEmpty) {
        setState(() {
          _catalogFailed = true;
          _ready = true;
        });
        return;
      }
      _buildFieldsFromCatalog(profileProvider);
      _prefill(profileProvider);
      setState(() {
        _catalogFailed = false;
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogFailed = true;
        _ready = true;
      });
    }
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

  int _templateCompare(LinkTemplate a, LinkTemplate b) {
    final byFeatured = (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
    if (byFeatured != 0) return byFeatured;
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  }

  /// Up to 5 templates: featured first, then other eligible to fill slots.
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

    final featured = all.where((t) => t.isFeatured).toList()
      ..sort(_templateCompare);
    final others = all.where((t) => !t.isFeatured).toList()
      ..sort(_templateCompare);

    final selected = <LinkTemplate>[];
    for (final t in featured) {
      if (selected.length >= _maxInitialFields) break;
      selected.add(t);
    }
    for (final t in others) {
      if (selected.length >= _maxInitialFields) break;
      selected.add(t);
    }
    return selected;
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

  TextInputType _keyboardFor(String fieldType) {
    switch (fieldType) {
      case 'phone':
        return TextInputType.phone;
      case 'email':
        return TextInputType.emailAddress;
      case 'url':
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  _QuickField _fieldFromTemplate(
    LinkTemplate template, {
    String? value,
    bool isExtra = false,
    String? keyId,
  }) {
    return _QuickField(
      keyId: keyId ?? template.id,
      label: template.label,
      hint: template.fieldLabel.isNotEmpty
          ? template.fieldLabel
          : template.label,
      controller: TextEditingController(text: value ?? ''),
      templateId: template.id,
      logoUrl: template.logo.isNotEmpty ? template.logo : null,
      assetPath: _assetForLabel(template.label),
      keyboardType: _keyboardFor(template.fieldType),
      fieldType: template.fieldType,
      isExtra: isExtra,
    );
  }

  void _buildFieldsFromCatalog(ProfileProvider provider) {
    for (final f in _fields) {
      f.controller.dispose();
    }
    _fields.clear();
    _fieldErrors.clear();

    for (final template in _templatesForQuickAdd(provider)) {
      _fields.add(_fieldFromTemplate(template));
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

  bool _hasTemplate(String templateId) {
    return _fields.any((f) => f.templateId == templateId);
  }

  void _onFieldChanged(String keyId) {
    if (_fieldErrors.containsKey(keyId) || _saveError != null) {
      setState(() {
        _fieldErrors.remove(keyId);
        _saveError = null;
      });
    } else {
      setState(() {});
    }
  }

  void _handleFieldAction(int index) {
    if (index < 0 || index >= _fields.length) return;
    final field = _fields[index];
    if (field.controller.text.trim().isNotEmpty) {
      field.controller.clear();
      setState(() {
        _fieldErrors.remove(field.keyId);
        _saveError = null;
      });
      return;
    }
    _fields.removeAt(index);
    field.controller.dispose();
    setState(() {
      _fieldErrors.remove(field.keyId);
      _saveError = null;
    });
  }

  Future<void> _openAddMore() async {
    FocusScope.of(context).unfocus();
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
        if (_hasTemplate(tid)) continue;
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
      if (template == null || !_isQuickAddTemplate(template)) continue;
      if (_hasTemplate(template.id)) continue;

      _fields.add(
        _fieldFromTemplate(
          template,
          value: link.value,
          isExtra: true,
          keyId: 'extra_${template.id}_${_fields.length}',
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

  bool _isValidUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;
    final candidate = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(candidate);
    if (uri == null) return false;
    if (uri.host.isEmpty) return false;
    return uri.host.contains('.');
  }

  String? _validateField(_QuickField field, String raw, AppLocalizations l10n) {
    if (raw.isEmpty) return null;
    switch (field.fieldType) {
      case 'email':
        if (!_emailPattern.hasMatch(raw)) {
          return l10n.pleaseEnterAValidEmailAddress;
        }
        break;
      case 'url':
        if (!_isValidUrl(raw)) {
          return l10n.pleaseEnterAValidUrl;
        }
        break;
      case 'phone':
        final normalized = PhoneUtils.normalize(raw);
        if (normalized.isEmpty || !PhoneUtils.isValid(normalized)) {
          return l10n.pleaseEnterValidPhoneNumber;
        }
        break;
      default:
        break;
    }
    return null;
  }

  void _goToNextOnboarding() {
    FocusScope.of(context).unfocus();
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

  void _handleBack() {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    // Stack was cleared after signup — back acts as skip forward.
    _goToNextOnboarding();
  }

  void _handleSkip() {
    if (_saving) return;
    _goToNextOnboarding();
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
    FocusScope.of(context).unfocus();

    final l10n = context.l10n;
    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.linkCatalog.isEmpty) {
      await profileProvider.fetchLinkCatalog();
    }

    final errors = <String, String>{};
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

      final error = _validateField(field, raw, l10n);
      if (error != null) {
        errors[field.keyId] = error;
        continue;
      }
      prepared.add((field: field, value: raw));
    }

    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors
          ..clear()
          ..addAll(errors);
        _saveError = null;
      });
      return;
    }

    if (prepared.isEmpty) {
      _handleSkip();
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

    setState(() {
      _saving = true;
      _saveError = null;
      _fieldErrors.clear();
    });

    try {
      final response = await profileProvider.updateLinks(
        links: links,
        context: context,
      );
      if (!mounted) return;
      if (!response.success) {
        setState(() {
          _saveError = response.message?.trim().isNotEmpty == true
              ? response.message!.trim()
              : l10n.quickAddSaveFailed;
        });
        return;
      }
      _goToNextOnboarding();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveError = l10n.quickAddSaveFailed;
      });
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

  Widget _buildHeader(AuthScale m, AppLocalizations l10n) {
    return SizedBox(
      height: m.appBarH,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: m.padH),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              l10n.quickAddLinksTitle,
              textAlign: TextAlign.center,
              style: AuthAppBarTitle.titleStyle(m, allCaps: false),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: AuthBackButton(
                onPressed: () {
                  if (!_saving) _handleBack();
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _saving ? null : _handleSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AuthUi.textPrimary,
                  padding: EdgeInsets.symmetric(horizontal: m.s(8)),
                  minimumSize: Size(m.s(48), m.s(40)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AuthScale m, AppLocalizations l10n) {
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: AuthUi.textPrimary,
        ),
      );
    }

    if (_catalogFailed && _fields.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: m.padH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.quickAddCatalogError,
                textAlign: TextAlign.center,
                style: _text(
                  m,
                  size: AuthUi.bodySize,
                  color: AuthUi.textSecondary,
                  height: 1.45,
                ),
              ),
              SizedBox(height: m.v(20)),
              TextButton(
                onPressed: _saving ? null : _bootstrap,
                child: Text(
                  l10n.tryAgain,
                  style: _text(
                    m,
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        m.padH,
        0,
        m.padH,
        m.v(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: m.v(24)),
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
          SizedBox(height: m.v(28)),
          if (_fields.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: m.v(12)),
              child: Text(
                l10n.quickAddEmptyCatalog,
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
              if (i > 0) SizedBox(height: m.v(14)),
              _LinkField(
                label: _fields[i].label,
                controller: _fields[i].controller,
                hintText: _fields[i].hint,
                assetPath: _fields[i].assetPath,
                logoUrl: _fields[i].logoUrl,
                keyboardType: _fields[i].keyboardType,
                enabled: !_saving,
                errorText: _fieldErrors[_fields[i].keyId],
                scale: m,
                onChanged: () => _onFieldChanged(_fields[i].keyId),
                onRemove: _saving ? null : () => _handleFieldAction(i),
              ),
            ],
          SizedBox(height: m.v(16)),
          _AddMoreLinksButton(
            enabled: !_saving,
            onTap: _openAddMore,
            scale: m,
            label: l10n.quickAddAddAnotherLink,
          ),
          if (_saveError != null) ...[
            SizedBox(height: m.v(16)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(m.s(12)),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(m.s(12)),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _saveError!,
                    style: _text(
                      m,
                      size: 14,
                      color: AuthUi.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: m.v(4)),
                  TextButton(
                    onPressed: _saving ? null : _handleContinue,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.retry,
                      style: _text(
                        m,
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
            _buildHeader(m, l10n),
            Expanded(child: _buildBody(m, l10n)),
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
                            m.v(8) + (bottom > 0 ? 0 : m.v(4)),
                          ),
                          child: AuthPrimaryPillButton(
                            label: l10n.continueLabel,
                            loading: _saving,
                            onPressed: _saving ? null : _handleContinue,
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
    required this.label,
    required this.controller,
    required this.hintText,
    required this.scale,
    required this.onChanged,
    this.assetPath,
    this.logoUrl,
    this.keyboardType,
    this.enabled = true,
    this.errorText,
    this.onRemove,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final AuthScale scale;
  final VoidCallback onChanged;
  final String? assetPath;
  final String? logoUrl;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? errorText;
  final VoidCallback? onRemove;

  static const _fill = Color(0xFFF5F5F5);
  static const _stroke = Color(0xFFE5E7EB);
  static const _hint = Color(0xFF6B7280);
  static const _error = Color(0xFFB42318);

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
    final clearSize = m.s(18);
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: m.s(4), bottom: m.s(8)),
          child: Text(
            label,
            style: AppFonts.textStyle(
              fontSize: m.s(13),
              fontWeight: FontWeight.w700,
              color: AuthUi.textPrimary,
              height: 1.2,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                height: m.s(54),
                decoration: BoxDecoration(
                  color: _fill,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: hasError ? _error : _stroke,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onChanged(),
                  scrollPadding: EdgeInsets.only(bottom: m.s(120)),
                  style: AppFonts.textStyle(
                    fontSize: m.s(15),
                    fontWeight: FontWeight.w600,
                    color: AuthUi.textPrimary,
                    height: 1.2,
                  ),
                  cursorColor: AuthUi.textPrimary,
                  inputFormatters: keyboardType == TextInputType.phone
                      ? [FilteringTextInputFormatter.allow(RegExp(r'[\d+\s\-()]'))]
                      : null,
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
                icon: Image.asset(
                  'assets/images/png/cross-icon.png',
                  width: clearSize,
                  height: clearSize,
                  color: _hint,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.close,
                    size: clearSize,
                    color: _hint,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          SizedBox(height: m.s(6)),
          Padding(
            padding: EdgeInsets.only(left: m.s(4)),
            child: Text(
              errorText!,
              style: AppFonts.textStyle(
                fontSize: m.s(12),
                fontWeight: FontWeight.w500,
                color: _error,
                height: 1.25,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
