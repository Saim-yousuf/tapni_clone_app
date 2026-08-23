import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/screens/e_invoice_result_screen.dart';
import 'package:tapni_app/screens/general_qr_result_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/general_qr_parser.dart';
import 'package:tapni_app/utils/profile_url_validator.dart';
import 'package:tapni_app/utils/zatca_qr_parser.dart';
import 'package:url_launcher/url_launcher.dart';

enum ScanMode { paperCard, qrCode, eInvoice, eventBadge }

const _tapniBlue = Color(0xFF2F80ED);

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ScanMode _selectedMode = ScanMode.qrCode;
  bool _flashOn = false;
  bool _cameraGranted = false;
  bool _permissionChecked = false;
  bool _scanHandled = false;
  Rect? _frameRect;

  final GlobalKey _frameKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  late final MobileScannerController _scannerController;

  bool get _isAutoScanMode =>
      _selectedMode == ScanMode.qrCode || _selectedMode == ScanMode.eInvoice;

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

  void _syncFrameRect() {
    final frameBox = _frameKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (frameBox == null ||
        stackBox == null ||
        !frameBox.hasSize ||
        !mounted) {
      return;
    }
    final topLeft = frameBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final next = topLeft & frameBox.size;
    if (_frameRect == next) return;
    setState(() => _frameRect = next);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFrameRect());
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
    // Release the camera immediately so the OS status-bar indicator clears.
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  Future<void> _stopCamera() async {
    try {
      await _scannerController.stop();
    } catch (_) {}
    if (_flashOn && mounted) {
      setState(() => _flashOn = false);
    }
  }

  Future<void> _resumeCamera() async {
    if (!mounted) return;
    setState(() => _scanHandled = false);
    try {
      await _scannerController.start();
    } catch (_) {}
  }

  Future<T?> _pushAndResumeCamera<T>(Widget page) async {
    await _stopCamera();
    if (!mounted) return null;
    final result = await Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
    await _resumeCamera();
    return result;
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (!_isAutoScanMode || _scanHandled) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;

      _scanHandled = true;
      _handleScanResult(value);
      return;
    }
  }

  Future<void> _handleScanResult(String value) async {
    if (!mounted) return;

    if (_selectedMode == ScanMode.eInvoice) {
      await _handleEInvoiceResult(value);
      return;
    }

    // QR Code (and gallery from other modes): BarQody profile first,
    // otherwise show any QR content (website, Wi‑Fi, product, text…).
    final parsed = ProfileUrlValidator.parse(value);
    if (parsed != null) {
      await _pushAndResumeCamera(
        ScannedProfileScreen(
          username: parsed.username,
          cardId: parsed.cardId,
        ),
      );
      return;
    }

    // Optional: if content is a ZATCA invoice, open invoice screen.
    final invoice = ZatcaQrParser.parse(value);
    if (invoice != null && _selectedMode == ScanMode.qrCode) {
      await _pushAndResumeCamera(EInvoiceResultScreen(invoice: invoice));
      return;
    }

    // Links / email / phone / SMS → open externally (no result page).
    final general = GeneralQrParser.parse(value);
    if (general.canLaunchExternally) {
      final uri = general.launchUri;
      if (uri != null) {
        await _stopCamera();
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (opened) {
          await _resumeCamera();
          return;
        }
      }
    }

    if (!mounted) return;
    await _pushAndResumeCamera(GeneralQrResultScreen(rawValue: value));
  }

  Future<void> _handleEInvoiceResult(String value) async {
    final invoice = ZatcaQrParser.parse(value);
    if (invoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.invalidEInvoiceQRScanAValidZATCAInvoiceQR,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) setState(() => _scanHandled = false);
      return;
    }

    await _pushAndResumeCamera(EInvoiceResultScreen(invoice: invoice));
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
        if (_selectedMode == ScanMode.eInvoice) {
          _scanHandled = true;
          _handleEInvoiceResult(value);
        } else {
          // QR / paper / event gallery pick → treat as QR content.
          _scanHandled = true;
          _handleScanResult(value);
        }
        return;
      }
    }
  }

  Future<void> _onShutterTap() async {
    if (_isAutoScanMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.holdTheQRCodeInsideTheFrameItScansAutomatically,
          ),
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
        content: Text(context.l10n.labelCapturedProcessing(label)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleFlash() async {
    await _scannerController.toggleTorch();
    if (!mounted) return;
    setState(() => _flashOn = !_flashOn);
  }

  void _selectMode(ScanMode mode) {
    setState(() {
      _selectedMode = mode;
      _scanHandled = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFrameRect());
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFrameRect());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        key: _stackKey,
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
            IgnorePointer(
              child: CustomPaint(
                painter: _ViewfinderMaskPainter(hole: _frameRect),
                child: const SizedBox.expand(),
              ),
            ),
          ] else if (_permissionChecked) ...[
            _CameraErrorView(
              message: context.l10n.cameraPermissionIsRequiredToScan,
              onRetry: _requestCameraPermission,
            ),
          ] else
            const Center(
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
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Frame is centered in remaining space so mask hole matches border.
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: AspectRatio(
                        aspectRatio: _isAutoScanMode ? 1 : 1.35,
                        child: Container(
                          key: _frameKey,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 72,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _ModeTab(
                        icon: Icons.badge_outlined,
                        label: context.l10n.paperCard,
                        selected: _selectedMode == ScanMode.paperCard,
                        onTap: () => _selectMode(ScanMode.paperCard),
                      ),
                      const SizedBox(width: 8),
                      _ModeTab(
                        icon: Icons.qr_code_2_rounded,
                        label: context.l10n.qrCode,
                        selected: _selectedMode == ScanMode.qrCode,
                        onTap: () => _selectMode(ScanMode.qrCode),
                      ),
                      const SizedBox(width: 8),
                      _ModeTab(
                        icon: Icons.receipt_long_rounded,
                        label: context.l10n.eInvoice,
                        selected: _selectedMode == ScanMode.eInvoice,
                        onTap: () => _selectMode(ScanMode.eInvoice),
                      ),
                      const SizedBox(width: 8),
                      _ModeTab(
                        icon: Icons.confirmation_number_outlined,
                        label: context.l10n.eventBadge,
                        selected: _selectedMode == ScanMode.eventBadge,
                        onTap: () => _selectMode(ScanMode.eventBadge),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
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
  final Rect? hole;

  const _ViewfinderMaskPainter({this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final full = Path()..addRect(Offset.zero & size);

    if (hole == null) {
      canvas.drawPath(full, paint);
      return;
    }

    final cutout = Path()
      ..addRRect(
        RRect.fromRectAndRadius(hole!, const Radius.circular(18)),
      );

    canvas.drawPath(
      Path.combine(PathOperation.difference, full, cutout),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ViewfinderMaskPainter oldDelegate) =>
      oldDelegate.hole != hole;
}

class _CameraErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CameraErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
