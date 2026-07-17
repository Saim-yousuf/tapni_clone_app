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
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _continue() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    _syncDraft();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InviteContactsScreen(draft: widget.draft),
      ),
    );
  }

  Future<void> _downloadCard() async {
    if (_downloading) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title before downloading')),
      );
      return;
    }

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
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
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
      recipientIds: const [],
      saveAsDraft: true,
      showFeedback: false,
      invitationId: draft.invitationId,
      context: context,
    );
    if (invitation != null && mounted) {
      draft.invitationId = invitation.id;
      finishInvitationFlow(
        context,
        message: 'Draft saved successfully',
        screensToPop: widget.fromDraftList ? 1 : 2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.scaffold,
      appBar: AppBar(
        backgroundColor: WaUi.surface,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text(
          widget.fromDraftList || widget.draft.invitationId != null
              ? 'Edit draft'
              : 'Customize card',
          style: WaUi.sectionHeader,
        ),
        actions: [
          IconButton(
            tooltip: 'Download card',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Live preview', style: WaUi.bodyMedium),
          const SizedBox(height: 10),
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
          OutlinedButton.icon(
            onPressed: _downloading ? null : _downloadCard,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(
              _downloading ? 'Saving...' : 'Download card (PNG / JPG)',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: WaUi.primaryText,
              side: const BorderSide(color: WaUi.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 28),

          _sectionTitle('Event type'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((type) {
              final selected = _type == type;
              return ChoiceChip(
                label: Text(EventInvitation.typeLabel(type)),
                selected: selected,
                onSelected: (_) => setState(() => _type = type),
                selectedColor: WaUi.chipBg,
                labelStyle: WaUi.caption.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                backgroundColor: WaUi.surface,
                side: BorderSide(
                  color: selected ? WaUi.accent : WaUi.divider,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _sectionTitle('Details'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _titleController,
            decoration: _decoration('Event title *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _venueController,
            decoration: _decoration('Venue / place name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: _decoration(
              'Full address',
              hint: 'Shown on the invitation card',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _decoration('Date & time'),
              child: Text(
                _eventAt == null
                    ? 'Select date & time'
                    : '${MaterialLocalizations.of(context).formatFullDate(_eventAt!)} · ${TimeOfDay.fromDateTime(_eventAt!).format(context)}',
                style: WaUi.body.copyWith(
                  color: _eventAt == null
                      ? WaUi.secondaryText
                      : WaUi.primaryText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _messageController,
            maxLines: 4,
            decoration: _decoration('Message / note'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Theme color'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _themes.map((hex) {
              final selected = _themeColor == hex;
              final color = invitationColorFromHex(hex);
              return GestureDetector(
                onTap: () => setState(() => _themeColor = hex),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? WaUi.primaryText : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Cover image'),
          const SizedBox(height: 12),
          if (_coverFile != null ||
              (widget.draft.existingCoverUrl != null &&
                  widget.draft.existingCoverUrl!.isNotEmpty)) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _coverFile != null
                  ? Image.file(
                      _coverFile!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      widget.draft.existingCoverUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: WaUi.navPill,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _picking ? null : _pickCover,
                  icon: _picking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_outlined),
                  label: Text(
                    (_coverFile != null ||
                            widget.draft.existingCoverUrl != null)
                        ? 'Change'
                        : 'Add cover',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WaUi.primaryText,
                    side: const BorderSide(color: WaUi.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_coverFile != null ||
                  widget.draft.existingCoverUrl != null) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _coverFile = null;
                      widget.draft.coverImageFile = null;
                      widget.draft.coverImageBase64 = null;
                      widget.draft.existingCoverUrl = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: WaUi.divider),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: context.watch<InvitationProvider>().isSending
                  ? null
                  : _saveDraft,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(
                widget.draft.invitationId != null
                    ? 'Update draft'
                    : 'Save draft',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: WaUi.primaryText,
                side: const BorderSide(color: WaUi.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: WaUi.buttonDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Select contacts & send'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: WaUi.bodyMedium);

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: WaUi.surface,
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WaUi.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WaUi.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WaUi.accent, width: 1.5),
      ),
    );
  }
}
