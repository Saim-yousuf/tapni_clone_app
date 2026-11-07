import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/cached_app_image.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';

class BusinessOptionItem {
  final String id;
  final String label;
  final String? emoji;
  final IconData? icon;
  final String? iconUrl;

  const BusinessOptionItem({
    required this.id,
    required this.label,
    this.emoji,
    this.icon,
    this.iconUrl,
  });
}

/// Interest-style wrap of pill chips (emoji + label) + progress + Continue.
class BusinessOptionPickerPage extends StatelessWidget {
  const BusinessOptionPickerPage({
    super.key,
    required this.title,
    required this.question,
    required this.options,
    required this.selectedId,
    required this.onSelect,
    required this.onContinue,
    this.subtitle,
    this.stepIndex = 0,
    this.totalSteps = 4,
    this.continueLabel = 'Continue',
    this.loading = false,
    this.onBack,
    this.shimmerItemCount = 10,
    // Kept for call-site compatibility; unused in pill layout.
    this.childAspectRatio = 1,
    this.iconBoxSize = 0,
    this.emojiSize = 18,
    this.iconSize = 18,
    this.cardPadding = EdgeInsets.zero,
    this.labelFontSize = 14,
  });

  final String title;
  final String question;
  final String? subtitle;
  final List<BusinessOptionItem> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onContinue;
  final int stepIndex;
  final int totalSteps;
  final String continueLabel;
  final bool loading;
  final VoidCallback? onBack;
  final int shimmerItemCount;
  final double childAspectRatio;
  final double iconBoxSize;
  final double emojiSize;
  final double iconSize;
  final EdgeInsets cardPadding;
  final double labelFontSize;

  bool get _showShimmer => loading && options.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BarqodyTitleBar(title: title, onBack: onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BarqodyChrome.sidePad,
            4,
            BarqodyChrome.sidePad,
            0,
          ),
          child: _StepProgress(current: stepIndex, total: totalSteps),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BarqodyChrome.sidePad,
              18,
              BarqodyChrome.sidePad,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAppear(
                  index: 0,
                  child: Text(
                    question,
                    style: AppFonts.textStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AuthUi.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  AppAppear(
                    index: 1,
                    child: Text(
                      subtitle!,
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AuthUi.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                AppContentSwitcher(
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      _showShimmer
                          ? 'shimmer-$stepIndex'
                          : 'pills-$stepIndex-${options.length}',
                    ),
                    child: _showShimmer
                        ? const _PillsShimmer()
                        : options.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 28),
                                child: Center(
                                  child: Text(
                                    'No options available',
                                    style: AppFonts.textStyle(
                                      fontSize: 14,
                                      color: AuthUi.textMuted,
                                    ),
                                  ),
                                ),
                              )
                            : Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (var i = 0; i < options.length; i++)
                                    AppAppear(
                                      index: i + 2,
                                      maxStagger: 12,
                                      child: _InterestPill(
                                        item: options[i],
                                        selected: options[i].id == selectedId,
                                        emojiSize: emojiSize,
                                        iconSize: iconSize,
                                        labelFontSize: labelFontSize,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          onSelect(options[i].id);
                                        },
                                      ),
                                    ),
                                ],
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BarqodyChrome.sidePad,
            8,
            BarqodyChrome.sidePad,
            14,
          ),
          child: PillButton(
            label: loading && !_showShimmer ? '…' : continueLabel,
            enabled: !loading && selectedId != null && onContinue != null,
            onPressed: () => onContinue?.call(),
          ),
        ),
      ],
    );
  }
}

class _PillsShimmer extends StatelessWidget {
  const _PillsShimmer();

  static const _widths = <double>[118, 132, 104, 146, 112, 128, 120, 138, 110, 124];

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final w in _widths)
            ShimmerBox(width: w, height: 44, borderRadius: 22),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: AnimatedContainer(
            duration: AppMotion.content,
            curve: AppMotion.easeOut,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 3,
            decoration: BoxDecoration(
              color: active ? AuthUi.textPrimary : AuthUi.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _InterestPill extends StatelessWidget {
  const _InterestPill({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.emojiSize,
    required this.iconSize,
    required this.labelFontSize,
  });

  final BusinessOptionItem item;
  final bool selected;
  final VoidCallback onTap;
  final double emojiSize;
  final double iconSize;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.black : const Color(0xFFF2F2F7);
    final fg = selected ? Colors.white : AuthUi.textPrimary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.fromLTRB(14, 11, 16, 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.black : const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Leading(
                item: item,
                selected: selected,
                emojiSize: emojiSize,
                iconSize: iconSize,
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: AppFonts.textStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({
    required this.item,
    required this.selected,
    required this.emojiSize,
    required this.iconSize,
  });

  final BusinessOptionItem item;
  final bool selected;
  final double emojiSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (item.iconUrl != null && item.iconUrl!.trim().isNotEmpty) {
      return CachedAppImage(
        url: item.iconUrl!,
        width: iconSize + 2,
        height: iconSize + 2,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(6),
        placeholder: ImageShimmerPlaceholder(
          width: iconSize + 2,
          height: iconSize + 2,
          borderRadius: BorderRadius.circular(6),
        ),
        error: _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    if (item.emoji != null && item.emoji!.isNotEmpty) {
      return Text(item.emoji!, style: TextStyle(fontSize: emojiSize));
    }
    return Icon(
      item.icon ?? Icons.category_rounded,
      size: iconSize,
      color: selected ? Colors.white : AuthUi.textPrimary,
    );
  }
}
