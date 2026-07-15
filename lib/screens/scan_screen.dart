import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/profile_url_validator.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
enum ScanMode { paperCard, qrCode, eventBadge }

const _tapniBlue = Color(0xFF2F80ED);

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ScanMode _selectedMode = ScanMode.paperCard;
  bool _flashOn = false;
  bool _cameraGranted = false;
  bool _permissionChecked = false;
  bool _scanHandled = false;

  late final MobileScannerController _scannerController;


  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _cameraGranted = status.isGranted;
      _permissionChecked = true;
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  String get _instructionText {
    switch (_selectedMode) {
      case ScanMode.paperCard:
        return context.l10n.pointTheCameraAtPaperCardAndTapTheCameraButton;
      case ScanMode.qrCode:
        return context.l10n.pointTheCameraAtAQRCodeToScanAutomatically;
      case ScanMode.eventBadge:
        return context.l10n.pointTheCameraAtAnEventBadgeAndTapTheCameraButton;
    }
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (_selectedMode != ScanMode.qrCode || _scanHandled) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;

      _scanHandled = true;
      _handleScanResult(value);
      return;
    }
  }

  void _handleScanResult(String value) {
    if (!mounted) return;

    final parsed = ProfileUrlValidator.parse(value);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.invalidProfileURLScanAValidBarQodyCardOrQRCode),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _scanHandled = false);
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ScannedProfileScreen(
              username: parsed.username,
              cardId: parsed.cardId,
            ),
          ),
        )
        .then((_) {
          if (mounted) setState(() => _scanHandled = false);
        });
  }

  Future<void> _pickFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    final capture = await _scannerController.analyzeImage(path);
    if (!mounted) return;

    if (capture == null || capture.barcodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noQRCodeFoundInThisImage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _handleScanResult(value);
        return;
      }
    }
  }

  Future<void> _onShutterTap() async {
    if (_selectedMode == ScanMode.qrCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.holdTheQRCodeInsideTheFrameItScansAutomatically),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final label = _selectedMode == ScanMode.paperCard
        ? context.l10n.paperCard2
        : context.l10n.eventBadge2;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label captured. Processing...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleFlash() async {
    await _scannerController.toggleTorch();
    if (!mounted) return;
    setState(() => _flashOn = !_flashOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraGranted) ...[
            MobileScanner(
              controller: _scannerController,
              fit: BoxFit.cover,
              onDetect: _onBarcodeDetect,
              errorBuilder: (context, error) => _CameraErrorView(
                message: error.errorDetails?.message ?? context.l10n.cameraError,
                onRetry: _requestCameraPermission,
              ),
            ),
            // Dimmed overlay outside viewfinder area
            IgnorePointer(
              child: CustomPaint(
                painter: _ViewfinderMaskPainter(),
                child: SizedBox.expand(),
              ),
            ),
          ] else if (_permissionChecked) ...[
            _CameraErrorView(
              message: context.l10n.cameraPermissionIsRequiredToScan,
              onRetry: _requestCameraPermission,
            ),
          ] else
            Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _instructionText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _LanguageChip(),
                        SizedBox(width: 6),
                        _AiButton(),
                      ],
                    ),
                  ),
                ),

                Spacer(),

                // Viewfinder frame
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: AspectRatio(
                    aspectRatio: _selectedMode == ScanMode.qrCode ? 1 : 1.35,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 22),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _ModeTab(
                        icon: Icons.badge_outlined,
                        label: context.l10n.paperCard,
                        selected: _selectedMode == ScanMode.paperCard,
                        onTap: () => setState(() {
                          _selectedMode = ScanMode.paperCard;
                          _scanHandled = false;
                        }),
                      ),
                      SizedBox(width: 8),
                      _ModeTab(
                        icon: Icons.qr_code_2_rounded,
                        label: context.l10n.qrCode,
                        selected: _selectedMode == ScanMode.qrCode,
                        onTap: () => setState(() {
                          _selectedMode = ScanMode.qrCode;
                          _scanHandled = false;
                        }),
                      ),
                      SizedBox(width: 8),
                      _ModeTab(
                        icon: Icons.confirmation_number_outlined,
                        label: context.l10n.eventBadge,
                        selected: _selectedMode == ScanMode.eventBadge,
                        onTap: () => setState(() {
                          _selectedMode = ScanMode.eventBadge;
                          _scanHandled = false;
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleIconButton(
                        icon: Icons.photo_library_outlined,
                        onTap: _pickFromGallery,
                      ),
                      GestureDetector(
                        onTap: _onShutterTap,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
                      _CircleIconButton(
                        icon: _flashOn
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        active: _flashOn,
                        onTap: _toggleFlash,
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

class _ViewfinderMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.45);

    final holeWidth = size.width - 56;
    final holeHeight = holeWidth * 0.72;
    final left = (size.width - holeWidth) / 2;
    final top = size.height * 0.28;

    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, holeWidth, holeHeight),
          Radius.circular(18),
        ),
      );

    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  _CameraErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF1A1A1A),
      alignment: Alignment.center,
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
          SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 20),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.l10n.allowCamera),
          ),
        ],
      ),
    );
  }
}

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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? _tapniBlue.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _tapniBlue
                  : Colors.white.withValues(alpha: 0.15),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : Colors.white60,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.white60,
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  _CircleIconButton({
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
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language, size: 12, color: Colors.white),
          SizedBox(width: 3),
          Text(
            context.l10n.lat,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 14, color: Colors.white),
        ],
      ),
    );
  }
}

class _AiButton extends StatelessWidget {
  _AiButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.ai,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1AFF),
            ),
          ),
          SizedBox(width: 2),
          Icon(Icons.auto_awesome, size: 12, color: Color(0xFF4A90FF)),
        ],
      ),
    );
  }
}
