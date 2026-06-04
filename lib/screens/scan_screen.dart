import 'package:flutter/material.dart';
import 'package:tapni_app/utils/theme.dart';

enum ScanMode { paperCard, qrCode, eventBadge }

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  ScanMode _selectedMode = ScanMode.paperCard;
  bool _flashOn = false;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  String get _instructionText {
    switch (_selectedMode) {
      case ScanMode.paperCard:
        return 'Point the camera at paper card\nand tap the Camera button.';
      case ScanMode.qrCode:
        return 'Point the camera at a QR code\nto scan automatically.';
      case ScanMode.eventBadge:
        return 'Point the camera at an event\nbadge and tap the Camera button.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Preview Placeholder ──────────────────────────────────
          Positioned.fill(
            child: Container(color: const Color(0xFF1A1A1A)),
          ),

          // ── Top controls ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Instruction Banner ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Instruction text
                        Expanded(
                          child: Text(
                            _instructionText,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF1A1A1A),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Language selector
                        _LanguageChip(),

                        const SizedBox(width: 8),

                        // AI button
                        _AiButton(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Viewfinder ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _Viewfinder(
                    scanLineAnim: _scanLineAnim,
                    mode: _selectedMode,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Mode selector tabs ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _ModeTab(
                        icon: Icons.badge_outlined,
                        label: 'Paper Card',
                        selected: _selectedMode == ScanMode.paperCard,
                        onTap: () =>
                            setState(() => _selectedMode = ScanMode.paperCard),
                      ),
                      const SizedBox(width: 10),
                      _ModeTab(
                        icon: Icons.qr_code_2_rounded,
                        label: 'QR Code',
                        selected: _selectedMode == ScanMode.qrCode,
                        onTap: () =>
                            setState(() => _selectedMode = ScanMode.qrCode),
                      ),
                      const SizedBox(width: 10),
                      _ModeTab(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Event Badge',
                        selected: _selectedMode == ScanMode.eventBadge,
                        onTap: () =>
                            setState(() => _selectedMode = ScanMode.eventBadge),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Bottom Row: Gallery | Shutter | Flash ──────────────────
                Padding(
                  padding: const EdgeInsets.only(
                      left: 32, right: 32, bottom: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gallery
                      _CircleIconButton(
                        icon: Icons.photo_library_outlined,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening gallery...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),

                      // Shutter button
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Scanning ${_selectedMode.name}...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.25),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.black,
                            size: 32,
                          ),
                        ),
                      ),

                      // Flash
                      _CircleIconButton(
                        icon: _flashOn
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        active: _flashOn,
                        onTap: () => setState(() => _flashOn = !_flashOn),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Viewfinder widget ────────────────────────────────────────────────────────
class _Viewfinder extends StatelessWidget {
  final Animation<double> scanLineAnim;
  final ScanMode mode;

  const _Viewfinder({required this.scanLineAnim, required this.mode});

  @override
  Widget build(BuildContext context) {
    final isQr = mode == ScanMode.qrCode;
    final double height = isQr ? 220 : 180;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Corner accents
            ..._buildCorners(),

            // Animated scan line
            AnimatedBuilder(
              animation: scanLineAnim,
              builder: (context, _) {
                return Positioned(
                  top: scanLineAnim.value * (height - 4),
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.accentGold.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const double size = 22;
    const double thickness = 3;
    final color = Colors.white;

    Widget corner({required Alignment align, required double rotDeg}) {
      return Align(
        alignment: align,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CornerPainter(
                  color: color, thickness: thickness, rotDeg: rotDeg),
            ),
          ),
        ),
      );
    }

    return [
      corner(align: Alignment.topLeft, rotDeg: 0),
      corner(align: Alignment.topRight, rotDeg: 90),
      corner(align: Alignment.bottomLeft, rotDeg: 270),
      corner(align: Alignment.bottomRight, rotDeg: 180),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double rotDeg;

  _CornerPainter(
      {required this.color,
      required this.thickness,
      required this.rotDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotDeg * 3.14159265 / 180);
    canvas.translate(-size.width / 2, -size.height / 2);

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// ── Mode tab ─────────────────────────────────────────────────────────────────
class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppTheme.accentGold.withOpacity(0.7)
                  : Colors.white.withOpacity(0.1),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : Colors.white54,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? Colors.white : Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Circle icon button ────────────────────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withOpacity(0.25)
              : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ── Language chip ─────────────────────────────────────────────────────────────
class _LanguageChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.translate_rounded, size: 13, color: Color(0xFF333333)),
          SizedBox(width: 4),
          Text(
            'Lat',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(width: 2),
          Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF333333)),
        ],
      ),
    );
  }
}

// ── AI button ─────────────────────────────────────────────────────────────────
class _AiButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'AI',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1AFF),
            ),
          ),
          SizedBox(width: 3),
          Icon(Icons.auto_awesome_rounded,
              size: 13, color: Color(0xFF4A90FF)),
        ],
      ),
    );
  }
}