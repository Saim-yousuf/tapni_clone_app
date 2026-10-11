import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/screens/e_invoice_result_screen.dart';
import 'package:tapni_app/screens/general_qr_result_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/general_qr_parser.dart';
import 'package:tapni_app/utils/profile_url_validator.dart';
import 'package:tapni_app/utils/zatca_qr_parser.dart';
import 'package:url_launcher/url_launcher.dart';

/// Camera QR scanner. Content is detected automatically (profile / e-invoice /
/// link / general). When [inviteEmployee] is true (Scan to invite flow), a
/// BarQody profile QR opens [EmployeeSettingsScreen] instead of the profile.
class ScanScreen extends StatefulWidget {
  final bool inviteEmployee;

  const ScanScreen({super.key, this.inviteEmployee = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _flashOn = false;
  bool _cameraGranted = false;
  bool _permissionChecked = false;
  bool _scanHandled = false;
  Rect? _frameRect;

  final GlobalKey _frameKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
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
    if (_scanHandled) return;

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

    final parsed = ProfileUrlValidator.parse(value);
    if (parsed != null) {
      if (widget.inviteEmployee) {
        await _openInviteMember(parsed.username);
      } else {
        await _pushAndResumeCamera(
          ScannedProfileScreen(
            username: parsed.username,
            cardId: parsed.cardId,
          ),
        );
      }
      return;
    }

    // Invite flow only accepts profile QRs.
    if (widget.inviteEmployee) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.scanAnyUserOrBusinessQRToAddEmployee,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _scanHandled = false);
      return;
    }

    final invoice = ZatcaQrParser.parse(value);
    if (invoice != null) {
      await _pushAndResumeCamera(EInvoiceResultScreen(invoice: invoice));
      return;
    }

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

  Future<void> _openInviteMember(String username) async {
    await _stopCamera();
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final response = await AuthRepo().profileByUsername(username: username);
    if (!mounted) return;
    Navigator.of(context).pop(); // loading dialog

    if (!response.success || response.data is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? context.l10n.profileNotFound,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _resumeCamera();
      return;
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final userJson = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;
    final profile = UserProfile.fromApiJson(userJson);
    final userId = profile.id?.trim() ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileNotFound),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _resumeCamera();
      return;
    }

    final saved = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EmployeeSettingsScreen(
          employeeUserId: userId,
          employeeName: profile.name.isNotEmpty
              ? profile.name
              : (profile.username ?? username),
        ),
      ),
    );

    if (!mounted) return;
    if (saved != null) {
      // Pop scanner so Scan-to-invite can also close back to Team.
      Navigator.of(context).pop(saved);
      return;
    }
    await _resumeCamera();
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
        _scanHandled = true;
        _handleScanResult(value);
        return;
      }
    }
  }

  Future<void> _toggleFlash() async {
    await _scannerController.toggleTorch();
    if (!mounted) return;
    setState(() => _flashOn = !_flashOn);
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
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: AspectRatio(
                        aspectRatio: 1,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleIconButton(
                        icon: Icons.photo_library_outlined,
                        onTap: _pickFromGallery,
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
