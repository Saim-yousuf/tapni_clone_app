import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';

/// Default stamp / loyalty presets (user can still pick any custom color).
const List<String> kDesignColorPresets = [
  '#1B4332',
  '#121212',
  '#0A0A0A',
  '#FFFFFF',
  '#FAFAFA',
  '#F7EDE8',
  '#D4AF37',
  '#C08081',
  '#8D1B3D',
  '#1A2744',
  '#2A9D8F',
  '#6C63FF',
  '#E91E63',
  '#4FC3F7',
  '#FF8C00',
  '#C0392B',
];

String designColorToHex(Color color) {
  final r = (color.r * 255).round().clamp(0, 255);
  final g = (color.g * 255).round().clamp(0, 255);
  final b = (color.b * 255).round().clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}'
          '${g.toRadixString(16).padLeft(2, '0')}'
          '${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

Color designColorFromHexSafe(String hex, {Color fallback = Colors.black}) {
  return designColorFromHex(hex, fallback: fallback);
}

/// Opens a visual color picker (saturation pad + hue bar + presets).
Future<String?> showDesignColorPicker(
  BuildContext context, {
  required String title,
  String initialHex = '#1B4332',
  List<String> presets = kDesignColorPresets,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: BarqodyChrome.scaffold,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(BarqodyChrome.sheetRadius),
      ),
    ),
    builder: (ctx) => DesignColorPickerSheet(
      title: title,
      initialHex: initialHex,
      presets: presets,
    ),
  );
}

class DesignColorPickerSheet extends StatefulWidget {
  final String title;
  final String initialHex;
  final List<String> presets;

  const DesignColorPickerSheet({
    super.key,
    required this.title,
    required this.initialHex,
    this.presets = kDesignColorPresets,
  });

  @override
  State<DesignColorPickerSheet> createState() => _DesignColorPickerSheetState();
}

class _DesignColorPickerSheetState extends State<DesignColorPickerSheet> {
  late HSVColor _hsv;
  late TextEditingController _hexCtrl;

  @override
  void initState() {
    super.initState();
    final color = designColorFromHex(
      widget.initialHex,
      fallback: const Color(0xFF1B4332),
    );
    _hsv = HSVColor.fromColor(color);
    _hexCtrl = TextEditingController(text: designColorToHex(color));
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  Color get _color => _hsv.toColor();

  void _setHsv(HSVColor next, {bool syncHex = true}) {
    setState(() => _hsv = next);
    if (syncHex) {
      _hexCtrl.value = TextEditingValue(
        text: designColorToHex(next.toColor()),
        selection: TextSelection.collapsed(
          offset: designColorToHex(next.toColor()).length,
        ),
      );
    }
  }

  void _applyHex(String raw) {
    var value = raw.trim().replaceAll('#', '');
    if (value.length == 3) {
      value = value.split('').map((c) => '$c$c').join();
    }
    if (value.length != 6) return;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return;
    _setHsv(HSVColor.fromColor(Color(0xFF000000 | parsed)), syncHex: false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: WaUi.toolsTitleOf(
                        size: 18,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  CircleCloseButton(onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              // Live preview
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: BarqodyChrome.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      designColorToHex(_color),
                      style: WaUi.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Visual saturation / value pad
              _SaturationValuePicker(
                hsv: _hsv,
                onChanged: _setHsv,
              ),
              const SizedBox(height: 14),
              // Hue bar
              _HueBar(
                hue: _hsv.hue,
                onChanged: (h) => _setHsv(_hsv.withHue(h)),
              ),
              const SizedBox(height: 18),
              Text(
                'PRESETS',
                style: WaUi.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: BarqodyChrome.secondaryText,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.presets.map((hex) {
                  final selected = designColorToHex(_color).toUpperCase() ==
                      hex.toUpperCase();
                  return GestureDetector(
                    onTap: () {
                      _setHsv(
                        HSVColor.fromColor(
                          designColorFromHex(hex, fallback: _color),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: designColorFromHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              selected ? Colors.black : BarqodyChrome.divider,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Hex optional (secondary)
              TextField(
                controller: _hexCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                style: WaUi.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                decoration: WaUi.fieldDecoration(
                  hintText: '#1B4332',
                  labelText: 'Hex (optional)',
                ),
                onChanged: _applyHex,
              ),
              const SizedBox(height: 18),
              PillButton(
                label: 'Apply color',
                onPressed: () =>
                    Navigator.pop(context, designColorToHex(_color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2D saturation (x) × value/brightness (y) picker.
class _SaturationValuePicker extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  const _SaturationValuePicker({
    required this.hsv,
    required this.onChanged,
  });

  void _update(Offset local, Size size) {
    final s = (local.dx / size.width).clamp(0.0, 1.0);
    final v = (1 - local.dy / size.height).clamp(0.0, 1.0);
    onChanged(HSVColor.fromAHSV(1, hsv.hue, s, v));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = 180.0;
        final size = Size(w, h);
        final thumbX = hsv.saturation * w;
        final thumbY = (1 - hsv.value) * h;

        return GestureDetector(
          onPanDown: (d) => _update(d.localPosition, size),
          onPanUpdate: (d) => _update(d.localPosition, size),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  // Base hue color
                  Positioned.fill(
                    child: ColoredBox(
                      color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                    ),
                  ),
                  // White → transparent (saturation)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Transparent → black (value)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Thumb
                  Positioned(
                    left: thumbX - 12,
                    top: thumbY - 12,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hsv.toColor(),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Horizontal rainbow hue slider.
class _HueBar extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HueBar({
    required this.hue,
    required this.onChanged,
  });

  static const _hues = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  void _update(Offset local, double width) {
    onChanged(((local.dx / width) * 360).clamp(0.0, 360.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final thumbX = (hue / 360) * w;

        return GestureDetector(
          onPanDown: (d) => _update(d.localPosition, w),
          onPanUpdate: (d) => _update(d.localPosition, w),
          child: SizedBox(
            height: 28,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(colors: _hues),
                  ),
                ),
                Positioned(
                  left: thumbX - 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Preset swatches + Custom color row that opens the visual picker.
class DesignColorSwatchRow extends StatelessWidget {
  final String selectedHex;
  final ValueChanged<String> onChanged;
  final List<String> presets;
  final String pickerTitle;

  const DesignColorSwatchRow({
    super.key,
    required this.selectedHex,
    required this.onChanged,
    this.presets = kDesignColorPresets,
    this.pickerTitle = 'Pick color',
  });

  Future<void> _openCustom(BuildContext context) async {
    final picked = await showDesignColorPicker(
      context,
      title: pickerTitle,
      initialHex: selectedHex.isEmpty ? '#1B4332' : selectedHex,
      presets: presets,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedHex.toUpperCase();
    final current = designColorFromHex(
      selectedHex,
      fallback: Colors.black,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...presets.take(12).map((hex) {
              final sel = selected == hex.toUpperCase();
              return GestureDetector(
                onTap: () => onChanged(hex),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: designColorFromHex(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? Colors.black : BarqodyChrome.divider,
                      width: sel ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: BarqodyChrome.fieldFill,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _openCustom(context),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: current,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Color picker',
                      style: WaUi.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    selectedHex.isEmpty ? '#······' : selectedHex.toUpperCase(),
                    style: WaUi.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: BarqodyChrome.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
