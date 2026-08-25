import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pill segmented control used on invitation / loyalty template galleries.
class OfficialCommunityTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final String officialLabel;
  final String communityLabel;

  const OfficialCommunityTabs({
    super.key,
    required this.index,
    required this.onChanged,
    required this.officialLabel,
    required this.communityLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment:
                    index == 0 ? Alignment.centerLeft : Alignment.centerRight,
                child: SizedBox(
                  width: tabWidth,
                  height: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _SegTab(
                      selected: index == 0,
                      icon: Icons.star_rounded,
                      label: officialLabel,
                      onTap: () {
                        if (index == 0) return;
                        HapticFeedback.selectionClick();
                        onChanged(0);
                      },
                    ),
                  ),
                  Expanded(
                    child: _SegTab(
                      selected: index == 1,
                      icon: Icons.people_alt_rounded,
                      label: communityLabel,
                      onTap: () {
                        if (index == 1) return;
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

class _SegTab extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SegTab({
    required this.selected,
    required this.icon,
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
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            letterSpacing: selected ? -0.2 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey<bool>(selected),
                  size: 17,
                  color: selected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 7),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
