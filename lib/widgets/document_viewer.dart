import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/utils/document_file.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openCatalogDocument(
  BuildContext context,
  CatalogItem item,
) async {
  final url = item.imageUrl.trim();
  if (url.isEmpty) return;

  if (DocumentFileHelper.isImage(url) && !url.startsWith('data:')) {
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageDocumentPage(title: item.name, imageUrl: url),
      ),
    );
    return;
  }

  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.couldNotOpenLink)),
    );
  }
}

class _ImageDocumentPage extends StatelessWidget {
  final String title;
  final String imageUrl;

  const _ImageDocumentPage({
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 16)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
