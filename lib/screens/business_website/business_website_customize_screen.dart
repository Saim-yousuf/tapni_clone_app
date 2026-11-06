import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/screens/business_website/business_presence_ui.dart';
import 'package:tapni_app/screens/business_website/business_website_webview_screen.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/app_toast.dart';

/// Curated accents that complement existing template packs (bg/ink stay pack-owned).
const List<Color> kWebsiteThemePalette = [
  Color(0xFFE4572E),
  Color(0xFFFF6FA5),
  Color(0xFFF18C2C),
  Color(0xFF2D9B6F),
  Color(0xFF1B2A4A),
  Color(0xFF8BA843),
  Color(0xFFC45C26),
  Color(0xFF111111),
  Color(0xFF2563EB),
  Color(0xFF7C3AED),
  Color(0xFF0F766E),
  Color(0xFFBE123C),
];

String colorToHex(Color c) {
  final r = ((c.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final g = ((c.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final b = ((c.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toLowerCase();
}

Color? tryParseHexColor(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  if (!s.startsWith('#')) s = '#$s';
  if (s.length == 4) {
    s = '#${s[1]}${s[1]}${s[2]}${s[2]}${s[3]}${s[3]}';
  }
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(s)) return null;
  return Color(int.parse(s.substring(1), radix: 16) + 0xFF000000);
}

String? normalizeHexColorInput(String raw) {
  final c = tryParseHexColor(raw);
  if (c == null) return null;
  return colorToHex(c);
}

/// Business-owner customization for theme accent + soft branding flags.
class BusinessWebsiteCustomizeScreen extends StatefulWidget {
  final BusinessWebsite website;
  final String? templateDefaultThemeColor;

  const BusinessWebsiteCustomizeScreen({
    super.key,
    required this.website,
    this.templateDefaultThemeColor,
  });

  @override
  State<BusinessWebsiteCustomizeScreen> createState() =>
      _BusinessWebsiteCustomizeScreenState();
}

class _BusinessWebsiteCustomizeScreenState
    extends State<BusinessWebsiteCustomizeScreen> {
  final _repo = BusinessWebsiteRepo();
  late final TextEditingController _hexCtrl;
  late final TextEditingController _headlineCtrl;

  late String _themeColor;
  late bool _hasCustomThemeColor;
  late bool _showLogo;
  late bool _showBio;
  late BusinessWebsiteDesign _initial;

  bool _saving = false;
  bool _previewing = false;

  String get _templateFallback {
    final raw = widget.templateDefaultThemeColor?.trim();
    if (raw != null && raw.isNotEmpty) {
      return normalizeHexColorInput(raw) ?? '#ff6fa5';
    }
    return normalizeHexColorInput(widget.website.design.themeColor) ??
        '#ff6fa5';
  }

  @override
  void initState() {
    super.initState();
    final d = widget.website.design;
    _initial = d;
    _themeColor = normalizeHexColorInput(d.themeColor) ?? _templateFallback;
    _hasCustomThemeColor = d.hasCustomThemeColor;
    _showLogo = d.showLogo;
    _showBio = d.showBio;
    _hexCtrl = TextEditingController(text: _themeColor.toUpperCase());
    _headlineCtrl = TextEditingController(text: d.homepageHeadline);
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    _headlineCtrl.dispose();
    super.dispose();
  }

  BusinessWebsiteDesign get _draft => BusinessWebsiteDesign(
        themeColor: _themeColor,
        hasCustomThemeColor: _hasCustomThemeColor,
        homepageHeadline: _headlineCtrl.text.trim(),
        showLogo: _showLogo,
        showBio: _showBio,
        fontStyle: _initial.fontStyle,
        buttonStyle: _initial.buttonStyle,
        cardStyle: _initial.cardStyle,
      );

  bool get _dirty {
    final d = _draft;
    return d.themeColor.toLowerCase() !=
            _initial.themeColor.toLowerCase() ||
        d.hasCustomThemeColor != _initial.hasCustomThemeColor ||
        d.homepageHeadline != _initial.homepageHeadline.trim() ||
        d.showLogo != _initial.showLogo ||
        d.showBio != _initial.showBio;
  }

  void _applyColor(String hex, {required bool custom}) {
    final normalized = normalizeHexColorInput(hex);
    if (normalized == null) return;
    setState(() {
      _themeColor = normalized;
      _hasCustomThemeColor = custom;
      _hexCtrl.text = normalized.toUpperCase();
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved customization will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _onBack() async {
    if (!await _confirmDiscard()) return;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _preview() async {
    if (_previewing || _saving) return;
    final hex = normalizeHexColorInput(_hexCtrl.text);
    if (hex == null) {
      showAppToast(
            context,
            'Enter a valid color like #E4572E',
            kind: AppToastKind.info,
          );
      return;
    }
    setState(() {
      _themeColor = hex;
      _previewing = true;
    });
    final res = await _repo.previewMine(
      websiteId: widget.website.id,
      websiteType: widget.website.websiteType,
      designDraft: _draft.toDesignPatchJson(),
    );
    if (!mounted) return;
    setState(() => _previewing = false);
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
          title: 'Customize preview',
          previewMode: true,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || _previewing) return;
    final hex = normalizeHexColorInput(_hexCtrl.text);
    if (hex == null) {
      showAppToast(
            context,
            'Enter a valid color like #E4572E',
            kind: AppToastKind.info,
          );
      return;
    }
    setState(() {
      _themeColor = hex;
      _saving = true;
    });
    final draft = _draft;
    final res = await _repo.updateWebsite(
      {'design': draft.toDesignPatchJson()},
      websiteId: widget.website.id,
      websiteType: widget.website.websiteType,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!res.success) {
      showAppToast(
            context,
            res.message ?? 'Could not save',
            kind: AppToastKind.error,
          );
      return;
    }
    final updated = _repo.parseWebsite(res.data);
    showAppToast(
          context,
          'Customization saved',
          kind: AppToastKind.success,
        );
    Navigator.of(context).pop(updated ?? widget.website.copyWith(design: draft));
  }

  @override
  Widget build(BuildContext context) {
    final selected = tryParseHexColor(_themeColor) ?? const Color(0xFFFF6FA5);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onBack();
      },
      child: BwPresenceScaffold(
        title: 'Customize Website',
        onBack: _onBack,
        bottom: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: AuthOutlinedPillButton(
                    label: _previewing ? 'Loading…' : 'Preview',
                    onPressed: (_saving || _previewing) ? null : _preview,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AuthPrimaryPillButton(
                    label: 'Save',
                    onPressed: (_saving || _previewing) ? null : _save,
                    loading: _saving,
                  ),
                ),
              ],
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Personalize accents without changing this template’s layout.',
              style: TextStyle(
                fontSize: 14,
                color: AuthUi.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _sectionCard(
              title: 'Theme color',
              subtitle:
                  'Buttons and highlights. Background and text stay with the template.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selected,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: BwUi.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: selected.withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _hexCtrl,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9a-fA-F#]'),
                            ),
                            LengthLimitingTextInputFormatter(7),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Hex color',
                            hintText: '#E4572E',
                            filled: true,
                            fillColor: AuthUi.fieldFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) {
                            final n = normalizeHexColorInput(v);
                            if (n != null) {
                              setState(() {
                                _themeColor = n;
                                _hasCustomThemeColor = true;
                              });
                            }
                          },
                          onEditingComplete: () {
                            final n = normalizeHexColorInput(_hexCtrl.text);
                            if (n == null) {
                              showAppToast(
                                    context,
                                    'Enter a valid color like #E4572E',
                                    kind: AppToastKind.info,
                                  );
                              _hexCtrl.text = _themeColor.toUpperCase();
                              return;
                            }
                            _applyColor(n, custom: true);
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in kWebsiteThemePalette)
                        _PaletteSwatch(
                          color: c,
                          selected: colorToHex(c) == _themeColor.toLowerCase(),
                          onTap: () =>
                              _applyColor(colorToHex(c), custom: true),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        _applyColor(_templateFallback, custom: false),
                    child: const Text('Use template default color'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Homepage headline',
              subtitle:
                  'Optional. Leave blank to keep the template’s original heading. Does not change your business name.',
              child: TextField(
                controller: _headlineCtrl,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. Fresh food, delivered fast',
                  filled: true,
                  fillColor: AuthUi.fieldFill,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Branding',
              subtitle: 'Show or hide profile photo and bio on the website.',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Show logo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Profile photo in the site header'),
                    value: _showLogo,
                    activeTrackColor: Colors.black,
                    onChanged: (v) => setState(() => _showLogo = v),
                  ),
                  const Divider(height: 1, color: BwUi.cardBorder),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Show bio',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Profile bio under the headline'),
                    value: _showBio,
                    activeTrackColor: Colors.black,
                    onChanged: (v) => setState(() => _showBio = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BwUi.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AuthUi.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black : Colors.white,
            width: selected ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
