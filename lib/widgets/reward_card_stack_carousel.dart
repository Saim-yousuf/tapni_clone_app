import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/loyalty_card_design_renderer.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

/// Display model for swipe stack (customer enrollments or business programs).
class RewardCardStackItem {
  final RewardProgram program;
  final int filledStamps;
  final bool showCompletedBadge;
  final String? footerHint;

  const RewardCardStackItem({
    required this.program,
    this.filledStamps = 0,
    this.showCompletedBadge = false,
    this.footerHint,
  });

  factory RewardCardStackItem.fromEnrollment(RewardEnrollment e) {
    final program = e.program ??
        RewardProgram(
          id: e.programId,
          title: 'Reward',
          stamps: 10,
          theme: RewardTheme(),
        );
    return RewardCardStackItem(
      program: program,
      filledStamps: e.stamps,
      showCompletedBadge: e.isCompleted,
    );
  }

  factory RewardCardStackItem.fromProgram(RewardProgram p) {
    return RewardCardStackItem(
      program: p,
      filledStamps: 0,
      footerHint: p.isActive ? null : 'inactive',
    );
  }
}

/// Swipeable stack of reward cards (same interaction as QR business-card sheet).
class RewardCardStackCarousel extends StatefulWidget {
  final List<RewardCardStackItem> items;
  final int initialIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onCardTap;
  final VoidCallback? onSwiped;
  final bool showPageIndicator;

  const RewardCardStackCarousel({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.onPageChanged,
    this.onCardTap,
    this.onSwiped,
    this.showPageIndicator = true,
  });

  @override
  State<RewardCardStackCarousel> createState() =>
      _RewardCardStackCarouselState();
}

class _RewardCardStackCarouselState extends State<RewardCardStackCarousel>
    with SingleTickerProviderStateMixin {
  static const _cardWidth = 340.0;
  static const _maxStackHeight = 480.0;
  static const _minStackHeight = 300.0;
  static const _swipeThreshold = 72.0;
  static const _velocityThreshold = 700.0;
  static const _maxVisibleDepth = 3;
  static const _peekInset = 20.0;

  late AnimationController _animController;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _rotationAnim;

  late List<int> _stackOrder;
  Offset _dragOffset = Offset.zero;
  bool _isAnimating = false;
  bool _isSwipeAway = false;
  double _stackHeight = _maxStackHeight;

  int get _topCardIndex => _stackOrder.isEmpty ? 0 : _stackOrder.first;

  @override
  void initState() {
    super.initState();
    _stackOrder = _buildStackOrder(widget.items.length, widget.initialIndex);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _offsetAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _rotationAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.addListener(() {
      if (mounted) setState(() {});
    });
    _animController.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      if (_isSwipeAway) _onSwipeAwayComplete();
    });
  }

  List<int> _buildStackOrder(int count, int topIndex) {
    if (count == 0) return [];
    final start = topIndex.clamp(0, count - 1);
    return List.generate(count, (i) => (start + i) % count);
  }

  @override
  void didUpdateWidget(covariant RewardCardStackCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cards = widget.items;
    if (cards.isEmpty) {
      _stackOrder = [];
      return;
    }
    if (cards.length != oldWidget.items.length) {
      final preservedTop = _topCardIndex.clamp(0, cards.length - 1);
      setState(() {
        _stackOrder = _buildStackOrder(cards.length, preservedTop);
      });
      return;
    }
    if (widget.initialIndex != oldWidget.initialIndex &&
        widget.initialIndex >= 0 &&
        widget.initialIndex < cards.length &&
        widget.initialIndex != _topCardIndex) {
      setState(() {
        _stackOrder = _buildStackOrder(cards.length, widget.initialIndex);
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _notifyTopChanged() => widget.onPageChanged(_topCardIndex);

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating || widget.items.length <= 1) return;
    setState(() => _dragOffset += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating || widget.items.length <= 1) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final dx = _dragOffset.dx;
    final shouldSwipe =
        dx.abs() > _swipeThreshold || velocity.abs() > _velocityThreshold;
    if (shouldSwipe) {
      final direction = dx != 0 ? dx.sign.toDouble() : velocity.sign.toDouble();
      _runSwipeAwayAnimation(direction);
    } else {
      _runSnapBackAnimation();
    }
  }

  void _runSwipeAwayAnimation(double direction) {
    if (_isAnimating) return;
    _isAnimating = true;
    _isSwipeAway = true;
    final startOffset = _dragOffset;
    final startRotation = _dragRotation(startOffset.dx);
    final endOffset = Offset(direction * 420, _dragOffset.dy + 28);
    final endRotation = direction * 0.28;
    _offsetAnim = Tween<Offset>(begin: startOffset, end: endOffset).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInCubic),
    );
    _rotationAnim = Tween<double>(begin: startRotation, end: endRotation)
        .animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInCubic),
    );
    _animController.forward(from: 0);
  }

  void _runSnapBackAnimation() {
    if (_isAnimating) return;
    _isAnimating = true;
    _isSwipeAway = false;
    final startOffset = _dragOffset;
    final startRotation = _dragRotation(startOffset.dx);
    _offsetAnim = Tween<Offset>(begin: startOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _rotationAnim = Tween<double>(begin: startRotation, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward(from: 0).then((_) {
      if (!mounted) return;
      _animController.reset();
      setState(() {
        _dragOffset = Offset.zero;
        _isAnimating = false;
      });
    });
  }

  void _onSwipeAwayComplete() {
    _animController.reset();
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_stackOrder.length > 1) {
        final top = _stackOrder.removeAt(0);
        _stackOrder.add(top);
      }
      _dragOffset = Offset.zero;
      _isAnimating = false;
      _isSwipeAway = false;
    });
    _notifyTopChanged();
    widget.onSwiped?.call();
  }

  double _dragRotation(double dx) => (dx / _cardWidth).clamp(-0.28, 0.28);

  Offset _cardOffsetForDepth(int depth) {
    if (depth == 0 && _isAnimating) return _offsetAnim.value;
    if (depth == 0) return _dragOffset;
    final yPeek = depth * 12.0;
    final parallax = _dragOffset.dx * 0.1 * depth;
    if (widget.items.length == 2 && depth == 1) {
      return Offset(parallax, yPeek);
    }
    final side = depth.isOdd ? -1.0 : 1.0;
    final xPeek = side * (12.0 + (depth - 1) * 6.0);
    return Offset(xPeek + parallax, yPeek);
  }

  double _cardRotationForDepth(int depth) {
    if (depth == 0 && _isAnimating) return _rotationAnim.value;
    if (depth == 0) return _dragRotation(_dragOffset.dx);
    if (widget.items.length == 2 && depth == 1) return 0;
    final side = depth.isOdd ? -1.0 : 1.0;
    return side * 0.045;
  }

  double _cardScaleForDepth(int depth) {
    if (depth == 0) return widget.items.length > 1 ? 0.96 : 1.0;
    if (widget.items.length == 2 && depth == 1) return 1.0;
    return 0.96 - depth * 0.035;
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.items;
    if (cards.isEmpty) return const SizedBox.shrink();

    final topIndex = _topCardIndex;
    final visibleDepth = math.min(_stackOrder.length, _maxVisibleDepth);
    final top = cards[topIndex];
    final title = top.program.title;
    final business = top.program.displayBusinessName;
    final status = !top.program.isActive
        ? context.l10n.inactive
        : (top.showCompletedBadge ? context.l10n.completed : null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = math.min(
          _cardWidth,
          constraints.maxWidth - _peekInset * 2,
        );
        final screenH = MediaQuery.sizeOf(context).height;
        _stackHeight = (screenH * 0.42)
            .clamp(_minStackHeight, _maxStackHeight)
            .toDouble();
        _stackHeight = math.min(_stackHeight, cardWidth * 1.42);

        return Column(
          children: [
            SizedBox(
              height: _stackHeight,
              width: constraints.maxWidth,
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  for (var depth = visibleDepth - 1; depth >= 0; depth--)
                    _buildStackLayer(
                      cards: cards,
                      cardIndex: _stackOrder[depth],
                      depth: depth,
                      isTop: depth == 0,
                      cardWidth: cardWidth,
                    ),
                ],
              ),
            ),
            if (widget.showPageIndicator) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Text(
                    '${topIndex + 1} of ${cards.length}',
                    textAlign: TextAlign.center,
                    style: WaUi.caption,
                  ),
                ),
              ),
              if (title.isNotEmpty ||
                  (business.isNotEmpty &&
                      business != 'Business' &&
                      business != title) ||
                  status != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text(
                      [
                        if (title.isNotEmpty) title,
                        if (business.isNotEmpty &&
                            business != 'Business' &&
                            business != title)
                          business,
                        if (status != null) status,
                      ].join(' · '),
                      textAlign: TextAlign.center,
                      style: WaUi.caption,
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildStackLayer({
    required List<RewardCardStackItem> cards,
    required int cardIndex,
    required int depth,
    required bool isTop,
    required double cardWidth,
  }) {
    final offset = _cardOffsetForDepth(depth);
    final rotation = _cardRotationForDepth(depth);
    final scale = _cardScaleForDepth(depth);

    Widget card = SizedBox(
      width: cardWidth,
      height: _stackHeight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: cardWidth,
          child: _RewardCardFace(
            key: ValueKey(cards[cardIndex].program.id),
            item: cards[cardIndex],
            width: cardWidth,
            isActive: isTop,
            onTap: isTop && widget.onCardTap != null
                ? () => widget.onCardTap!(cardIndex)
                : null,
          ),
        ),
      ),
    );

    card = Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          // Avoid Opacity around image-backed cards — causes black frames while swiping.
          child: card,
        ),
      ),
    );

    if (!isTop) {
      return Align(alignment: Alignment.topCenter, child: card);
    }

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Align(alignment: Alignment.topCenter, child: card),
      ),
    );
  }
}

class _RewardCardFace extends StatelessWidget {
  final RewardCardStackItem item;
  final double width;
  final bool isActive;
  final VoidCallback? onTap;

  const _RewardCardFace({
    super.key,
    required this.item,
    required this.width,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final program = item.program;
    final theme = program.theme;
    final total = program.stamps;
    final current = item.filledStamps;

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isActive ? 0.14 : 0.08),
          blurRadius: isActive ? 18 : 10,
          offset: Offset(0, isActive ? 8 : 4),
        ),
      ],
    );

    Widget body;
    if (program.hasDesign) {
      // Design already shows stamp progress on the card — don't duplicate below.
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoyaltyCardDesignRenderer(
            design: program.design!,
            filledStamps: current,
            borderRadius: 22,
            shadows: const [],
          ),
          if (item.showCompletedBadge) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.completed,
              style: WaUi.caption.copyWith(color: WaUi.accent),
            ),
          ] else if (!program.isActive) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.inactive,
              style: WaUi.caption.copyWith(color: Colors.red),
            ),
          ],
        ],
      );
    } else {
      body = Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (program.logo.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      program.logo,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                if (program.logo.isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    program.label.isNotEmpty
                        ? program.label
                        : program.displayBusinessName,
                    style: TextStyle(
                      color: theme.cardTextColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
                if (item.showCompletedBadge)
                  Icon(Icons.check_circle, color: theme.cardTextColor, size: 20)
                else if (!program.isActive)
                  Text(
                    context.l10n.inactive,
                    style: TextStyle(
                      color: theme.cardTextColor.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              program.title,
              style: TextStyle(
                color: theme.cardTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(total.clamp(1, 16), (i) {
                return RewardStampSlot(
                  filled: i < current,
                  theme: theme,
                  stampIconUrl: program.stampIcon,
                  unstampIconUrl: program.unstampIcon,
                  size: 36,
                );
              }),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.stampsRequiredCount(total),
              style: TextStyle(
                color: theme.cardTextColor.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(decoration: decoration, child: body),
    );
  }
}
