import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/business_review.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/models/explore_cart.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/explore_cart_provider.dart';
import 'package:tapni_app/repository/review_repo.dart';
import 'package:tapni_app/screens/explore_cart_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/profile_reviews_section.dart';
import 'package:tapni_app/widgets/service_booking_sheet.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

class ExploreItemDetailScreen extends StatefulWidget {
  final ExploreItem exploreItem;
  final CatalogItem catalogItem;
  final UserProfile profile;
  final SocialLink catalogLink;
  final String catalogType;

  const ExploreItemDetailScreen({
    super.key,
    required this.exploreItem,
    required this.catalogItem,
    required this.profile,
    required this.catalogLink,
    required this.catalogType,
  });

  @override
  State<ExploreItemDetailScreen> createState() =>
      _ExploreItemDetailScreenState();
}

class _ExploreItemDetailScreenState extends State<ExploreItemDetailScreen> {
  final _repo = ReviewRepo();
  final _notesCtrl = TextEditingController();
  int _qty = 1;

  List<BusinessReview> _reviews = [];
  bool _loadingReviews = true;
  String? _reviewsError;

  bool get _isService => widget.catalogType == 'services';

  CatalogItem get _item => widget.catalogItem;

  ExploreItem get _explore => widget.exploreItem;

  String get _businessName =>
      widget.profile.businessName?.trim().isNotEmpty == true
          ? widget.profile.businessName!.trim()
          : widget.profile.name;

  String get _address {
    final fromProfile = widget.profile.businessAddress?.trim() ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    return _explore.businessAddress.trim();
  }

  String get _priceLabel {
    if (_item.price > 0) return 'Rs ${_item.price.toStringAsFixed(0)}';
    return _isService ? 'Contact for price' : 'Free';
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final businessId = widget.profile.id;
    if (businessId == null || businessId.isEmpty) return;

    setState(() {
      _loadingReviews = true;
      _reviewsError = null;
    });

    final res = await _repo.listReviews(
      businessId: businessId,
      targetType: 'catalog_item',
      targetId: _item.name,
    );

    if (!mounted) return;

    if (!res.success) {
      setState(() {
        _loadingReviews = false;
        _reviewsError = res.message ?? 'Could not load reviews';
      });
      return;
    }

    setState(() {
      _loadingReviews = false;
      _reviews = _repo.parseReviews(res.data);
    });
  }

  Future<void> _writeReview() async {
    final businessId = widget.profile.id;
    if (businessId == null) return;

    final result = await showWriteReviewSheet(
      context,
      title: 'Review ${_item.name}',
    );
    if (result == null) return;

    final res = await _repo.upsertReview(
      targetType: 'catalog_item',
      targetId: _item.name,
      businessId: businessId,
      rating: result.rating,
      text: result.text,
      targetLabel: _item.name,
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? 'Review saved'
              : (res.message ?? 'Could not save review'),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
    if (res.success) _loadReviews();
  }

  void _openBusiness() {
    final username = widget.profile.username ?? _explore.businessUsername;
    if (username == null || username.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScannedProfileScreen(username: username),
      ),
    );
  }

  Future<void> _onPrimaryAction() async {
    final businessId = widget.profile.id;
    if (businessId == null) return;

    if (_isService) {
      await showServiceBookingSheet(
        context: context,
        item: _item,
        businessId: businessId,
        businessLinkId: widget.catalogLink.id,
        businessName: _businessName,
      );
      return;
    }

    final cart = context.read<ExploreCartProvider>();
    cart.addItem(
      businessId: businessId,
      businessLinkId: widget.catalogLink.id,
      businessName: _businessName,
      catalogType:
          widget.catalogType.isNotEmpty ? widget.catalogType : 'catalog',
      catalogItems: widget.catalogLink.catalogItems ?? const [],
      line: ExploreCartLine(
        item: _item,
        quantity: _qty,
        notes: _notesCtrl.text.trim(),
      ),
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${_item.name} added to cart'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _item.imageUrl.trim().isNotEmpty
        ? _item.imageUrl.trim()
        : (_explore.image ?? '').trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: Colors.white,
                  foregroundColor: WaUi.primaryText,
                  actions: [
                    IconButton(
                      tooltip: 'Cart',
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.hideCurrentSnackBar();
                        final cart = context.read<ExploreCartProvider>();
                        if (cart.isEmpty) {
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Your cart is empty'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ExploreCartScreen(),
                          ),
                        );
                      },
                      icon: Consumer<ExploreCartProvider>(
                        builder: (context, cart, _) {
                          return Badge(
                            isLabelVisible: cart.hasItems,
                            label: Text('${cart.itemCount}'),
                            child: const Icon(Icons.shopping_cart_outlined),
                          );
                        },
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: image.isNotEmpty
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _heroFallback(),
                          )
                        : _heroFallback(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _item.name,
                                style: WaUi.headline.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _chip(
                              _isService ? 'Service' : 'Item',
                              icon: _isService
                                  ? Icons.handyman_outlined
                                  : Icons.fastfood_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _priceLabel,
                          style: WaUi.headline.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _businessCard(),
                        const SizedBox(height: 18),
                        _metaChips(),
                        const SizedBox(height: 20),
                        Text(
                          'Description',
                          style: WaUi.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _item.description.trim().isNotEmpty
                              ? _item.description
                              : (_isService
                                  ? 'No service description added yet.'
                                  : 'No item description added yet.'),
                          style: WaUi.body.copyWith(
                            color: WaUi.secondaryText,
                            height: 1.45,
                          ),
                        ),
                        if (!_isService) ...[
                          const SizedBox(height: 22),
                          Text(
                            context.l10n.specialInstructions,
                            style: WaUi.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: WaUi.fieldDecoration(
                              hintText: context.l10n.eGNoSugarExtraHot,
                              radius: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                context.l10n.quantity,
                                style: WaUi.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _qty > 1
                                    ? () => setState(() => _qty--)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '$_qty',
                                style: WaUi.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _qty++),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 28),
                        _reviewsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _businessCard() {
    final photo = widget.profile.profilePhotoUrl;
    final avg = widget.profile.avgRating > 0
        ? widget.profile.avgRating
        : _explore.avgRating;
    final count = widget.profile.reviewCount > 0
        ? widget.profile.reviewCount
        : _explore.reviewCount;

    return InkWell(
      onTap: _openBusiness,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WaUi.searchBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WaUi.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              backgroundImage:
                  photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo == null || photo.isEmpty
                  ? Text(
                      _businessName.isNotEmpty
                          ? _businessName[0].toUpperCase()
                          : 'B',
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WaUi.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (widget.profile.businessCategory != null &&
                      widget.profile.businessCategory!.trim().isNotEmpty)
                    Text(
                      widget.profile.businessCategory!,
                      style: WaUi.label.copyWith(color: WaUi.secondaryText),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (avg > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFF5A623),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${avg.toStringAsFixed(1)}${count > 0 ? ' ($count)' : ''}',
                          style: WaUi.label.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else
                        Text(
                          'No ratings yet',
                          style: WaUi.label.copyWith(
                            color: WaUi.secondaryText,
                          ),
                        ),
                    ],
                  ),
                  if (_address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.label.copyWith(color: WaUi.secondaryText),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: WaUi.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _metaChips() {
    final chips = <Widget>[];
    final itemRating = _explore.avgRating;
    final itemCount = _explore.reviewCount;
    if (itemRating > 0) {
      chips.add(
        _chip(
          itemCount > 0
              ? '${itemRating.toStringAsFixed(1)} ($itemCount)'
              : itemRating.toStringAsFixed(1),
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFF5A623),
        ),
      );
    }
    if (_explore.distanceKm != null) {
      chips.add(
        _chip(
          '${_explore.distanceKm!.toStringAsFixed(1)} km',
          icon: Icons.near_me_outlined,
        ),
      );
    }
    if (_item.category.isNotEmpty) {
      chips.add(_chip(_item.category, icon: Icons.label_outline));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _reviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: WaUi.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _writeReview,
              child: const Text('Write a review'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingReviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_reviewsError != null)
          Text(
            _reviewsError!,
            style: WaUi.label.copyWith(color: Colors.redAccent),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WaUi.searchBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'No reviews for this ${_isService ? 'service' : 'item'} yet.',
              style: WaUi.body.copyWith(color: WaUi.secondaryText),
            ),
          )
        else
          ..._reviews.map(_reviewTile),
      ],
    );
  }

  Widget _reviewTile(BusinessReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WaUi.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: WaUi.searchBg,
                backgroundImage: review.reviewerPhoto != null &&
                        review.reviewerPhoto!.isNotEmpty
                    ? NetworkImage(review.reviewerPhoto!)
                    : null,
                child: review.reviewerPhoto == null ||
                        review.reviewerPhoto!.isEmpty
                    ? Text(
                        review.reviewerName.isNotEmpty
                            ? review.reviewerName[0].toUpperCase()
                            : 'U',
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.reviewerName.isNotEmpty
                      ? review.reviewerName
                      : 'Customer',
                  style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: const Color(0xFFF5A623),
                  );
                }),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.text, style: WaUi.body),
          ],
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final total = _item.price * (_isService ? 1 : _qty);
    final totalLabel = _item.price > 0
        ? 'Rs ${total.toStringAsFixed(0)}'
        : _priceLabel;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEF0F2))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isService ? 'Service' : context.l10n.total,
                    style: WaUi.label.copyWith(color: WaUi.secondaryText),
                  ),
                  Text(
                    totalLabel,
                    style: WaUi.title.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: WaPrimaryButton(
                label: _isService ? 'Book now' : context.l10n.addToCart,
                onPressed: _onPrimaryAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    String label, {
    IconData? icon,
    Color iconColor = WaUi.secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: WaUi.searchBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: WaUi.label.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      color: WaUi.searchBg,
      child: Icon(
        _isService ? Icons.handyman_outlined : Icons.fastfood_outlined,
        size: 64,
        color: WaUi.secondaryText,
      ),
    );
  }
}
