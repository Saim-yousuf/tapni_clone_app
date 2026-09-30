import 'package:flutter/material.dart';
import 'package:tapni_app/models/business_review.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/repository/review_repo.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/review_ui.dart';

/// Full-screen Reviews list matching the Barqody mock.
class ReviewsListScreen extends StatefulWidget {
  final UserProfile profile;
  final bool isOwnProfile;
  final List<CatalogItem> catalogItems;

  const ReviewsListScreen({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    this.catalogItems = const [],
  });

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  final _repo = ReviewRepo();
  List<BusinessReview> _reviews = [];
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

    final res = await _repo.listReviews(
      businessId: businessId,
      targetType: 'business',
    );

    if (!mounted) return;

    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load reviews';
      });
      return;
    }

    setState(() {
      _loading = false;
      _reviews = _repo.parseReviews(res.data);
    });
  }

  Future<void> _report(String id) async {
    await _repo.reportReview(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review reported')),
    );
  }

  Future<void> _write() async {
    final businessId = widget.profile.id;
    if (businessId == null || widget.isOwnProfile) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Reviews',
              trailing: widget.isOwnProfile
                  ? const SizedBox(width: 40)
                  : CircleAssetButton(
                      asset: 'assets/images/png/plus-icon.png',
                      iconSize: 14,
                      onTap: _write,
                    ),
            ),
            Expanded(
              child: !Constants.reviewsEnabled
                  ? Center(
                      child: Text(
                        'Reviews are currently disabled',
                        style: WaUi.body.copyWith(
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                    )
                  : _loading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: WaUi.body.copyWith(
                                    color: BarqodyChrome.secondaryText,
                                  ),
                                ),
                              ),
                            )
                          : _reviews.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.isOwnProfile
                                              ? 'No reviews yet'
                                              : 'Be the first to leave a review',
                                          textAlign: TextAlign.center,
                                          style: WaUi.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (!widget.isOwnProfile) ...[
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: 160,
                                            child: PillButton(
                                              label: 'Submit',
                                              onPressed: _write,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    16,
                                    20,
                                    28,
                                  ),
                                  itemCount: _reviews.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final review = _reviews[index];
                                    return BarqodyReviewCard(
                                      review: review,
                                      onDelete: () => _report(review.id),
                                    );
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }
}
