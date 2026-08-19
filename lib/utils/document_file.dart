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

  static bool isImage(String url) => kindFrom(url) == DocumentKind.image;

  static bool isPdf(String url) => kindFrom(url) == DocumentKind.pdf;

  static bool isWord(String url) => kindFrom(url) == DocumentKind.word;

  static DocumentKind kindFrom(String url, [String? fileName]) {
    final value = '${url.trim()} ${fileName ?? ''}'.toLowerCase();
    if (value.isEmpty) return DocumentKind.file;
    if (value.contains('.pdf') ||
        value.contains('application/pdf') ||
        value.startsWith('data:application/pdf')) {
      return DocumentKind.pdf;
    }
    if (value.contains('.docx') ||
        value.contains('.doc') ||
        value.contains('msword') ||
        value.contains('wordprocessingml') ||
        value.contains('officedocument')) {
      return DocumentKind.word;
    }
    if (value.startsWith('data:image/') ||
        value.contains('/image/upload/') ||
        imageExtensions.any((ext) => value.contains('.$ext'))) {
      return DocumentKind.image;
    }
    return DocumentKind.file;
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
}
