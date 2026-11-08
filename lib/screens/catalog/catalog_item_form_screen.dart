import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/catalog_item_options.dart';
import 'package:tapni_app/models/marketplace_category.dart';
import 'package:tapni_app/repository/marketplace_repo.dart';
import 'package:tapni_app/utils/document_file.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/app_toast.dart';

class CatalogItemFormScreen extends StatefulWidget {
  final String catalogLabel;
  final CatalogItem? existingItem;
  final List<String> existingCategories;
  final bool requireCategory;
  final bool isDocument;
  final bool isService;
  final bool isPortfolio;

  /// Shows Marketplace Classification (global taxonomy) — products only.
  final bool isProduct;

  /// Shared modifier library for this catalog (menu). Attach instead of retyping.
  final List<CatalogOptionGroup> modifierLibrary;

  const CatalogItemFormScreen({
    super.key,
    required this.catalogLabel,
    this.existingItem,
    this.existingCategories = const [],
    this.requireCategory = false,
    this.isDocument = false,
    this.isService = false,
    this.isPortfolio = false,
    this.isProduct = false,
    this.modifierLibrary = const [],
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
  Uint8List? _pickedBytes;
  String? _pickedMimeType;
  String? _pickedFileName;
  String? _savedImageUrl;
  bool _isActive = true;
  bool _isSaving = false;
  bool _featured = false;
  final Set<String> _tags = {};

  /// Menu / product sizes (per item) + attached shared modifier group ids.
  final List<_VariantEditors> _variantEditors = [];
  final Set<String> _attachedGroupIds = {};
  /// Legacy item-local groups not in the shared library.
  List<CatalogOptionGroup> _localOptionGroups = [];

  /// Marketplace classification (products only).
  final _marketplaceRepo = MarketplaceRepo();
  List<MarketplaceCategory> _marketplaceTree = const [];
  bool _marketplaceLoading = false;
  String? _marketplaceError;
  bool _listOnMarketplace = false;
  MarketplaceCategory? _marketplaceCategory;
  MarketplaceCategory? _marketplaceSubcategory;

  bool get _isEditing => widget.existingItem != null;
  bool get _showMarketplace => widget.isProduct && !widget.isDocument;
  bool get _isMenuItem =>
      !widget.isDocument &&
      !widget.isService &&
      !widget.isPortfolio &&
      !widget.isProduct;
  /// Sizes + shared modifiers: menu and products catalogs.
  bool get _supportsSizesAndModifiers =>
      !widget.isDocument && !widget.isService && !widget.isPortfolio;

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
    _featured = existing?.featured ?? false;
    _tags
      ..clear()
      ..addAll(existing?.tags ?? const []);
    _variantEditors
      ..clear()
      ..addAll(
        (existing?.variants ?? const <CatalogVariant>[]).map(_editorFromVariant),
      );
    _attachedGroupIds
      ..clear()
      ..addAll(existing?.optionGroupIds ?? const []);
    final libIds = {
      for (final g in widget.modifierLibrary)
        if (g.id.isNotEmpty) g.id,
    };
    // Promote legacy embedded groups that match library ids; keep true locals.
    _localOptionGroups = [];
    for (final g in existing?.optionGroups ?? const <CatalogOptionGroup>[]) {
      if (g.id.isNotEmpty && libIds.contains(g.id)) {
        _attachedGroupIds.add(g.id);
      } else if (g.name.trim().isNotEmpty) {
        _localOptionGroups.add(g);
      }
    }
    _listOnMarketplace =
        (existing?.marketplaceCategoryId.trim().isNotEmpty ?? false);
    if (_showMarketplace) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarketplace());
    }
  }

  Future<void> _loadMarketplace() async {
    setState(() {
      _marketplaceLoading = true;
      _marketplaceError = null;
    });
    final res = await _marketplaceRepo.getCategories();
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _marketplaceLoading = false;
        _marketplaceError = res.message ?? 'Could not load marketplace categories';
      });
      return;
    }
    final tree = _marketplaceRepo.parseTree(res.data);
    final existing = widget.existingItem;
    MarketplaceCategory? cat;
    MarketplaceCategory? sub;
    final catId = existing?.marketplaceCategoryId.trim() ?? '';
    final subId = existing?.marketplaceSubcategoryId.trim() ?? '';
    if (catId.isNotEmpty) {
      for (final c in tree) {
        if (c.id == catId) {
          cat = c;
          if (subId.isNotEmpty) {
            for (final s in c.children) {
              if (s.id == subId) {
                sub = s;
                break;
              }
            }
          }
          break;
        }
      }
    }
    setState(() {
      _marketplaceTree = tree;
      _marketplaceCategory = cat;
      _marketplaceSubcategory = sub;
      _listOnMarketplace = catId.isNotEmpty;
      _marketplaceLoading = false;
    });
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
    for (final e in _variantEditors) {
      e.dispose();
    }
    super.dispose();
  }

  _VariantEditors _editorFromVariant(CatalogVariant v) {
    return _VariantEditors(
      id: v.id.isNotEmpty ? v.id : newCatalogOptionId(),
      name: TextEditingController(text: v.name),
      price: TextEditingController(
        text: v.price > 0 ? v.price.toStringAsFixed(0) : '',
      ),
      isActive: v.isActive,
    );
  }

  _VariantEditors _newVariantEditor({double seedPrice = 0}) {
    return _VariantEditors(
      id: newCatalogOptionId(),
      name: TextEditingController(),
      price: TextEditingController(
        text: seedPrice > 0 ? seedPrice.toStringAsFixed(0) : '',
      ),
    );
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
    if (file == null || !file.hasData) return;
    final bytes = await file.readBytes();
    if (!mounted) return;
    setState(() {
      _pickedBytes = bytes;
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
                title: 'Add Section',
                onBack: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('SECTION NAME'),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => Navigator.pop(ctx, v),
                decoration: WaUi.fieldDecoration(
                  hintText: 'e.g. New Arrivals',
                ),
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
    FocusScope.of(context).unfocus();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showAppToast(
            context,
            widget.isDocument
                      ? context.l10n.pleaseEnterDocumentName
                      : context.l10n.pleaseEnterItemName,
            kind: AppToastKind.info,
          );
      return;
    }

    final category = _selectedCategory?.trim() ?? '';
    if (widget.requireCategory && category.isEmpty) {
      showAppToast(
            context,
            'Please select a business section',
            kind: AppToastKind.warning,
          );
      return;
    }

    if (_showMarketplace && _listOnMarketplace) {
      if (_marketplaceCategory == null) {
        showAppToast(
              context,
              'Select a marketplace category or turn listing off',
              kind: AppToastKind.info,
            );
        return;
      }
    }

    if (_supportsSizesAndModifiers && _variantEditors.any((e) {
      final n = e.name.text.trim();
      final p = e.price.text.trim();
      return n.isNotEmpty && (p.isEmpty || (double.tryParse(p) ?? 0) <= 0);
    })) {
      showAppToast(
        context,
        'Enter a price for every size',
        kind: AppToastKind.warning,
      );
      return;
    }

    // Discount allowed for menu / products / services (not documents).
    // Valid only when discounted > 0 and strictly < base (free items unchanged).
    if (!widget.isDocument && _offerDiscount) {
      // Sizes replace base price — validate against cheapest size when present.
      final sized = _supportsSizesAndModifiers ? _normalizedVariants() : const [];
      var base = _priceValue;
      if (sized.isNotEmpty) {
        base = sized.map((v) => v.price).reduce((a, b) => a < b ? a : b);
      }
      final sale = _discountedValue;
      String? discountError;
      if (base <= 0) {
        discountError = 'Set a base price before offering a discount';
      } else if (sale <= 0) {
        discountError = 'Discounted price must be greater than zero';
      } else if (sale >= base) {
        discountError =
            'Discounted price must be lower than the original price';
      }
      if (discountError != null) {
        showAppToast(
              context,
              discountError,
              kind: AppToastKind.error,
            );
        return;
      }
    }

    setState(() => _isSaving = true);

    var imageValue = _savedImageUrl ?? '';
    if (_pickedBytes != null && _pickedBytes!.isNotEmpty) {
      // Always persist as data-URI so web + API upload + local preview work.
      final mime = (_pickedMimeType != null &&
              _pickedMimeType!.isNotEmpty &&
              _pickedMimeType != 'unknown')
          ? _pickedMimeType
          : (widget.isDocument ? 'application/octet-stream' : 'image/jpeg');
      imageValue = bytesToDataUri(_pickedBytes!, mimeType: mime);
    }

    if (widget.isDocument && imageValue.trim().isEmpty) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showAppToast(
            context,
            context.l10n.pleaseUploadADocument,
            kind: AppToastKind.info,
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
    final listOnMarket = _showMarketplace && _listOnMarketplace;
    final variants =
        _supportsSizesAndModifiers ? _normalizedVariants() : const <CatalogVariant>[];
    // Keep list/base price in sync with cheapest size so "From" never shows 0
    // when sizes have real prices.
    var basePrice = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (variants.isNotEmpty) {
      var min = variants.first.price;
      for (final v in variants) {
        if (v.price < min) min = v.price;
      }
      if (min > 0) basePrice = min;
    }
    Navigator.pop(
      context,
      CatalogItem(
        id: widget.existingItem?.id ?? '',
        name: name,
        price: basePrice,
        description: _descCtrl.text.trim(),
        category: category,
        marketplaceCategoryId:
            listOnMarket ? (_marketplaceCategory?.id ?? '') : '',
        marketplaceSubcategoryId:
            listOnMarket ? (_marketplaceSubcategory?.id ?? '') : '',
        imageUrl: imageValue,
        isActive: _isActive,
        durationMinutes: int.tryParse(_durationCtrl.text.trim()) ?? 0,
        offerDiscount: !widget.isDocument && _offerDiscount,
        discountedPrice: !widget.isDocument && _offerDiscount
            ? (double.tryParse(_discountedPriceCtrl.text.trim()) ?? 0)
            : 0,
        rewardPoints: widget.isService
            ? (int.tryParse(_rewardPointsCtrl.text.trim()) ?? 0)
            : 0,
        bookingType: widget.isService ? bookingType : 'appointment',
        featured: _isMenuItem && _featured,
        tags: _isMenuItem ? _tags.toList() : const [],
        variants: variants,
        optionGroupIds:
            _supportsSizesAndModifiers ? _attachedGroupIds.toList() : const [],
        // Snapshot attached library groups onto the item for cart/configurator
        // even before remote id sync — plus any legacy local groups.
        optionGroups: _supportsSizesAndModifiers
            ? _snapshotAttachedGroups()
            : const [],
      ),
    );
  }

  List<CatalogVariant> _normalizedVariants() {
    final out = <CatalogVariant>[];
    for (var i = 0; i < _variantEditors.length; i++) {
      final e = _variantEditors[i];
      final name = e.name.text.trim();
      if (name.isEmpty) continue;
      final price = double.tryParse(e.price.text.trim()) ?? 0;
      out.add(
        CatalogVariant(
          id: e.id.isNotEmpty ? e.id : newCatalogOptionId(),
          name: name,
          price: price,
          sortOrder: i,
          isActive: e.isActive,
        ),
      );
    }
    return out;
  }

  List<CatalogOptionGroup> _snapshotAttachedGroups() {
    final byId = {
      for (final g in widget.modifierLibrary)
        if (g.id.isNotEmpty) g.id: g,
    };
    final out = <CatalogOptionGroup>[];
    final seen = <String>{};
    for (final id in _attachedGroupIds) {
      final g = byId[id];
      if (g != null && seen.add(id)) out.add(g);
    }
    for (final g in _localOptionGroups) {
      final key = g.id.isNotEmpty ? g.id : 'local:${g.name}';
      if (seen.add(key)) out.add(g);
    }
    return out;
  }

  /// Shared Offer Discount toggle + discounted price fields (menu/products/services).
  Widget _buildDiscountFields({required String priceHint}) {
    final saveAmt = _saveAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          decoration: WaUi.fieldDecoration(hintText: priceHint),
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
            decoration: WaUi.fieldDecoration(hintText: 'e.g. 80'),
          ),
          if (saveAmt != null) ...[
            const SizedBox(height: 8),
            Text(
              'You save ${saveAmt.toStringAsFixed(0)}',
              style: WaUi.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF27AE60),
              ),
            ),
          ],
        ],
      ],
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
                    const _FieldLabel('BUSINESS SECTION'),
                    const SizedBox(height: 8),
                    _buildCategoryField(hint: 'Select section'),
                    const SizedBox(height: 6),
                    Text(
                      'Groups this service on your website.',
                      style: WaUi.body.copyWith(
                        fontSize: 12,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
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
                    _buildDiscountFields(priceHint: 'e.g. 100'),
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
        ? (widget.isDocument
            ? context.l10n.editItem
            : widget.isPortfolio
                ? 'Edit Project'
                : 'Edit Item')
        : widget.isDocument
            ? context.l10n.addDocument
            : widget.isPortfolio
                ? 'Add Project'
                : widget.catalogLabel.toLowerCase().contains('product')
                    ? 'Add Product'
                    : 'Add Item';

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
                    if (widget.isProduct) ...[
                      _sectionHeading('Product Information'),
                      const SizedBox(height: 14),
                    ],
                    Center(child: _buildImagePicker()),
                    const SizedBox(height: 28),
                    _FieldLabel(
                      widget.isDocument
                          ? 'DOCUMENT NAME'
                          : widget.isPortfolio
                              ? 'PROJECT NAME'
                              : widget.isProduct
                                  ? 'PRODUCT NAME'
                                  : 'ITEM NAME',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      style: WaUi.body.copyWith(fontSize: 15),
                      decoration: WaUi.fieldDecoration(
                        hintText: widget.isDocument
                            ? context.l10n.name
                            : widget.isPortfolio
                                ? 'e.g. Brand Refresh'
                                : widget.isProduct
                                    ? 'e.g. Wireless Earbuds'
                                    : 'e.g. Cheese Burger',
                      ),
                    ),
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
                    if (!widget.isDocument && !widget.isPortfolio) ...[
                      const SizedBox(height: 28),
                      _sectionHeading('Pricing'),
                      const SizedBox(height: 14),
                      _buildDiscountFields(priceHint: '0'),
                      const SizedBox(height: 28),
                      _sectionHeading('Business Website Organization'),
                      const SizedBox(height: 6),
                      Text(
                        'Sections group products on your own website only.',
                        style: WaUi.body.copyWith(
                          fontSize: 12,
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _FieldLabel('BUSINESS SECTION'),
                      const SizedBox(height: 8),
                      _buildCategoryField(hint: 'Select section'),
                    ],
                    if (widget.isPortfolio) ...[
                      const SizedBox(height: 28),
                      _sectionHeading('Business Website Organization'),
                      const SizedBox(height: 12),
                      const _FieldLabel('BUSINESS SECTION'),
                      const SizedBox(height: 8),
                      _buildCategoryField(hint: 'e.g. Branding'),
                    ],
                    if (_showMarketplace) ...[
                      const SizedBox(height: 28),
                      _sectionHeading('Marketplace Classification'),
                      const SizedBox(height: 6),
                      Text(
                        'Help customers discover this product across BarQody Marketplace. Independent of your website section.',
                        style: WaUi.body.copyWith(
                          fontSize: 12,
                          color: BarqodyChrome.secondaryText,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMarketplaceBlock(),
                    ],
                    if (_supportsSizesAndModifiers) ...[
                      const SizedBox(height: 28),
                      _sectionHeading('Sizes'),
                      const SizedBox(height: 6),
                      Text(
                        'Add Small / Medium / Large with each price. Customers pick a size on the detail page.',
                        style: WaUi.body.copyWith(
                          fontSize: 12,
                          color: BarqodyChrome.secondaryText,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildVariantsEditor(),
                      const SizedBox(height: 28),
                      _sectionHeading('Modifiers'),
                      const SizedBox(height: 6),
                      Text(
                        'Attach shared groups from your catalog library (Toppings, Sauce…). Create groups once under Modifiers.',
                        style: WaUi.body.copyWith(
                          fontSize: 12,
                          color: BarqodyChrome.secondaryText,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAttachModifiers(),
                    ],
                    if (_isMenuItem) ...[
                      const SizedBox(height: 28),
                      _sectionHeading('Menu highlights'),
                      const SizedBox(height: 12),
                      _menuFeaturedToggle(),
                      const SizedBox(height: 12),
                      const _FieldLabel('TAGS'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in const [
                            ('veg', 'Veg'),
                            ('spicy', 'Spicy'),
                            ('popular', 'Popular'),
                          ])
                            FilterChip(
                              label: Text(tag.$2),
                              selected: _tags.contains(tag.$1),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _tags.add(tag.$1);
                                  } else {
                                    _tags.remove(tag.$1);
                                  }
                                });
                              },
                              selectedColor: Colors.black,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: _tags.contains(tag.$1)
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
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
                        : widget.isProduct
                            ? 'Update Product'
                            : 'Update')
                    : (widget.isDocument
                        ? context.l10n.addDocument
                        : widget.isProduct
                            ? 'Add Product'
                            : 'Add Item'),
                loading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _variantEditors.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _VariantRow(
            key: ValueKey('variant-${_variantEditors[i].id}-$i'),
            editor: _variantEditors[i],
            onRemove: () {
              setState(() {
                final removed = _variantEditors.removeAt(i);
                removed.dispose();
              });
            },
          ),
        ],
        if (_variantEditors.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'No sizes yet — e.g. Small 499, Medium 799, Large 999.',
              style: WaUi.body.copyWith(
                fontSize: 12,
                color: BarqodyChrome.secondaryText,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _variantEditors.add(
                  _newVariantEditor(
                    seedPrice: double.tryParse(_priceCtrl.text.trim()) ?? 0,
                  ),
                );
              });
            },
            icon: const Icon(Icons.add, size: 18, color: Colors.black),
            label: const Text(
              'Add size',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachModifiers() {
    final lib = widget.modifierLibrary
        .where((g) => g.id.isNotEmpty && g.name.trim().isNotEmpty)
        .toList();
    if (lib.isEmpty && _localOptionGroups.isEmpty) {
      return _modifierCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 10, 10),
          child: Text(
            'No shared groups yet. Open Modifiers on the menu screen, create Toppings / Sauce once, then come back and attach them here.',
            style: WaUi.body.copyWith(
              fontSize: 13,
              color: BarqodyChrome.secondaryText,
              height: 1.35,
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lib.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in lib)
                FilterChip(
                  label: Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: _attachedGroupIds.contains(g.id),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _attachedGroupIds.add(g.id);
                      } else {
                        _attachedGroupIds.remove(g.id);
                      }
                    });
                  },
                  selectedColor: Colors.black,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _attachedGroupIds.contains(g.id)
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        if (_localOptionGroups.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Item-only groups (legacy)',
            style: WaUi.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: BarqodyChrome.secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < _localOptionGroups.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _modifierCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _localOptionGroups[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _localOptionGroups.removeAt(i)),
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _modifierCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _menuFeaturedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                SizedBox(height: 2),
                Text(
                  'Show in the featured strip on your menu site',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _featured,
            activeColor: Colors.black,
            onChanged: (v) => setState(() => _featured = v),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return Text(
      text,
      style: WaUi.toolsTitleOf(
        size: 16,
        weight: FontWeight.w800,
        color: Colors.black,
      ),
    );
  }

  Widget _buildMarketplaceBlock() {
    if (_marketplaceLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }
    if (_marketplaceError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _marketplaceError!,
            style: WaUi.body.copyWith(
              fontSize: 13,
              color: BarqodyChrome.secondaryText,
            ),
          ),
          TextButton(onPressed: _loadMarketplace, child: const Text('Retry')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: BarqodyChrome.fieldFill,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'List on Marketplace',
                  style: WaUi.toolsTitleOf(
                    size: 15,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              Switch(
                value: _listOnMarketplace,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.black,
                onChanged: (v) => setState(() {
                  _listOnMarketplace = v;
                  if (!v) {
                    _marketplaceCategory = null;
                    _marketplaceSubcategory = null;
                  }
                }),
              ),
            ],
          ),
        ),
        if (_listOnMarketplace) ...[
          const SizedBox(height: 16),
          if (_marketplaceTree.isEmpty)
            Text(
              'No marketplace categories yet. Ask an admin to add them.',
              style: WaUi.body.copyWith(
                fontSize: 13,
                color: BarqodyChrome.secondaryText,
              ),
            )
          else ...[
            const _FieldLabel('MARKETPLACE CATEGORY'),
            const SizedBox(height: 8),
            _selectorTile(
              value: _marketplaceCategory?.name,
              placeholder: 'Select category',
              onTap: _pickMarketplaceCategory,
            ),
            const SizedBox(height: 16),
            const _FieldLabel('SUBCATEGORY'),
            const SizedBox(height: 8),
            _selectorTile(
              value: _marketplaceSubcategory?.name,
              placeholder: _marketplaceCategory == null
                  ? 'Select a category first'
                  : (_marketplaceCategory!.children.isEmpty
                      ? 'No subcategories'
                      : 'Select subcategory (optional)'),
              enabled: _marketplaceCategory != null &&
                  _marketplaceCategory!.children.isNotEmpty,
              onTap: _pickMarketplaceSubcategory,
            ),
          ],
        ],
      ],
    );
  }

  Widget _selectorTile({
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  (value != null && value.isNotEmpty) ? value : placeholder,
                  style: WaUi.body.copyWith(
                    fontSize: 15,
                    color: (value != null && value.isNotEmpty)
                        ? Colors.black
                        : BarqodyChrome.secondaryText,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: enabled
                    ? Colors.black
                    : BarqodyChrome.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMarketplaceCategory() async {
    final selected = await _showMarketplacePicker(
      title: 'Marketplace Category',
      items: _marketplaceTree,
      selectedId: _marketplaceCategory?.id,
      allowClear: true,
      searchHint: 'Search categories',
    );
    if (!mounted || selected == null) return;
    if (selected.id.isEmpty) {
      setState(() {
        _marketplaceCategory = null;
        _marketplaceSubcategory = null;
      });
      return;
    }
    setState(() {
      _marketplaceCategory = selected;
      _marketplaceSubcategory = null;
    });
  }

  Future<void> _pickMarketplaceSubcategory() async {
    final parent = _marketplaceCategory;
    if (parent == null || parent.children.isEmpty) return;
    final selected = await _showMarketplacePicker(
      title: parent.name,
      items: parent.children,
      selectedId: _marketplaceSubcategory?.id,
      allowClear: true,
      searchHint: 'Search subcategories',
    );
    if (!mounted || selected == null) return;
    setState(() {
      _marketplaceSubcategory =
          selected.id.isEmpty ? null : selected;
    });
  }

  /// Returns selected category, empty-id sentinel for clear, or null if dismissed.
  Future<MarketplaceCategory?> _showMarketplacePicker({
    required String title,
    required List<MarketplaceCategory> items,
    String? selectedId,
    bool allowClear = false,
    String searchHint = 'Search',
  }) async {
    final searchCtrl = TextEditingController();
    return showModalBottomSheet<MarketplaceCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var query = '';
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final filtered = items.where((c) {
              if (query.isEmpty) return true;
              return c.name.toLowerCase().contains(query);
            }).toList();
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(BarqodyChrome.modalRadius),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(
                    title: title,
                    onBack: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (v) =>
                        setSheet(() => query = v.trim().toLowerCase()),
                    decoration: WaUi.fieldDecoration(hintText: searchHint),
                  ),
                  if (allowClear) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(
                        ctx,
                        const MarketplaceCategory(id: '', name: ''),
                      ),
                      child: const Text('Clear selection'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No categories found',
                              style: WaUi.body.copyWith(
                                color: BarqodyChrome.secondaryText,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              final selected = item.id == selectedId;
                              return Material(
                                color: selected
                                    ? Colors.black
                                    : BarqodyChrome.fieldFill,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => Navigator.pop(ctx, item),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Text(
                                      item.name,
                                      style: WaUi.body.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
            'Add a business section first (or tap +).',
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
    final pickedName = _pickedFileName ?? '';
    final pickedIsImage = _pickedBytes != null &&
        DocumentFileHelper.isImage(pickedName, pickedName);

    Widget content;
    if (_pickedBytes != null && pickedIsImage) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(
          _pickedBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (_pickedBytes != null) {
      content = _filePlaceholder(size, _pickedFileName ?? 'Document');
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

    final hasContent = (_pickedBytes != null) ||
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

class _VariantEditors {
  final String id;
  final TextEditingController name;
  final TextEditingController price;
  final bool isActive;

  _VariantEditors({
    required this.id,
    required this.name,
    required this.price,
    this.isActive = true,
  });

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _VariantRow extends StatelessWidget {
  final _VariantEditors editor;
  final VoidCallback onRemove;

  const _VariantRow({
    super.key,
    required this.editor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: editor.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Size name',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: TextField(
              controller: editor.price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Price',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: Image.asset(
              'assets/images/png/trash-bin-icon.png',
              width: 16,
              height: 16,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.delete_outline, size: 18),
            ),
          ),
        ],
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
