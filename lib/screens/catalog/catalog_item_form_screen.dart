import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/utils/document_file.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/theme.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:provider/provider.dart';

class CatalogItemFormScreen extends StatefulWidget {
  final String catalogLabel;
  final CatalogItem? existingItem;
  final List<String> existingCategories;
  final bool requireCategory;
  final bool isDocument;

  const CatalogItemFormScreen({
    super.key,
    required this.catalogLabel,
    this.existingItem,
    this.existingCategories = const [],
    this.requireCategory = false,
    this.isDocument = false,
  });

  @override
  State<CatalogItemFormScreen> createState() => _CatalogItemFormScreenState();
}

class _CatalogItemFormScreenState extends State<CatalogItemFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  String? _selectedCategory;
  String? _pickedImagePath;
  String? _pickedMimeType;
  String? _pickedFileName;
  String? _savedImageUrl;
  bool _isSaving = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _priceCtrl = TextEditingController(
      text: existing != null && existing.price > 0
          ? existing.price.toStringAsFixed(0)
          : '',
    );
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    final existingCat = existing?.category.trim() ?? '';
    _selectedCategory = existingCat.isNotEmpty ? existingCat : null;
    _savedImageUrl = existing?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = widget.isDocument
        ? await pickDocumentFile(
            allowedExtensions: DocumentFileHelper.allowedExtensions,
          )
        : await pickSingleFile(
            allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
          );
    if (file?.file == null) return;
    setState(() {
      _pickedImagePath = file!.file!.path;
      _pickedMimeType = file.mimeType;
      _pickedFileName = file.name;
      _savedImageUrl = '';
      if (widget.isDocument && _nameCtrl.text.trim().isEmpty) {
        final raw = file.name ?? '';
        final withoutExt = raw.contains('.')
            ? raw.substring(0, raw.lastIndexOf('.'))
            : raw;
        if (withoutExt.isNotEmpty) _nameCtrl.text = withoutExt;
      }
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isDocument
                ? context.l10n.pleaseEnterDocumentName
                : context.l10n.pleaseEnterItemName,
          ),
        ),
      );
      return;
    }

    final category = _selectedCategory?.trim() ?? '';
    if (widget.requireCategory && category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseSelectACategory)),
      );
      return;
    }

    setState(() => _isSaving = true);

    var imageValue = _savedImageUrl ?? '';
    if (_pickedImagePath != null) {
      imageValue = widget.isDocument
          ? await fileToDataUri(
              File(_pickedImagePath!),
              mimeType: _pickedMimeType,
            )
          : await fileToBase64(File(_pickedImagePath!));
    }

    if (widget.isDocument && imageValue.trim().isEmpty) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseUploadADocument)),
      );
      return;
    }

    if (!mounted) return;

    Navigator.pop(
      context,
      CatalogItem(
        name: name,
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        description: _descCtrl.text.trim(),
        category: category,
        imageUrl: imageValue,
        isActive: widget.existingItem?.isActive ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing
        ? context.l10n.editItem
        : widget.isDocument
            ? context.l10n.addDocument
            : context.l10n.addCatalogItem(widget.catalogLabel);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.black,
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _buildImagePicker()),
                    SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(
                          widget.isDocument
                              ? Icons.upload_file_outlined
                              : Icons.photo_outlined,
                        ),
                        label: Text(
                          _pickedImagePath != null ||
                                  (_savedImageUrl?.isNotEmpty == true)
                              ? (widget.isDocument
                                  ? context.l10n.changeDocument
                                  : context.l10n.changePhoto)
                              : (widget.isDocument
                                  ? context.l10n.uploadDocument
                                  : context.l10n.addPhoto),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: WaUi.fieldDecoration(
                        labelText: context.l10n.name,
                      ),
                    ),
                    if (!widget.isDocument) ...[
                      SizedBox(height: 16),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: WaUi.fieldDecoration(
                          labelText: priceFieldLabel(
                            context.read<ProfileProvider>().profile.currency,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      if (widget.existingCategories.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: widget.existingCategories.contains(_selectedCategory)
                              ? _selectedCategory
                              : null,
                          decoration: WaUi.fieldDecoration(
                            labelText: context.l10n.category,
                          ),
                          items: widget.existingCategories
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val),
                        )
                      else
                        Text(
                          context.l10n.addCategoriesInYourCatalogSettingsFirst,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                    ],
                    SizedBox(height: 16),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      decoration: WaUi.fieldDecoration(
                        labelText: context.l10n.descriptionOptional,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing
                              ? context.l10n.updateItem
                              : widget.isDocument
                                  ? context.l10n.addDocument
                                  : context.l10n.addItem,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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

  Widget _buildImagePicker() {
    const size = 160.0;
    final pickedIsImage = _pickedImagePath != null &&
        DocumentFileHelper.isImage(_pickedImagePath!);

    if (_pickedImagePath != null && pickedIsImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_pickedImagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_pickedImagePath != null) {
      return _filePlaceholder(
        size,
        _pickedFileName ?? _pickedImagePath!,
      );
    }

    final saved = _savedImageUrl?.trim() ?? '';
    if (saved.isNotEmpty && DocumentFileHelper.isImage(saved)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          saved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder(size),
        ),
      );
    }

    if (saved.isNotEmpty) {
      return _filePlaceholder(size, saved.split('/').last);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: _imagePlaceholder(size),
    );
  }

  Widget _filePlaceholder(double size, String label) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            DocumentFileHelper.isPdf(label)
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined,
            color: Colors.grey.shade600,
            size: 40,
          ),
          SizedBox(height: 8),
          Text(
            label,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isDocument
                ? Icons.upload_file_outlined
                : Icons.add_a_photo_outlined,
            color: Colors.grey.shade500,
            size: 40,
          ),
          SizedBox(height: 8),
          Text(
            widget.isDocument
                ? context.l10n.tapToUploadDocument
                : context.l10n.tapToAddPhoto,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
