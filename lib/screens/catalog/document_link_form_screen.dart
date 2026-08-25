import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/document_file.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/document_kind_icon.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

class DocumentLinkFormScreen extends StatefulWidget {
  final ProfileProvider provider;
  final LinkTemplate template;
  final SocialLink? existingLink;

  const DocumentLinkFormScreen({
    super.key,
    required this.provider,
    required this.template,
    this.existingLink,
  });

  @override
  State<DocumentLinkFormScreen> createState() => _DocumentLinkFormScreenState();
}

class _DocumentLinkFormScreenState extends State<DocumentLinkFormScreen> {
  late final TextEditingController _nameCtrl;
  String? _pickedFilePath;
  String? _pickedMimeType;
  String? _pickedFileName;
  String? _fileExt;
  String? _savedFileUrl;
  String? _pickedLogoPath;
  String? _savedLogoUrl;
  bool _useCustomIcon = false;
  bool _showLink = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existingLink != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingLink;
    final migrated = existing?.catalogItems?.isNotEmpty == true
        ? existing!.catalogItems!.first
        : null;
    _nameCtrl = TextEditingController(
      text: existing?.customLabel?.trim().isNotEmpty == true
          ? existing!.customLabel!
          : (migrated?.name ?? ''),
    );
    final fileUrl = existing?.isDocumentLink == true
        ? (existing!.url?.startsWith('catalog:') == true
              ? (migrated?.imageUrl ?? existing.value)
              : (existing.url?.isNotEmpty == true
                    ? existing.url!
                    : existing.value))
        : (migrated?.imageUrl ?? existing?.url ?? existing?.value ?? '');
    _savedFileUrl = fileUrl;
    _fileExt = DocumentFileHelper.normalizeExt(existing?.fileExt);
    final logo = existing?.logoUrl?.trim() ?? '';
    _savedLogoUrl = logo;
    _useCustomIcon = logo.startsWith('http://') || logo.startsWith('https://');
    _showLink = existing?.isPublic ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final file = await pickDocumentFile(
      allowedExtensions: DocumentFileHelper.allowedExtensions,
    );
    if (file?.file == null) return;
    setState(() {
      _pickedFilePath = file!.file!.path;
      _pickedMimeType = file.mimeType;
      _pickedFileName = file.name;
      _fileExt = DocumentFileHelper.normalizeExt(file.extension) ??
          DocumentFileHelper.normalizeExt(file.name);
      _savedFileUrl = '';
      if (_nameCtrl.text.trim().isEmpty) {
        final raw = file.name ?? '';
        final withoutExt = raw.contains('.')
            ? raw.substring(0, raw.lastIndexOf('.'))
            : raw;
        if (withoutExt.isNotEmpty) _nameCtrl.text = withoutExt;
      }
    });
  }

  Future<void> _pickCustomIcon() async {
    final file = await pickSingleFile(
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (file?.file == null) return;
    setState(() {
      _pickedLogoPath = file!.file!.path;
      _savedLogoUrl = '';
      _useCustomIcon = true;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseEnterDocumentName)),
      );
      return;
    }

    var fileValue = _savedFileUrl ?? '';
    if (_pickedFilePath != null) {
      fileValue = await fileToDataUri(
        File(_pickedFilePath!),
        mimeType: DocumentFileHelper.mimeFor(
          mimeType: _pickedMimeType,
          fileName: _pickedFileName,
          path: _pickedFilePath,
        ),
      );
    }
    if (fileValue.trim().isEmpty || fileValue.startsWith('catalog:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseUploadADocument)),
      );
      return;
    }

    setState(() => _isSaving = true);

    var logoValue = '';
    if (_useCustomIcon) {
      if (_pickedLogoPath != null) {
        logoValue = await fileToDataUri(File(_pickedLogoPath!));
      } else {
        logoValue = _savedLogoUrl ?? '';
      }
    }

    if (!mounted) return;

    final templateId = widget.template.id.isNotEmpty
        ? widget.template.id
        : widget.existingLink?.templateId;
    final link = widget.existingLink != null
        ? widget.existingLink!.copyWith(
            customLabel: name,
            fieldType: 'document',
            actionType: 'document',
            catalogType: 'documents',
            fileExt: _fileExt,
            templateId: templateId,
            logoUrl: logoValue,
            url: fileValue,
            value: fileValue,
            catalogItems: const [],
            isPublic: _showLink,
            isActive: true,
          )
        : SocialLink(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            platform: SocialPlatform.wave,
            templateId: templateId,
            customLabel: name,
            fieldType: 'document',
            actionType: 'document',
            catalogType: 'documents',
            fileExt: _fileExt,
            logoUrl: logoValue,
            url: fileValue,
            value: fileValue,
            isActive: true,
            isPublic: _showLink,
          );

    final updated = List<SocialLink>.from(widget.provider.profile.socialLinks);
    if (widget.existingLink != null) {
      final idx = updated.indexWhere((l) => l.id == widget.existingLink!.id);
      if (idx != -1) {
        updated[idx] = link;
      } else {
        updated.add(link);
      }
    } else {
      updated.add(link);
    }

    await widget.provider.updateLinks(links: updated, context: context);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.existingLink?.id;
    if (id == null) return;
    await widget.provider.deleteSocialLink(id, context);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _pickedFilePath ?? _savedFileUrl ?? '';
    final previewName = _pickedFileName ?? _nameCtrl.text;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.black,
        title: Text(
          _isEditing ? context.l10n.editItem : context.l10n.addDocument,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: DocumentKindIcon(
                        fileUrl: previewUrl,
                        fileName: _pickedFileName ?? previewName,
                        fileExt: _fileExt,
                        customLogoUrl: _useCustomIcon ? _savedLogoUrl : null,
                        localImagePath: _pickedLogoPath,
                        size: 120,
                        radius: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: _pickDocument,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(
                          (_pickedFilePath != null ||
                                  (_savedFileUrl?.isNotEmpty == true &&
                                      !_savedFileUrl!.startsWith('catalog:')))
                              ? context.l10n.changeDocument
                              : context.l10n.uploadDocument,
                        ),
                      ),
                    ),
                    if (_pickedFileName != null)
                      Center(
                        child: Text(
                          _pickedFileName!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _useCustomIcon
                            ? () => setState(() {
                                _useCustomIcon = false;
                                _pickedLogoPath = null;
                                _savedLogoUrl = '';
                              })
                            : _pickCustomIcon,
                        child: Text(
                          _useCustomIcon
                              ? context.l10n.useFileTypeIcon
                              : context.l10n.setCustomIcon,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      decoration: WaUi.fieldDecoration(
                        labelText: context.l10n.documentName,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: WaUi.fieldBox.copyWith(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.showLink,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch.adaptive(
                            value: _showLink,
                            activeColor: Colors.black,
                            onChanged: (val) => setState(() => _showLink = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_isEditing) ...[
                    IconButton(
                      onPressed: _isSaving ? null : _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: WaPrimaryButton(
                      label: _isEditing ? context.l10n.save : context.l10n.add,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
