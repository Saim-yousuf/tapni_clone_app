import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/models/business_review.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/repository/review_repo.dart';
import 'package:tapni_app/screens/reviews_list_screen.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/profile_empty_state.dart';
import 'package:tapni_app/widgets/review_ui.dart';

export 'package:tapni_app/widgets/review_ui.dart'
    show WriteReviewResult, showWriteReviewSheet;

class ProfileReviewsSection extends StatefulWidget {
  final UserProfile profile;
  final bool isOwnProfile;
  final List<CatalogItem> catalogItems;

  const ProfileReviewsSection({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    this.catalogItems = const [],
  });

  @override
  State<ProfileReviewsSection> createState() => _ProfileReviewsSectionState();
}

class _ProfileReviewsSectionState extends State<ProfileReviewsSection> {
  final _repo = ReviewRepo();
  int _tabIndex = 0;

  List<BusinessReview> _businessReviews = [];
  List<ItemReviewSummary> _itemSummaries = [];
  bool _loading = true;
  String? _error;

  static const int _previewLimit = 3;

  bool get _showItemTab =>
      _itemSummaries.isNotEmpty ||
      (!widget.isOwnProfile && widget.catalogItems.isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (Constants.reviewsEnabled) _load();
  }

  Future<void> _load() async {
    final businessId = widget.profile.id;
    if (businessId == null || businessId.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final businessRes = await _repo.listReviews(
      businessId: businessId,
      targetType: 'business',
    );
    final itemsRes = await _repo.listReviews(
      businessId: businessId,
      targetType: 'catalog_item',
    );

    if (!mounted) return;

    if (!businessRes.success) {
      setState(() {
        _loading = false;
        _error = businessRes.message ?? 'Could not load reviews';
      });
      return;
    }

    final summaries = itemsRes.success
        ? _repo.parseItemSummaries(itemsRes.data)
        : <ItemReviewSummary>[];
    final showItems = summaries.isNotEmpty ||
        (!widget.isOwnProfile && widget.catalogItems.isNotEmpty);

    setState(() {
      _loading = false;
      _businessReviews = _repo.parseReviews(businessRes.data);
      _itemSummaries = summaries;
      if (!showItems) _tabIndex = 0;
    });
  }

  Future<void> _openReviewsList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewsListScreen(
          profile: widget.profile,
          isOwnProfile: widget.isOwnProfile,
          catalogItems: widget.catalogItems,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _writeBusinessReview() async {
    final businessId = widget.profile.id;
    if (businessId == null) return;

    final result = await showWriteReviewSheet(
      context,
      title: 'Review ${widget.profile.businessName ?? widget.profile.name}',
    );
    if (result == null) return;

    final res = await _repo.upsertReview(
      targetType: 'business',
      targetId: businessId,
      businessId: businessId,
      rating: result.rating,
      text: result.text,
      targetLabel: widget.profile.businessName ?? widget.profile.name,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? 'Review saved'
              : (res.message ?? 'Could not save review'),
        ),
      ),
    );
    if (res.success) _load();
  }

  Future<void> _writeItemReview(ItemReviewSummary summary) async {
    final businessId = widget.profile.id;
    if (businessId == null) return;

    final result = await showWriteReviewSheet(
      context,
      title: 'Review ${summary.targetLabel}',
    );
    if (result == null) return;

    final res = await _repo.upsertReview(
      targetType: 'catalog_item',
      targetId: summary.targetId,
      businessId: businessId,
      rating: result.rating,
      text: result.text,
      targetLabel: summary.targetLabel,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? 'Review saved'
              : (res.message ?? 'Could not save review'),
        ),
      ),
    );
    if (res.success) _load();
  }

  Future<void> _writeNewItemReview() async {
    if (widget.catalogItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No catalog items to review yet')),
      );
      return;
    }

    final item = await showModalBottomSheet<CatalogItem>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: SheetHeader(
                  title: 'Select item or service',
                  onBack: () => Navigator.pop(ctx),
                ),
              ),
              ...widget.catalogItems.map(
                (item) => ListTile(
                  title: Text(item.name),
                  onTap: () => Navigator.pop(ctx, item),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (item == null) return;

    final businessId = widget.profile.id;
    if (businessId == null) return;
    final itemId = item.name;

    final result = await showWriteReviewSheet(
      context,
      title: 'Review ${item.name}',
    );
    if (result == null) return;

    final res = await _repo.upsertReview(
      targetType: 'catalog_item',
      targetId: itemId,
      businessId: businessId,
      rating: result.rating,
      text: result.text,
      targetLabel: item.name,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? 'Review saved'
              : (res.message ?? 'Could not save review'),
        ),
      ),
    );
    if (res.success) _load();
  }

  Future<void> _report(String id) async {
    await _repo.reportReview(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review reported')),
    );
  }

  void _onPlus() {
    HapticFeedback.selectionClick();
    if (widget.isOwnProfile) {
      _openReviewsList();
      return;
    }
    if (_tabIndex == 0) {
      _writeBusinessReview();
    } else {
      _writeNewItemReview();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Constants.reviewsEnabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _YourReviewsHeader(
            onTitleTap: _openReviewsList,
            onPlus: _onPlus,
          ),
          if (_showItemTab) ...[
            const SizedBox(height: 14),
            _ReviewsSegmentedTabs(
              selected: _tabIndex,
              onChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _tabIndex = i);
              },
            ),
          ],
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
                ),
              ),
            )
          else if (_tabIndex == 0)
            _BusinessReviewsBody(
              reviews: _businessReviews,
              previewLimit: _previewLimit,
              isOwnProfile: widget.isOwnProfile,
              onWrite: _writeBusinessReview,
              onReport: _report,
              onSeeAll: _businessReviews.length > _previewLimit
                  ? _openReviewsList
                  : null,
            )
          else
            _ItemReviewsBody(
              summaries: _itemSummaries,
              isOwnProfile: widget.isOwnProfile,
              onWriteSummary: _writeItemReview,
              onWriteNew: _writeNewItemReview,
            ),
        ],
      ),
    );
  }
}

class _YourReviewsHeader extends StatelessWidget {
  final VoidCallback onTitleTap;
  final VoidCallback onPlus;

  const _YourReviewsHeader({
    required this.onTitleTap,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTitleTap,
          behavior: HitTestBehavior.opaque,
          child: Text(
            'Your Reviews',
            style: WaUi.toolsTitleOf(
              size: 17,
              weight: FontWeight.w700,
              color: Colors.black,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE8E8E8),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPlus,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD1D1D6),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/png/plus-icon.png',
                  width: 12,
                  height: 12,
                  color: Colors.black,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewsSegmentedTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _ReviewsSegmentedTabs({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegTab(
              selected: selected == 0,
              label: 'Business',
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _SegTab(
              selected: selected == 1,
              label: 'Items / Services',
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _SegTab({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.black : BarqodyChrome.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _BusinessReviewsBody extends StatelessWidget {
  final List<BusinessReview> reviews;
  final int previewLimit;
  final bool isOwnProfile;
  final VoidCallback onWrite;
  final ValueChanged<String> onReport;
  final VoidCallback? onSeeAll;

  const _BusinessReviewsBody({
    required this.reviews,
    required this.previewLimit,
    required this.isOwnProfile,
    required this.onWrite,
    required this.onReport,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return ProfileEmptyState(
        icon: Icons.star_outline_rounded,
        title: 'No business reviews yet',
        subtitle: isOwnProfile
            ? 'Customer reviews will appear here.'
            : 'Be the first to share your experience.',
        action: isOwnProfile
            ? null
            : TextButton(
                onPressed: onWrite,
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Write a review'),
              ),
      );
    }

    final preview = reviews.take(previewLimit).toList();

    return Column(
      children: [
        ...preview.map(
          (review) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BarqodyReviewCard(
              review: review,
              onDelete: () => onReport(review.id),
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: Text(
              'See all ${reviews.length} reviews',
              style: WaUi.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _ItemReviewsBody extends StatelessWidget {
  final List<ItemReviewSummary> summaries;
  final bool isOwnProfile;
  final ValueChanged<ItemReviewSummary> onWriteSummary;
  final VoidCallback onWriteNew;

  const _ItemReviewsBody({
    required this.summaries,
    required this.isOwnProfile,
    required this.onWriteSummary,
    required this.onWriteNew,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return ProfileEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No item reviews yet',
        subtitle: isOwnProfile
            ? 'Reviews for your items and services will show here.'
            : 'Review an item or service you have used.',
        action: isOwnProfile
            ? null
            : TextButton(
                onPressed: onWriteNew,
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Review an item'),
              ),
      );
    }

    return Column(
      children: [
        if (!isOwnProfile)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onWriteNew,
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('Review an item'),
            ),
          ),
        ...summaries.map((summary) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            decoration: BoxDecoration(
              color: ReviewUi.cardBg,
              borderRadius: BorderRadius.circular(ReviewUi.cardRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.targetLabel.isEmpty
                            ? 'Item'
                            : summary.targetLabel,
                        style: WaUi.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: ReviewUi.starActive,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${summary.avgRating.toStringAsFixed(1)} · ${summary.reviewCount} reviews',
                            style: WaUi.label.copyWith(
                              color: BarqodyChrome.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => onWriteSummary(summary),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
