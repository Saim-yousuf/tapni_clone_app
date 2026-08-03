import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/invitation_design.dart';
import 'package:tapni_app/providers/invitation_provider.dart';
import 'package:tapni_app/screens/invitations/invite_contacts_screen.dart';
import 'package:tapni_app/screens/invitations/invitation_nav.dart';
import 'package:tapni_app/utils/business_card_export_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';

/// Canva-like invitation design editor: select, drag, add/remove layers,
/// edit text, upload logo, toggle RTL, change colors.
class InvitationDesignEditorScreen extends StatefulWidget {
  final InvitationDesign design;
  final InvitationDraft? existingDraft;

  const InvitationDesignEditorScreen({
    super.key,
    required this.design,
    this.existingDraft,
  });

  @override
  State<InvitationDesignEditorScreen> createState() =>
      _InvitationDesignEditorScreenState();
}

class _InvitationDesignEditorScreenState
    extends State<InvitationDesignEditorScreen> {
  late InvitationDesign _design;
  String? _selectedId;
  final GlobalKey _cardKey = GlobalKey();
  final List<InvitationDesign> _undo = [];
  final List<InvitationDesign> _redo = [];
  bool _downloading = false;

  DesignLayer? get _selected {
    if (_selectedId == null) return null;
    try {
      return _design.layers.firstWhere((l) => l.id == _selectedId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _design = widget.design.copy();
  }

  void _pushUndo() {
    _undo.add(_design.copy());
    if (_undo.length > 40) _undo.removeAt(0);
    _redo.clear();
  }

  void _doUndo() {
    if (_undo.isEmpty) return;
    _redo.add(_design.copy());
    setState(() => _design = _undo.removeLast());
  }

  void _doRedo() {
    if (_redo.isEmpty) return;
    _undo.add(_design.copy());
    setState(() => _design = _redo.removeLast());
  }

  void _updateLayer(String id, DesignLayer Function(DesignLayer) fn) {
    _pushUndo();
    setState(() {
      final i = _design.layers.indexWhere((l) => l.id == id);
      if (i >= 0) _design.layers[i] = fn(_design.layers[i]);
    });
  }

  void _onLayerTap(String id) {
    setState(() => _selectedId = id);
    final layer = _design.layers.firstWhere((l) => l.id == id);
    if (layer.type == DesignLayerType.text ||
        layer.type == DesignLayerType.iconField) {
      _editText(layer);
    } else if (layer.type == DesignLayerType.logo ||
        layer.type == DesignLayerType.image) {
      _pickImageForLayer(layer);
    } else if (layer.type == DesignLayerType.qr) {
      _editQr(layer);
    }
  }

  void _onLayerDrag(String id, Offset delta) {
    final i = _design.layers.indexWhere((l) => l.id == id);
    if (i < 0 || _design.layers[i].locked) return;
    setState(() {
      final l = _design.layers[i];
      _design.layers[i] = l.copyWith(
        x: (l.x + delta.dx).clamp(-0.2, 0.95),
        y: (l.y + delta.dy).clamp(-0.2, 0.95),
      );
    });
  }

  Future<void> _editText(DesignLayer layer) async {
    final controller = TextEditingController(text: layer.text);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit text', style: WaUi.sectionHeader),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                textDirection:
                    _design.rtl ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'Enter text…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                style: FilledButton.styleFrom(
                  backgroundColor: WaUi.buttonDark,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      _updateLayer(layer.id, (l) => l.copyWith(text: result));
    }
  }

  Future<void> _editQr(DesignLayer layer) async {
    final controller = TextEditingController(text: layer.qrData);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('QR code data (URL / text)', style: WaUi.sectionHeader),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'https://maps.google.com/…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                style: FilledButton.styleFrom(
                  backgroundColor: WaUi.buttonDark,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      _updateLayer(layer.id, (l) => l.copyWith(qrData: result));
    }
  }

  Future<void> _pickImageForLayer(DesignLayer layer) async {
    final picked = await pickSingleFile();
    if (picked?.file == null) return;
    final b64 = await fileToBase64(picked!.file!);
    final mime = picked.mimeType.startsWith('image/')
        ? picked.mimeType
        : 'image/jpeg';
    final dataUri = 'data:$mime;base64,$b64';
    _updateLayer(layer.id, (l) => l.copyWith(imageSrc: dataUri));
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    _pushUndo();
    setState(() {
      _design.layers.removeWhere((l) => l.id == _selectedId);
      _selectedId = null;
    });
  }

  void _addLayer(DesignLayerType type) {
    _pushUndo();
    final z = _design.layers.isEmpty
        ? 1
        : _design.layers.map((e) => e.zIndex).reduce((a, b) => a > b ? a : b) +
            1;
    late DesignLayer layer;
    switch (type) {
      case DesignLayerType.text:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.text,
          fieldKey: 'custom',
          text: _design.rtl ? 'نص جديد' : 'New text',
          fontFamily: _design.rtl ? 'cairo' : 'playfair',
          fontSize: 0.04,
          color: _isDarkBg ? '#FFFFFF' : '#212121',
          x: 0.15,
          y: 0.4,
          width: 0.7,
          height: 0.08,
          zIndex: z,
        );
      case DesignLayerType.iconField:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.iconField,
          fieldKey: 'custom',
          text: _design.rtl ? 'تفاصيل' : 'Details',
          iconName: 'calendar',
          fontFamily: _design.rtl ? 'cairo' : 'roboto',
          fontSize: 0.028,
          color: _isDarkBg ? '#FFFFFF' : '#212121',
          x: 0.3,
          y: 0.5,
          width: 0.4,
          height: 0.12,
          zIndex: z,
        );
      case DesignLayerType.logo:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.logo,
          fieldKey: 'logo',
          color: _isDarkBg ? '#D4AF37' : '#212121',
          x: 0.35,
          y: 0.1,
          width: 0.3,
          height: 0.15,
          zIndex: z,
          borderWidth: 1.5,
          borderColor: _isDarkBg ? '#D4AF37' : '#212121',
        );
      case DesignLayerType.image:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.image,
          fieldKey: 'photo',
          x: 0.2,
          y: 0.3,
          width: 0.6,
          height: 0.3,
          zIndex: z,
        );
      case DesignLayerType.qr:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.qr,
          fieldKey: 'qr',
          qrData: 'barqody://invitation/preview',
          qrColor: '#000000',
          x: 0.35,
          y: 0.65,
          width: 0.3,
          height: 0.18,
          zIndex: z,
        );
      case DesignLayerType.shape:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.shape,
          shape: 'divider',
          color: _isDarkBg ? '#D4AF37' : '#212121',
          x: 0.25,
          y: 0.5,
          width: 0.5,
          height: 0.03,
          zIndex: z,
        );
      case DesignLayerType.ornament:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.ornament,
          shape: 'diamond',
          color: _isDarkBg ? '#D4AF37' : '#212121',
          x: 0.45,
          y: 0.5,
          width: 0.1,
          height: 0.06,
          zIndex: z,
        );
    }
    setState(() {
      _design.layers.add(layer);
      _selectedId = layer.id;
    });
    if (type == DesignLayerType.logo || type == DesignLayerType.image) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImageForLayer(layer);
      });
    }
  }

  bool get _isDarkBg {
    final c = designColorFromHex(_design.backgroundColor, fallback: Colors.black);
    return c.computeLuminance() < 0.45;
  }

  InvitationDraft _toDraft() {
    final title = _design.textForField('title') ??
        _design.textForField('names') ??
        'Invitation';
    final message = _design.textForField('message') ??
        _design.textForField('greeting') ??
        '';
    final venue = _design.textForField('venue') ?? '';
    final address = _design.textForField('address') ?? '';
    final host = _design.textForField('host') ?? '';

    String type = 'other';
    switch (_design.category) {
      case 'wedding':
      case 'engagement':
        type = 'wedding';
      case 'birthday':
        type = 'birthday';
      case 'anniversary':
        type = 'anniversary';
      case 'business':
        type = 'business_meeting';
      default:
        type = 'other';
    }

    final existing = widget.existingDraft;
    return InvitationDraft(
      invitationId: existing?.invitationId,
      type: type,
      title: title.trim().isEmpty ? 'Invitation' : title.trim(),
      message: [message, if (host.isNotEmpty) host].where((e) => e.isNotEmpty).join('\n'),
      venue: venue,
      address: address,
      eventAt: existing?.eventAt,
      themeColor: _design.backgroundColor.startsWith('#')
          ? _design.backgroundColor
          : '#E85D2A',
      coverImageFile: existing?.coverImageFile,
      coverImageBase64: existing?.coverImageBase64,
      existingCoverUrl: existing?.existingCoverUrl,
      clearCoverImage: existing?.clearCoverImage ?? false,
      design: _design,
    );
  }

  void _continue() {
    final draft = _toDraft();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InviteContactsScreen(draft: draft),
      ),
    );
  }

  Future<void> _saveDraft() async {
    final draft = _toDraft();
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
      widget.existingDraft?.invitationId = invitation.id;
      finishInvitationFlow(
        context,
        message: 'Draft saved successfully',
        screensToPop: widget.existingDraft != null ? 1 : 2,
      );
    }
  }

  Future<void> _publishTemplate() async {
    final nameCtrl = TextEditingController(
      text: _design.textForField('title') ?? 'My invitation template',
    );
    final descCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share this design so other users can use it from the template gallery.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Template name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: WaUi.buttonDark),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    await context.read<InvitationProvider>().publishTemplate(
          name: name,
          description: descCtrl.text.trim(),
          design: _design,
          context: context,
        );
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final name = 'invitation_${_design.templateId}';
      final ok = await BusinessCardExportHelper.savePng(
        _cardKey,
        fileName: name,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(ok ? 'Saved to gallery' : 'Could not save'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _pickBackgroundColor() async {
    final presets = [
      '#0A0A0A',
      '#F5F2EB',
      '#F7EDE8',
      '#0B3D2E',
      '#1A0A2E',
      '#0D1B2A',
      '#FAFAFA',
      '#6C63FF',
      '#8D1B3D',
      '#1C2833',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Background color', style: WaUi.sectionHeader),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: presets.map((hex) {
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, hex),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: invitationColorFromHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(color: WaUi.chipBorder),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      _pushUndo();
      setState(() => _design.backgroundColor = picked);
    }
  }

  Future<void> _pickBackgroundImage() async {
    final picked = await pickSingleFile();
    if (picked?.file == null) return;
    final b64 = await fileToBase64(picked!.file!);
    final mime = picked.mimeType.startsWith('image/')
        ? picked.mimeType
        : 'image/jpeg';
    _pushUndo();
    setState(() => _design.backgroundImage = 'data:$mime;base64,$b64');
  }

  void _showAddMenu() {
    showModalBottomSheet(
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
              leading: const Icon(Icons.text_fields),
              title: const Text('Text'),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Info field (icon + text)'),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.iconField);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Logo'),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.logo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('QR code'),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.qr);
              },
            ),
            ListTile(
              leading: const Icon(Icons.horizontal_rule),
              title: const Text('Divider'),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.shape);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLayerStyleSheet() {
    final layer = _selected;
    if (layer == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _LayerStyleSheet(
          layer: layer,
          rtl: _design.rtl,
          onChanged: (updated) {
            _updateLayer(layer.id, (_) => updated);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final isSending = context.watch<InvitationProvider>().isSending;
    final isPublishing = context.watch<InvitationProvider>().isPublishing;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      appBar: AppBar(
        backgroundColor: WaUi.surface,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text('Design invitation', style: WaUi.sectionHeader),
        actions: [
          IconButton(
            tooltip: 'Publish for others',
            onPressed: isPublishing ? null : _publishTemplate,
            icon: isPublishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.public),
          ),
          IconButton(
            tooltip: 'Undo',
            onPressed: _undo.isEmpty ? null : _doUndo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: _redo.isEmpty ? null : _doRedo,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Download',
            onPressed: _downloading ? null : _download,
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
      body: Column(
        children: [
          // Toolbar
          Container(
            color: WaUi.surface,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolBtn(
                    icon: Icons.add_box_outlined,
                    label: 'Add',
                    onTap: _showAddMenu,
                  ),
                  _ToolBtn(
                    icon: Icons.palette_outlined,
                    label: 'BG',
                    onTap: _pickBackgroundColor,
                  ),
                  _ToolBtn(
                    icon: Icons.wallpaper_outlined,
                    label: 'Photo BG',
                    onTap: _pickBackgroundImage,
                  ),
                  _ToolBtn(
                    icon: Icons.translate,
                    label: _design.rtl ? 'RTL' : 'LTR',
                    onTap: () {
                      _pushUndo();
                      setState(() => _design.rtl = !_design.rtl);
                    },
                  ),
                  _ToolBtn(
                    icon: Icons.public,
                    label: 'Publish',
                    onTap: _publishTemplate,
                  ),
                  if (selected != null) ...[
                    _ToolBtn(
                      icon: Icons.tune,
                      label: 'Style',
                      onTap: _showLayerStyleSheet,
                    ),
                    _ToolBtn(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: _deleteSelected,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Canvas
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedId = null),
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: InvitationDesignRenderer(
                        design: _design,
                        interactive: true,
                        selectedLayerId: _selectedId,
                        onLayerTap: _onLayerTap,
                        onLayerDrag: (id, d) {
                          // Don't push undo every frame — only on first move of gesture
                          // handled simply by updating without undo during drag
                          _onLayerDrag(id, d);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom bar
          SafeArea(
            top: false,
            child: Container(
              color: WaUi.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSending ? null : _saveDraft,
                      child: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: WaUi.buttonDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Continue · Invite'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: WaUi.primaryText),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, color: WaUi.primaryText),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }
}

class _LayerStyleSheet extends StatefulWidget {
  final DesignLayer layer;
  final bool rtl;
  final ValueChanged<DesignLayer> onChanged;

  const _LayerStyleSheet({
    required this.layer,
    required this.rtl,
    required this.onChanged,
  });

  @override
  State<_LayerStyleSheet> createState() => _LayerStyleSheetState();
}

class _LayerStyleSheetState extends State<_LayerStyleSheet> {
  late DesignLayer _layer;

  static const _fonts = [
    'cairo',
    'amiri',
    'noto_naskh',
    'playfair',
    'cormorant',
    'roboto',
  ];

  static const _colors = [
    '#FFFFFF',
    '#000000',
    '#D4AF37',
    '#C08081',
    '#1B3A4B',
    '#2A9D8F',
    '#E91E63',
    '#4FC3F7',
    '#FF8C00',
    '#C0392B',
  ];

  static const _icons = [
    'calendar',
    'clock',
    'location',
    'person',
    'phone',
    'email',
    'link',
  ];

  @override
  void initState() {
    super.initState();
    _layer = widget.layer.copyWith();
  }

  void _apply(DesignLayer next) {
    setState(() => _layer = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (ctx, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text('Layer style', style: WaUi.sectionHeader),
            const SizedBox(height: 16),
            if (_layer.type == DesignLayerType.text ||
                _layer.type == DesignLayerType.iconField) ...[
              Text('Font', style: WaUi.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _fonts.map((f) {
                  final sel = _layer.fontFamily == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: sel,
                    onSelected: (_) =>
                        _apply(_layer.copyWith(fontFamily: f)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Size  ${(_layer.fontSize * 100).toStringAsFixed(0)}%',
                style: WaUi.label,
              ),
              Slider(
                value: _layer.fontSize.clamp(0.018, 0.12),
                min: 0.018,
                max: 0.12,
                onChanged: (v) => _apply(_layer.copyWith(fontSize: v)),
              ),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Bold'),
                    selected: _layer.bold,
                    onSelected: (v) => _apply(_layer.copyWith(bold: v)),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Italic'),
                    selected: _layer.italic,
                    onSelected: (v) => _apply(_layer.copyWith(italic: v)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_layer.type == DesignLayerType.iconField) ...[
              Text('Icon', style: WaUi.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _icons.map((name) {
                  return ChoiceChip(
                    avatar: Icon(designIconData(name), size: 16),
                    label: Text(name),
                    selected: _layer.iconName == name,
                    onSelected: (_) =>
                        _apply(_layer.copyWith(iconName: name)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Text('Color', style: WaUi.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((hex) {
                final sel = _layer.color.toUpperCase() == hex;
                return GestureDetector(
                  onTap: () => _apply(_layer.copyWith(color: hex)),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: invitationColorFromHex(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? WaUi.accent : WaUi.chipBorder,
                        width: sel ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_layer.type == DesignLayerType.qr) ...[
              const SizedBox(height: 16),
              Text('QR color', style: WaUi.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: ['#000000', '#C08081', '#D4AF37', '#1B3A4B']
                    .map((hex) {
                  return GestureDetector(
                    onTap: () => _apply(_layer.copyWith(qrColor: hex)),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: invitationColorFromHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(color: WaUi.chipBorder),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text('Width', style: WaUi.label),
            Slider(
              value: _layer.width.clamp(0.1, 1.0),
              min: 0.1,
              max: 1.0,
              onChanged: (v) => _apply(_layer.copyWith(width: v)),
            ),
            Text('Height', style: WaUi.label),
            Slider(
              value: _layer.height.clamp(0.04, 0.8),
              min: 0.04,
              max: 0.8,
              onChanged: (v) => _apply(_layer.copyWith(height: v)),
            ),
          ],
        );
      },
    );
  }
}
