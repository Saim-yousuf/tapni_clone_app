import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item_options.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Food-app style size picker shared by explore detail + configurator.
class CatalogSizeChips extends StatelessWidget {
  final List<CatalogVariant> variants;
  final String? selectedId;
  final String currency;
  final ValueChanged<String> onSelected;

  const CatalogSizeChips({
    super.key,
    required this.variants,
    required this.selectedId,
    required this.currency,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in variants)
          _SizeChip(
            name: v.name,
            priceLabel: v.price > 0
                ? formatMoney(v.price, currency: currency)
                : '',
            selected: selectedId == v.id,
            onTap: () => onSelected(v.id),
          ),
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String name;
  final String priceLabel;
  final bool selected;
  final VoidCallback onTap;

  const _SizeChip({
    required this.name,
    required this.priceLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: AppMotion.content,
          curve: AppMotion.easeOut,
          constraints: const BoxConstraints(minWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.black : const Color(0xFFF6F6F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: WaUi.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: selected ? Colors.white : Colors.black,
                  height: 1.15,
                ),
              ),
              if (priceLabel.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  priceLabel,
                  style: WaUi.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.88)
                        : BarqodyChrome.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
