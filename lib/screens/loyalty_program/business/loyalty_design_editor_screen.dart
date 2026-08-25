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
import 'package:tapni_app/widgets/invitation_card_preview.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';
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
    } else if (layer.type == DesignLayerType.stampGrid) {
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
                textDirection:
                    _design.rtl ? TextDirection.rtl : TextDirection.ltr,
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
    const presets = [
      '#1B4332',
      '#D4A5A5',
      '#7BA3A8',
      '#121212',
      '#0B3D2E',
      '#1A2744',
      '#5C4033',
      '#FAFAFA',
      '#0A0A0A',
      '#F7EDE8',
      '#8D1B3D',
      '#6C63FF',
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
              title: Text(ctx.l10n.textLabel),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
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
              leading: const Icon(Icons.grid_view_rounded),
              title: Text(ctx.l10n.stampCard),
              onTap: () {
                Navigator.pop(ctx);
                _addLayer(DesignLayerType.stampGrid);
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
              leading: const Icon(Icons.horizontal_rule),
              title: Text(ctx.l10n.divider),
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
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(ctx.l10n.rewardProgram, style: WaUi.sectionHeader),
              const SizedBox(height: 16),
              TextField(
                controller: _labelCtrl,
                decoration: WaUi.fieldDecoration(
                  labelText: ctx.l10n.label,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: WaUi.fieldDecoration(
                  labelText: ctx.l10n.descriptionOptional,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _stampsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: WaUi.fieldDecoration(
                  labelText: ctx.l10n.stamps,
                ),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= 1) {
                    setState(() => _design.syncStampCount(n));
                  }
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(backgroundColor: WaUi.buttonDark),
                child: Text(ctx.l10n.done),
              ),
            ],
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

  Future<void> _saveProgram() async {
    if (_saving) return;
    if (_design.stamps < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseEnterAValidNumberOfStamps)),
      );
      return;
    }
    setState(() => _saving = true);
    final body = _programBody();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loyaltyProgramSaved)),
      );
      Navigator.of(context).pop(true);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.publishTemplate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.l10n.shareDesignForGallery),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: WaUi.fieldDecoration(
                labelText: ctx.l10n.templateName,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: WaUi.fieldDecoration(
                labelText: ctx.l10n.descriptionOptional,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: WaUi.buttonDark),
            child: Text(ctx.l10n.publish),
          ),
        ],
      ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      appBar: AppBar(
        title: Text(context.l10n.customizeCard),
        actions: [
          IconButton(
            tooltip: context.l10n.publishForOthers,
            onPressed: _publishing ? null : _publishTemplate,
            icon: _publishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.public)),
          IconButton(
            tooltip: context.l10n.undo,
            onPressed: _undo.isEmpty ? null : _doUndo,
            icon: const Icon(Icons.undo)),
          IconButton(
            tooltip: context.l10n.redo,
            onPressed: _redo.isEmpty ? null : _doRedo,
            icon: const Icon(Icons.redo)),
          IconButton(
            tooltip: context.l10n.download,
            onPressed: _downloading ? null : _download,
            icon: _downloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_rounded)),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: WaUi.surface,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolBtn(
                    icon: Icons.add_box_outlined,
                    label: context.l10n.add,
                    onTap: _showAddMenu,
                  ),
                  _ToolBtn(
                    icon: Icons.palette_outlined,
                    label: context.l10n.bgShort,
                    onTap: _pickBackgroundColor,
                  ),
                  _ToolBtn(
                    icon: Icons.wallpaper_outlined,
                    label: context.l10n.photoBg,
                    onTap: _pickBackgroundImage,
                  ),
                  _ToolBtn(
                    icon: Icons.translate,
                    label: _design.rtl ? context.l10n.rtl : context.l10n.ltr,
                    onTap: () {
                      _pushUndo();
                      setState(() => _design.rtl = !_design.rtl);
                    },
                  ),
                  _ToolBtn(
                    icon: Icons.settings_outlined,
                    label: context.l10n.stamps,
                    onTap: _showProgramMeta,
                  ),
                  _ToolBtn(
                    icon: Icons.public,
                    label: context.l10n.publish,
                    onTap: _publishTemplate,
                  ),
                  if (selected != null) ...[
                    _ToolBtn(
                      icon: Icons.tune,
                      label: context.l10n.style,
                      onTap: _showLayerStyleSheet,
                    ),
                    _ToolBtn(
                      icon: Icons.delete_outline,
                      label: context.l10n.delete,
                      onTap: _deleteSelected,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
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
          SafeArea(
            top: false,
            child: Container(
              color: WaUi.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _showProgramMeta,
                      child: Text(context.l10n.details),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _saveProgram,
                      style: FilledButton.styleFrom(
                        backgroundColor: WaUi.buttonDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(context.l10n.saveProgram),
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
    '#F4A261',
    '#1B4332',
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (ctx, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(context.l10n.layerStyle, style: WaUi.sectionHeader),
            const SizedBox(height: 16),
            if (_layer.type == DesignLayerType.text ||
                _layer.type == DesignLayerType.iconField) ...[
              Text(context.l10n.font, style: WaUi.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _fonts.map((f) {
                  final sel = _layer.fontFamily == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: sel,
                    onSelected: (_) => _apply(_layer.copyWith(fontFamily: f)),
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
            Text(context.l10n.color, style: WaUi.label),
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
            if (_layer.type == DesignLayerType.stampGrid) ...[
              const SizedBox(height: 12),
              Text(context.l10n.stampIcon, style: WaUi.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((hex) {
                  return GestureDetector(
                    onTap: () => _apply(_layer.copyWith(borderColor: hex)),
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
            if (_layer.type == DesignLayerType.qr) ...[
              const SizedBox(height: 16),
              Text(context.l10n.qrColor, style: WaUi.label),
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
        );
      },
    );
  }
}
