import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';

class FaceCaptureSheet extends StatefulWidget {
  final String title;

  const FaceCaptureSheet({super.key, this.title = 'Capture Face'});

  static Future<String?> show(BuildContext context, {String? title}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Colors.black, width: 3),
      ),
      builder: (_) => FaceCaptureSheet(title: title ?? 'Capture Face'),
    );
  }

  @override
  State<FaceCaptureSheet> createState() => _FaceCaptureSheetState();
}

class _FaceCaptureSheetState extends State<FaceCaptureSheet> {
  final _picker = ImagePicker();
  File? _imageFile;
  bool _isCapturing = false;

  Future<void> _capture() async {
    setState(() => _isCapturing = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (image != null) {
        setState(() => _imageFile = File(image.path));
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<String?> _toBase64() async {
    if (_imageFile == null) return null;
    final bytes = await _imageFile!.readAsBytes();
    return base64Encode(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.title, style: AttendanceUi.sectionTitle),
          const SizedBox(height: 10),
          Text(
            'Take a quick selfie for attendance verification',
            textAlign: TextAlign.center,
            style: AttendanceUi.bodyMuted,
          ),
          const SizedBox(height: 24),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 4),
              image: _imageFile != null
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _imageFile == null
                ? const Icon(
                    Icons.face_retouching_natural,
                    size: 72,
                    color: Colors.black54,
                  )
                : null,
          ),
          const SizedBox(height: 24),
          AttendanceUi.secondaryButton(
            label: _imageFile == null ? 'Open Camera' : 'Retake Photo',
            icon: Icons.camera_alt_outlined,
            loading: _isCapturing,
            onPressed: _capture,
          ),
          const SizedBox(height: 12),
          AttendanceUi.primaryButton(
            label: 'Use This Photo',
            icon: Icons.check_rounded,
            onPressed: _imageFile == null
                ? null
                : () async {
                    final base64 = await _toBase64();
                    if (context.mounted) Navigator.pop(context, base64);
                  },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(
              'Skip for now',
              style: AttendanceUi.body.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
