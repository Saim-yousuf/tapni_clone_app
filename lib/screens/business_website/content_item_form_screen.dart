import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class ContentItemFormScreen extends StatefulWidget {
  final String contentType;
  final BusinessContentItem? existing;
  final List<BusinessContentCategory> categories;

  const ContentItemFormScreen({
    super.key,
    required this.contentType,
    this.existing,
    this.categories = const [],
  });

  @override
  State<ContentItemFormScreen> createState() => _ContentItemFormScreenState();
}

class _ContentItemFormScreenState extends State<ContentItemFormScreen> {
  final _repo = BusinessWebsiteRepo();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  String? _categoryId;
  Uint8List? _imageBytes;
  String? _savedImageUrl;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  String get _title {
    final type = widget.contentType;
    final label = type.isEmpty
        ? 'Item'
        : '${type[0].toUpperCase()}${type.substring(1)}';
    return _isEditing ? 'Edit $label' : 'Add $label';
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    _priceCtrl = TextEditingController(text: existing?.price ?? '');
    _categoryId = existing?.contentCategoryId;
    _savedImageUrl = existing?.image;
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await pickSingleFile(
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (picked == null || !picked.hasData) return;
    final bytes = await picked.readBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _savedImageUrl = null;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    setState(() => _saving = true);

    String? imagePayload;
    if (_imageBytes != null && _imageBytes!.isNotEmpty) {
      imagePayload = await bytesToCompressedDataUri(_imageBytes!);
    }

    final body = <String, dynamic>{
      'type': widget.contentType,
      'name': name,
      'description': _descCtrl.text.trim(),
      'price': _priceCtrl.text.trim(),
      'contentCategoryId': _categoryId,
      'isActive': _isActive,
      if (imagePayload != null) 'image': imagePayload,
    };

    final res = _isEditing
        ? await _repo.updateContent(widget.existing!.id, body)
        : await _repo.createContent(body);

    if (!mounted) return;
    setState(() => _saving = false);

    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Could not save')),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final imageUrl = _savedImageUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: _title),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: m.padH),
                children: [
                  AuthFieldLabel('NAME'),
                  SizedBox(height: m.v(10)),
                  _field(_nameCtrl, 'Name'),
                  SizedBox(height: m.v(18)),
                  AuthFieldLabel('DESCRIPTION'),
                  SizedBox(height: m.v(10)),
                  _field(_descCtrl, 'Description', maxLines: 4),
                  SizedBox(height: m.v(18)),
                  AuthFieldLabel('PRICE'),
                  SizedBox(height: m.v(10)),
                  _field(_priceCtrl, 'Price', keyboard: TextInputType.text),
                  if (widget.categories.isNotEmpty) ...[
                    SizedBox(height: m.v(18)),
                    AuthFieldLabel('CATEGORY'),
                    SizedBox(height: m.v(10)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _categoryId,
                          hint: const Text('None'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('None'),
                            ),
                            ...widget.categories.map(
                              (c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: m.v(18)),
                  AuthFieldLabel('IMAGE'),
                  SizedBox(height: m.v(10)),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                        image: _imageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_imageBytes!),
                                fit: BoxFit.cover,
                              )
                            : (imageUrl != null && imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child: (_imageBytes == null &&
                              (imageUrl == null || imageUrl.isEmpty))
                          ? const Center(
                              child: Text(
                                'Tap to add image',
                                style: TextStyle(color: Color(0xFF8E8E93)),
                              ),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: m.v(12)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  SizedBox(height: m.v(32)),
                  AuthPrimaryPillButton(
                    label: _isEditing ? 'Save' : 'Create',
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                  SizedBox(height: m.v(28)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}
