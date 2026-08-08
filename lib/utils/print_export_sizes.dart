/// Print / display PNG export presets for business cards and QR codes.
enum PrintExportKind { fullCard, qrOnly }

enum PrintExportPreset {
  standard,
  stand,
  a4,
  square,
  qrSmall,
  qrMedium,
  qrLarge,
  qrCustom,
}

class PrintExportSize {
  final PrintExportPreset preset;
  final String label;
  final int width;
  final int height;
  final PrintExportKind kind;
  /// When true, card is letterboxed onto a white A4 canvas.
  final bool letterboxOnA4;

  const PrintExportSize({
    required this.preset,
    required this.label,
    required this.width,
    required this.height,
    required this.kind,
    this.letterboxOnA4 = false,
  });

  String get dimensionLabel => '$width × $height px';

  static const int minCustomPx = 128;
  static const int maxCustomPx = 4096;

  /// Portrait sizes aligned with existing vertical cards (~0.7 aspect).
  static const List<PrintExportSize> fullCardSizes = [
    PrintExportSize(
      preset: PrintExportPreset.standard,
      label: 'Standard',
      width: 700,
      height: 1000,
      kind: PrintExportKind.fullCard,
    ),
    PrintExportSize(
      preset: PrintExportPreset.stand,
      label: 'Stand',
      width: 1080,
      height: 1543,
      kind: PrintExportKind.fullCard,
    ),
    PrintExportSize(
      preset: PrintExportPreset.a4,
      label: 'A4',
      width: 2480,
      height: 3508,
      kind: PrintExportKind.fullCard,
      letterboxOnA4: true,
    ),
    PrintExportSize(
      preset: PrintExportPreset.square,
      label: 'Square',
      width: 1080,
      height: 1080,
      kind: PrintExportKind.fullCard,
    ),
  ];

  static const List<PrintExportSize> qrPresetSizes = [
    PrintExportSize(
      preset: PrintExportPreset.qrSmall,
      label: 'Small',
      width: 512,
      height: 512,
      kind: PrintExportKind.qrOnly,
    ),
    PrintExportSize(
      preset: PrintExportPreset.qrMedium,
      label: 'Medium',
      width: 1024,
      height: 1024,
      kind: PrintExportKind.qrOnly,
    ),
    PrintExportSize(
      preset: PrintExportPreset.qrLarge,
      label: 'Large',
      width: 2048,
      height: 2048,
      kind: PrintExportKind.qrOnly,
    ),
  ];

  /// Custom square QR size (clamped).
  static PrintExportSize qrCustom(int px) {
    final clamped = px.clamp(minCustomPx, maxCustomPx);
    return PrintExportSize(
      preset: PrintExportPreset.qrCustom,
      label: 'Custom',
      width: clamped,
      height: clamped,
      kind: PrintExportKind.qrOnly,
    );
  }
}
