import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

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

/// Screenshot-style progress + title + 2-col option grid + Continue.
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
    this.childAspectRatio = 1.05,
    this.iconBoxSize = 52,
    this.emojiSize = 24,
    this.iconSize = 26,
    this.cardPadding = const EdgeInsets.fromLTRB(12, 18, 12, 14),
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
  final double childAspectRatio;
  final double iconBoxSize;
  final double emojiSize;
  final double iconSize;
  final EdgeInsets cardPadding;
  final double labelFontSize;

  static const _muted = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BarqodyTitleBar(title: title, onBack: onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BarqodyChrome.sidePad,
            10,
            BarqodyChrome.sidePad,
            0,
          ),
          child: _StepProgress(current: stepIndex, total: totalSteps),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BarqodyChrome.sidePad,
              28,
              BarqodyChrome.sidePad,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: AppFonts.textStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.15,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    subtitle!,
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _muted,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                if (options.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        loading ? 'Loading…' : 'No options available',
                        style: AppFonts.textStyle(
                          fontSize: 14,
                          color: _muted,
                        ),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: options.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final item = options[index];
                      final selected = item.id == selectedId;
                      return _OptionCard(
                        item: item,
                        selected: selected,
                        iconBoxSize: iconBoxSize,
                        emojiSize: emojiSize,
                        iconSize: iconSize,
                        padding: cardPadding,
                        labelFontSize: labelFontSize,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelect(item.id);
                        },
                      );
                    },
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
            16,
          ),
          child: PillButton(
            label: loading ? '…' : continueLabel,
            enabled: !loading && selectedId != null && onContinue != null,
            onPressed: () => onContinue?.call(),
          ),
        ),
      ],
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
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 3,
            decoration: BoxDecoration(
              color: active ? Colors.black : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.iconBoxSize,
    required this.emojiSize,
    required this.iconSize,
    required this.padding,
    required this.labelFontSize,
  });

  final BusinessOptionItem item;
  final bool selected;
  final VoidCallback onTap;
  final double iconBoxSize;
  final double emojiSize;
  final double iconSize;
  final EdgeInsets padding;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    final radius = iconBoxSize >= 60 ? 16.0 : 14.0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.black : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: selected ? Colors.black : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(radius),
                ),
                alignment: Alignment.center,
                child: _buildIcon(selected),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.textStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool selected) {
    final imageSize = iconSize + 2;
    if (item.iconUrl != null && item.iconUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          item.iconUrl!,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(selected),
        ),
      );
    }
    return _fallbackIcon(selected);
  }

  Widget _fallbackIcon(bool selected) {
    if (item.emoji != null && item.emoji!.isNotEmpty) {
      return Text(item.emoji!, style: TextStyle(fontSize: emojiSize));
    }
    return Icon(
      item.icon ?? Icons.category_rounded,
      size: iconSize,
      color: selected ? Colors.white : Colors.black87,
    );
  }
}
