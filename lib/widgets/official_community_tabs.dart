import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pill segmented control used on invitation / loyalty template galleries.
///
/// [position] should track the page/tab animation (0 = first, 1 = second)
/// so the indicator stays in sync while swiping.
class OfficialCommunityTabs extends StatelessWidget {
  final double position;
  final ValueChanged<int> onChanged;
  final String officialLabel;
  final String communityLabel;

  const OfficialCommunityTabs({
    super.key,
    required this.position,
    required this.onChanged,
    required this.officialLabel,
    required this.communityLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = position.clamp(0.0, 1.0);
    final selected = t < 0.5 ? 0 : 1;

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
              Align(
                alignment: Alignment.lerp(
                  Alignment.centerLeft,
                  Alignment.centerRight,
                  t,
                )!,
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
                      selected: selected == 0,
                      icon: Icons.star_rounded,
                      label: officialLabel,
                      onTap: () {
                        if (selected == 0 && t < 0.05) return;
                        HapticFeedback.selectionClick();
                        onChanged(0);
                      },
                    ),
                  ),
                  Expanded(
                    child: _SegTab(
                      selected: selected == 1,
                      icon: Icons.people_alt_rounded,
                      label: communityLabel,
                      onTap: () {
                        if (selected == 1 && t > 0.95) return;
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
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            letterSpacing: selected ? -0.2 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
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
