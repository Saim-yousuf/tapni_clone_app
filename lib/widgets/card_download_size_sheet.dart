import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/models/business_card_design.dart';
import 'package:tapni_app/utils/business_card_export_helper.dart';
import 'package:tapni_app/utils/print_export_sizes.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';

/// Bottom sheet: download full business card or QR-only PNG at selectable sizes.
class CardDownloadSizeSheet extends StatefulWidget {
  final GlobalKey? cardCaptureKey;
  final String profileUrl;
  final String? fileName;
  final double? cardAspectRatio;
  final PrintExportKind initialKind;
  final Color? qrForeground;
  final Color? qrBackground;

  const CardDownloadSizeSheet({
    super.key,
    this.cardCaptureKey,
    required this.profileUrl,
    this.fileName,
    this.cardAspectRatio,
    this.initialKind = PrintExportKind.fullCard,
    this.qrForeground,
    this.qrBackground,
  });

  static Future<void> show(
    BuildContext context, {
    GlobalKey? cardCaptureKey,
    required String profileUrl,
    String? fileName,
    double? cardAspectRatio,
    PrintExportKind initialKind = PrintExportKind.fullCard,
    Color? qrForeground,
    Color? qrBackground,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: true,
      builder: (_) => CardDownloadSizeSheet(
        cardCaptureKey: cardCaptureKey,
        profileUrl: profileUrl,
        fileName: fileName,
        cardAspectRatio: cardAspectRatio,
        initialKind: initialKind,
        qrForeground: qrForeground,
        qrBackground: qrBackground,
      ),
    );
  }

  @override
  State<CardDownloadSizeSheet> createState() => _CardDownloadSizeSheetState();
}

class _CardDownloadSizeSheetState extends State<CardDownloadSizeSheet> {
  late PrintExportKind _kind;
  PrintExportSize? _selectedCardSize;
  PrintExportSize? _selectedQrSize;
  bool _customQr = false;
  final _customPxCtrl = TextEditingController(text: '1024');
  bool _saving = false;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _selectedCardSize = PrintExportSize.fullCardSizes.first;
    _selectedQrSize = PrintExportSize.qrPresetSizes[1]; // medium
  }

  @override
  void dispose() {
    _customPxCtrl.dispose();
    super.dispose();
  }

  PrintExportSize get _activeSize {
    if (_kind == PrintExportKind.fullCard) {
      return _selectedCardSize ?? PrintExportSize.fullCardSizes.first;
    }
    if (_customQr) {
      final px = int.tryParse(_customPxCtrl.text.trim()) ?? 1024;
      return PrintExportSize.qrCustom(px);
    }
    return _selectedQrSize ?? PrintExportSize.qrPresetSizes[1];
  }

  Future<void> _save() async {
    final messenger = sheetMessenger(context);
    setState(() => _saving = true);

    bool ok = false;
    try {
      if (_kind == PrintExportKind.fullCard) {
        final key = widget.cardCaptureKey;
        if (key == null || key.currentContext == null) {
          ok = false;
        } else {
          ok = await BusinessCardExportHelper.captureAndSaveSized(
            key,
            size: _activeSize,
            fileName: widget.fileName ?? 'business_card',
            contentAspectRatio:
                widget.cardAspectRatio ?? BusinessCardDesign.defaultAspectRatio,
          );
        }
      } else {
        // Wait a frame so QR RepaintBoundary is laid out at target preview size
        await Future<void>.delayed(Duration.zero);
        ok = await BusinessCardExportHelper.captureAndSaveSized(
          _qrKey,
          size: _activeSize,
          fileName: '${widget.fileName ?? 'tapni'}_qr',
          contentAspectRatio: 1.0,
          pixelRatio: 3.0,
        );
      }
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Saved to gallery' : 'Failed to save'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final size = _activeSize;
    final canFullCard = widget.cardCaptureKey != null;

    return SheetScaffold(
      body: Container(
        decoration: WaUi.sheetDecoration,
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: WaUi.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Download PNG', style: WaUi.headline),
            const SizedBox(height: 4),
            Text(
              size.dimensionLabel,
              style: WaUi.caption,
            ),
            const SizedBox(height: 16),
            SegmentedButton<PrintExportKind>(
              segments: [
                ButtonSegment(
                  value: PrintExportKind.fullCard,
                  label: const Text('Full card'),
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  enabled: canFullCard,
                ),
                const ButtonSegment(
                  value: PrintExportKind.qrOnly,
                  label: Text('QR only'),
                  icon: Icon(Icons.qr_code_2, size: 18),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) {
                setState(() => _kind = s.first);
              },
            ),
            const SizedBox(height: 16),
            if (_kind == PrintExportKind.fullCard)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PrintExportSize.fullCardSizes.map((s) {
                  final selected = _selectedCardSize?.preset == s.preset;
                  return ChoiceChip(
                    label: Text(s.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCardSize = s),
                  );
                }).toList(),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...PrintExportSize.qrPresetSizes.map((s) {
                    final selected =
                        !_customQr && _selectedQrSize?.preset == s.preset;
                    return ChoiceChip(
                      label: Text(s.label),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _customQr = false;
                        _selectedQrSize = s;
                      }),
                    );
                  }),
                  ChoiceChip(
                    label: const Text('Custom'),
                    selected: _customQr,
                    onSelected: (_) => setState(() => _customQr = true),
                  ),
                ],
              ),
              if (_customQr) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customPxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Size (px)',
                    hintText: '128 – 4096',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    color: widget.qrBackground ?? Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: widget.profileUrl,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: widget.qrBackground ?? Colors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: widget.qrForeground ?? Colors.black,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: widget.qrForeground ?? Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(_saving ? 'Saving…' : 'Save PNG'),
                style: FilledButton.styleFrom(
                  backgroundColor: WaUi.buttonDark,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
