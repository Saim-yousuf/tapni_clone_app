import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Get started wall — video: fan unfolds into a horizontal peek row, then CTAs.
class OnboardingGetStarted extends StatefulWidget {
  const OnboardingGetStarted({
    super.key,
    required this.faces,
    required this.onBack,
    required this.onPhone,
    required this.onQr,
    required this.onLegal,
  });

  final List<String> faces;
  final VoidCallback onBack;
  final VoidCallback onPhone;
  final VoidCallback onQr;
  final Future<void> Function(String path) onLegal;

  @override
  State<OnboardingGetStarted> createState() => _OnboardingGetStartedState();
}

class _OnboardingGetStartedState extends State<OnboardingGetStarted>
    with TickerProviderStateMixin {
  late final AnimationController _morph;
  late final AnimationController _chrome;
  late final PageController _page;
  Timer? _auto;
  bool _lineReady = false;
  int _index = 0;

  List<String> get _faces =>
      widget.faces.isEmpty ? const <String>[] : widget.faces;

  @override
  void initState() {
    super.initState();
    _index =
        _faces.isEmpty ? 0 : (_faces.length ~/ 2).clamp(0, _faces.length - 1);
    _page = PageController(viewportFraction: 0.72, initialPage: _index);
    _morph = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _chrome = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Brief hold on fan, then unfold → line, then chrome + PageView.
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      _morph.forward().whenComplete(() {
        if (!mounted) return;
        setState(() => _lineReady = true);
        _chrome.forward();
        _startAuto();
      });
    });
  }

  void _startAuto() {
    _auto?.cancel();
    _auto = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (!mounted || !_page.hasClients || _faces.length < 2) return;
      final next = (_index + 1) % _faces.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _morph.dispose();
    _chrome.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = (size.width * 0.072).clamp(22.0, 32.0);
    final cardH = math.min(size.width * 0.58, 260.0) * 1.22;
    final chrome = CurvedAnimation(parent: _chrome, curve: Curves.easeOutCubic);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
              child: SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FadeTransition(
                    opacity: chrome,
                    child: CircleBackButton(onTap: widget.onBack),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: (size.height * 0.38).clamp(260.0, 340.0),
              width: double.infinity,
              child: _lineReady
                  ? PageView.builder(
                      controller: _page,
                      itemCount: _faces.length,
                      onPageChanged: (i) => _index = i,
                      itemBuilder: (context, i) {
                        return AnimatedBuilder(
                          animation: _page,
                          builder: (context, child) {
                            var page = _index.toDouble();
                            if (_page.hasClients && _page.page != null) {
                              page = _page.page!;
                            }
                            final d = (page - i).abs().clamp(0.0, 1.0);
                            return Transform.scale(
                              scale: 1.0 - d * 0.06,
                              child: child,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Center(
                              child: _CardImage(
                                asset: _faces[i],
                                width: math.min(size.width * 0.58, 260.0),
                                height: cardH,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : AnimatedBuilder(
                      animation: _morph,
                      builder: (_, _) => _FanToLine(
                        faces: _faces,
                        progress: _morph.value,
                        cardH: cardH,
                      ),
                    ),
            ),
            const Spacer(),
            FadeTransition(
              opacity: chrome,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(chrome),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 18),
                  child: Column(
                    children: [
                      Text(
                        'Get started',
                        textAlign: TextAlign.center,
                        style: AppFonts.textStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your digital card, one tap away',
                        textAlign: TextAlign.center,
                        style: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AuthUi.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      AuthSoftPillButton(
                        label: 'Continue with Phone',
                        leading:
                            const Icon(Icons.phone_iphone_rounded, size: 20),
                        onPressed: widget.onPhone,
                      ),
                      const SizedBox(height: 12),
                      AuthSoftPillButton(
                        label: 'Continue with QR',
                        leading: const Icon(Icons.qr_code_2_rounded, size: 20),
                        onPressed: widget.onQr,
                      ),
                      const SizedBox(height: 22),
                      Text.rich(
                        TextSpan(
                          style: AppFonts.textStyle(
                            fontSize: 12,
                            color: AuthUi.textSecondary,
                            height: 1.45,
                          ),
                          children: [
                            const TextSpan(
                              text: 'By continuing, you agree to the ',
                            ),
                            TextSpan(
                              text: 'Barqody ',
                              style: AppFonts.textStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AuthUi.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () => widget.onLegal('/terms'),
                                child: Text(
                                  context.l10n.termsOfService,
                                  style: AppFonts.textStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AuthUi.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Video morph: stacked fan → one centered horizontal line.
class _FanToLine extends StatelessWidget {
  const _FanToLine({
    required this.faces,
    required this.progress,
    required this.cardH,
  });

  final List<String> faces;
  final double progress;
  final double cardH;

  /// Depth → horizontal slot so center stays occupied.
  static int _slot(int depth) {
    switch (depth) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return -1;
      case 3:
        return 2;
      default:
        return -2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final p = progress.clamp(0.0, 1.0);
    // Phase 1: unwind rotation. Phase 2: slide into line.
    final unwind = Curves.easeOutCubic.transform((p / 0.40).clamp(0.0, 1.0));
    final spread = Curves.easeInOutCubic.transform(
      ((p - 0.18) / 0.82).clamp(0.0, 1.0),
    );
    final count = math.min(faces.length, 5);
    final cardW = math.min(w * 0.58, 260.0);
    final gap = cardW * 0.62;
    final fanBias = -((count - 1) * 18.0 * 0.45) * (1.0 - spread);

    return Center(
      child: SizedBox(
        width: w,
        height: cardH + 40,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (var depth = count - 1; depth >= 0; depth--)
              Builder(
                builder: (context) {
                  final fanAngle = depth * 0.11;
                  final fanX = depth * 18.0 + fanBias;
                  final fanY = depth * 6.0;
                  final fanScale = 1.0 - depth * 0.028;
                  final slot = _slot(depth);
                  final lineX = slot * gap;
                  final lineScale = slot == 0 ? 1.0 : 0.94;

                  final angle = fanAngle * (1.0 - unwind);
                  final dx = fanX + (lineX - fanX) * spread;
                  final dy = fanY * (1.0 - spread);
                  final scale = fanScale + (lineScale - fanScale) * spread;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..translateByDouble(dx, dy, 0, 1)
                      ..rotateZ(angle)
                      ..scaleByDouble(scale, scale, 1, 1),
                    child: _CardImage(
                      asset: faces[depth % faces.length],
                      width: cardW,
                      height: cardH,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({
    required this.asset,
    required this.width,
    required this.height,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xFFE8E8ED),
            child: Icon(Icons.image_outlined, size: 40),
          ),
        ),
      ),
    );
  }
}
