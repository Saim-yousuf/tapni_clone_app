import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/user_custom_card.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/custom_card_editor_sheet.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class MyCardsCarousel extends StatelessWidget {
  MyCardsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    final cards = provider.allCardDisplays;
    final activeId = provider.activeCardId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            context.l10n.myCards,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == cards.length) {
                return _AddCardTile(
                  onTap: () => CustomCardEditorSheet.show(context),
                );
              }
              final card = cards[index];
              final isActive = card.id == activeId;
              return _CardTile(
                card: card,
                isActive: isActive,
                onTap: () => provider.setActiveCard(card.id),
                onEdit: card.isPrimary
                    ? null
                    : () {
                        final custom = provider.customCardById(card.id);
                        if (custom != null) {
                          CustomCardEditorSheet.show(context, existing: custom);
                        }
                      },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final CardDisplayData card;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _CardTile({
    required this.card,
    required this.isActive,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onEdit,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 96,
        decoration: BoxDecoration(
          color: card.template.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.accentGold : Colors.black12,
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppTheme.accentGold.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: card.template.textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit,
                      size: 12,
                      color: card.template.textColor.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            Spacer(),
            Text(
              card.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: card.template.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            SizedBox(height: 4),
            if (isActive)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(context.l10n.active2,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddCardTile extends StatelessWidget {
  final VoidCallback onTap;

  _AddCardTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          color: Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 32, color: Colors.black87),
            SizedBox(height: 6),
            Text(
              context.l10n.newCard,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
