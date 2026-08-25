import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/models/business_review.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/repository/review_repo.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/profile_empty_state.dart';
import 'package:tapni_app/widgets/wa_primary_button.dart';

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

    setState(() {
      _loading = false;
      _businessReviews = _repo.parseReviews(businessRes.data);
      _itemSummaries = itemsRes.success
          ? _repo.parseItemSummaries(itemsRes.data)
          : [];
    });
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
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(WaUi.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select item or service',
                  style: WaUi.headline.copyWith(fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    if (!Constants.reviewsEnabled) return const SizedBox.shrink();

    final avg = widget.profile.avgRating;
    final count = widget.profile.reviewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Text(
                'Reviews',
                style: WaUi.headline.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (count > 0) ...[
                const Icon(Icons.star_rounded,
                    size: 18, color: Color(0xFFF5A623)),
                const SizedBox(width: 4),
                Text(
                  '${avg.toStringAsFixed(1)} ($count)',
                  style: WaUi.bodyMedium,
                ),
              ] else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'No ratings yet',
                    style: WaUi.label.copyWith(
                      color: WaUi.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ReviewsSegmentedTabs(
            index: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
        ),
        const SizedBox(height: 4),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Center(
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(color: WaUi.secondaryText),
              ),
            ),
          )
        else if (_tabIndex == 0)
          _BusinessReviewsTab(
            reviews: _businessReviews,
            isOwnProfile: widget.isOwnProfile,
            onWrite: _writeBusinessReview,
            onReport: (id) async {
              await _repo.reportReview(id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review reported')),
              );
            },
          )
        else
          _ItemReviewsTab(
            summaries: _itemSummaries,
            isOwnProfile: widget.isOwnProfile,
            onWriteSummary: _writeItemReview,
            onWriteNew: _writeNewItemReview,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ReviewsSegmentedTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _ReviewsSegmentedTabs({
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              // Animated sliding indicator pill
              AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
                child: SizedBox(
                  width: tabWidth,
                  height: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ReviewSegTab(
                      selected: index == 0,
                      label: 'Business',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(0);
                      },
                    ),
                  ),
                  Expanded(
                    child: _ReviewSegTab(
                      selected: index == 1,
                      label: 'Items / Services',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(1);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewSegTab extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _ReviewSegTab({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _BusinessReviewsTab extends StatelessWidget {
  final List<BusinessReview> reviews;
  final bool isOwnProfile;
  final VoidCallback onWrite;
  final ValueChanged<String> onReport;

  const _BusinessReviewsTab({
    required this.reviews,
    required this.isOwnProfile,
    required this.onWrite,
    required this.onReport,
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
            : TextButton.icon(
                onPressed: onWrite,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Write a review'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
              ),
      );
    }

    return Column(
      children: [
        if (!isOwnProfile)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onWrite,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Write a review'),
              ),
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const Divider(height: 20),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return _ReviewTile(
              review: review,
              onReport: () => onReport(review.id),
            );
          },
        ),
      ],
    );
  }
}

class _ItemReviewsTab extends StatelessWidget {
  final List<ItemReviewSummary> summaries;
  final bool isOwnProfile;
  final ValueChanged<ItemReviewSummary> onWriteSummary;
  final VoidCallback onWriteNew;

  const _ItemReviewsTab({
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
            : TextButton.icon(
                onPressed: onWriteNew,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Review an item'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
              ),
      );
    }

    return Column(
      children: [
        if (!isOwnProfile)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onWriteNew,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Review an item'),
              ),
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: summaries.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final summary = summaries[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                summary.targetLabel.isEmpty ? 'Item' : summary.targetLabel,
                style: WaUi.bodyMedium,
              ),
              subtitle: Text(
                '${summary.avgRating.toStringAsFixed(1)} · ${summary.reviewCount} reviews',
                style: WaUi.label.copyWith(color: WaUi.secondaryText),
              ),
              trailing: isOwnProfile
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => onWriteSummary(summary),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final BusinessReview review;
  final VoidCallback onReport;

  const _ReviewTile({required this.review, required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: review.reviewerPhoto != null &&
                      review.reviewerPhoto!.isNotEmpty
                  ? NetworkImage(review.reviewerPhoto!)
                  : null,
              child: review.reviewerPhoto == null ||
                      review.reviewerPhoto!.isEmpty
                  ? Text(
                      review.reviewerName.isNotEmpty
                          ? review.reviewerName[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.reviewerName.isNotEmpty
                        ? review.reviewerName
                        : '@${review.reviewerUsername}',
                    style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 14,
                          color: const Color(0xFFF5A623),
                        ),
                      ),
                      if (review.verified) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Verified',
                          style: WaUi.label.copyWith(color: WaUi.accent),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'report') onReport();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Report')),
              ],
            ),
          ],
        ),
        if (review.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review.text, style: WaUi.body),
        ],
      ],
    );
  }
}

class WriteReviewResult {
  final int rating;
  final String text;
  const WriteReviewResult({required this.rating, required this.text});
}

Future<WriteReviewResult?> showWriteReviewSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<WriteReviewResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: WaUi.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(WaUi.radiusLg)),
    ),
    builder: (ctx) => _WriteReviewSheet(title: title),
  );
}

class _WriteReviewSheet extends StatefulWidget {
  final String title;
  const _WriteReviewSheet({required this.title});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 5;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: WaUi.headline.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Only customers with a completed order or loyalty card can review.',
            style: WaUi.label.copyWith(color: WaUi.secondaryText),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFF5A623),
                ),
              );
            }),
          ),
          TextField(
            controller: _textController,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Share your experience',
              filled: true,
              fillColor: WaUi.fieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WaUi.radiusMd),
              ),
            ),
          ),
          const SizedBox(height: 12),
          WaPrimaryButton(
            label: 'Submit review',
            onPressed: () {
              Navigator.pop(
                context,
                WriteReviewResult(
                  rating: _rating,
                  text: _textController.text.trim(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
