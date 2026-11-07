import 'package:flutter/material.dart';
import 'package:tapni_app/models/business_review.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Shared Barqody review tokens / widgets used on profile + Reviews list.
class ReviewUi {
  ReviewUi._();

  static const Color cardBg = Color(0xFFF5F5F5);
  static const Color starActive = Color(0xFFFFCC00);
  static const Color starInactive = Color(0xFFD1D1D6);
  static const Color deleteRed = Color(0xFFFF3B30);
  static const Color bodyGray = Color(0xFF8E8E93);
  static const double cardRadius = 18;
}

class ReviewStarRow extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const ReviewStarRow({
    super.key,
    required this.rating,
    this.size = 18,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= rating;
        final icon = Icon(
          Icons.star_rounded,
          size: size,
          color: filled ? ReviewUi.starActive : ReviewUi.starInactive,
        );
        if (onChanged == null) return icon;
        return _AnimatedReviewStar(
          key: ValueKey('review-star-$star'),
          filled: filled,
          size: size,
          onTap: () => onChanged!(star),
        );
      }),
    );
  }
}

class _AnimatedReviewStar extends StatefulWidget {
  final bool filled;
  final double size;
  final VoidCallback onTap;

  const _AnimatedReviewStar({
    super.key,
    required this.filled,
    required this.size,
    required this.onTap,
  });

  @override
  State<_AnimatedReviewStar> createState() => _AnimatedReviewStarState();
}

class _AnimatedReviewStarState extends State<_AnimatedReviewStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedReviewStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filled != widget.filled && widget.filled) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.28), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 1), weight: 55),
    ]).animate(CurvedAnimation(parent: _pulse, curve: AppMotion.easeOut));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _pulse.forward(from: 0);
        widget.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ScaleTransition(
          scale: scale,
          child: Icon(
            Icons.star_rounded,
            size: widget.size,
            color: widget.filled ? ReviewUi.starActive : ReviewUi.starInactive,
          ),
        ),
      ),
    );
  }
}

class ReviewDeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const ReviewDeleteButton({
    super.key,
    required this.onTap,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ReviewUi.deleteRed,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Image.asset(
              'assets/images/png/delete-icon.png',
              width: size * 0.42,
              height: size * 0.42,
              color: Colors.white,
              errorBuilder: (_, __, ___) => Icon(
                Icons.delete_outline_rounded,
                size: size * 0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BarqodyReviewCard extends StatelessWidget {
  final BusinessReview review;
  final VoidCallback? onDelete;
  final int appearIndex;

  const BarqodyReviewCard({
    super.key,
    required this.review,
    this.onDelete,
    this.appearIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppAppear(
      index: appearIndex,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
        decoration: BoxDecoration(
          color: ReviewUi.cardBg,
          borderRadius: BorderRadius.circular(ReviewUi.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ReviewStarRow(rating: review.rating, size: 18),
                ),
                if (onDelete != null) ReviewDeleteButton(onTap: onDelete!),
              ],
            ),
            if (review.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                review.text.trim(),
                style: WaUi.body.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: ReviewUi.bodyGray,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WriteReviewResult {
  final int rating;
  final String text;
  const WriteReviewResult({required this.rating, required this.text});
}

/// Pixel-matched Submit Review dialog (replaces the old bottom sheet chrome).
Future<WriteReviewResult?> showWriteReviewSheet(
  BuildContext context, {
  required String title,
}) {
  return showGeneralDialog<WriteReviewResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: AppMotion.dialog,
    pageBuilder: (ctx, anim, secondary) => _WriteReviewDialog(title: title),
    transitionBuilder: (ctx, anim, secondary, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: AppMotion.easeOut,
        reverseCurve: AppMotion.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _WriteReviewDialog extends StatefulWidget {
  // Kept for call-site compatibility; mock title is fixed.
  // ignore: unused_field
  final String title;
  const _WriteReviewDialog({required this.title});

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> {
  int _rating = 5;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: AnimatedPadding(
        duration: AppMotion.dialogReverse,
        curve: AppMotion.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BarqodyChrome.modalRadius),
          clipBehavior: Clip.antiAlias,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submit a review',
                            style: WaUi.toolsTitleOf(
                              size: 20,
                              weight: FontWeight.w700,
                              color: Colors.black,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Share your private feedback directly with this person',
                            style: WaUi.body.copyWith(
                              fontSize: 13,
                              height: 1.35,
                              color: BarqodyChrome.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CircleCloseButton(),
                  ],
                ),
                const SizedBox(height: 22),
                Center(
                  child: ReviewStarRow(
                    rating: _rating,
                    size: 36,
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  minLines: 4,
                  maxLength: 1000,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your review here',
                    hintStyle: WaUi.body.copyWith(
                      fontSize: 14,
                      color: const Color(0xFFB0B0B5),
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: BarqodyChrome.fieldFill,
                    contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PillButton(
                  label: 'Submit',
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
          ),
        ),
      ),
    );
  }
}
