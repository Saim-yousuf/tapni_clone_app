import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/utils/document_file.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class CatalogItemFormScreen extends StatefulWidget {
  final String catalogLabel;
  final CatalogItem? existingItem;
  final List<String> existingCategories;
  final bool requireCategory;
  final bool isDocument;
  final bool isService;

  const CatalogItemFormScreen({
    super.key,
    required this.catalogLabel,
    this.existingItem,
    this.existingCategories = const [],
    this.requireCategory = false,
    this.isDocument = false,
    this.isService = false,
  });

  @override
  State<CatalogItemFormScreen> createState() => _CatalogItemFormScreenState();
}

class _CatalogItemFormScreenState extends State<CatalogItemFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;

  // Service form fields (persisted on CatalogItem).
  late final TextEditingController _discountedPriceCtrl;
  late final TextEditingController _rewardPointsCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _slotsCtrl;
  bool _offerDiscount = false;
  int _bookingTypeIndex = 0;

  String? _selectedCategory;
  late List<String> _categoryOptions;
  String? _pickedImagePath;
  String? _pickedMimeType;
  String? _pickedFileName;
  String? _savedImageUrl;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existingItem != null;

  static const _bookingTypes = ['Appointment', 'Request', 'No Scheduling'];

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
    _discountedPriceCtrl = TextEditingController(
      text: existing != null &&
              existing.offerDiscount &&
              existing.discountedPrice > 0
          ? existing.discountedPrice.toStringAsFixed(0)
          : '',
    );
    _rewardPointsCtrl = TextEditingController(
      text: existing != null && existing.rewardPoints > 0
          ? existing.rewardPoints.toString()
          : '',
    );
    _durationCtrl = TextEditingController(
      text: existing != null && existing.durationMinutes > 0
          ? existing.durationMinutes.toString()
          : '',
    );
    _slotsCtrl = TextEditingController();
    _offerDiscount = existing?.offerDiscount ?? false;
    _bookingTypeIndex = switch (existing?.bookingType) {
      'request' => 1,
      'none' => 2,
      _ => 0,
    };
    final existingCat = existing?.category.trim() ?? '';
    _categoryOptions = List<String>.from(widget.existingCategories);
    if (existingCat.isNotEmpty && !_categoryOptions.contains(existingCat)) {
      _categoryOptions.add(existingCat);
    }
    _selectedCategory = existingCat.isNotEmpty ? existingCat : null;
    _savedImageUrl = existing?.imageUrl ?? '';
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _discountedPriceCtrl.dispose();
    _rewardPointsCtrl.dispose();
    _durationCtrl.dispose();
    _slotsCtrl.dispose();
    super.dispose();
  }

  double get _priceValue => double.tryParse(_priceCtrl.text.trim()) ?? 0;
  double get _discountedValue =>
      double.tryParse(_discountedPriceCtrl.text.trim()) ?? 0;

  double? get _saveAmount {
    if (!_offerDiscount) return null;
    final original = _priceValue;
    final discounted = _discountedValue;
    if (original <= 0 || discounted <= 0 || discounted >= original) return null;
    return original - discounted;
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

  Future<void> _addNewCategory() async {
    final ctrl = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(BarqodyChrome.modalRadius),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(
                title: 'Add Category',
                onBack: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('CATEGORY NAME'),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => Navigator.pop(ctx, v),
                decoration: WaUi.fieldDecoration(hintText: 'e.g. Burgers'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Cancel',
                      filled: false,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PillButton(
                      label: 'Save',
                      onPressed: () => Navigator.pop(ctx, ctrl.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    setState(() {
      if (!_categoryOptions.any(
        (c) => c.toLowerCase() == trimmed.toLowerCase(),
      )) {
        _categoryOptions.add(trimmed);
      }
      _selectedCategory = trimmed;
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

    // Persist CatalogItem fields (including service extras).
    final bookingType = switch (_bookingTypeIndex) {
      1 => 'request',
      2 => 'none',
      _ => 'appointment',
    };
    Navigator.pop(
      context,
      CatalogItem(
        name: name,
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        description: _descCtrl.text.trim(),
        category: category,
        imageUrl: imageValue,
        isActive: _isActive,
        durationMinutes: int.tryParse(_durationCtrl.text.trim()) ?? 0,
        offerDiscount: widget.isService && _offerDiscount,
        discountedPrice: widget.isService && _offerDiscount
            ? (double.tryParse(_discountedPriceCtrl.text.trim()) ?? 0)
            : 0,
        rewardPoints: widget.isService
            ? (int.tryParse(_rewardPointsCtrl.text.trim()) ?? 0)
            : 0,
        bookingType: widget.isService ? bookingType : 'appointment',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isService) {
      return _buildServiceForm();
    }
    return _buildDefaultForm();
  }

  Widget _buildServiceForm() {
    final title = _isEditing ? 'Edit Service' : 'Add Service';
    final saveLabel = _isEditing ? 'Update Service' : 'Add Service';
    final saveAmt = _saveAmount;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _buildImagePicker()),
                    const SizedBox(height: 28),
                    const _FieldLabel('SERVICE NAME'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      style: WaUi.body.copyWith(fontSize: 15),
                      decoration:
                          WaUi.fieldDecoration(hintText: 'e.g. Haircut'),
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('CATEGORY'),
                    const SizedBox(height: 8),
                    _buildCategoryField(hint: 'Select category'),
                    const SizedBox(height: 20),
                    const _FieldLabel('DESCRIPTION'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      textInputAction: TextInputAction.next,
                      style: WaUi.body.copyWith(fontSize: 15),
                      decoration: WaUi.fieldDecoration(
                        hintText: 'Describe your service',
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: _FieldLabel('PRICE')),
                        Text(
                          'Offer Discount',
                          style: WaUi.body.copyWith(
                            fontSize: 13,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _offerDiscount,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.black,
                          onChanged: (v) => setState(() => _offerDiscount = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      style: WaUi.body.copyWith(fontSize: 15),
                      onChanged: (_) => setState(() {}),
                      decoration:
                          WaUi.fieldDecoration(hintText: 'e.g. 100'),
                    ),
                    if (_offerDiscount) ...[
                      const SizedBox(height: 20),
                      const _FieldLabel('DISCOUNTED PRICE'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _discountedPriceCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        style: WaUi.body.copyWith(fontSize: 15),
                        onChanged: (_) => setState(() {}),
                        decoration:
                            WaUi.fieldDecoration(hintText: 'e.g. 80'),
                      ),
                      if (saveAmt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'You save \$${saveAmt.toStringAsFixed(0)}',
                          style: WaUi.body.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    const _FieldLabel('REWARD POINTS'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rewardPointsCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      style: WaUi.body.copyWith(fontSize: 15),
                      decoration:
                          WaUi.fieldDecoration(hintText: 'Enter points'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Give customers points as a reward for this service',
                      style: WaUi.body.copyWith(
                        fontSize: 12,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('BOOKING TYPE'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (var i = 0; i < _bookingTypes.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _BookingTypeChip(
                              label: _bookingTypes[i],
                              selected: _bookingTypeIndex == i,
                              onTap: () =>
                                  setState(() => _bookingTypeIndex = i),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('DURATION (IN MINUTES)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      style: WaUi.body.copyWith(fontSize: 15),
                      decoration:
                          WaUi.fieldDecoration(hintText: 'e.g. 30'),
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('AVAILABILITY SLOTS'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _slotsCtrl,
                      readOnly: true,
                      style: WaUi.body.copyWith(fontSize: 15),
                      decoration: WaUi.fieldDecoration(
                        hintText: 'Select Slots',
                      ).copyWith(
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                      onTap: () {
                        // Local-only UI — no persistence / schedule picker.
                      },
                    ),
                    const SizedBox(height: 20),
                    _publicToggle(filled: false),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _SavePill(
                label: saveLabel,
                loading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultForm() {
    final title = _isEditing
        ? (widget.isDocument ? context.l10n.editItem : 'Edit Item')
        : widget.isDocument
            ? context.l10n.addDocument
            : 'Add Menu';

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _buildImagePicker()),
                    const SizedBox(height: 28),
                    _FieldLabel(
                      widget.isDocument ? 'DOCUMENT NAME' : 'ITEM NAME',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      style: WaUi.body.copyWith(fontSize: 15),
                      decoration: WaUi.fieldDecoration(
                        hintText: widget.isDocument
                            ? context.l10n.name
                            : 'e.g. Cheese Burger',
                      ),
                    ),
                    if (!widget.isDocument) ...[
                      const SizedBox(height: 20),
                      const _FieldLabel('ORIGINAL PRICE'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        style: WaUi.body.copyWith(fontSize: 15),
                        decoration: WaUi.fieldDecoration(hintText: '0'),
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('CATEGORY'),
                      const SizedBox(height: 8),
                      _buildCategoryField(hint: context.l10n.category),
                    ],
                    const SizedBox(height: 20),
                    const _FieldLabel('DESCRIPTION (OPTIONAL)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      style: WaUi.body.copyWith(fontSize: 15),
                      decoration: WaUi.fieldDecoration(
                        hintText: context.l10n.descriptionOptional,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 20),
                    _publicToggle(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _SavePill(
                label: _isEditing
                    ? (widget.isDocument
                        ? context.l10n.updateItem
                        : 'Update')
                    : (widget.isDocument
                        ? context.l10n.addDocument
                        : 'Add Menu'),
                loading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryField({required String hint}) {
    if (_categoryOptions.isNotEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _categoryOptions.contains(_selectedCategory)
                  ? _selectedCategory
                  : null,
              style: WaUi.body.copyWith(fontSize: 15, color: Colors.black),
              decoration: WaUi.fieldDecoration(hintText: hint),
              items: _categoryOptions
                  .map(
                    (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
          ),
          const SizedBox(width: 10),
          CircleAssetButton(
            asset: 'assets/images/png/plus-icon.png',
            iconSize: 16,
            onTap: _addNewCategory,
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.addCategoriesInYourCatalogSettingsFirst,
            style: WaUi.body.copyWith(
              color: BarqodyChrome.secondaryText,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        CircleAssetButton(
          asset: 'assets/images/png/plus-icon.png',
          iconSize: 16,
          onTap: _addNewCategory,
        ),
      ],
    );
  }

  Widget _publicToggle({bool filled = true}) {
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Public',
          style: WaUi.toolsTitleOf(
            size: 15,
            weight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        Switch(
          value: _isActive,
          activeThumbColor: Colors.white,
          activeTrackColor: Colors.black,
          onChanged: (val) => setState(() => _isActive = val),
        ),
      ],
    );

    if (!filled) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: row,
    );
  }

  Widget _buildImagePicker() {
    const size = 140.0;
    final pickedIsImage = _pickedImagePath != null &&
        DocumentFileHelper.isImage(_pickedImagePath!);

    Widget content;
    if (_pickedImagePath != null && pickedIsImage) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(
          File(_pickedImagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (_pickedImagePath != null) {
      content = _filePlaceholder(size, _pickedFileName ?? _pickedImagePath!);
    } else {
      final saved = _savedImageUrl?.trim() ?? '';
      if (saved.isNotEmpty && DocumentFileHelper.isImage(saved)) {
        content = ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            saved,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder(size),
          ),
        );
      } else if (saved.isNotEmpty) {
        content = _filePlaceholder(size, saved.split('/').last);
      } else {
        content = _imagePlaceholder(size);
      }
    }

    final hasContent = (_pickedImagePath != null) ||
        (_savedImageUrl?.trim().isNotEmpty ?? false);

    return GestureDetector(
      onTap: _pickImage,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            content,
            if (hasContent)
              Positioned(
                right: -4,
                bottom: -4,
                child: CircleAssetButton(
                  asset: 'assets/images/png/add-camera.png',
                  iconSize: 16,
                  onTap: _pickImage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filePlaceholder(double size, String label) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            DocumentFileHelper.isPdf(label)
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined,
            color: BarqodyChrome.secondaryText,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              color: BarqodyChrome.secondaryText,
              fontSize: 12,
            ),
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
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            widget.isDocument
                ? 'assets/images/png/file-icon.png'
                : 'assets/images/png/add-camera.png',
            width: 32,
            height: 32,
            errorBuilder: (_, __, ___) => Icon(
              widget.isDocument
                  ? Icons.upload_file_outlined
                  : Icons.add_a_photo_outlined,
              color: BarqodyChrome.secondaryText,
              size: 32,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.isDocument ? context.l10n.uploadDocument : 'Add Photo',
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              color: BarqodyChrome.secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BookingTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? Colors.black : const Color(0xFFE0E0E0),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WaUi.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : BarqodyChrome.secondaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: WaUi.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: BarqodyChrome.secondaryText,
      ),
    );
  }
}

class _SavePill extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _SavePill({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: WaUi.promoButton.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
