import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;





Future<FilePickerM?> pickFile({
  bool allowMultiple = false,
  List<String> allowedExtensions = const ['png', 'jpg', 'jpeg'],
}) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
    );

    if (result != null && result.files.isNotEmpty) {
      List<File> files = [];
      List<String> names = [];
      List<String> mimeTypes = [];
      List<String> extensions = [];
      List<int> sizes = [];

      for (var file in result.files) {
        if (file.path != null) {
          File pickedFile = File(file.path!);
          files.add(pickedFile);
          names.add(file.name);

          String? mimeType = lookupMimeType(file.path!);
          mimeTypes.add(mimeType ?? 'unknown');

          String extension = path.extension(file.path!);
          extensions.add(
            extension.isNotEmpty ? extension.replaceAll(".", "") : 'unknown',
          );

          int fileSizeInBytes = pickedFile.lengthSync();
          sizes.add(fileSizeInBytes);
        }
      }

      List<String> sizeInKB = sizes
          .map((size) => '${(size / 1024).toStringAsFixed(2)} KB')
          .toList();
      // List<String> sizeInMB = sizes
      //     .map((size) => '${(size / (1024 * 1024)).toStringAsFixed(2)} MB')
      //     .toList();

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

Future<FilePickerM?> pickSingleFile({
  List<String> allowedExtensions = const ['png', 'jpg', 'jpeg'],
}) async {
  return await pickFile(
    allowMultiple: false,
    allowedExtensions: allowedExtensions,
  );
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
