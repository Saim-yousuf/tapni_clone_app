import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/business_card_design.dart';
import 'package:tapni_app/models/invitation_design.dart';
import 'package:tapni_app/models/user_custom_card.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/print_export_sizes.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/business_card_design_renderer.dart';
import 'package:tapni_app/widgets/card_download_size_sheet.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';

/// Canva-style business card design editor (invitation-style tools).
class BusinessCardDesignEditorScreen extends StatefulWidget {
  final BusinessCardDesign design;
  /// Target card id (`primary` or custom card id).
  final String? cardId;
  /// When true, saving creates a new custom card with this design.
  final bool createNewCard;

  const BusinessCardDesignEditorScreen({
    super.key,
    required this.design,
    this.cardId,
    this.createNewCard = false,
  });

  @override
  State<BusinessCardDesignEditorScreen> createState() =>
      _BusinessCardDesignEditorScreenState();
}

class _BusinessCardDesignEditorScreenState
    extends State<BusinessCardDesignEditorScreen> {
  late BusinessCardDesign _design;
  String? _selectedId;
  final GlobalKey _cardKey = GlobalKey();
  final List<BusinessCardDesign> _undo = [];
  final List<BusinessCardDesign> _redo = [];
  bool _saving = false;

  DesignLayer? get _selected {
    if (_selectedId == null) return null;
    try {
      return _design.layers.firstWhere((l) => l.id == _selectedId);
    } catch (_) {
      return null;
    }
  }

  bool get _isDarkBg {
    final hex = _design.backgroundColor.replaceAll('#', '');
    if (hex.length < 6) return true;
    final v = int.tryParse(hex.substring(0, 6), radix: 16) ?? 0;
    final r = (v >> 16) & 0xFF;
    final g = (v >> 8) & 0xFF;
    final b = v & 0xFF;
    return (0.299 * r + 0.587 * g + 0.114 * b) < 140;
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
              Text(ctx.l10n.editText, style: WaUi.sectionHeader),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                decoration: WaUi.fieldDecoration(
                  hintText: ctx.l10n.enterTextHint,
                  radius: 12,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                style: FilledButton.styleFrom(
                  backgroundColor: WaUi.buttonDark,
                ),
                child: Text(ctx.l10n.done),
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
              Text(ctx.l10n.qrCodeDataUrlText, style: WaUi.sectionHeader),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: WaUi.fieldDecoration(
                  hintText: 'https://…',
                  radius: 12,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                style: FilledButton.styleFrom(
                  backgroundColor: WaUi.buttonDark,
                ),
                child: Text(ctx.l10n.done),
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
    final fg = _isDarkBg ? '#FFFFFF' : '#212121';
    switch (type) {
      case DesignLayerType.text:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.text,
          fieldKey: 'custom',
          text: context.l10n.newText,
          fontFamily: 'cairo',
          fontSize: 0.05,
          color: fg,
          x: 0.15,
          y: 0.4,
          width: 0.7,
          height: 0.12,
          zIndex: z,
        );
      case DesignLayerType.iconField:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.iconField,
          fieldKey: 'custom',
          text: context.l10n.details,
          iconName: 'phone',
          fontSize: 0.032,
          color: fg,
          x: 0.2,
          y: 0.55,
          width: 0.5,
          height: 0.14,
          zIndex: z,
        );
      case DesignLayerType.logo:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.logo,
          fieldKey: 'logo',
          color: fg,
          x: 0.35,
          y: 0.1,
          width: 0.3,
          height: 0.25,
          zIndex: z,
        );
      case DesignLayerType.image:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.image,
          fieldKey: 'photo',
          x: 0.35,
          y: 0.2,
          width: 0.3,
          height: 0.4,
          zIndex: z,
        );
      case DesignLayerType.qr:
        final url =
            context.read<ProfileProvider>().activeCardDisplay.profileUrl;
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.qr,
          fieldKey: 'qr',
          qrData: url,
          qrColor: '#000000',
          x: 0.7,
          y: 0.3,
          width: 0.22,
          height: 0.4,
          zIndex: z,
        );
      case DesignLayerType.shape:
        layer = DesignLayer(
          id: InvitationDesign.newId(),
          type: DesignLayerType.shape,
          shape: 'rect',
          color: _isDarkBg ? '#38BDF8' : '#0EA5E9',
          x: 0,
          y: 0,
          width: 0.04,
          height: 1,
          zIndex: z,
        );
      default:
        return;
    }
    setState(() {
      _design.layers.add(layer);
      _selectedId = layer.id;
    });
  }

  Future<void> _pickBackgroundColor() async {
    const presets = [
      '#0F172A',
      '#111827',
      '#1C1917',
      '#FAFAFA',
      '#FFFFFF',
      '#FFF7ED',
      '#F8FAFC',
      '#0B3D2E',
      '#1A0A2E',
      '#0D1B2A',
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
              Text(ctx.l10n.backgroundColor, style: WaUi.sectionHeader),
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
    setState(() {
      _design.backgroundImage = 'data:$mime;base64,$b64';
      // Keep picture as full-card background (not a side frame).
      // Hide large opaque shapes that would cover the center.
      for (var i = 0; i < _design.layers.length; i++) {
        final l = _design.layers[i];
        if (l.type != DesignLayerType.shape) continue;
        if (l.width >= 0.7 && l.height >= 0.7 && l.opacity > 0.15) {
          _design.layers[i] = l.copyWith(
            opacity: 0,
            // Keep thin border if template had one
            color: l.borderWidth > 0 ? l.color : '#00000000',
          );
        }
      }
    });
  }

  void _clearBackgroundImage() {
    if (_design.backgroundImage.isEmpty) return;
    _pushUndo();
    setState(() => _design.backgroundImage = '');
  }

  void _showBackgroundMenu() {
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
              leading: const Icon(Icons.palette_outlined),
              title: Text(ctx.l10n.backgroundColor),
              onTap: () {
                Navigator.pop(ctx);
                _pickBackgroundColor();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Background picture'),
              subtitle: const Text('Upload a photo as card background'),
              onTap: () {
                Navigator.pop(ctx);
                _pickBackgroundImage();
              },
            ),
            if (_design.backgroundImage.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.hide_image_outlined, color: Colors.red),
                title: const Text('Remove background picture'),
                onTap: () {
                  Navigator.pop(ctx);
                  _clearBackgroundImage();
                },
              ),
          ],
        ),
      ),
    );
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
              title: Text(ctx.l10n.textLabel),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(ctx.l10n.infoFieldIconText),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.iconField);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(ctx.l10n.logo),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.logo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: Text(ctx.l10n.photo),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: Text(ctx.l10n.qrCode),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.qr);
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_square),
              title: const Text('Shape'),
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

  Future<void> _download() async {
    final provider = context.read<ProfileProvider>();
    final url = provider.activeCardDisplay.profileUrl;
    await CardDownloadSizeSheet.show(
      context,
      cardCaptureKey: _cardKey,
      profileUrl: url,
      fileName: 'print_card',
      cardAspectRatio: _design.aspectRatio,
      initialKind: PrintExportKind.fullCard,
    );
  }

  Future<void> _deleteCard() async {
    final id = widget.cardId;
    if (widget.createNewCard ||
        id == null ||
        id.isEmpty ||
        id == UserCustomCard.primaryId) {
      return;
    }
    final provider = context.read<ProfileProvider>();
    if (provider.allCardDisplays.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Last card cannot be deleted'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteCard),
        content: Text(ctx.l10n.thisCardAndItsQRCodeWillBeRemoved),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await provider.deleteCustomCard(id);
    if (!mounted) return;
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final provider = context.read<ProfileProvider>();
    final targetId = widget.createNewCard
        ? (widget.cardId ??
            DateTime.now().millisecondsSinceEpoch.toString())
        : (widget.cardId ?? provider.activeCardId);
    final ok = await provider.savePrintDesign(
      design: _design,
      cardId: targetId,
      createNewCard: widget.createNewCard,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (widget.createNewCard
                  ? 'Card created'
                  : 'Design saved')
              : 'Could not save design',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    if (ok) {
      if (!mounted) return;
      // Return card id so callers can open links settings next.
      Navigator.of(context).pop(targetId);
    }
  }

  Widget _toolChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: danger ? Colors.red : null),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;

    return Scaffold(
      backgroundColor: WaUi.scaffold,
      appBar: AppBar(
        title: Text(widget.createNewCard ? 'Customize card' : 'Edit card design'),
        actions: [
          if (!widget.createNewCard &&
              widget.cardId != null &&
              widget.cardId != UserCustomCard.primaryId)
            IconButton(
              tooltip: context.l10n.deleteCard,
              onPressed: _deleteCard,
              icon: const Icon(Icons.delete_outline, color: Colors.red)),
          IconButton(
            tooltip: 'Undo',
            onPressed: _undo.isEmpty ? null : _doUndo,
            icon: const Icon(Icons.undo)),
          IconButton(
            tooltip: 'Redo',
            onPressed: _redo.isEmpty ? null : _doRedo,
            icon: const Icon(Icons.redo)),
          IconButton(
            tooltip: context.l10n.download,
            onPressed: _download,
            icon: const Icon(Icons.download_rounded)),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(context.l10n.save)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: BusinessCardDesignRenderer(
                    design: _design,
                    interactive: true,
                    selectedLayerId: _selectedId,
                    onLayerTap: _onLayerTap,
                    onLayerDrag: _onLayerDrag,
                  ),
                ),
              ),
            ),
          ),
          if (sel != null &&
              (sel.type == DesignLayerType.text ||
                  sel.type == DesignLayerType.iconField))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  const Text('Size'),
                  Expanded(
                    child: Slider(
                      value: sel.fontSize.clamp(0.02, 0.14),
                      min: 0.02,
                      max: 0.14,
                      onChanged: (v) {
                        setState(() {
                          final i = _design.layers
                              .indexWhere((l) => l.id == sel.id);
                          if (i >= 0) {
                            _design.layers[i] =
                                _design.layers[i].copyWith(fontSize: v);
                          }
                        });
                      },
                      onChangeEnd: (_) {
                        // Record undo once at end would be nicer; skip for simplicity
                      },
                    ),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                _toolChip(
                  icon: Icons.add,
                  label: 'Add',
                  onTap: _showAddMenu,
                ),
                _toolChip(
                  icon: Icons.wallpaper_outlined,
                  label: 'Background',
                  onTap: _showBackgroundMenu,
                ),
                if (_selectedId != null)
                  _toolChip(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onTap: _deleteSelected,
                    danger: true,
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: WaUi.buttonDark,
                  ),
                  child: Text(_saving ? 'Saving…' : 'Save print design'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
