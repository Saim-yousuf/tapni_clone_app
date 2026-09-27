import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/contacts_sync_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/services/contacts_sync_service.dart';
import 'package:tapni_app/utils/phone_utils.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/links_widget.dart';

class QuickAddLinksScreen extends StatefulWidget {
  const QuickAddLinksScreen({super.key, this.phone});

  final String? phone;

  @override
  State<QuickAddLinksScreen> createState() => _QuickAddLinksScreenState();
}

class _QuickAddLinksScreenState extends State<QuickAddLinksScreen> {
  late final TextEditingController _whatsAppController;
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _snapchatController = TextEditingController();
  bool _saving = false;
  bool _didPrefill = false;

  @override
  void initState() {
    super.initState();
    _whatsAppController = TextEditingController(text: widget.phone ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.linkCatalog.isEmpty) {
        await profileProvider.fetchLinkCatalog();
      }
      if (!mounted) return;
      _prefillFromProfile(profileProvider);
    });
  }

  @override
  void dispose() {
    _whatsAppController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _snapchatController.dispose();
    super.dispose();
  }

  void _prefillFromProfile(ProfileProvider provider) {
    if (_didPrefill) return;
    _didPrefill = true;

    String? valueFor(SocialPlatform platform) {
      final template = _templateFor(platform, provider);
      for (final link in provider.profile.socialLinks) {
        if (_matches(link, template, platform)) {
          return link.value;
        }
      }
      return null;
    }

    if (_whatsAppController.text.trim().isEmpty) {
      final existing = valueFor(SocialPlatform.whatsApp);
      if (existing != null && existing.isNotEmpty) {
        _whatsAppController.text = existing;
      }
    }
    if (_instagramController.text.trim().isEmpty) {
      final existing = valueFor(SocialPlatform.instagram);
      if (existing != null) _instagramController.text = existing;
    }
    if (_tiktokController.text.trim().isEmpty) {
      final existing = valueFor(SocialPlatform.tiktok);
      if (existing != null) _tiktokController.text = existing;
    }
    if (_snapchatController.text.trim().isEmpty) {
      final existing = valueFor(SocialPlatform.snapchat);
      if (existing != null) _snapchatController.text = existing;
    }
  }

  String _cleanUsername(String raw) {
    var value = raw.trim();
    if (value.startsWith('@')) value = value.substring(1).trim();
    return value;
  }

  void _goToContactsSync() {
    if (!ContactsSyncService.isFeatureEnabled) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const ContactsSyncScreen(isOnboarding: true),
      ),
      (_) => false,
    );
  }

  LinkTemplate? _templateFor(
    SocialPlatform platform,
    ProfileProvider profileProvider,
  ) {
    final name = SocialLink.getPlatformName(platform);
    return profileProvider.findCatalogTemplate(
      label: name,
      type: SocialLink(
        id: 'lookup',
        platform: platform,
        value: '',
      ).apiType,
    );
  }

  bool _matches(
    SocialLink link,
    LinkTemplate? template,
    SocialPlatform platform,
  ) {
    if (template != null &&
        template.id.isNotEmpty &&
        link.templateId == template.id) {
      return true;
    }
    if (link.platform == platform) return true;
    final name = SocialLink.getPlatformName(platform).toLowerCase();
    return link.platformName.toLowerCase() == name;
  }

  SocialLink _linkFromCatalog({
    required SocialPlatform platform,
    required String value,
    required ProfileProvider profileProvider,
    String? existingId,
    bool isPublic = true,
  }) {
    final template = _templateFor(platform, profileProvider);
    if (template != null) {
      return SocialLink(
        id: existingId ??
            '${DateTime.now().millisecondsSinceEpoch}_${platform.name}',
        platform: SocialPlatform.wave,
        templateId: template.id,
        customLabel: template.label,
        fieldLabel: template.fieldLabel,
        fieldType: template.fieldType,
        actionType: template.actionType,
        logoUrl: template.logo,
        value: value,
        isActive: true,
        isPublic: isPublic,
      );
    }
    return SocialLink(
      id: existingId ??
          '${DateTime.now().millisecondsSinceEpoch}_${platform.name}',
      platform: platform,
      customLabel: SocialLink.getPlatformName(platform),
      value: value,
      isActive: true,
      isPublic: isPublic,
    );
  }

  Future<void> _handleContinue() async {
    if (_saving) return;

    final whatsAppRaw = _whatsAppController.text.trim();
    final normalized =
        whatsAppRaw.isEmpty ? '' : PhoneUtils.normalize(whatsAppRaw);
    final whatsApp = normalized.isNotEmpty ? normalized : whatsAppRaw;
    final instagram = _cleanUsername(_instagramController.text);
    final tiktok = _cleanUsername(_tiktokController.text);
    final snapchat = _cleanUsername(_snapchatController.text);

    if (whatsApp.isEmpty &&
        instagram.isEmpty &&
        tiktok.isEmpty &&
        snapchat.isEmpty) {
      _goToContactsSync();
      return;
    }

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    if (profileProvider.linkCatalog.isEmpty) {
      await profileProvider.fetchLinkCatalog();
    }
    final links = List<SocialLink>.from(profileProvider.profile.socialLinks);

    void upsert(SocialPlatform platform, String value) {
      if (value.isEmpty) return;
      final template = _templateFor(platform, profileProvider);
      final existingIndex = links.indexWhere(
        (link) => _matches(link, template, platform),
      );
      final existing = existingIndex >= 0 ? links[existingIndex] : null;
      final next = _linkFromCatalog(
        platform: platform,
        value: value,
        profileProvider: profileProvider,
        existingId: existing?.id,
        isPublic: existing?.isPublic ?? true,
      );
      if (existingIndex >= 0) {
        links[existingIndex] = next;
      } else {
        links.add(next);
      }
    }

    upsert(SocialPlatform.whatsApp, whatsApp);
    upsert(SocialPlatform.instagram, instagram);
    upsert(SocialPlatform.tiktok, tiktok);
    upsert(SocialPlatform.snapchat, snapchat);

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

  void _openAddMore() {
    final profileProvider = context.read<ProfileProvider>();
    LinkSheet().showAddLinkBottomSheet(context, profileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      backgroundColor: AuthUi.bg,
      appBar: AppBar(
        backgroundColor: AuthUi.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          context.l10n.quickAddLinksTitle,
          style: AuthUi.screenTitle.copyWith(letterSpacing: 0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuthUi.horizontalPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.quickAddLinksSubtitle,
                      textAlign: TextAlign.center,
                      style: AuthUi.body,
                    ),
                    const SizedBox(height: 24),
                    _LinkField(
                      controller: _whatsAppController,
                      hintText: context.l10n.quickAddWhatsAppHint,
                      assetPath:
                          SocialLink.getAssetPath(SocialPlatform.whatsApp),
                      logoUrl:
                          _templateFor(SocialPlatform.whatsApp, provider)?.logo,
                      keyboardType: TextInputType.phone,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 12),
                    _LinkField(
                      controller: _instagramController,
                      hintText: context.l10n.quickAddInstagramHint,
                      assetPath:
                          SocialLink.getAssetPath(SocialPlatform.instagram),
                      logoUrl: _templateFor(
                        SocialPlatform.instagram,
                        provider,
                      )?.logo,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 12),
                    _LinkField(
                      controller: _snapchatController,
                      hintText: context.l10n.quickAddSnapchatHint,
                      assetPath:
                          SocialLink.getAssetPath(SocialPlatform.snapchat),
                      logoUrl: _templateFor(
                        SocialPlatform.snapchat,
                        provider,
                      )?.logo,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 12),
                    _LinkField(
                      controller: _tiktokController,
                      hintText: context.l10n.quickAddTiktokHint,
                      assetPath: SocialLink.getAssetPath(SocialPlatform.tiktok),
                      logoUrl:
                          _templateFor(SocialPlatform.tiktok, provider)?.logo,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 16),
                    AuthOutlinedChip(
                      label: 'Add more links',
                      onTap: _saving ? null : _openAddMore,
                      icon: Image.asset(
                        AuthUi.iconPlus,
                        width: 14,
                        height: 14,
                        color: AuthUi.textPrimary,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.add,
                          size: 16,
                          color: AuthUi.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AuthUi.horizontalPad,
                8,
                AuthUi.horizontalPad,
                8,
              ),
              child: AuthPillButton(
                label: context.l10n.next,
                loading: _saving,
                onPressed: _saving ? null : _handleContinue,
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _goToContactsSync,
              child: Text(
                context.l10n.skip,
                style: WaUi.bodyMedium.copyWith(
                  color: AuthUi.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.controller,
    required this.hintText,
    required this.assetPath,
    this.logoUrl,
    this.keyboardType,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final String assetPath;
  final String? logoUrl;
  final TextInputType? keyboardType;
  final bool enabled;

  Widget _icon() {
    final network = logoUrl?.trim() ?? '';
    final asset = Image.asset(
      assetPath,
      width: 28,
      height: 28,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.link,
        size: 22,
        color: AuthUi.textMuted,
      ),
    );
    if (network.startsWith('http://') || network.startsWith('https://')) {
      return Image.network(
        network,
        width: 28,
        height: 28,
        errorBuilder: (_, __, ___) => asset,
      );
    }
    return asset;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: WaUi.bodyMedium.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AuthUi.textPrimary,
      ),
      cursorColor: AuthUi.textPrimary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WaUi.body.copyWith(
          color: AuthUi.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: _icon(),
        ),
        filled: true,
        fillColor: AuthUi.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthUi.fieldRadius),
          borderSide: const BorderSide(color: AuthUi.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthUi.fieldRadius),
          borderSide: const BorderSide(color: AuthUi.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthUi.fieldRadius),
          borderSide: const BorderSide(
            color: AuthUi.borderFocused,
            width: 1.6,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthUi.fieldRadius),
          borderSide: const BorderSide(color: AuthUi.border),
        ),
      ),
    );
  }
}
