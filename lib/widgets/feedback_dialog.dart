import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Feedback modal matching Tools redesign. Submission stays mock-only.
class FeedbackDialog extends StatefulWidget {
  final VoidCallback onSubmitted;

  const FeedbackDialog({super.key, required this.onSubmitted});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onSubmitted,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => FeedbackDialog(onSubmitted: onSubmitted),
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  static const _maxLen = 500;
  final _controller = TextEditingController();
  double _rating = 4.5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop();
    widget.onSubmitted();
  }

  @override
  Widget build(BuildContext context) {
    final len = _controller.text.characters.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 14, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BarqodyChrome.modalRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: CircleCloseButton(
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'How has your experience been with BarQody?',
                style: WaUi.toolsTitleOf(
                  size: 22,
                  weight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Center(
                  child: RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    glow: false,
                    unratedColor: const Color(0xFFD1D1D6),
                    itemSize: 42,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFCC00),
                    ),
                    onRatingUpdate: (rating) {
                      setState(() => _rating = rating);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'What ideas, features, or issues would you like to share with us?',
                style: WaUi.body.copyWith(
                  fontSize: 14,
                  color: BarqodyChrome.bodyText,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: BarqodyChrome.fieldFill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLength: _maxLen,
                      maxLines: null,
                      expands: true,
                      onChanged: (_) => setState(() {}),
                      style: WaUi.body.copyWith(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                      cursorColor: Colors.black,
                      decoration: const InputDecoration(
                        hintText: 'Enter your thought...',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: BarqodyChrome.secondaryText,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.fromLTRB(16, 14, 16, 28),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 10,
                      child: Text(
                        '$len/$_maxLen',
                        style: WaUi.caption.copyWith(
                          fontSize: 12,
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PillButton(
                label: context.l10n.sendFeedback,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
