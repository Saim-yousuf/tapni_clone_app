import 'package:flutter/material.dart';

/// Lightweight shimmer used while the main profile screen is waiting on API.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.0 - t * 2, 0),
              end: Alignment(1.0 + t * 2, 0),
              colors: const [
                Color(0xFFE8E8E8),
                Color(0xFFF5F5F5),
                Color(0xFFE8E8E8),
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton that mirrors [ProfileScreen] view-mode layout.
class ProfileScreenShimmer extends StatelessWidget {
  const ProfileScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const ShimmerBox(
                width: 130,
                height: 130,
                shape: BoxShape.circle,
              ),
              const SizedBox(height: 20),
              const ShimmerBox(width: 180, height: 28, borderRadius: 8),
              const SizedBox(height: 30),
              LayoutBuilder(
                builder: (context, constraints) {
                  const columns = 3;
                  const spacing = 12.0;
                  final cellWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                          columns;
                  final iconSize = cellWidth > 130 ? 130.0 : cellWidth;
                  final radius = 24.0 * (iconSize / 130.0);

                  return Wrap(
                    spacing: spacing,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(6, (_) {
                      return SizedBox(
                        width: cellWidth,
                        child: Column(
                          children: [
                            ShimmerBox(
                              width: iconSize,
                              height: iconSize,
                              borderRadius: radius,
                            ),
                            const SizedBox(height: 8),
                            ShimmerBox(
                              width: iconSize * 0.7,
                              height: 14,
                              borderRadius: 6,
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 50),
              const SizedBox(
                width: double.infinity,
                child: ShimmerBox(
                  width: double.infinity,
                  height: 62,
                  borderRadius: 35,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 88, height: 22, borderRadius: 8),
                    SizedBox(height: 12),
                    ShimmerBox(width: 72, height: 12, borderRadius: 6),
                    SizedBox(height: 8),
                    ShimmerBox(width: 160, height: 26, borderRadius: 8),
                    SizedBox(height: 10),
                    ShimmerBox(width: 120, height: 12, borderRadius: 6),
                    SizedBox(height: 10),
                    ShimmerBox(width: 140, height: 14, borderRadius: 6),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
