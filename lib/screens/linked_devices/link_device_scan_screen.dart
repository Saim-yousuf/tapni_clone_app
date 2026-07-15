import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/services/account_storage.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';

class LinkDeviceScanScreen extends StatefulWidget {
  const LinkDeviceScanScreen({super.key});

  @override
  State<LinkDeviceScanScreen> createState() => _LinkDeviceScanScreenState();
}

class _LinkDeviceScanScreenState extends State<LinkDeviceScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final AuthRepo _repo = AuthRepo();
  bool _handling = false;
  final _manualController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  String? _extractCode(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri != null) {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        return code.toUpperCase();
      }
    }

    final match = RegExp(r'code=([A-Fa-f0-9]+)').firstMatch(value);
    if (match != null) return match.group(1)!.toUpperCase();

    if (RegExp(r'^[A-Fa-f0-9]{6,12}$').hasMatch(value)) {
      return value.toUpperCase();
    }
    return null;
  }

  Future<void> _handleRaw(String raw) async {
    if (_handling) return;
    final code = _extractCode(raw);
    if (code == null) {
      if (mounted) {
        ShowAlert.error(
          message: 'Invalid QR code. Use a Barqody link QR.',
          context: context,
        );
      }
      return;
    }

    setState(() => _handling = true);
    await _controller.stop();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WaUi.radiusLg),
        ),
        title: Text('Link this device?', style: WaUi.title),
        content: Text(
          'Allow this device to access your Barqody account? You can remove it anytime from Linked devices.',
          style: WaUi.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: WaUi.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Link',
              style: WaUi.bodyMedium.copyWith(color: WaUi.accent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      setState(() => _handling = false);
      await _controller.start();
      return;
    }

    final res = await _repo.approveDevicePairing(
      code: code,
      deviceName: 'Linked ${AccountStorage.devicePlatformLabel()}',
      platform: AccountStorage.devicePlatformLabel(),
    );

    if (!mounted) return;

    if (res.success) {
      ShowAlert.success(message: 'Device linked', context: context);
      Navigator.of(context).pop(true);
    } else {
      ShowAlert.error(
        message: res.message ?? 'Could not link device',
        context: context,
      );
      setState(() => _handling = false);
      await _controller.start();
    }
  }

  void _showManualEntry() {
    showModalBottomSheet(
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
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Enter code instead', style: WaUi.headline),
              const SizedBox(height: 8),
              Text(
                'Type the 8-character code shown under the QR.',
                style: WaUi.caption,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _manualController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'AABBCCDD',
                  filled: true,
                  fillColor: WaUi.navBarBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WaUi.buttonDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                  ),
                ),
                onPressed: () {
                  final code = _manualController.text.trim();
                  Navigator.pop(ctx);
                  _handleRaw(code);
                },
                child: Text('Continue', style: WaUi.bodyMedium.copyWith(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Link a device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined),
            onPressed: _showManualEntry,
            tooltip: 'Enter code',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;
              final raw = capture.barcodes.first.rawValue;
              if (raw != null) _handleRaw(raw);
            },
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: WaUi.accent, width: 2.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              'Point your camera at the QR code on the other device',
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(color: Colors.white),
            ),
          ),
          if (_handling)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: WaUi.accent),
              ),
            ),
        ],
      ),
    );
  }
}
