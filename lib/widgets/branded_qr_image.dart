import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/utils/branded_qr.dart';

/// QR with the BarQody logo in the center and high error correction.
class BrandedQrImage extends StatelessWidget {
  final String data;
  final double? size;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool gapless;
  final QrEyeStyle? eyeStyle;
  final QrDataModuleStyle? dataModuleStyle;
  final bool showLogo;

  const BrandedQrImage({
    super.key,
    required this.data,
    this.size,
    this.padding = const EdgeInsets.all(10),
    this.backgroundColor = Colors.transparent,
    this.foregroundColor = Colors.black,
    this.gapless = true,
    this.eyeStyle,
    this.dataModuleStyle,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedEye = eyeStyle ??
        QrEyeStyle(eyeShape: QrEyeShape.square, color: foregroundColor);
    final resolvedModules = dataModuleStyle ??
        QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: foregroundColor,
        );

    final qr = QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      padding: padding,
      gapless: gapless,
      backgroundColor: backgroundColor,
      errorCorrectionLevel: BrandedQr.errorCorrectionLevel,
      eyeStyle: resolvedEye,
      dataModuleStyle: resolvedModules,
    );

    if (!showLogo) return qr;

    Widget stackFor(double side) {
      final inner = (side - padding.horizontal).clamp(1.0, side);
      final plate = BrandedQr.plateSizeFor(inner).width;
      final radius = BrandedQr.plateRadiusFor(plate);
      final inset = plate * BrandedQr.logoInsetFraction;
      return Stack(
        alignment: Alignment.center,
        children: [
          qr,
          IgnorePointer(
            child: Container(
              width: plate,
              height: plate,
              padding: EdgeInsets.all(inset),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  (plate - inset * 2) * BrandedQr.logoCornerFraction,
                ),
                child: Image.asset(
                  BrandedQr.logoAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (size != null) {
      return SizedBox(
        width: size,
        height: size,
        child: stackFor(size!),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final double side = (w.isFinite && h.isFinite)
            ? (w < h ? w : h)
            : (w.isFinite ? w : (h.isFinite ? h : 160.0));
        return stackFor(side);
      },
    );
  }
}
