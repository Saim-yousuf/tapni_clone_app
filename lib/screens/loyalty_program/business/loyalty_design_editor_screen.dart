import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/invitation_design.dart';
import 'package:tapni_app/models/loyalty_card_design.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/business_card_export_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_program_success_screen.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/design_color_picker_sheet.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';

/// Full Canva-style loyalty stamp-card editor (same tools as invitations).
class LoyaltyDesignEditorScreen extends StatefulWidget {
  final LoyaltyCardDesign design;
  final String? existingProgramId;
  final RewardProgram? existingProgram;

  const LoyaltyDesignEditorScreen({
    super.key,
    required this.design,
    this.existingProgramId,
    this.existingProgram,
  });

  @override
  State<LoyaltyDesignEditorScreen> createState() =>
      _LoyaltyDesignEditorScreenState();
}

class _LoyaltyDesignEditorScreenState extends State<LoyaltyDesignEditorScreen> {
  late LoyaltyCardDesign _design;
  String? _selectedId;
  final GlobalKey _cardKey = GlobalKey();
  final List<LoyaltyCardDesign> _undo = [];
  final List<LoyaltyCardDesign> _redo = [];
  bool _saving = false;
  bool _publishing = false;
  bool _downloading = false;
  final _labelCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stampsCtrl = TextEditingController();

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
    // Unlock stamp grids so they can be moved like other layers.
    for (var i = 0; i < _design.layers.length; i++) {
      if (_design.layers[i].type == DesignLayerType.stampGrid) {
        _design.layers[i] = _design.layers[i].copyWith(locked: false);
      }
    }
    final existing = widget.existingProgram;
    _labelCtrl.text = existing?.label ?? '';
    _descCtrl.text = existing?.description ?? '';
    _stampsCtrl.text = _design.stamps.toString();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _descCtrl.dispose();
    _stampsCtrl.dispose();
    super.dispose();
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

  void _updateLayer(String id, DesignLayer Function(DesignLayer) fn, {bool recordUndo = true}) {
    if (recordUndo) _pushUndo();
    setState(() {
      final i = _design.layers.indexWhere((l) => l.id == id);
      if (i >= 0) {
        _design.layers[i] = fn(_design.layers[i]);
        if (_design.layers[i].type == DesignLayerType.stampGrid) {
          final n = int.tryParse(_design.layers[i].text);
          if (n != null) _design.stamps = n.clamp(1, 24);
          if (_design.layers[i].shape.isNotEmpty) {
            _design.stampShape = _design.layers[i].shape;
          }
          if (_design.layers[i].color.isNotEmpty) {
            _design.stampColor = _design.layers[i].color;
          }
          if (_design.layers[i].borderColor.isNotEmpty) {
            _design.stampBorderColor = _design.layers[i].borderColor;
          }
        }
        if (_design.layers[i].fieldKey == 'logo' &&
            _design.layers[i].imageSrc.isNotEmpty) {
          _design.logo = _design.layers[i].imageSrc;
        }
      }
    });
  }

  void _onLayerTap(String id) {
    // Canva-style: first tap selects, second tap edits content.
    if (_selectedId == id) {
      _editSelectedContent();
      return;
    }
    setState(() => _selectedId = id);
  }

  void _editSelectedContent() {
    final layer = _selected;
    if (layer == null) return;
    switch (layer.type) {
      case DesignLayerType.text:
      case DesignLayerType.iconField:
        _editText(layer);
      case DesignLayerType.logo:
      case DesignLayerType.image:
        _pickImageForLayer(layer);
      case DesignLayerType.qr:
        _editQr(layer);
      case DesignLayerType.stampGrid:
      case DesignLayerType.shape:
      case DesignLayerType.ornament:
        _showLayerStyleSheet();
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
      backgroundColor: BarqodyChrome.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SheetHandleThen(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ctx.l10n.editText,
                          style: WaUi.toolsTitleOf(
                            size: 18,
                            weight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      CircleCloseButton(onTap: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    autofocus: true,
                    textDirection:
                        _design.rtl ? TextDirection.rtl : TextDirection.ltr,
                    style: WaUi.body.copyWith(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    decoration: WaUi.fieldDecoration(
                      hintText: ctx.l10n.enterTextHint,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PillButton(
                    label: ctx.l10n.done,
                    onPressed: () => Navigator.pop(ctx, controller.text),
                  ),
                ],
              ),
            ),
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
      backgroundColor: BarqodyChrome.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SheetHandleThen(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'QR code link',
                          style: WaUi.toolsTitleOf(
                            size: 18,
                            weight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      CircleCloseButton(onTap: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: WaUi.fieldDecoration(
                      hintText: 'https://…',
                    ),
                  ),
                  const SizedBox(height: 20),
                  PillButton(
                    label: ctx.l10n.done,
                    onPressed: () =>
                        Navigator.pop(ctx, controller.text.trim()),
                  ),
                ],
              ),
            ),
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
    if (layer.fieldKey == 'logo' || layer.type == DesignLayerType.logo) {
      setState(() => _design.logo = dataUri);
    }
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    _pushUndo();
    setState(() {
      _design.layers.removeWhere((l) => l.id == _selectedId);
      _selectedId = null;
    });
  }

  void _duplicateSelected() {
    final layer = _selected;
    if (layer == null || layer.locked) return;
    _pushUndo();
    final z = _design.layers.isEmpty
        ? 1
        : _design.layers.map((e) => e.zIndex).reduce((a, b) => a > b ? a : b) +
            1;
    final copy = layer.copyWith(
      id: LoyaltyCardDesign.newId(),
      x: (layer.x + 0.03).clamp(-0.2, 0.9),
      y: (layer.y + 0.03).clamp(-0.2, 0.9),
      zIndex: z,
      locked: false,
    );
    setState(() {
      _design.layers.add(copy);
      _selectedId = copy.id;
    });
  }

  void _moveSelectedZ({required bool forward}) {
    final layer = _selected;
    if (layer == null || layer.locked) return;
    _pushUndo();
    setState(() {
      final sorted = List<DesignLayer>.from(_design.layers)
        ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
      final idx = sorted.indexWhere((l) => l.id == layer.id);
      if (idx < 0) return;
      final swapWith = forward ? idx + 1 : idx - 1;
      if (swapWith < 0 || swapWith >= sorted.length) return;
      final a = sorted[idx];
      final b = sorted[swapWith];
      final az = a.zIndex;
      final iA = _design.layers.indexWhere((l) => l.id == a.id);
      final iB = _design.layers.indexWhere((l) => l.id == b.id);
      if (iA < 0 || iB < 0) return;
      _design.layers[iA] = a.copyWith(zIndex: b.zIndex);
      _design.layers[iB] = b.copyWith(zIndex: az);
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
      backgroundColor: BarqodyChrome.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: SheetHandleThen(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Background',
                  style: WaUi.toolsTitleOf(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              _AddSheetTile(
                icon: Icons.palette_outlined,
                label: 'Solid color',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickBackgroundColor();
                },
              ),
              _AddSheetTile(
                icon: Icons.image_outlined,
                label: 'Photo background',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickBackgroundImage();
                },
              ),
              if (_design.backgroundImage.isNotEmpty)
                _AddSheetTile(
                  icon: Icons.hide_image_outlined,
                  label: 'Remove photo',
                  onTap: () {
                    Navigator.pop(ctx);
                    _clearBackgroundImage();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: BarqodyChrome.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: SheetHandleThen(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'More',
                  style: WaUi.toolsTitleOf(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              _AddSheetTile(
                icon: Icons.translate_rounded,
                label: _design.rtl ? 'Switch to LTR' : 'Switch to RTL',
                onTap: () {
                  Navigator.pop(ctx);
                  _pushUndo();
                  setState(() => _design.rtl = !_design.rtl);
                },
              ),
              _AddSheetTile(
                icon: Icons.download_rounded,
                label: context.l10n.download,
                onTap: () {
                  Navigator.pop(ctx);
                  _download();
                },
              ),
              _AddSheetTile(
                icon: Icons.public_outlined,
                label: 'Share to Community',
                onTap: () {
                  Navigator.pop(ctx);
                  _publishTemplate();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showArrangeMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: BarqodyChrome.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: SheetHandleThen(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Arrange',
                  style: WaUi.toolsTitleOf(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              _AddSheetTile(
                icon: Icons.flip_to_front_rounded,
                label: 'Bring forward',
                onTap: () {
                  Navigator.pop(ctx);
                  _moveSelectedZ(forward: true);
                },
              ),
              _AddSheetTile(
                icon: Icons.flip_to_back_rounded,
                label: 'Send backward',
                onTap: () {
                  Navigator.pop(ctx);
                  _moveSelectedZ(forward: false);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _addLayer(DesignLayerType type) {
    _pushUndo();
    final z = _design.layers.isEmpty
        ? 1
        : _design.layers.map((e) => e.zIndex).reduce((a, b) => a > b ? a : b) +
            1;
    late DesignLayer layer;
    final dark = _isDarkBg;
    switch (type) {
      case DesignLayerType.text:
        layer = DesignLayer(
          id: LoyaltyCardDesign.newId(),
          type: DesignLayerType.text,
          fieldKey: 'custom',
          text: _design.rtl ? 'نص جديد' : context.l10n.newText,
          fontFamily: _design.rtl ? 'cairo' : 'playfair',
          fontSize: 0.04,
          color: dark ? '#FFFFFF' : '#212121',
          x: 0.15,
          y: 0.4,
          width: 0.7,
          height: 0.08,
          zIndex: z,
          bold: true,
        );
      case DesignLayerType.iconField:
        layer = DesignLayer(
          id: LoyaltyCardDesign.newId(),
          type: DesignLayerType.iconField,
          fieldKey: 'custom',
          text: context.l10n.details,
          iconName: 'star',
          fontFamily: _design.rtl ? 'cairo' : 'roboto',
          fontSize: 0.028,
          color: dark ? '#FFFFFF' : '#212121',
          x: 0.3,
          y: 0.5,
          width: 0.4,
          height: 0.12,
          zIndex: z,
        );
      case DesignLayerType.logo:
        layer = DesignLayer(
          id: LoyaltyCardDesign.newId(),
          type: DesignLayerType.logo,
          fieldKey: 'logo',
          color: dark ? '#D4AF37' : '#212121',
          x: 0.35,
          y: 0.08,
          width: 0.3,
          height: 0.14,
          zIndex: z,
          shape: 'circle',
        );
      case DesignLayerType.image:
        layer = DesignLayer(
          id: LoyaltyCardDesign.newId(),
          type: DesignLayerType.image,
          fieldKey: 'photo',
          x: 0.2,
          y: 0.3,
          width: 0.6,
          height: 0.25,
          zIndex: z,
        );
      case DesignLayerType.qr:
        layer = DesignLayer(
          id: LoyaltyCardDesign.newId(),
          type: DesignLayerType.qr,
          fieldKey: 'qr',
          qrData: 'barqody://loyalty/preview',
          qrColor: '#000000',
          x: 0.35,
          y: 0.7,
          width: 0.3,
          height: 0.16,
          zIndex: z,
        );
      case DesignLayerType.shape:
        layer = DesignLayer(
          id: LoyaltyCardDesign.newId(),
          type: DesignLayerType.shape,
          shape: 'divider',
          color: dark ? '#D4AF37' : '#212121',
          x: 0.25,
          y: 0.5,
          width: 0.5,
          height: 0.03,
          zIndex: z,
        );
      case DesignLayerType.ornament:
        layer = DesignLayer(
          id: LoyaltyCardDesign.newId(),
          type: DesignLayerType.ornament,
          shape: 'diamond',
          color: dark ? '#D4AF37' : '#212121',
          x: 0.45,
          y: 0.5,
          width: 0.1,
          height: 0.06,
          zIndex: z,
        );
      case DesignLayerType.stampGrid:
        layer = DesignLayer(
          id: LoyaltyCardDesign.newId(),
          type: DesignLayerType.stampGrid,
          fieldKey: 'stampGrid',
          text: _design.stamps.toString(),
          shape: _design.stampShape,
          color: _design.stampColor,
          borderColor: _design.stampBorderColor,
          x: 0.12,
          y: 0.35,
          width: 0.76,
          height: 0.35,
          zIndex: z,
          locked: false,
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
    final c =
        designColorFromHex(_design.backgroundColor, fallback: Colors.black);
    return c.computeLuminance() < 0.45;
  }

  Future<void> _pickBackgroundColor() async {
    final picked = await showDesignColorPicker(
      context,
      title: context.l10n.backgroundColor,
      initialHex: _design.backgroundColor,
    );
    if (picked == null || !mounted) return;
    _pushUndo();
    setState(() {
      _design.backgroundColor = picked;
      if (_design.backgroundImage.isNotEmpty) {
        _design.backgroundImage = '';
      }
    });
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
      backgroundColor: BarqodyChrome.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: SheetHandleThen(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Add to card',
                  style: WaUi.toolsTitleOf(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              _AddSheetTile(
                icon: Icons.text_fields_rounded,
                label: ctx.l10n.textLabel,
                onTap: () {
                  Navigator.pop(ctx);
                  _addLayer(DesignLayerType.text);
                },
              ),
              _AddSheetTile(
                icon: Icons.calendar_today_outlined,
                label: ctx.l10n.infoFieldIconText,
                onTap: () {
                  Navigator.pop(ctx);
                  _addLayer(DesignLayerType.iconField);
                },
              ),
              _AddSheetTile(
                icon: Icons.image_outlined,
                label: ctx.l10n.logo,
                onTap: () {
                  Navigator.pop(ctx);
                  _addLayer(DesignLayerType.logo);
                },
              ),
              _AddSheetTile(
                icon: Icons.photo_outlined,
                label: ctx.l10n.photo,
                onTap: () {
                  Navigator.pop(ctx);
                  _addLayer(DesignLayerType.image);
                },
              ),
              _AddSheetTile(
                icon: Icons.grid_view_rounded,
                label: ctx.l10n.stampCard,
                onTap: () {
                  Navigator.pop(ctx);
                  _addLayer(DesignLayerType.stampGrid);
                },
              ),
              _AddSheetTile(
                icon: Icons.qr_code_2,
                label: ctx.l10n.qrCode,
                onTap: () {
                  Navigator.pop(ctx);
                  _addLayer(DesignLayerType.qr);
                },
              ),
              _AddSheetTile(
                icon: Icons.horizontal_rule,
                label: ctx.l10n.divider,
                onTap: () {
                  Navigator.pop(ctx);
                  _addLayer(DesignLayerType.shape);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
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
      backgroundColor: BarqodyChrome.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return _LoyaltyLayerStyleSheet(
          layer: layer,
          stamps: _design.stamps,
          stampIcon: _design.stampIcon,
          unstampIcon: _design.unstampIcon,
          onChanged: (updated) {
            // Style sheet already holds local UI state; avoid undo-spam on sliders.
            _updateLayer(layer.id, (_) => updated, recordUndo: false);
          },
          onStampsChanged: (n) {
            // Don't push undo every slider tick — canvas updates live.
            setState(() {
              _design.syncStampCount(n);
              _stampsCtrl.text = n.toString();
            });
          },
          onPickStampIcon: (filled) async {
            final picked = await pickSingleFile();
            if (picked?.file == null) return;
            final b64 = await fileToBase64(picked!.file!);
            final mime = picked.mimeType.startsWith('image/')
                ? picked.mimeType
                : 'image/jpeg';
            final uri = 'data:$mime;base64,$b64';
            _pushUndo();
            setState(() {
              if (filled) {
                _design.stampIcon = uri;
              } else {
                _design.unstampIcon = uri;
              }
            });
          },
        );
      },
    );
  }

  Future<void> _showProgramMeta() async {
    _stampsCtrl.text = _design.stamps.toString();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BarqodyChrome.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SheetHandleThen(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Program details',
                          style: WaUi.toolsTitleOf(
                            size: 18,
                            weight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      CircleCloseButton(onTap: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Name, description, and how many stamps unlock the reward.',
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      color: BarqodyChrome.secondaryText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'REWARD PROGRAM NAME',
                    style: WaUi.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _labelCtrl,
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: WaUi.fieldDecoration(
                      hintText: ctx.l10n.egCoffeeClub,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DESCRIPTION',
                    style: WaUi.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: WaUi.fieldDecoration(
                      hintText: ctx.l10n.descriptionOptional,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'STAMPS REQUIRED',
                    style: WaUi.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _stampsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: WaUi.fieldDecoration(
                      hintText: '10',
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 1) {
                        setState(() => _design.syncStampCount(n));
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  PillButton(
                    label: ctx.l10n.done,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    setState(() {});
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final name = 'loyalty_${_design.templateId}';
      final ok = await BusinessCardExportHelper.savePng(
        _cardKey,
        fileName: name,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok ? context.l10n.savedToGallery : context.l10n.couldNotSave,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Map<String, dynamic> _programBody() {
    final title = _design.titleText.isNotEmpty
        ? _design.titleText
        : (_labelCtrl.text.trim().isNotEmpty
            ? _labelCtrl.text.trim()
            : 'Loyalty Rewards');
    final theme = RewardTheme(
      cardBackgroundColor: designColorFromHex(_design.backgroundColor),
      cardTextColor: Colors.white,
      stampColor: designColorFromHex(_design.stampColor),
      stampBorderColor: designColorFromHex(_design.stampBorderColor),
      screenBackgroundColor: const Color(0xFFF0F2F5),
      screenTextColor: Colors.black,
    );
    return {
      'label': _labelCtrl.text.trim().isNotEmpty
          ? _labelCtrl.text.trim()
          : title,
      'title': title,
      'description': _descCtrl.text.trim(),
      'stamps': _design.stamps,
      'theme': theme.toJson(),
      'design': _design.toJson(),
      if (_design.logo.isNotEmpty) 'logo': _design.logo,
      if (_design.stampIcon.isNotEmpty) 'stampIcon': _design.stampIcon,
      if (_design.unstampIcon.isNotEmpty) 'unstampIcon': _design.unstampIcon,
    };
  }

  /// Saves stamp card as a business program.
  /// Draft → Inactive tab. Go Live → Active tab (customers can earn stamps).
  /// Community share is separate: [_publishTemplate] / More → Share to Community.
  Future<void> _saveProgram({bool asDraft = false}) async {
    if (_saving || _publishing) return;
    if (_design.stamps < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseEnterAValidNumberOfStamps)),
      );
      return;
    }
    setState(() => _saving = true);
    final body = _programBody();
    body['isActive'] = !asDraft;
    final repo = RewardRepo();
    late ApiResponse res;
    final id = widget.existingProgramId;
    if (id != null && id.isNotEmpty) {
      res = await repo.updateProgram(id, body);
    } else {
      res = await repo.createProgram(body);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      final isNewProgram =
          widget.existingProgramId == null || widget.existingProgramId!.isEmpty;
      if (isNewProgram && !asDraft) {
        final share = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const LoyaltyProgramSuccessScreen(),
          ),
        );
        if (share == true && mounted) {
          await _publishTemplate();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              asDraft
                  ? 'Saved as draft. Find it under Inactive.'
                  : 'Program is live for your customers.',
            ),
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? context.l10n.failedToSave)),
      );
    }
  }

  Future<void> _publishTemplate() async {
    final nameCtrl = TextEditingController(
      text: _design.titleText.isNotEmpty
          ? _design.titleText
          : context.l10n.myLoyaltyTemplate,
    );
    final descCtrl = TextEditingController(text: _descCtrl.text);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BarqodyChrome.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SheetHandleThen(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Share to Community',
                          style: WaUi.toolsTitleOf(
                            size: 18,
                            weight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      CircleCloseButton(onTap: () => Navigator.pop(ctx, false)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share this design so other businesses can use it as a template. This does not make your program live.',
                    style: WaUi.body.copyWith(
                      fontSize: 13,
                      color: BarqodyChrome.secondaryText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: WaUi.fieldDecoration(
                      hintText: ctx.l10n.templateName,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: WaUi.body.copyWith(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: WaUi.fieldDecoration(
                      hintText: ctx.l10n.descriptionOptional,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PillButton(
                    label: 'Share to Community',
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                  const SizedBox(height: 10),
                  PillButton(
                    label: ctx.l10n.cancel,
                    filled: false,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.nameIsRequired)),
      );
      return;
    }
    setState(() => _publishing = true);
    final res = await RewardRepo().publishLoyaltyTemplate({
      'name': name,
      'description': descCtrl.text.trim(),
      'category': _design.category,
      'locale': _design.locale,
      'rtl': _design.rtl,
      'previewColor': _design.backgroundColor,
      'accentColor': _design.stampColor,
      'design': _design.toJson(),
    });
    if (!mounted) return;
    setState(() => _publishing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? context.l10n.templatePublishedOthersCanUse
              : (res.message ?? context.l10n.failedToSave),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final busy = _saving || _publishing;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Customize Card',
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 18,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.1,
                      ),
                    ),
                    Row(
                      children: [
                        const CircleBackButton(),
                        const Spacer(),
                        _CircleIconBtn(
                          tooltip: context.l10n.undo,
                          icon: Icons.undo_rounded,
                          onTap: _undo.isEmpty || busy ? null : _doUndo,
                        ),
                        const SizedBox(width: 6),
                        _CircleIconBtn(
                          tooltip: context.l10n.redo,
                          icon: Icons.redo_rounded,
                          onTap: _redo.isEmpty || busy ? null : _doRedo,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF5F5F5),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedId = null),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: RepaintBoundary(
                              key: _cardKey,
                              child: LoyaltyCardDesignRenderer(
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
                    ),
                  ),
                ),
              ),
            ),
            // CapCut / Canva style dock: canvas tools OR layer tools.
            Container(
              decoration: const BoxDecoration(
                color: BarqodyChrome.scaffold,
                border: Border(
                  top: BorderSide(color: BarqodyChrome.divider),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Layer selected · tap again to edit',
                              style: WaUi.body.copyWith(
                                fontSize: 12,
                                color: BarqodyChrome.secondaryText,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selectedId = null),
                            child: Text(
                              'Done',
                              style: WaUi.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    height: 88,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      children: selected == null
                          ? [
                              _ToolChip(
                                icon: Icons.add_rounded,
                                label: 'Add',
                                onTap: busy ? null : _showAddMenu,
                              ),
                              _ToolChip(
                                icon: Icons.wallpaper_outlined,
                                label: 'Background',
                                onTap: busy ? null : _showBackgroundMenu,
                              ),
                              _ToolChip(
                                icon: Icons.card_giftcard_outlined,
                                label: 'Program',
                                onTap: busy ? null : _showProgramMeta,
                              ),
                              _ToolChip(
                                icon: Icons.more_horiz_rounded,
                                label: 'More',
                                onTap: busy ? null : _showMoreMenu,
                              ),
                            ]
                          : [
                              _ToolChip(
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                                onTap: busy ? null : _editSelectedContent,
                                emphasized: true,
                              ),
                              _ToolChip(
                                icon: Icons.palette_outlined,
                                label: 'Style',
                                onTap: busy ? null : _showLayerStyleSheet,
                              ),
                              _ToolChip(
                                icon: Icons.copy_rounded,
                                label: 'Duplicate',
                                onTap: busy ? null : _duplicateSelected,
                              ),
                              _ToolChip(
                                icon: Icons.layers_outlined,
                                label: 'Arrange',
                                onTap: busy ? null : _showArrangeMenu,
                              ),
                              _ToolChip(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                onTap: busy ? null : _deleteSelected,
                                danger: true,
                              ),
                            ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Draft = inactive · Go Live = customers can earn stamps',
                          textAlign: TextAlign.center,
                          style: WaUi.body.copyWith(
                            fontSize: 11,
                            color: BarqodyChrome.secondaryText,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: PillButton(
                                label: _saving && !_publishing
                                    ? 'Saving…'
                                    : 'Save Draft',
                                filled: false,
                                enabled: !busy,
                                onPressed: () =>
                                    _saveProgram(asDraft: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PillButton(
                                label: _saving && !_publishing
                                    ? 'Going live…'
                                    : 'Go Live',
                                enabled: !busy,
                                onPressed: () =>
                                    _saveProgram(asDraft: false),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _CircleIconBtn({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: BarqodyChrome.circleBtn,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: onTap == null
                    ? BarqodyChrome.secondaryText
                    : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool emphasized;
  final bool danger;

  const _ToolChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.emphasized = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = danger
        ? const Color(0xFFB42318)
        : emphasized
            ? Colors.black
            : Colors.black;
    final bg = danger
        ? const Color(0xFFFEE4E2)
        : emphasized
            ? const Color(0xFFE8E8E8)
            : BarqodyChrome.fieldFill;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WaUi.body.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: fg,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlignChip extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AlignChip({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _AddSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: BarqodyChrome.fieldFill,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.black),
      ),
      title: Text(
        label,
        style: WaUi.body.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: BarqodyChrome.secondaryText,
      ),
      onTap: onTap,
    );
  }
}

class _LoyaltyLayerStyleSheet extends StatefulWidget {
  final DesignLayer layer;
  final int stamps;
  final String stampIcon;
  final String unstampIcon;
  final ValueChanged<DesignLayer> onChanged;
  final ValueChanged<int> onStampsChanged;
  final Future<void> Function(bool filled) onPickStampIcon;

  const _LoyaltyLayerStyleSheet({
    required this.layer,
    required this.stamps,
    required this.stampIcon,
    required this.unstampIcon,
    required this.onChanged,
    required this.onStampsChanged,
    required this.onPickStampIcon,
  });

  @override
  State<_LoyaltyLayerStyleSheet> createState() =>
      _LoyaltyLayerStyleSheetState();
}

class _LoyaltyLayerStyleSheetState extends State<_LoyaltyLayerStyleSheet> {
  late DesignLayer _layer;
  late int _stamps;

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
    _stamps = widget.stamps.clamp(1, 24);
  }

  void _apply(DesignLayer next) {
    setState(() => _layer = next);
    widget.onChanged(next);
  }

  void _setStamps(int n) {
    final count = n.clamp(1, 24);
    setState(() {
      _stamps = count;
      _layer = _layer.copyWith(text: count.toString());
    });
    widget.onStampsChanged(count);
  }

  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet needs the scrollable as a direct child.
    // Wrapping ListView in SheetHandleThen (Column) collapses the sheet to
    // ~0 height — grey barrier with no content.
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scroll) {
        return Material(
          color: BarqodyChrome.scaffold,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(BarqodyChrome.sheetRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 14),
              Text(
                context.l10n.layerStyle,
                style: WaUi.toolsTitleOf(
                  size: 18,
                  weight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
            if (_layer.type == DesignLayerType.text ||
                _layer.type == DesignLayerType.iconField) ...[
              Text('FONT FAMILY', style: WaUi.label),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'font_${designFontKnown(_layer.fontFamily) ? _layer.fontFamily : 'cairo'}',
                ),
                initialValue: designFontKnown(_layer.fontFamily)
                    ? _layer.fontFamily
                    : 'cairo',
                isExpanded: true,
                menuMaxHeight: 360,
                decoration: WaUi.fieldDecoration(
                  hintText: 'Select font',
                ),
                selectedItemBuilder: (ctx) => kDesignFonts
                    .map(
                      (f) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          f.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: designFontStyle(
                            family: f.id,
                            fontSize: 16,
                            color: Colors.black,
                            bold: true,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                items: kDesignFonts.map((f) {
                  return DropdownMenuItem<String>(
                    value: f.id,
                    child: Text(
                      f.label,
                      style: designFontStyle(
                        family: f.id,
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    _apply(_layer.copyWith(fontFamily: v));
                  }
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Preview: The quick brown fox',
                style: designFontStyle(
                  family: designFontKnown(_layer.fontFamily)
                      ? _layer.fontFamily
                      : 'cairo',
                  fontSize: 18,
                  color: Colors.black,
                  bold: _layer.bold,
                  italic: _layer.italic,
                ),
              ),
              const SizedBox(height: 14),
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
                    label: Text(context.l10n.bold),
                    selected: _layer.bold,
                    onSelected: (v) => _apply(_layer.copyWith(bold: v)),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(context.l10n.italic),
                    selected: _layer.italic,
                    onSelected: (v) => _apply(_layer.copyWith(italic: v)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Align', style: WaUi.label),
              const SizedBox(height: 8),
              Row(
                children: [
                  _AlignChip(
                    icon: Icons.format_align_left_rounded,
                    selected: _layer.align == DesignTextAlign.left,
                    onTap: () =>
                        _apply(_layer.copyWith(align: DesignTextAlign.left)),
                  ),
                  const SizedBox(width: 8),
                  _AlignChip(
                    icon: Icons.format_align_center_rounded,
                    selected: _layer.align == DesignTextAlign.center,
                    onTap: () => _apply(
                      _layer.copyWith(align: DesignTextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AlignChip(
                    icon: Icons.format_align_right_rounded,
                    selected: _layer.align == DesignTextAlign.right,
                    onTap: () =>
                        _apply(_layer.copyWith(align: DesignTextAlign.right)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_layer.type == DesignLayerType.iconField) ...[
              Text(context.l10n.icon, style: WaUi.label),
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
            if (_layer.type == DesignLayerType.stampGrid) ...[
              Text(
                '${context.l10n.stamps}: $_stamps',
                style: WaUi.label,
              ),
              Slider(
                value: _stamps.toDouble(),
                min: 1,
                max: 24,
                divisions: 23,
                label: '$_stamps',
                onChanged: (v) => _setStamps(v.round()),
              ),
              Text(context.l10n.stampShape, style: WaUi.label),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(context.l10n.circle),
                    selected: _layer.shape == 'circle',
                    onSelected: (_) =>
                        _apply(_layer.copyWith(shape: 'circle')),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(context.l10n.square),
                    selected: _layer.shape == 'square',
                    onSelected: (_) =>
                        _apply(_layer.copyWith(shape: 'square')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onPickStampIcon(true),
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(context.l10n.stampIcon),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onPickStampIcon(false),
                      icon: const Icon(Icons.circle_outlined),
                      label: Text(context.l10n.emptyStampIcon),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_layer.type == DesignLayerType.qr) ...[
              Text(context.l10n.qrColor, style: WaUi.label),
              const SizedBox(height: 8),
              DesignColorSwatchRow(
                selectedHex: _layer.qrColor,
                pickerTitle: context.l10n.qrColor,
                onChanged: (hex) => _apply(_layer.copyWith(qrColor: hex)),
              ),
            ] else ...[
              Text(
                _layer.type == DesignLayerType.stampGrid
                    ? 'Stamp color'
                    : context.l10n.color,
                style: WaUi.label,
              ),
              const SizedBox(height: 8),
              DesignColorSwatchRow(
                selectedHex: _layer.color,
                pickerTitle: context.l10n.color,
                onChanged: (hex) => _apply(_layer.copyWith(color: hex)),
              ),
            ],
            if (_layer.type == DesignLayerType.stampGrid) ...[
              const SizedBox(height: 12),
              Text('Stamp border', style: WaUi.label),
              const SizedBox(height: 8),
              DesignColorSwatchRow(
                selectedHex: _layer.borderColor,
                pickerTitle: 'Stamp border',
                onChanged: (hex) =>
                    _apply(_layer.copyWith(borderColor: hex)),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Opacity  ${(_layer.opacity * 100).round()}%',
              style: WaUi.label,
            ),
            Slider(
              value: _layer.opacity.clamp(0.1, 1.0),
              min: 0.1,
              max: 1.0,
              onChanged: (v) => _apply(_layer.copyWith(opacity: v)),
            ),
            Text(
              'Rotate  ${_layer.rotation.round()}°',
              style: WaUi.label,
            ),
            Slider(
              value: _layer.rotation.clamp(-180.0, 180.0),
              min: -180,
              max: 180,
              divisions: 72,
              onChanged: (v) => _apply(_layer.copyWith(rotation: v)),
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: Text(_layer.locked ? 'Locked' : 'Unlocked'),
              selected: _layer.locked,
              onSelected: (v) => _apply(_layer.copyWith(locked: v)),
            ),
            const SizedBox(height: 12),
            Text(context.l10n.width, style: WaUi.label),
            Slider(
              value: _layer.width.clamp(0.1, 1.0),
              min: 0.1,
              max: 1.0,
              onChanged: (v) => _apply(_layer.copyWith(width: v)),
            ),
              Text(context.l10n.height, style: WaUi.label),
              Slider(
                value: _layer.height.clamp(0.04, 0.8),
                min: 0.04,
                max: 0.8,
                onChanged: (v) => _apply(_layer.copyWith(height: v)),
              ),
            ],
          ),
        );
      },
    );
  }
}
