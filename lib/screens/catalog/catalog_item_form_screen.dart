import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/utils/theme.dart';

class CatalogItemFormScreen extends StatefulWidget {
  final String catalogLabel;
  final CatalogItem? existingItem;

  const CatalogItemFormScreen({
    super.key,
    required this.catalogLabel,
    this.existingItem,
  });

  @override
  State<CatalogItemFormScreen> createState() => _CatalogItemFormScreenState();
}

class _CatalogItemFormScreenState extends State<CatalogItemFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  String? _pickedImagePath;
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
    final file = await pickSingleFile();
    if (file?.file == null) return;
    setState(() {
      _pickedImagePath = file!.file!.path;
      _savedImageUrl = '';
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter item name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    var imageValue = _savedImageUrl ?? '';
    if (_pickedImagePath != null) {
      imageValue = await fileToBase64(File(_pickedImagePath!));
    }

    if (!mounted) return;

    Navigator.pop(
      context,
      CatalogItem(
        name: name,
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        description: _descCtrl.text.trim(),
        imageUrl: imageValue,
        isActive: widget.existingItem?.isActive ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Edit item' : 'Add ${widget.catalogLabel} item';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
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
                    Center(child: _buildImagePicker()),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_outlined),
                        label: Text(
                          _pickedImagePath != null ||
                                  (_savedImageUrl?.isNotEmpty == true)
                              ? 'Change photo'
                              : 'Add photo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Price (Rs)',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update item' : 'Add item',
                          style: const TextStyle(
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

    if (_pickedImagePath != null) {
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

    final saved = _savedImageUrl?.trim() ?? '';
    if (saved.isNotEmpty) {
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

    return GestureDetector(
      onTap: _pickImage,
      child: _imagePlaceholder(size),
    );
  }

  Widget _imagePlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade500, size: 40),
          const SizedBox(height: 8),
          Text(
            'Tap to add photo',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
