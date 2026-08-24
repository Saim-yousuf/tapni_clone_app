import 'package:flutter/material.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';

/// Skeleton for [ExploreItemDetailScreen] — hero image, title, business row, CTA bar.
class ExploreItemDetailShimmer extends StatelessWidget {
  const ExploreItemDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.primaryBlack : Colors.white;
    final barBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: AppShimmer(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: bg,
                    automaticallyImplyLeading: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: ShimmerBox(
                        width: MediaQuery.sizeOf(context).width,
                        height: 300,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: ShimmerBox(
                                  width: double.infinity,
                                  height: 28,
                                  borderRadius: 8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ShimmerBox(width: 64, height: 28, borderRadius: 14),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const ShimmerBox(width: 120, height: 24, borderRadius: 8),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF3A3B3C)
                                    : WaUi.divider,
                              ),
                            ),
                            child: const Row(
                              children: [
                                ShimmerBox(
                                  width: 48,
                                  height: 48,
                                  shape: BoxShape.circle,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ShimmerBox(
                                        width: 140,
                                        height: 16,
                                        borderRadius: 6,
                                      ),
                                      SizedBox(height: 8),
                                      ShimmerBox(
                                        width: 100,
                                        height: 12,
                                        borderRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            children: [
                              ShimmerBox(width: 72, height: 28, borderRadius: 14),
                              SizedBox(width: 8),
                              ShimmerBox(width: 56, height: 28, borderRadius: 14),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const ShimmerBox(width: 90, height: 16, borderRadius: 6),
                          const SizedBox(height: 8),
                          const ShimmerBox(
                            width: double.infinity,
                            height: 14,
                            borderRadius: 6,
                          ),
                          SizedBox(height: 6),
                          ShimmerBox(
                            width: MediaQuery.sizeOf(context).width * 0.72,
                            height: 14,
                            borderRadius: 6,
                          ),
                          const SizedBox(height: 28),
                          const ShimmerBox(width: 80, height: 18, borderRadius: 6),
                          const SizedBox(height: 12),
                          const ShimmerBox(
                            width: double.infinity,
                            height: 72,
                            borderRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: barBg,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF3A3B3C)
                          : const Color(0xFFEEF0F2),
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShimmerBox(width: 40, height: 12, borderRadius: 6),
                          SizedBox(height: 6),
                          ShimmerBox(width: 72, height: 18, borderRadius: 6),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ShimmerBox(
                        width: double.infinity,
                        height: 48,
                        borderRadius: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for [CustomerProgramDetailsScreen] — business row, title, card, status.
class CustomerProgramDetailShimmer extends StatelessWidget {
  const CustomerProgramDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.primaryBlack : Colors.white;
    final text = isDark ? Colors.white : WaUi.primaryText;
    final cardWidth = MediaQuery.sizeOf(context).width * 0.84;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: text),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: AppShimmer(
          child: ShimmerBox(width: 120, height: 18, borderRadius: 6),
        ),
      ),
      body: AppShimmer(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3A3B3C)
                        : WaUi.divider,
                  ),
                ),
                child: const Row(
                  children: [
                    ShimmerBox(width: 44, height: 44, shape: BoxShape.circle),
                    SizedBox(width: 12),
                    Expanded(
                      child: ShimmerBox(
                        width: double.infinity,
                        height: 16,
                        borderRadius: 6,
                      ),
                    ),
                    SizedBox(width: 8),
                    ShimmerBox(width: 64, height: 36, borderRadius: 20),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const ShimmerBox(width: 200, height: 24, borderRadius: 8),
              const SizedBox(height: 10),
              const ShimmerBox(width: 260, height: 14, borderRadius: 6),
              const SizedBox(height: 28),
              ShimmerBox(
                width: cardWidth,
                height: cardWidth * 0.62,
                borderRadius: 20,
              ),
              const SizedBox(height: 16),
              const ShimmerBox(width: 140, height: 14, borderRadius: 6),
              const SizedBox(height: 24),
              const ShimmerBox(
                width: double.infinity,
                height: 96,
                borderRadius: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Re-export for scanned business profiles opened from Explore.
class ScannedProfileShimmer extends StatelessWidget {
  const ScannedProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreenShimmer();
  }
}
