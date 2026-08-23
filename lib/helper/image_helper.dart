import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;





Future<FilePickerM?> pickFile({
  bool allowMultiple = false,
  List<String> allowedExtensions = const ['png', 'jpg', 'jpeg'],
  bool anyFileType = false,
}) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: anyFileType || allowedExtensions.isEmpty
          ? FileType.any
          : FileType.custom,
      allowedExtensions: anyFileType || allowedExtensions.isEmpty
          ? null
          : allowedExtensions,
      allowMultiple: allowMultiple,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      List<File> files = [];
      List<String> names = [];
      List<String> mimeTypes = [];
      List<String> extensions = [];
      List<int> sizes = [];

      for (var file in result.files) {
        final File? pickedFile = await _fileFromPlatformFile(file);
        if (pickedFile == null) continue;

        files.add(pickedFile);
        names.add(file.name);

        String? mimeType =
            lookupMimeType(pickedFile.path) ?? lookupMimeType(file.name);
        mimeTypes.add(mimeType ?? 'unknown');

        String extension = path.extension(pickedFile.path);
        if (extension.isEmpty && file.extension != null) {
          extension = '.${file.extension}';
        }
        extensions.add(
          extension.isNotEmpty ? extension.replaceAll(".", "") : 'unknown',
        );

        int fileSizeInBytes = pickedFile.lengthSync();
        sizes.add(fileSizeInBytes);
      }

      if (files.isEmpty) return null;

      List<String> sizeInKB = sizes
          .map((size) => '${(size / 1024).toStringAsFixed(2)} KB')
          .toList();

      return FilePickerM(
        files: allowMultiple ? files : [files.first],
        names: names,
        file: allowMultiple ? null : files.first,
        name: allowMultiple ? null : names.first,
        mimeTypes: mimeTypes,
        mimeType: mimeTypes.isNotEmpty ? mimeTypes[0] : 'unknown',
        extensions: extensions,
        extension: extensions.first,
        sizes: sizeInKB,
        size: sizeInKB.isNotEmpty ? sizeInKB[0] : 'unknown',
      );
    }
  } catch (e) {
    log('Error picking file: $e');
  }
  return null;
}

Future<File?> _fileFromPlatformFile(PlatformFile file) async {
  if (file.path != null && file.path!.isNotEmpty) {
    return File(file.path!);
  }
  if (file.bytes == null || file.bytes!.isEmpty) return null;
  final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]+'), '_');
  final tmp = File(
    '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName',
  );
  await tmp.writeAsBytes(file.bytes!, flush: true);
  return tmp;
}

Future<FilePickerM?> pickSingleFile({
  List<String> allowedExtensions = const ['png', 'jpg', 'jpeg'],
}) async {
  return await pickFile(
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

  final ext = (picked.extension).toLowerCase();
  final allowed = allowedExtensions.map((e) => e.toLowerCase()).toSet();
  if (allowed.isNotEmpty && ext != 'unknown' && !allowed.contains(ext)) {
    return null;
  }
  return picked;
}

Future<FilePickerM?> pickMultiFile({
  List<String> allowedExtensions = const ['png', 'jpg', 'jpeg'],
}) async {
  return await pickFile(
    allowMultiple: true,
    allowedExtensions: allowedExtensions,
  );
}

Future<String> fileToBase64(File file) async {
  final bytes = await file.readAsBytes();
  return base64Encode(bytes);
}

Future<String> fileToDataUri(File file, {String? mimeType}) async {
  final bytes = await file.readAsBytes();
  final mime = (mimeType != null &&
          mimeType.isNotEmpty &&
          mimeType != 'unknown')
      ? mimeType
      : lookupMimeType(file.path) ?? 'application/octet-stream';
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

/// Resize + JPEG-compress a photo so gallery uploads stay under the API JSON limit.
Future<String> fileToCompressedDataUri(
  File file, {
  int maxSide = 1600,
  int quality = 82,
}) async {
  try {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return fileToDataUri(file);

    img.Image out = decoded;
    if (decoded.width > maxSide || decoded.height > maxSide) {
      out = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxSide : null,
        height: decoded.height > decoded.width ? maxSide : null,
      );
    }
    final jpg = img.encodeJpg(out, quality: quality);
    return 'data:image/jpeg;base64,${base64Encode(jpg)}';
  } catch (e) {
    log('Error compressing image: $e');
    return fileToDataUri(file);
  }
}

class FilePickerM {
  final List<File> files;
  final List<String> names;
  final File? file;
  final String? name;
  final List<String> mimeTypes;
  final String mimeType;
  final List<String> extensions;
  final String extension;
  final List<String> sizes;
  final String size;

  FilePickerM({
    required this.files,
    required this.names,
    this.file,
    this.name,
    required this.mimeTypes,
    required this.mimeType,
    required this.extensions,
    required this.extension,
    required this.sizes,
    required this.size,
  });
}
