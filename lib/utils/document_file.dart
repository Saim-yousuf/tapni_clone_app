import 'dart:typed_data';

import 'package:http/http.dart' as http;

enum DocumentKind { pdf, word, image, file }

class DocumentFileHelper {
  static const imageExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif'];
  static const allowedExtensions = [
    'png',
    'jpg',
    'jpeg',
    'webp',
    'pdf',
    'doc',
    'docx',
  ];

  static const _extKinds = <String, DocumentKind>{
    'pdf': DocumentKind.pdf,
    'doc': DocumentKind.word,
    'docx': DocumentKind.word,
    'png': DocumentKind.image,
    'jpg': DocumentKind.image,
    'jpeg': DocumentKind.image,
    'webp': DocumentKind.image,
    'gif': DocumentKind.image,
  };

  static const _mimeByExt = <String, String>{
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };

  static final Map<String, DocumentKind> _sniffCache = {};

  static bool isImage(String url, [String? fileName, String? fileExt]) =>
      kindFrom(url, fileName, fileExt) == DocumentKind.image;

  static bool isPdf(String url, [String? fileName, String? fileExt]) =>
      kindFrom(url, fileName, fileExt) == DocumentKind.pdf;

  static bool isWord(String url, [String? fileName, String? fileExt]) =>
      kindFrom(url, fileName, fileExt) == DocumentKind.word;

  static String? normalizeExt(String? raw) {
    final ext = (raw ?? '').trim().toLowerCase().replaceAll('.', '');
    if (ext == 'jpeg') return 'jpg';
    if (_extKinds.containsKey(ext)) return ext;
    return null;
  }

  static String mimeFor({String? mimeType, String? fileName, String? path}) {
    final given = mimeType?.trim() ?? '';
    if (given.isNotEmpty &&
        given != 'unknown' &&
        given != 'application/octet-stream') {
      return given;
    }
    final ext =
        normalizeExt(_extensionOf(fileName)) ??
        normalizeExt(_extensionOf(path));
    return _mimeByExt[ext] ?? 'application/octet-stream';
  }

  static DocumentKind kindFrom(String url, [String? fileName, String? fileExt]) {
    final knownExt = normalizeExt(fileExt);
    if (knownExt != null) return _extKinds[knownExt]!;

    final value = '${url.trim()} ${fileName ?? ''}'.toLowerCase();
    if (value.trim().isEmpty) return DocumentKind.file;
    if (value.contains('application/pdf') ||
        value.startsWith('data:application/pdf')) {
      return DocumentKind.pdf;
    }
    if (value.contains('msword') ||
        value.contains('wordprocessingml') ||
        value.contains('officedocument')) {
      return DocumentKind.word;
    }
    if (value.startsWith('data:image/') || value.contains('/image/upload/')) {
      return DocumentKind.image;
    }

    final fromPath = _kindFromPath(url) ?? _kindFromPath(fileName ?? '');
    if (fromPath != null) return fromPath;

    final tokens = value.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty);
    for (final token in tokens) {
      final kind = _extKinds[token == 'jpeg' ? 'jpg' : token];
      if (kind != null) return kind;
    }
    return DocumentKind.file;
  }

  static Future<DocumentKind> resolveKind({
    required String url,
    String? fileName,
    String? fileExt,
  }) async {
    final kind = kindFrom(url, fileName, fileExt);
    if (kind != DocumentKind.file) return kind;
    final cached = _sniffCache[url];
    if (cached != null) return cached;
    final sniffed = await sniffRemoteKind(url);
    if (sniffed != null) {
      _sniffCache[url] = sniffed;
      return sniffed;
    }
    return DocumentKind.file;
  }

  static Future<DocumentKind?> sniffRemoteKind(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }
    final client = http.Client();
    try {
      final request = http.Request('GET', uri)
        ..headers['Range'] = 'bytes=0-15';
      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 3));
      final bytes = <int>[];
      await for (final chunk in streamed.stream.timeout(
        const Duration(seconds: 3),
      )) {
        bytes.addAll(chunk);
        if (bytes.length >= 16) break;
      }
      final magic = kindFromMagic(bytes);
      if (magic != null) return magic;
      final contentType = (streamed.headers['content-type'] ?? '').toLowerCase();
      if (contentType.contains('pdf')) return DocumentKind.pdf;
      if (contentType.contains('word') ||
          contentType.contains('officedocument') ||
          contentType.contains('msword')) {
        return DocumentKind.word;
      }
      if (contentType.startsWith('image/')) return DocumentKind.image;
    } catch (_) {
    } finally {
      client.close();
    }
    return null;
  }

  static DocumentKind? kindFromMagic(List<int> bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return DocumentKind.pdf;
    }
    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4b) {
      return DocumentKind.word;
    }
    if (bytes.length >= 4 && bytes[0] == 0xd0 && bytes[1] == 0xcf) {
      return DocumentKind.word;
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return DocumentKind.image;
    }
    if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8) {
      return DocumentKind.image;
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return DocumentKind.image;
    }
    return null;
  }

  static String labelFor(DocumentKind kind) {
    switch (kind) {
      case DocumentKind.pdf:
        return 'PDF';
      case DocumentKind.word:
        return 'DOC';
      case DocumentKind.image:
        return 'IMG';
      case DocumentKind.file:
        return 'FILE';
    }
  }

  static String? _extensionOf(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final path = () {
      try {
        if (raw.startsWith('http://') || raw.startsWith('https://')) {
          return Uri.parse(raw).path;
        }
      } catch (_) {}
      return raw;
    }();
    final last = path.split('/').last;
    final dot = last.lastIndexOf('.');
    if (dot <= 0 || dot == last.length - 1) return null;
    return last.substring(dot + 1);
  }

  static DocumentKind? _kindFromPath(String value) {
    final ext = normalizeExt(_extensionOf(value));
    return ext == null ? null : _extKinds[ext];
  }

  static Future<Uint8List> downloadBytes(
    String url, {
    void Function(int received, int? total)? onProgress,
  }) async {
    final uri = Uri.parse(url.trim());
    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 45));
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        throw Exception('download failed ${streamed.statusCode}');
      }
      final total = streamed.contentLength;
      final builder = BytesBuilder(copy: false);
      var received = 0;
      await for (final chunk in streamed.stream.timeout(
        const Duration(seconds: 45),
      )) {
        builder.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      return Uint8List.fromList(builder.takeBytes());
    } finally {
      client.close();
    }
  }
}
