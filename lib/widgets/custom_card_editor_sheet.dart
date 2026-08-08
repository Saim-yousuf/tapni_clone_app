import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/user_custom_card.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/card_template_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/template_business_card_preview.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
enum _CardSetupMode { pick, template, customize }

class CustomCardEditorSheet extends StatefulWidget {
  final UserCustomCard? existing;

  const CustomCardEditorSheet({super.key, this.existing});

  static Future<void> show(BuildContext context, {UserCustomCard? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomCardEditorSheet(existing: existing),
    );
  }

  @override
  State<CustomCardEditorSheet> createState() => _CustomCardEditorSheetState();
}

class _CustomCardEditorSheetState extends State<CustomCardEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _nameController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _bioController;

  late _CardSetupMode _step;
  late String _templateId;
  String? _backgroundColorHex;
  String? _profilePhotoPath;
  String? _coverPhotoPath;
  late Set<String> _enabledLinkIds;
  bool _saving = false;

  static const _colorPresets = [
    '#1E2022',
    '#000000',
    '#EA2C3B',
    '#7A78FF',
    '#6BB5FF',
    '#9EBF7B',
    '#FFFFFF',
    '#F5EBE1',
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
    final existing = widget.existing;

    _titleController = TextEditingController(
      text: existing?.title ?? context.l10n.newCard,
    );
    _nameController = TextEditingController(
      text: existing?.displayName ?? profile.name,
    );
    _subtitleController = TextEditingController(text: existing?.subtitle ?? '');
    _bioController = TextEditingController(text: existing?.bio ?? '');
    _templateId = existing?.cardTemplateId ?? CardTemplateCatalog.defaultTemplateId;
    _backgroundColorHex = existing?.backgroundColorHex;
    _profilePhotoPath = existing?.profilePhotoUrl;
    _coverPhotoPath = existing?.coverPhotoUrl;

    final allLinkIds = profile.socialLinks
        .where((l) => l.isActive)
        .map((l) => l.id)
        .toSet();
    if (existing != null && existing.enabledLinkIds.isNotEmpty) {
      _enabledLinkIds = existing.enabledLinkIds.toSet();
    } else {
      _enabledLinkIds = allLinkIds;
    }

    if (_isEditing) {
      final hasCustomDesign = existing!.backgroundColorHex != null ||
          existing.coverPhotoUrl != null ||
          existing.profilePhotoUrl != null;
      _step = hasCustomDesign ? _CardSetupMode.customize : _CardSetupMode.template;
    } else {
      _step = _CardSetupMode.pick;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _subtitleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  UserCustomCard _buildCard(String id) {
    return UserCustomCard(
      id: id,
      title: _titleController.text.trim().isEmpty
          ? context.l10n.myCard
          : _titleController.text.trim(),
      displayName: _nameController.text.trim().isEmpty
          ? context.l10n.myName
          : _nameController.text.trim(),
      subtitle: _subtitleController.text.trim().isEmpty
          ? null
          : _subtitleController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      cardTemplateId: _templateId,
      backgroundColorHex: _step == _CardSetupMode.template ? null : _backgroundColorHex,
      profilePhotoUrl: _profilePhotoPath,
      coverPhotoUrl: _step == _CardSetupMode.template ? null : _coverPhotoPath,
      enabledLinkIds: _enabledLinkIds.toList(),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final id = widget.existing?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final card = _buildCard(id);

    String? profilePhoto = _profilePhotoPath;
    String? coverPhoto = _step == _CardSetupMode.customize ? _coverPhotoPath : null;

    if (_profilePhotoPath != null &&
        !_profilePhotoPath!.startsWith('http') &&
        !_profilePhotoPath!.startsWith('data:')) {
      profilePhoto = await fileToBase64(File(_profilePhotoPath!));
    }
    if (coverPhoto != null &&
        !coverPhoto.startsWith('http') &&
        !coverPhoto.startsWith('data:')) {
      coverPhoto = await fileToBase64(File(coverPhoto));
    }

    final savedCard = card.copyWith(
      profilePhotoUrl: profilePhoto,
      coverPhotoUrl: coverPhoto,
      clearCoverPhoto: _step == _CardSetupMode.template,
      clearBackgroundColor: _step == _CardSetupMode.template,
    );

    final ok = _isEditing
        ? await provider.updateCustomCard(savedCard)
        : await provider.addCustomCard(savedCard);

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (_isEditing ? context.l10n.cardUpdated : context.l10n.cardCreated)
              : context.l10n.savedLocallySyncMayHaveFailed,
          style: WaUi.body.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: WaUi.primaryText,
      ),
    );
    if (ok || !_isEditing) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteCard, style: WaUi.title),
        content: Text(context.l10n.thisCardAndItsQRCodeWillBeRemoved, style: WaUi.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    await provider.deleteCustomCard(widget.existing!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      decoration: WaUi.sheetDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: WaUi.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                if (_step != _CardSetupMode.pick && !_isEditing)
                  IconButton(
                    onPressed: () => setState(() => _step = _CardSetupMode.pick),
                    icon: Icon(Icons.arrow_back, color: WaUi.secondaryText),
                  ),
                Expanded(
                  child: Text(
                    _headerTitle,
                    style: WaUi.headline,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: WaUi.secondaryText),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
              child: _step == _CardSetupMode.pick
                  ? _buildModePicker()
                  : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  String get _headerTitle {
    if (_step == _CardSetupMode.pick) return context.l10n.newCard2;
    if (_isEditing) return context.l10n.editCard;
    return _step == _CardSetupMode.template ? context.l10n.chooseTemplate2 : context.l10n.customizeCard;
  }

  Widget _buildModePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.howDoYouWantToDesignThisCard, style: WaUi.body),
        SizedBox(height: 16),
        _ModeTile(
          icon: Icons.palette_outlined,
          title: context.l10n.useATemplate,
          subtitle: context.l10n.pickAReadyMadeColorThemeQuickAndClean,
          onTap: () => setState(() => _step = _CardSetupMode.template),
        ),
        SizedBox(height: 10),
        _ModeTile(
          icon: Icons.tune_rounded,
          title: context.l10n.customizeYourself,
          subtitle: context.l10n.setYourOwnColorsPhotosAndBackground,
          onTap: () => setState(() => _step = _CardSetupMode.customize),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final provider = Provider.of<ProfileProvider>(context);
    final profile = provider.profile;
    final username = profile.username ?? '';
    final previewCard = _buildCard(widget.existing?.id ?? 'preview');
    final previewUrl = previewCard.profileUrl(username);
    final links = profile.socialLinks.where((l) => l.isActive).toList();
    final isCustomize = _step == _CardSetupMode.customize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: TemplateBusinessCardPreview(
            template: previewCard.effectiveTemplate(),
            name: previewCard.displayName,
            profileUrl: previewUrl,
            userInitial: previewCard.displayName.isNotEmpty
                ? previewCard.displayName[0].toUpperCase()
                : '?',
            profilePhotoUrl: _profilePhotoPath,
            coverPhotoUrl: isCustomize ? _coverPhotoPath : null,
            subtitle: previewCard.subtitle,
            bio: previewCard.bio,
            width: 300,
          ),
        ),
        SizedBox(height: 20),
        _field(
          context.l10n.cardName,
          _titleController,
          hint: context.l10n.egWorkEvents,
        ),
        SizedBox(height: 10),
        _field(context.l10n.displayName, _nameController),
        SizedBox(height: 10),
        _field(
          context.l10n.subtitle,
          _subtitleController,
          hint: context.l10n.roleOrCompany,
        ),
        SizedBox(height: 10),
        _field(context.l10n.bio2, _bioController, maxLines: 2),
        SizedBox(height: 16),
        Text(context.l10n.template, style: WaUi.bodyMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CardTemplateCatalog.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final template = CardTemplateCatalog.all[index];
              final selected = template.id == _templateId;
              return GestureDetector(
                onTap: () {
                  if (template.isPro && !provider.isProUser) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ProUpgradeSheet(),
                    );
                    return;
                  }
                  setState(() => _templateId = template.id);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: template.backgroundColor,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: selected ? WaUi.accent : WaUi.divider,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    template.name,
                    style: TextStyle(
                      color: template.textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (isCustomize) ...[
          SizedBox(height: 16),
          Text(context.l10n.photos, style: WaUi.bodyMedium),
          SizedBox(height: 8),
          Row(
            children: [
              _photoPicker(
                label: context.l10n.profile,
                path: _profilePhotoPath,
                onPick: () async {
                  final file = await pickFile();
                  if (file?.file != null) {
                    setState(() => _profilePhotoPath = file!.file!.path);
                  }
                },
              ),
              SizedBox(width: 12),
              _photoPicker(
                label: context.l10n.background,
                path: _coverPhotoPath,
                onPick: () async {
                  final file = await pickFile();
                  if (file?.file != null) {
                    setState(() => _coverPhotoPath = file!.file!.path);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(context.l10n.backgroundColor, style: WaUi.bodyMedium),
          SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _colorDot(null, label: context.l10n.template),
              ..._colorPresets.map(_colorDot),
            ],
          ),
        ],
        SizedBox(height: 16),
        Text(context.l10n.linksOnThisCard, style: WaUi.bodyMedium),
        SizedBox(height: 4),
        Text(
          context.l10n.onlyEnabledLinksShowWhenSomeoneScansThisCard,
          style: WaUi.caption,
        ),
        SizedBox(height: 8),
        if (links.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WaUi.scaffold,
              borderRadius: BorderRadius.circular(WaUi.radiusMd),
            ),
            child: Text(
              context.l10n.addLinksToYourProfileFirstThenEnableThemHere,
              style: WaUi.caption,
            ),
          )
        else
          ...links.map((link) {
            final enabled = _enabledLinkIds.contains(link.id);
            return _LinkToggleRow(
              linkName: link.platformName,
              logoUrl: link.logoUrl,
              enabled: enabled,
              onChanged: (val) {
                setState(() {
                  if (val) {
                    _enabledLinkIds.add(link.id);
                  } else {
                    _enabledLinkIds.remove(link.id);
                  }
                });
              },
            );
          }),
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: WaUi.primaryText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WaUi.radiusMd),
              ),
            ),
            child: _saving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? context.l10n.saveCard : context.l10n.createCard,
                    style: WaUi.button.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      style: WaUi.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: WaUi.caption,
        hintText: hint,
        hintStyle: WaUi.caption,
        filled: true,
        fillColor: WaUi.scaffold,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WaUi.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _photoPicker({
    required String label,
    required String? path,
    required VoidCallback onPick,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPick,
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: WaUi.scaffold,
            borderRadius: BorderRadius.circular(WaUi.radiusMd),
            image: path != null && path.isNotEmpty
                ? DecorationImage(
                    image: path.startsWith('http') || path.startsWith('data:')
                        ? NetworkImage(path)
                        : FileImage(File(path)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: path == null || path.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined, color: WaUi.secondaryText),
                    const SizedBox(height: 4),
                    Text(label, style: WaUi.caption),
                  ],
                )
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.black45,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: WaUi.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _colorDot(String? hex, {String? label}) {
    final selected = _backgroundColorHex == hex;
    final color = hex == null
        ? Colors.transparent
        : Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));

    return GestureDetector(
      onTap: () => setState(() => _backgroundColorHex = hex),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: hex == null ? WaUi.scaffold : color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? WaUi.accent : WaUi.divider,
                width: selected ? 2 : 1,
              ),
            ),
            child: hex == null
                ? const Icon(Icons.auto_awesome, size: 16, color: WaUi.secondaryText)
                : null,
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label, style: WaUi.caption.copyWith(fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _LinkToggleRow extends StatelessWidget {
  final String linkName;
  final String? logoUrl;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _LinkToggleRow({
    required this.linkName,
    this.logoUrl,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WaUi.surface,
      borderRadius: BorderRadius.circular(WaUi.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            if (logoUrl?.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  logoUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.link, color: WaUi.secondaryText),
                ),
              )
            else
              Icon(Icons.link, color: WaUi.secondaryText, size: 40),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(linkName, style: WaUi.bodyMedium),
                  Text(context.l10n.showOnThisCard, style: WaUi.caption),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onChanged,
              activeTrackColor: WaUi.accent.withValues(alpha: 0.35),
              activeThumbColor: WaUi.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WaUi.scaffold,
      borderRadius: BorderRadius.circular(WaUi.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WaUi.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WaUi.chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: WaUi.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: WaUi.bodyMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: WaUi.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: WaUi.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
