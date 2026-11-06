import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

Future<FilePickerM?> pickFile({
  bool allowMultiple = false,
  List<String> allowedExtensions = const ['png', 'jpg', 'jpeg'],
  bool anyFileType = false,
}) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: anyFileType || allowedExtensions.isEmpty
          ? FileType.any
          : FileType.custom,
      allowedExtensions: anyFileType || allowedExtensions.isEmpty
          ? null
          : allowedExtensions,
      allowMultiple: allowMultiple,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final entries = <_PickedEntry>[];
    for (final file in result.files) {
      final entry = await _entryFromPlatformFile(file);
      if (entry != null) entries.add(entry);
    }
    if (entries.isEmpty) return null;

    final names = entries.map((e) => e.name).toList();
    final mimeTypes = entries.map((e) => e.mimeType).toList();
    final extensions = entries.map((e) => e.extension).toList();
    final bytesList = entries.map((e) => e.bytes).toList();
    final fileRefs = entries.map((e) => e.file).toList();
    final sizeInKB = entries
        .map((e) => '${(e.bytes.length / 1024).toStringAsFixed(2)} KB')
        .toList();

    return FilePickerM(
      bytesList: allowMultiple ? bytesList : [bytesList.first],
      files: allowMultiple
          ? fileRefs.whereType<File>().toList()
          : [
              if (fileRefs.first != null) fileRefs.first!,
            ],
      names: names,
      file: allowMultiple ? null : fileRefs.first,
      bytes: allowMultiple ? null : bytesList.first,
      name: allowMultiple ? null : names.first,
      mimeTypes: mimeTypes,
      mimeType: mimeTypes.isNotEmpty ? mimeTypes[0] : 'unknown',
      extensions: extensions,
      extension: extensions.first,
      sizes: sizeInKB,
      size: sizeInKB.isNotEmpty ? sizeInKB[0] : 'unknown',
    );
  } catch (e) {
    log('Error picking file: $e');
  }
  return null;
}

class _PickedEntry {
  final Uint8List bytes;
  final File? file;
  final String name;
  final String mimeType;
  final String extension;

  const _PickedEntry({
    required this.bytes,
    required this.file,
    required this.name,
    required this.mimeType,
    required this.extension,
  });
}

Future<_PickedEntry?> _entryFromPlatformFile(PlatformFile file) async {
  Uint8List? bytes = file.bytes;
  File? localFile;

  if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
    localFile = File(file.path!);
    bytes ??= await localFile.readAsBytes();
  }

  if (bytes == null || bytes.isEmpty) return null;

  final mimeType =
      lookupMimeType(file.name, headerBytes: bytes) ??
      (file.path != null ? lookupMimeType(file.path!) : null) ??
      'application/octet-stream';

  var extension = '';
  if (file.extension != null && file.extension!.isNotEmpty) {
    extension = file.extension!.toLowerCase();
  } else {
    extension = path.extension(file.name).replaceAll('.', '').toLowerCase();
  }
  if (extension.isEmpty) extension = 'unknown';

  return _PickedEntry(
    bytes: bytes,
    file: localFile,
    name: file.name,
    mimeType: mimeType,
    extension: extension,
  );
}

Future<FilePickerM?> pickSingleFile({
  List<String> allowedExtensions = const ['png', 'jpg', 'jpeg'],
}) async {
  return pickFile(
    allowMultiple: false,
    allowedExtensions: allowedExtensions,
  );
}

Future<FilePickerM?> pickDocumentFile({
  List<String> allowedExtensions = const [
    'png',
    'jpg',
    'jpeg',
    'webp',
    'pdf',
    'doc',
    'docx',
  ],
}) async {
  final picked = await pickFile(
    allowMultiple: false,
    allowedExtensions: allowedExtensions,
    anyFileType: true,
  );
  if (picked == null) return null;

  final ext = picked.extension.toLowerCase();
  final allowed = allowedExtensions.map((e) => e.toLowerCase()).toSet();
  if (allowed.isNotEmpty && ext != 'unknown' && !allowed.contains(ext)) {
    return null;
  }
  return picked;
}

Future<FilePickerM?> pickMultiFile({
  List<String> allowedExtensions = const ['png', 'jpg', 'jpeg'],
}) async {
  return pickFile(
    allowMultiple: true,
    allowedExtensions: allowedExtensions,
  );
}

Future<String> fileToBase64(File file) async {
  final bytes = await file.readAsBytes();
  return base64Encode(bytes);
}

Future<String> bytesToBase64(Uint8List bytes) async => base64Encode(bytes);

Future<String> pickedToBase64(FilePickerM picked) async {
  final bytes = await picked.readBytes();
  return base64Encode(bytes);
}

Future<String> fileToDataUri(File file, {String? mimeType}) async {
  final bytes = await file.readAsBytes();
  return bytesToDataUri(
    bytes,
    mimeType: mimeType ?? lookupMimeType(file.path),
  );
}

String bytesToDataUri(Uint8List bytes, {String? mimeType}) {
  final mime = (mimeType != null &&
          mimeType.isNotEmpty &&
          mimeType != 'unknown')
      ? mimeType
      : 'application/octet-stream';
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

Future<String> pickedToDataUri(FilePickerM picked) async {
  final bytes = await picked.readBytes();
  return bytesToDataUri(bytes, mimeType: picked.mimeType);
}

/// Resize + JPEG-compress a photo so gallery uploads stay under the API JSON limit.
Future<String> fileToCompressedDataUri(
  File file, {
  int maxSide = 1600,
  int quality = 82,
}) async {
  final bytes = await file.readAsBytes();
  return bytesToCompressedDataUri(bytes, maxSide: maxSide, quality: quality);
}

/// Runs off the UI isolate — full-res phone photos freeze the app if decoded
/// on the main thread.
Uint8List? compressJpegBytes(List<Object?> args) {
  final bytes = args[0] as Uint8List;
  final maxSide = args[1] as int;
  final quality = args[2] as int;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  var out = decoded;
  if (decoded.width > maxSide || decoded.height > maxSide) {
    out = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxSide : null,
      height: decoded.height > decoded.width ? maxSide : null,
    );
  }
  return Uint8List.fromList(img.encodeJpg(out, quality: quality));
}

Future<String> bytesToCompressedDataUri(
  Uint8List bytes, {
  int maxSide = 1600,
  int quality = 82,
  String? mimeType,
}) async {
  try {
    final jpg = await compute(compressJpegBytes, <Object?>[bytes, maxSide, quality]);
    if (jpg == null || jpg.isEmpty) {
      return bytesToDataUri(bytes, mimeType: mimeType);
    }
    return 'data:image/jpeg;base64,${base64Encode(jpg)}';
  } catch (e) {
    log('Error compressing image: $e');
    return bytesToDataUri(bytes, mimeType: mimeType);
  }
}

Future<String> pickedToCompressedDataUri(
  FilePickerM picked, {
  int maxSide = 1600,
  int quality = 82,
}) async {
  final bytes = await picked.readBytes();
  return bytesToCompressedDataUri(
    bytes,
    maxSide: maxSide,
    quality: quality,
    mimeType: picked.mimeType,
  );
}

ImageProvider? localImageProvider({Uint8List? bytes, File? file}) {
  if (bytes != null && bytes.isNotEmpty) return MemoryImage(bytes);
  if (!kIsWeb && file != null) return FileImage(file);
  return null;
}

Widget localPickedImage({
  Uint8List? bytes,
  File? file,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  if (bytes != null && bytes.isNotEmpty) {
    return Image.memory(
      bytes,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
    );
  }
  if (!kIsWeb && file != null) {
    return Image.file(
      file,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
    );
  }
  return const SizedBox.shrink();
}

class FilePickerM {
  /// Always populated for successful picks (web + mobile).
  final List<Uint8List> bytesList;
  final List<File> files;
  final List<String> names;
  final File? file;
  final Uint8List? bytes;
  final String? name;
  final List<String> mimeTypes;
  final String mimeType;
  final List<String> extensions;
  final String extension;
  final List<String> sizes;
  final String size;

  FilePickerM({
    required this.bytesList,
    required this.files,
    required this.names,
    this.file,
    this.bytes,
    this.name,
    required this.mimeTypes,
    required this.mimeType,
    required this.extensions,
    required this.extension,
    required this.sizes,
    required this.size,
  });

  bool get hasData =>
      (bytes != null && bytes!.isNotEmpty) ||
      bytesList.isNotEmpty ||
      file != null ||
      files.isNotEmpty;

  Future<Uint8List> readBytes({int index = 0}) async {
    if (index == 0 && bytes != null && bytes!.isNotEmpty) return bytes!;
    if (index >= 0 && index < bytesList.length && bytesList[index].isNotEmpty) {
      return bytesList[index];
    }
    if (index == 0 && file != null) return file!.readAsBytes();
    if (index >= 0 && index < files.length) return files[index].readAsBytes();
    throw StateError('No file bytes available');
  }
}
