import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/screens/linked_devices/qr_login_screen.dart';
import 'package:tapni_app/screens/phone_auth_screen.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bleap-faithful onboarding: fanned lifestyle cards → Get started wall.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide({
    required this.before,
    required this.accent,
    required this.after,
    required this.faces,
  });

  final String before;
  final String accent;
  final String after;
  final List<String> faces;
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const _accent = Color(0xFF3D6BFF);
  static const _autoAdvance = Duration(milliseconds: 3400);
  static const _k = 'assets/images/png/onboarding';

  static const _deck = <String>[
    '$_k/ob_1.jpg',
    '$_k/ob_2.jpg',
    '$_k/ob_3.jpg',
    '$_k/ob_4.jpg',
    '$_k/ob_5.jpg',
  ];

  static const _slides = <_Slide>[
    _Slide(
      before: 'Share your identity with a tap that ',
      accent: 'actually',
      after: ' lands',
      faces: _deck,
    ),
    _Slide(
      before: 'Keep every detail ',
      accent: 'always',
      after: ' up to date',
      faces: [
        '$_k/ob_2.jpg',
        '$_k/ob_3.jpg',
        '$_k/ob_4.jpg',
        '$_k/ob_5.jpg',
        '$_k/ob_1.jpg',
      ],
    ),
    _Slide(
      before: 'A card that works ',
      accent: 'everywhere',
      after: ' you network',
      faces: [
        '$_k/ob_3.jpg',
        '$_k/ob_4.jpg',
        '$_k/ob_5.jpg',
        '$_k/ob_1.jpg',
        '$_k/ob_2.jpg',
      ],
    ),
  ];

  late final PageController _authPage;
  late final AnimationController _fanCtrl;
  late final AnimationController _idleCtrl;

  int _index = 0;
  int _prev = 0;
  int _dir = 1;
  int _authIndex = 2;
  bool _authWall = false;
  Timer? _timer;
  Timer? _authTimer;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _authPage = PageController(viewportFraction: 0.88, initialPage: _authIndex);
    _fanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
      value: 1,
    );
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _armTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authTimer?.cancel();
    _authPage.dispose();
    _fanCtrl.dispose();
    _idleCtrl.dispose();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    if (_authWall) return;
    _timer = Timer.periodic(_autoAdvance, (_) {
      if (!mounted || _authWall) return;
      _setSlide(_index + 1, dir: 1);
    });
  }

  void _armAuthTimer() {
    _authTimer?.cancel();
    _authTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (!mounted || !_authPage.hasClients || !_authWall) return;
      final next = (_authIndex + 1) % _deck.length;
      _authPage.animateToPage(
        next,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _setSlide(int i, {required int dir}) {
    final next = ((i % _slides.length) + _slides.length) % _slides.length;
    if (next == _index) return;
    setState(() {
      _prev = _index;
      _index = next;
      _dir = dir;
      _drag = 0;
    });
    _fanCtrl.forward(from: 0);
    _armTimer();
  }

  void _onDragUpdate(DragUpdateDetails d) =>
      setState(() => _drag += d.delta.dx);

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (_drag < -40 || v < -350) {
      _setSlide(_index + 1, dir: 1);
    } else if (_drag > 40 || v > 350) {
      _setSlide(_index - 1, dir: -1);
    } else {
      setState(() => _drag = 0);
    }
  }

  void _openAuth() {
    _timer?.cancel();
    _idleCtrl.stop();
    setState(() => _authWall = true);
    _armAuthTimer();
  }

  void _closeAuth() {
    _authTimer?.cancel();
    setState(() => _authWall = false);
    _idleCtrl.repeat(reverse: true);
    _armTimer();
  }

  void _toPhone() {
    Navigator.of(context).pushReplacement(
      AppPageRoute(builder: (_) => const PhoneAuthScreen()),
    );
  }

  void _toQr() {
    Navigator.of(context).push(
      AppPageRoute(builder: (_) => const QrLoginScreen()),
    );
  }

  Future<void> _legal(String path) async {
    await launchUrl(
      Uri.parse('${Constants.appDomain}$path'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(anim);
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: _authWall
              ? _AuthWall(
                  key: const ValueKey('auth'),
                  pageController: _authPage,
                  faces: _slides[_index].faces,
                  authIndex: _authIndex.clamp(0, _slides[_index].faces.length - 1),
                  onPageChanged: (i) => _authIndex = i,
                  onBack: _closeAuth,
                  onPhone: _toPhone,
                  onQr: _toQr,
                  onLegal: _legal,
                )
              : _FeaturePage(
                  key: const ValueKey('feature'),
                  slide: _slides[_index],
                  prevFaces: _slides[_prev].faces,
                  settle: _fanCtrl,
                  idle: _idleCtrl,
                  direction: _dir,
                  dragDx: _drag,
                  accent: _accent,
                  onDragUpdate: _onDragUpdate,
                  onDragEnd: _onDragEnd,
                  onGetStarted: _openAuth,
                  onLogIn: _toPhone,
                ),
        ),
      ),
    );
  }
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    super.key,
    required this.slide,
    required this.prevFaces,
    required this.settle,
    required this.idle,
    required this.direction,
    required this.dragDx,
    required this.accent,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onGetStarted,
    required this.onLogIn,
  });

  final _Slide slide;
  final List<String> prevFaces;
  final Animation<double> settle;
  final Animation<double> idle;
  final int direction;
  final double dragDx;
  final Color accent;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onGetStarted;
  final VoidCallback onLogIn;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = (w * 0.072).clamp(22.0, 32.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 18, pad, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: settle,
            builder: (_, _) {
              final raw = settle.value.clamp(0.0, 1.0);
              final gather = ((raw - 0.38) / 0.62).clamp(0.0, 1.0);
              final t = Curves.easeOutCubic.transform(gather);
              return Opacity(
                opacity: 0.2 + 0.8 * t,
                child: Transform.translate(
                  offset: Offset((1 - t) * -12, (1 - t) * 10),
                  child: _Headline(
                    before: slide.before,
                    accent: slide.accent,
                    after: slide.after,
                    accentColor: accent,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: onDragUpdate,
              onHorizontalDragEnd: onDragEnd,
              child: AnimatedBuilder(
                animation: Listenable.merge([settle, idle]),
                builder: (_, _) => _BleapFan(
                  faces: slide.faces,
                  prevFront: prevFaces.isNotEmpty ? prevFaces.first : null,
                  settle: settle.value,
                  idle: idle.value,
                  direction: direction,
                  dragDx: dragDx,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AuthPrimaryPillButton(
            label: context.l10n.getStarted,
            onPressed: onGetStarted,
          ),
          const SizedBox(height: 12),
          AuthSoftPillButton(
            label: 'Log in',
            onPressed: onLogIn,
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({
    required this.before,
    required this.accent,
    required this.after,
    required this.accentColor,
  });

  final String before;
  final String accent;
  final String after;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = (w * 0.082).clamp(28.0, 34.0);
    final style = AppFonts.textStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: Colors.black,
      height: 1.12,
      letterSpacing: -0.7,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: before),
          TextSpan(text: accent, style: style.copyWith(color: accentColor)),
          TextSpan(text: after),
        ],
      ),
      textAlign: TextAlign.left,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Scatter → gather fan shuffle (feature slides only — no morph).
class _BleapFan extends StatelessWidget {
  const _BleapFan({
    required this.faces,
    required this.prevFront,
    required this.settle,
    required this.idle,
    required this.direction,
    required this.dragDx,
  });

  final List<String> faces;
  final String? prevFront;
  final double settle;
  final double idle;
  final int direction;
  final double dragDx;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cardW = math.min(size.width * 0.58, 260.0);
    final cardH = cardW * 1.22;
    final raw = settle.clamp(0.0, 1.0);
    final scatter = Curves.easeOutCubic.transform((raw / 0.42).clamp(0.0, 1.0));
    final gather =
        Curves.easeOutCubic.transform(((raw - 0.42) / 0.58).clamp(0.0, 1.0));
    final open = raw < 0.42 ? scatter : (1.0 - gather);
    final breath = math.sin(idle * math.pi * 2) * 0.5;
    final dragN = (dragDx / 140).clamp(-1.0, 1.0);
    final count = math.min(faces.length, 5);
    final shuffling = raw < 0.995 && prevFront != null;
    final fanSpread = (count - 1) * 18.0 * (1.0 + open * 0.6);

    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(-fanSpread * 0.45, 0),
        child: SizedBox(
          width: cardW + fanSpread + 48,
          height: cardH + 80,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              for (var depth = count - 1; depth >= 0; depth--)
                _card(
                  asset: faces[depth % faces.length],
                  depth: depth,
                  cardW: cardW,
                  cardH: cardH,
                  open: open,
                  gather: gather,
                  breath: breath,
                  isFront: depth == 0,
                  shuffling: shuffling,
                ),
              if (shuffling)
                _fly(
                  asset: prevFront!,
                  cardW: cardW,
                  cardH: cardH,
                  scatter: scatter,
                  gather: gather,
                  direction: direction,
                  dragN: dragN,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String asset,
    required int depth,
    required double cardW,
    required double cardH,
    required double open,
    required double gather,
    required double breath,
    required bool isFront,
    required bool shuffling,
  }) {
    final restAngle = depth * 0.11;
    final restX = depth * 18.0;
    final restY = depth * 6.0;
    final restScale = 1.0 - depth * 0.028;

    final fanSpread = 1.0 + open * 1.35;
    var angle = restAngle * fanSpread + breath * 0.018 * (depth + 1);
    var dx = restX * fanSpread + breath * 3.5 * depth;
    var dy = restY * fanSpread + open * 8;
    var scale = restScale - open * 0.04;
    var opacity = 1.0;
    var rotY = -depth * 0.06 - open * 0.04;

    if (isFront && shuffling) {
      final rise = gather;
      angle = 0.16 * (1 - rise) + breath * 0.01;
      dx = 28 * (1 - rise);
      dy = 18 * (1 - rise);
      scale = 0.90 + 0.10 * rise;
      opacity = 0.55 + 0.45 * rise;
    } else if (!isFront && shuffling) {
      final fromAngle = restAngle * 2.2;
      final fromX = restX * 2.2;
      final fromY = restY * 2.0 + 10;
      angle = fromAngle + (restAngle - fromAngle) * gather + breath * 0.012;
      dx = fromX + (restX - fromX) * gather + breath * 2;
      dy = fromY + (restY - fromY) * gather;
      scale = restScale - 0.03 * (1 - gather);
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.00135)
        ..translateByDouble(dx, dy, 0, 1)
        ..rotateZ(angle)
        ..rotateY(rotY)
        ..scaleByDouble(scale, scale, 1, 1),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: _PhotoCard(asset: asset, width: cardW, height: cardH),
      ),
    );
  }

  Widget _fly({
    required String asset,
    required double cardW,
    required double cardH,
    required double scatter,
    required double gather,
    required int direction,
    required double dragN,
  }) {
    final dir = direction >= 0 ? -1.0 : 1.0;
    final boost = dragN.abs() > 0.08 ? dragN : dir;
    final fly = Curves.easeInCubic.transform(scatter);
    final fade = gather > 0 ? gather : 0.0;
    final dx = boost * (40 + 200 * fly);
    final dy = -28 * fly + 10 * fade;
    final angle = boost * (0.18 + 0.55 * fly);
    final scale = 1.0 + 0.04 * fly - 0.12 * fade;
    final opacity = (1.0 - fly * 0.15 - fade * 1.1).clamp(0.0, 1.0);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..translateByDouble(dx, dy, 0, 1)
        ..rotateZ(angle)
        ..rotateY(boost * 0.25 * fly)
        ..scaleByDouble(scale, scale, 1, 1),
      child: Opacity(
        opacity: opacity,
        child: _PhotoCard(asset: asset, width: cardW, height: cardH),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.asset,
    required this.width,
    required this.height,
    this.radius = 26,
  });

  final String asset;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
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
        borderRadius: BorderRadius.circular(radius),
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

class _AuthWall extends StatefulWidget {
  const _AuthWall({
    super.key,
    required this.pageController,
    required this.faces,
    required this.authIndex,
    required this.onPageChanged,
    required this.onBack,
    required this.onPhone,
    required this.onQr,
    required this.onLegal,
  });

  final PageController pageController;
  final List<String> faces;
  final int authIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback onPhone;
  final VoidCallback onQr;
  final Future<void> Function(String) onLegal;

  @override
  State<_AuthWall> createState() => _AuthWallState();
}

class _AuthWallState extends State<_AuthWall> with TickerProviderStateMixin {
  AnimationController? _morph;
  AnimationController? _chrome;
  bool _lineReady = false;
  bool _started = false;

  AnimationController get morphCtrl => _morph ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 780),
      );

  AnimationController get chromeCtrl => _chrome ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMorph());
  }

  void _startMorph() {
    if (!mounted || _started) return;
    _started = true;
    // Cards unfold fan → line first, then CTAs fade in.
    morphCtrl.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _lineReady = true);
      chromeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _morph?.dispose();
    _chrome?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = (size.width * 0.065).clamp(24.0, 30.0);
    final cardH = (size.height * 0.34).clamp(240.0, 290.0);
    final cardW = size.width * 0.82;
    final fade = CurvedAnimation(parent: chromeCtrl, curve: Curves.easeOutCubic);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FadeTransition(
                  opacity: fade,
                  child: CircleBackButton(onTap: widget.onBack),
                ),
              ),
            ),
          ),
          SizedBox(height: (size.height * 0.04).clamp(20.0, 36.0)),
          SizedBox(
            height: cardH,
            child: _lineReady
                ? _NewsTickerCards(
                    faces: widget.faces,
                    cardW: cardW,
                    cardH: cardH,
                  )
                : AnimatedBuilder(
                    animation: morphCtrl,
                    builder: (_, _) => _FanToLine(
                      faces: widget.faces,
                      progress: morphCtrl.value,
                      cardH: cardH,
                      cardW: cardW,
                    ),
                  ),
          ),
          const SizedBox(height: 22),
          FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(fade),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
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
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 26),
                    AuthSoftPillButton(
                      label: 'Continue with Phone',
                      leading: Image.asset(
                        'assets/images/png/phone-icon.png',
                        width: 22,
                        height: 22,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.phone, size: 22),
                      ),
                      onPressed: widget.onPhone,
                    ),
                    const SizedBox(height: 12),
                    AuthSoftPillButton(
                      label: 'Continue with QR',
                      leading: Image.asset(
                        'assets/images/png/qr-code-icon.png',
                        width: 22,
                        height: 22,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.qr_code_2, size: 22),
                      ),
                      onPressed: widget.onQr,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          FadeTransition(
            opacity: fade,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Text.rich(
                TextSpan(
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    color: AuthUi.textSecondary,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'By continuing, you agree to the '),
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Slow continuous strip — news-headline style (no snap pagination).
class _NewsTickerCards extends StatefulWidget {
  const _NewsTickerCards({
    required this.faces,
    required this.cardW,
    required this.cardH,
  });

  final List<String> faces;
  final double cardW;
  final double cardH;

  @override
  State<_NewsTickerCards> createState() => _NewsTickerCardsState();
}

class _NewsTickerCardsState extends State<_NewsTickerCards>
    with SingleTickerProviderStateMixin {
  static const _gap = 10.0;
  static const _speed = 28.0; // px/sec

  final ScrollController _scroll = ScrollController();
  AnimationController? _ticker;
  bool _userDragging = false;
  bool _seeded = false;
  double _lead = 0;

  double get _itemW => widget.cardW + _gap;
  double get _loopW =>
      (widget.faces.isEmpty ? 1 : widget.faces.length) * _itemW;

  AnimationController get tickerCtrl {
    if (_ticker != null) return _ticker!;
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_onTick);
    _ticker!.repeat();
    return _ticker!;
  }

  void _onTick() {
    if (!mounted || _userDragging || !_scroll.hasClients) return;
    final next = _scroll.offset + _speed * 0.016;
    _scroll.jumpTo(next);
    _wrapIfNeeded();
  }

  void _wrapIfNeeded() {
    if (!_scroll.hasClients) return;
    final loop = _loopW;
    if (loop <= 0) return;
    var o = _scroll.offset;
    // Stay in middle copy for seamless infinite scroll.
    while (o >= loop * 2) {
      o -= loop;
    }
    while (o < loop * 0.15) {
      o += loop;
    }
    if ((o - _scroll.offset).abs() > 0.5) {
      _scroll.jumpTo(o);
    }
  }

  void _onScrollStart() {
    _userDragging = true;
  }

  void _onScrollEnd() {
    _userDragging = false;
    _wrapIfNeeded();
  }

  @override
  void dispose() {
    _ticker?.removeListener(_onTick);
    _ticker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faces = widget.faces;
    if (faces.isEmpty) return const SizedBox.shrink();

    // Three copies for infinite drag + auto crawl.
    final strip = [...faces, ...faces, ...faces];
    final screenW = MediaQuery.sizeOf(context).width;
    _lead = ((screenW - widget.cardW) / 2).clamp(0.0, screenW);

    // Touch ticker so it starts; seed scroll once.
    tickerCtrl;
    if (!_seeded) {
      _seeded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        // Start on middle copy (left padding already centers first card).
        _scroll.jumpTo(_loopW);
      });
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollStartNotification && n.dragDetails != null) {
          _onScrollStart();
        } else if (n is ScrollEndNotification) {
          _onScrollEnd();
        } else if (n is UserScrollNotification &&
            n.direction != ScrollDirection.idle) {
          _userDragging = true;
        }
        return false;
      },
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(left: _lead, right: _lead),
        itemCount: strip.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(right: _gap),
            child: _PhotoCard(
              asset: strip[i],
              width: widget.cardW,
              height: widget.cardH,
              radius: 28,
            ),
          );
        },
      ),
    );
  }
}

/// Auth-only entrance: stacked fan unfolds into horizontal peek line.
/// Does not touch the first-screen fan widget.
class _FanToLine extends StatelessWidget {
  const _FanToLine({
    required this.faces,
    required this.progress,
    required this.cardH,
    required this.cardW,
  });

  final List<String> faces;
  final double progress;
  final double cardH;
  final double cardW;

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
    final unwind = Curves.easeOutCubic.transform((p / 0.40).clamp(0.0, 1.0));
    final spread = Curves.easeInOutCubic.transform(
      ((p - 0.18) / 0.82).clamp(0.0, 1.0),
    );
    final count = math.min(faces.length, 5);
    // Start size close to feature fan, grow into auth peek width.
    final startW = math.min(w * 0.58, 260.0);
    final width = startW + (cardW - startW) * spread;
    final startH = startW * 1.22;
    final height = startH + (cardH - startH) * spread;
    final gap = width * 0.62;
    final fanBias = -((count - 1) * 18.0 * 0.45) * (1.0 - spread);

    return Center(
      child: SizedBox(
        width: w,
        height: cardH,
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
                  final lineScale = slot == 0 ? 1.0 : 0.96;

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
                    child: _PhotoCard(
                      asset: faces[depth % faces.length],
                      width: width,
                      height: height,
                      radius: 26 + 2 * spread,
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
