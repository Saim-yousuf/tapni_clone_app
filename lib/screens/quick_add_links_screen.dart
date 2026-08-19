import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/contacts_sync_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

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

  @override
  void initState() {
    super.initState();
    _whatsAppController = TextEditingController(text: widget.phone ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.linkCatalog.isEmpty) {
        profileProvider.fetchLinkCatalog();
      }
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

  String _cleanUsername(String raw) {
    var value = raw.trim();
    if (value.startsWith('@')) value = value.substring(1).trim();
    return value;
  }

  void _goToContactsSync() {
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
    final name = SocialLink.getPlatformName(platform).toLowerCase();
    for (final category in profileProvider.linkCatalog) {
      for (final template in category.templates) {
        final label = template.label.toLowerCase();
        if (label.contains(name) || name.contains(label)) {
          return template;
        }
      }
    }
    return null;
  }

  SocialLink _link(
    SocialPlatform platform,
    String value,
    ProfileProvider profileProvider,
  ) {
    final template = _templateFor(platform, profileProvider);
    return SocialLink(
      id: 'quick_${platform.name}_${value.hashCode}',
      platform: platform,
      templateId: template?.id,
      customLabel: SocialLink.getPlatformName(platform),
      fieldLabel: template?.fieldLabel,
      fieldType: template?.fieldType,
      actionType: template?.actionType,
      logoUrl: template?.logo,
      value: value,
      isActive: true,
      isPublic: true,
    );
  }

  Future<void> _handleContinue() async {
    if (_saving) return;

    final whatsApp = _whatsAppController.text.trim();
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
      links.removeWhere((link) => link.platform == platform);
      links.add(_link(platform, value, profileProvider));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: false,
        foregroundColor: WaUi.primaryText,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.quickAddLinksTitle,
                      textAlign: TextAlign.center,
                      style: WaUi.headline.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.quickAddLinksSubtitle,
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(color: WaUi.secondaryText),
                    ),
                    const SizedBox(height: 28),
                    _LinkField(
                      controller: _whatsAppController,
                      hintText: context.l10n.quickAddWhatsAppHint,
                      assetPath: SocialLink.getAssetPath(SocialPlatform.whatsApp),
                      keyboardType: TextInputType.phone,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 12),
                    _LinkField(
                      controller: _instagramController,
                      hintText: context.l10n.quickAddInstagramHint,
                      assetPath:
                          SocialLink.getAssetPath(SocialPlatform.instagram),
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 12),
                    _LinkField(
                      controller: _tiktokController,
                      hintText: context.l10n.quickAddTiktokHint,
                      assetPath: SocialLink.getAssetPath(SocialPlatform.tiktok),
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 12),
                    _LinkField(
                      controller: _snapchatController,
                      hintText: context.l10n.quickAddSnapchatHint,
                      assetPath:
                          SocialLink.getAssetPath(SocialPlatform.snapchat),
                      enabled: !_saving,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
              child: WaPrimaryButton(
                label: context.l10n.next,
                loading: _saving,
                onPressed: _saving ? null : _handleContinue,
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _goToContactsSync,
              child: Text(
                context.l10n.skip,
                style: WaUi.bodyMedium.copyWith(color: WaUi.secondaryText),
              ),
            ),
            const SizedBox(height: 12),
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
    this.keyboardType,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final String assetPath;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: WaUi.bodyMedium.copyWith(fontSize: 16),
      cursorColor: AppTheme.primaryBlack,
      decoration: WaUi.fieldDecoration(
        hintText: hintText,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            assetPath,
            width: 24,
            height: 24,
            errorBuilder: (_, __, ___) => Icon(
              Icons.link,
              size: 22,
              color: WaUi.promoIconFg,
            ),
          ),
        ),
      ),
    );
  }
}
