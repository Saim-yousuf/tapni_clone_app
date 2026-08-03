import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/screens/invitations/invite_contacts_screen.dart';
import 'package:tapni_app/screens/invitations/invitation_nav.dart';
import 'package:tapni_app/utils/business_card_export_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';

class CustomizeInvitationScreen extends StatefulWidget {
  final InvitationDraft draft;

  /// When true, opened from an existing draft (pop 1 screen after save).
  final bool fromDraftList;

  const CustomizeInvitationScreen({
    super.key,
    required this.draft,
    this.fromDraftList = false,
  });

  @override
  State<CustomizeInvitationScreen> createState() =>
      _CustomizeInvitationScreenState();
}

class _CustomizeInvitationScreenState extends State<CustomizeInvitationScreen> {
  static const _themes = [
    '#E85D2A',
    '#D4A017',
    '#C62828',
    '#AD1457',
    '#6A1B9A',
    '#1565C0',
    '#00838F',
    '#1F6B4A',
    '#37474F',
    '#4E342E',
  ];

  static const _types = [
    'wedding',
    'anniversary',
    'birthday',
    'business_meeting',
    'other',
  ];

  final GlobalKey _cardKey = GlobalKey();
  late final TextEditingController _titleController;
  late final TextEditingController _venueController;
  late final TextEditingController _addressController;
  late final TextEditingController _messageController;

  late String _type;
  late String _themeColor;
  DateTime? _eventAt;
  File? _coverFile;
  bool _picking = false;
  bool _downloading = false;

  bool get _hasWallpaper =>
      _coverFile != null ||
      (widget.draft.existingCoverUrl != null &&
          widget.draft.existingCoverUrl!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _type = d.type;
    _themeColor = d.themeColor;
    _eventAt = d.eventAt;
    _coverFile = d.coverImageFile;
    _titleController = TextEditingController(text: d.title);
    _venueController = TextEditingController(text: d.venue);
    _addressController = TextEditingController(text: d.address);
    _messageController = TextEditingController(text: d.message);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _syncDraft() {
    widget.draft
      ..type = _type
      ..title = _titleController.text.trim()
      ..venue = _venueController.text.trim()
      ..address = _addressController.text.trim()
      ..message = _messageController.text.trim()
      ..eventAt = _eventAt
      ..themeColor = _themeColor
      ..coverImageFile = _coverFile;
  }

  bool _requireTitle() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return false;
    }
    return true;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventAt ?? now.add(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventAt ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _eventAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickCover() async {
    setState(() => _picking = true);
    try {
      final picked = await pickSingleFile();
      if (picked?.file == null) return;
      final base64 = await fileToBase64(picked!.file!);
      setState(() {
        _coverFile = picked.file;
        widget.draft.coverImageFile = picked.file;
        widget.draft.coverImageBase64 = base64;
        widget.draft.clearCoverImage = false;
        widget.draft.existingCoverUrl = null;
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _removeWallpaper() {
    setState(() {
      _coverFile = null;
      widget.draft.coverImageFile = null;
      widget.draft.coverImageBase64 = null;
      widget.draft.existingCoverUrl = null;
      widget.draft.clearCoverImage = true;
    });
  }

  void _continue() {
    if (!_requireTitle()) return;
    _syncDraft();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InviteContactsScreen(draft: widget.draft),
      ),
    );
  }

  Future<void> _downloadCard() async {
    if (_downloading) return;
    if (!_requireTitle()) return;

    final format = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Save as PNG'),
              onTap: () => Navigator.pop(ctx, 'png'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Save as JPG'),
              onTap: () => Navigator.pop(ctx, 'jpg'),
            ),
          ],
        ),
      ),
    );
    if (format == null || !mounted) return;

    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final name = 'invitation_${_titleController.text.trim()}';
      final ok = format == 'jpg'
          ? await BusinessCardExportHelper.saveJpg(_cardKey, fileName: name)
          : await BusinessCardExportHelper.savePng(_cardKey, fileName: name);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Card saved to gallery (${format.toUpperCase()})'
                : 'Could not save. Check gallery permission.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _saveDraft() async {
    if (!_requireTitle()) return;
    _syncDraft();
    final draft = widget.draft;
    final provider = context.read<InvitationProvider>();
    final invitation = await provider.sendInvitation(
      type: draft.type,
      title: draft.title,
      message: draft.message,
      venue: draft.venue,
      address: draft.address,
      eventAt: draft.eventAt,
      themeColor: draft.themeColor,
      coverImageBase64: draft.coverImageBase64,
      clearCoverImage: draft.clearCoverImage,
      design: draft.design?.toJson(),
      recipientIds: const [],
      saveAsDraft: true,
      showFeedback: false,
      invitationId: draft.invitationId,
      context: context,
    );
    if (invitation != null && mounted) {
      draft.invitationId = invitation.id;
      draft.clearCoverImage = false;
      draft.existingCoverUrl =
          invitation.coverImage.isEmpty ? null : invitation.coverImage;
      finishInvitationFlow(
        context,
        message: 'Draft saved successfully',
        screensToPop: widget.fromDraftList ? 1 : 2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit =
        widget.fromDraftList || widget.draft.invitationId != null;
    final isSending = context.watch<InvitationProvider>().isSending;

    return Scaffold(
      backgroundColor: WaUi.scaffold,
      appBar: AppBar(
        backgroundColor: WaUi.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text(
          isEdit ? 'Edit invitation' : 'Customize card',
          style: WaUi.sectionHeader,
        ),
        actions: [
          IconButton(
            tooltip: 'Download',
            onPressed: _downloading ? null : _downloadCard,
            icon: _downloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                // Preview
                RepaintBoundary(
                  key: _cardKey,
                  child: InvitationCardPreview(
                    type: _type,
                    title: _titleController.text.trim(),
                    message: _messageController.text.trim(),
                    venue: _venueController.text.trim(),
                    address: _addressController.text.trim(),
                    eventAt: _eventAt,
                    themeColor: _themeColor,
                    coverImageFile: _coverFile,
                    coverImageUrl: _coverFile == null
                        ? widget.draft.existingCoverUrl
                        : null,
                    invitationId: widget.draft.invitationId,
                    isPreview: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Design
                _Section(
                  title: 'Design',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme', style: WaUi.label),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _themes.map((hex) {
                          final selected = _themeColor == hex;
                          final color = invitationColorFromHex(hex);
                          return GestureDetector(
                            onTap: () => setState(() => _themeColor = hex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? WaUi.primaryText
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text('Wallpaper', style: WaUi.label),
                      const SizedBox(height: 10),
                      _WallpaperTile(
                        hasImage: _hasWallpaper,
                        picking: _picking,
                        preview: _coverFile != null
                            ? Image.file(
                                _coverFile!,
                                fit: BoxFit.cover,
                              )
                            : (widget.draft.existingCoverUrl != null
                                ? Image.network(
                                    widget.draft.existingCoverUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  )
                                : null),
                        onPick: _pickCover,
                        onRemove: _hasWallpaper ? _removeWallpaper : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Type
                _Section(
                  title: 'Event type',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _types.map((type) {
                      final selected = _type == type;
                      return ChoiceChip(
                        label: Text(EventInvitation.typeLabel(type)),
                        selected: selected,
                        onSelected: (_) => setState(() => _type = type),
                        selectedColor: WaUi.chipBg,
                        showCheckmark: false,
                        labelStyle: WaUi.caption.copyWith(
                          color: WaUi.primaryText,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        backgroundColor: WaUi.scaffold,
                        side: BorderSide(
                          color: selected ? WaUi.accent : WaUi.divider,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Details
                _Section(
                  title: 'Details',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: _field('Title', required: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _venueController,
                        decoration: _field('Venue'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: _field(
                          'Address',
                          hint: 'Shown on the card',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDateTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: _field('Date & time'),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _eventAt == null
                                      ? 'Optional'
                                      : '${MaterialLocalizations.of(context).formatMediumDate(_eventAt!)} · ${TimeOfDay.fromDateTime(_eventAt!).format(context)}',
                                  style: WaUi.body.copyWith(
                                    color: _eventAt == null
                                        ? WaUi.secondaryText
                                        : WaUi.primaryText,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: WaUi.secondaryText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: _field('Message', hint: 'Optional note'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _BottomBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSending ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WaUi.buttonDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Select contacts & send'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: isSending ? null : _saveDraft,
                    style: TextButton.styleFrom(
                      foregroundColor: WaUi.secondaryText,
                    ),
                    child: Text(
                      widget.draft.invitationId != null
                          ? 'Update draft'
                          : 'Save as draft',
                    ),
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

  InputDecoration _field(String label, {String? hint, bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,
      filled: true,
      fillColor: WaUi.scaffold,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WaUi.accent, width: 1.5),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: WaUi.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: WaUi.bodyMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  final bool hasImage;
  final bool picking;
  final Widget? preview;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _WallpaperTile({
    required this.hasImage,
    required this.picking,
    required this.preview,
    required this.onPick,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WaUi.scaffold,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: picking ? null : onPick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: hasImage && preview != null
                      ? preview
                      : ColoredBox(
                          color: WaUi.divider,
                          child: Icon(
                            Icons.wallpaper_rounded,
                            size: 22,
                            color: WaUi.secondaryText,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasImage ? 'Wallpaper selected' : 'Add wallpaper',
                      style: WaUi.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fills the full card background',
                      style: WaUi.label,
                    ),
                  ],
                ),
              ),
              if (picking)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: WaUi.secondaryText,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove',
                )
              else
                const Icon(
                  Icons.add_rounded,
                  color: WaUi.secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: WaUi.surface,
        border: Border(top: BorderSide(color: WaUi.divider)),
      ),
      child: child,
    );
  }
}
