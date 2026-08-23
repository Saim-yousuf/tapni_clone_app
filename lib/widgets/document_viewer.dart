import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/utils/document_file.dart';
import 'package:tapni_app/utils/docx_preview.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

Future<void> openCatalogDocument(
  BuildContext context,
  CatalogItem item, {
  String? fileExt,
}) async {
  final url = item.imageUrl.trim();
  if (url.isEmpty) return;
  if (!context.mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => InAppDocumentScreen(
        title: item.name,
        fileUrl: url,
        fileExt: fileExt,
      ),
    ),
  );
}

class InAppDocumentScreen extends StatefulWidget {
  final String title;
  final String fileUrl;
  final String? fileExt;

  const InAppDocumentScreen({
    super.key,
    required this.title,
    required this.fileUrl,
    this.fileExt,
  });

  @override
  State<InAppDocumentScreen> createState() => _InAppDocumentScreenState();
}

class _InAppDocumentScreenState extends State<InAppDocumentScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _page = 1;
  int _pageCount = 0;
  Uint8List? _bytes;
  DocumentKind _kind = DocumentKind.file;
  DocxPreview? _docx;
  String? _error;
  bool _loading = true;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _progress = null;
    });

    try {
      final guessed = DocumentFileHelper.kindFrom(
        widget.fileUrl,
        widget.title,
        widget.fileExt,
      );
      final bytes = await DocumentFileHelper.downloadBytes(
        widget.fileUrl,
        fileExt: widget.fileExt,
        onProgress: (received, total) {
          if (!mounted || total == null || total <= 0) return;
          setState(() => _progress = received / total);
        },
      );
      final kind =
          DocumentFileHelper.kindFromMagic(bytes) ?? guessed;
      DocxPreview? docx;
      if (kind == DocumentKind.word &&
          bytes.length >= 2 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4b) {
        docx = extractDocxPreview(bytes);
      }
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _kind = kind;
        _docx = docx;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.couldNotOpenLink;
      });
    }
  }

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null) return;
    final ext = _fileExtFor(_kind, bytes);
    final dir = await getTemporaryDirectory();
    final safeTitle = widget.title.replaceAll(RegExp(r'[^\w.\- ]+'), '_');
    final file = File('${dir.path}/$safeTitle.$ext');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path, name: '$safeTitle.$ext')]);
  }

  String _fileExtFor(DocumentKind kind, Uint8List bytes) {
    final stored = DocumentFileHelper.normalizeExt(widget.fileExt);
    if (stored != null) return stored;
    switch (kind) {
      case DocumentKind.pdf:
        return 'pdf';
      case DocumentKind.image:
        if (bytes.length >= 8 && bytes[0] == 0x89) return 'png';
        return 'jpg';
      case DocumentKind.word:
        if (bytes.length >= 2 && bytes[0] == 0x50) return 'docx';
        return 'doc';
      case DocumentKind.file:
        return 'bin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : WaUi.scaffold;
    final bar = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final fg = isDark ? Colors.white : WaUi.primaryText;
    final muted = isDark ? Colors.white70 : WaUi.secondaryText;

    return AnnotatedRegion(
      value: AppTheme.systemUiFor(theme.brightness),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: WaUi.toolsTitleOf(
              weight: FontWeight.w600,
              color: fg,
            ),
          ),
          centerTitle: false,
          titleSpacing: 0,
          automaticallyImplyLeading: true,
          backgroundColor: bar,
          foregroundColor: fg,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            if (_bytes != null)
              IconButton(
                onPressed: _share,
                icon: const Icon(Icons.ios_share_rounded),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: isDark ? Colors.white10 : WaUi.divider,
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: _buildBody(bg, muted, fg)),
            if (_kind == DocumentKind.pdf && !_loading && _pageCount > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: Material(
                    color: bar,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            color: fg,
                            onPressed: _page > 1
                                ? () => _pdfController.goToPage(
                                    pageNumber: _page - 1,
                                  )
                                : null,
                            icon: const Icon(Icons.chevron_left, size: 22),
                          ),
                          Text(
                            '$_page / $_pageCount',
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            color: fg,
                            onPressed: _page < _pageCount
                                ? () => _pdfController.goToPage(
                                    pageNumber: _page + 1,
                                  )
                                : null,
                            icon: const Icon(Icons.chevron_right, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color bg, Color muted, Color fg) {
    if (_loading) {
      return ColoredBox(
        color: bg,
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 3,
              color: WaUi.primaryText,
            ),
          ),
        ),
      );
    }

    if (_error != null || _bytes == null) {
      return _message(_error ?? context.l10n.couldNotOpenLink, muted);
    }

    switch (_kind) {
      case DocumentKind.image:
        return ColoredBox(
          color: bg,
          child: Center(
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 6,
              child: Image.memory(_bytes!, fit: BoxFit.contain),
            ),
          ),
        );
      case DocumentKind.pdf:
        return PdfViewer.data(
          _bytes!,
          sourceName: widget.fileUrl,
          controller: _pdfController,
          params: PdfViewerParams(
            backgroundColor: bg,
            loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
              return ColoredBox(
                color: bg,
                child: const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: WaUi.primaryText,
                    ),
                  ),
                ),
              );
            },
            errorBannerBuilder: (context, error, stackTrace, documentRef) {
              return _message(context.l10n.couldNotOpenLink, muted);
            },
            onPageChanged: (page) {
              if (!mounted) return;
              setState(() {
                _page = page ?? 1;
                try {
                  _pageCount = _pdfController.pageCount;
                } catch (_) {}
              });
            },
          ),
        );
      case DocumentKind.word:
        return _wordBody(bg, muted, fg);
      case DocumentKind.file:
        return _message(context.l10n.couldNotOpenLink, muted);
    }
  }

  Widget _wordBody(Color bg, Color muted, Color fg) {
    final preview = _docx;
    final isLegacyDoc =
        _bytes != null &&
        _bytes!.length >= 4 &&
        _bytes![0] == 0xd0 &&
        _bytes![1] == 0xcf;

    if (isLegacyDoc || preview == null || preview.isEmpty) {
      return ColoredBox(
        color: bg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, size: 48, color: muted),
                const SizedBox(height: 16),
                Text(
                  context.l10n.couldNotOpenLink,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(context.l10n.share),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (preview.text.isNotEmpty)
            SelectableText(
              preview.text,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                height: 1.55,
              ),
            ),
          for (final image in preview.images) ...[
            const SizedBox(height: 16),
            Image.memory(image, fit: BoxFit.contain),
          ],
        ],
      ),
    );
  }

  Widget _message(String message, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
      ),
    );
  }
}
