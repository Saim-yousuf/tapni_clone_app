import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class DocxPreview {
  final String text;
  final List<Uint8List> images;

  const DocxPreview({required this.text, this.images = const []});

  bool get isEmpty => text.trim().isEmpty && images.isEmpty;
}

DocxPreview extractDocxPreview(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final images = <Uint8List>[];
    ArchiveFile? documentXml;

    for (final file in archive.files) {
      if (!file.isFile) continue;
      final name = file.name.replaceAll('\\', '/');
      if (name == 'word/document.xml') {
        documentXml = file;
        continue;
      }
      final lower = name.toLowerCase();
      if (lower.startsWith('word/media/') &&
          (lower.endsWith('.png') ||
              lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.webp') ||
              lower.endsWith('.gif'))) {
        images.add(Uint8List.fromList(file.content as List<int>));
      }
    }

    if (documentXml == null) return const DocxPreview(text: '');
    final xml = utf8.decode(
      documentXml.content as List<int>,
      allowMalformed: true,
    );
    return DocxPreview(text: _textFromDocumentXml(xml), images: images);
  } catch (_) {
    return const DocxPreview(text: '');
  }
}

String _textFromDocumentXml(String xml) {
  final buffer = StringBuffer();
  for (final para in xml.split(RegExp(r'<w:p[\s>]'))) {
    final texts = RegExp(r'<w:t\b[^>]*>([^<]*)</w:t>').allMatches(para);
    if (texts.isEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      continue;
    }
    buffer.writeln(
      texts.map((match) => _unescapeXml(match.group(1) ?? '')).join(),
    );
  }
  return buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

String _unescapeXml(String value) {
  return value
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'");
}
