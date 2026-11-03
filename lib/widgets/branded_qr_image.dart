import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/utils/branded_qr.dart';

/// Starbucks-style branded QR: sparse circular modules, circular eyes, and a
/// circular white center plate with the Barqody logo. High ECC recovers the
/// covered center.
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
    this.gapless = BrandedQr.gapless,
    this.eyeStyle,
    this.dataModuleStyle,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    // Retained for call-site compatibility; paint style is fixed centrally.
    assert(() {
      gapless;
      eyeStyle;
      dataModuleStyle;
      return true;
    }());

    Widget qrPaint(double innerSide) {
      return CustomPaint(
        size: Size.square(innerSide),
        painter: BrandedQrPainter(
          data: data,
          foreground: foregroundColor,
          background: backgroundColor,
        ),
      );
    }

    Widget framed(double side) {
      final inner =
          (side - padding.horizontal).clamp(1.0, side).toDouble();
      return SizedBox(
        width: side,
        height: side,
        child: Padding(
          padding: padding,
          child: qrPaint(inner),
        ),
      );
    }

    Widget stackFor(double side) {
      final inner =
          (side - padding.horizontal).clamp(1.0, side).toDouble();
      final plate = BrandedQr.plateSizeFor(inner).width;
      final inset = plate * BrandedQr.logoInsetFraction;
      return SizedBox(
        width: side,
        height: side,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(padding: padding, child: qrPaint(inner)),
            if (showLogo)
              IgnorePointer(
                child: Container(
                  width: plate,
                  height: plate,
                  padding: EdgeInsets.all(inset),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      BrandedQr.logoAsset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget buildFor(double side) =>
        showLogo ? stackFor(side) : framed(side);

    if (size != null) return buildFor(size!);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final double side = (w.isFinite && h.isFinite)
            ? (w < h ? w : h)
            : (w.isFinite ? w : (h.isFinite ? h : 160.0));
        return buildFor(side);
      },
    );
  }
}
