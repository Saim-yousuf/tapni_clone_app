import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tapni_app/models/invitation_design.dart';
import 'package:tapni_app/models/user_custom_card.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/business_card_design_renderer.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';
import 'package:tapni_app/widgets/template_business_card_preview.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class QrCardStackCarousel extends StatefulWidget {
  final List<CardDisplayData> cards;
  final int initialIndex;
  final GlobalKey cardKey;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onEditCard;
  final VoidCallback? onDeleteCard;
  final VoidCallback onAddCard;

  const QrCardStackCarousel({
    super.key,
    required this.cards,
    required this.initialIndex,
    required this.cardKey,
    required this.onPageChanged,
    required this.onAddCard,
    this.onEditCard,
    this.onDeleteCard,
  });

  @override
  State<QrCardStackCarousel> createState() => _QrCardStackCarouselState();
}

class _QrCardStackCarouselState extends State<QrCardStackCarousel>
    with SingleTickerProviderStateMixin {
  static const _cardWidth = 340.0;
  static const _stackHeight = 480.0;
  static const _swipeThreshold = 72.0;
  static const _velocityThreshold = 700.0;
  static const _maxVisibleDepth = 3;
  static const _peekInset = 20.0;

  late AnimationController _animController;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _rotationAnim;

  /// Front card first — swiped card moves to the end.
  late List<int> _stackOrder;
  Offset _dragOffset = Offset.zero;
  bool _isAnimating = false;
  bool _isSwipeAway = false;

  int get _topCardIndex => _stackOrder.isEmpty ? 0 : _stackOrder.first;

  @override
  void initState() {
    super.initState();
    _stackOrder = _buildStackOrder(widget.cards.length, widget.initialIndex);
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
      if (_isSwipeAway) {
        _onSwipeAwayComplete();
      }
    });
  }

  List<int> _buildStackOrder(int count, int topIndex) {
    if (count == 0) return [];
    final start = topIndex.clamp(0, count - 1);
    return List.generate(count, (i) => (start + i) % count);
  }

  @override
  void didUpdateWidget(covariant QrCardStackCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cards = widget.cards;
    if (cards.isEmpty) {
      _stackOrder = [];
      return;
    }

    if (cards.length != oldWidget.cards.length) {
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

  void _notifyTopChanged() {
    widget.onPageChanged(_topCardIndex);
  }

  void _bringNextToFront() {
    if (_stackOrder.length <= 1 || _isAnimating) return;
    _runSwipeAwayAnimation(_dragOffset.dx >= 0 ? 1 : -1);
  }

  void _bringPreviousToFront() {
    if (_stackOrder.length <= 1 || _isAnimating) return;
    setState(() {
      final back = _stackOrder.removeLast();
      _stackOrder.insert(0, back);
    });
    _notifyTopChanged();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating || widget.cards.length <= 1) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating || widget.cards.length <= 1) return;

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
  }

  double _dragRotation(double dx) => (dx / _cardWidth).clamp(-0.28, 0.28);

  Offset _cardOffsetForDepth(int depth) {
    if (depth == 0 && _isAnimating) {
      return _offsetAnim.value;
    }
    if (depth == 0) return _dragOffset;

    final yPeek = depth * 12.0;
    final parallax = _dragOffset.dx * 0.1 * depth;

    // One card behind: keep centered but wider than front so both edges peek.
    if (widget.cards.length == 2 && depth == 1) {
      return Offset(parallax, yPeek);
    }

    // Multiple back cards: fan out left/right.
    final side = depth.isOdd ? -1.0 : 1.0;
    final xPeek = side * (12.0 + (depth - 1) * 6.0);

    return Offset(xPeek + parallax, yPeek);
  }

  double _cardRotationForDepth(int depth) {
    if (depth == 0 && _isAnimating) {
      return _rotationAnim.value;
    }
    if (depth == 0) return _dragRotation(_dragOffset.dx);
    if (widget.cards.length == 2 && depth == 1) return 0;

    final side = depth.isOdd ? -1.0 : 1.0;
    return side * 0.045;
  }

  double _cardScaleForDepth(int depth) {
    if (depth == 0) {
      return widget.cards.length > 1 ? 0.96 : 1.0;
    }
    if (widget.cards.length == 2 && depth == 1) {
      return 1.0;
    }
    return 0.96 - depth * 0.035;
  }

  double _cardOpacityForDepth(int depth) => depth == 0 ? 1.0 : 1 - depth * 0.08;

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (cards.isEmpty) {
      return _AddOnlyCard(onAdd: widget.onAddCard);
    }

    final topIndex = _topCardIndex;
    final visibleDepth = math.min(_stackOrder.length, _maxVisibleDepth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = math.min(
          _cardWidth,
          constraints.maxWidth - _peekInset * 2,
        );

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
            SizedBox(height: 8),
            Text(context.l10n.swipeToBrowseCards, style: WaUi.caption),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconCircleButton(
                  icon: Icons.chevron_left,
                  tooltip: context.l10n.previousCard,
                  onTap: cards.length > 1
                      ? () => _bringPreviousToFront()
                      : () {},
                  enabled: cards.length > 1 && !_isAnimating,
                ),
                SizedBox(width: 6),
                ...List.generate(cards.length, (i) {
                  final active = i == topIndex;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? WaUi.accent : WaUi.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
                SizedBox(width: 6),
                _IconCircleButton(
                  icon: Icons.chevron_right,
                  tooltip: context.l10n.nextCard,
                  onTap: cards.length > 1 ? () => _bringNextToFront() : () {},
                  enabled: cards.length > 1 && !_isAnimating,
                ),
                SizedBox(width: 8),
                _IconCircleButton(
                  icon: Icons.add,
                  tooltip: context.l10n.newCard2,
                  onTap: widget.onAddCard,
                ),
                if (widget.onEditCard != null &&
                    !cards[topIndex].isPrimary) ...[
                  SizedBox(width: 8),
                  _IconCircleButton(
                    icon: Icons.edit_outlined,
                    tooltip: context.l10n.editCard,
                    onTap: widget.onEditCard!,
                  ),
                ],
                // Last remaining card cannot be deleted.
                if (widget.onDeleteCard != null &&
                    cards.length > 1 &&
                    !cards[topIndex].isPrimary) ...[
                  SizedBox(width: 8),
                  _IconCircleButton(
                    icon: Icons.delete_outline,
                    tooltip: context.l10n.deleteCard,
                    onTap: widget.onDeleteCard!,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${topIndex + 1} of ${cards.length} · ${cards[topIndex].title}',
              style: WaUi.caption,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStackLayer({
    required List<CardDisplayData> cards,
    required int cardIndex,
    required int depth,
    required bool isTop,
    required double cardWidth,
  }) {
    final offset = _cardOffsetForDepth(depth);
    final rotation = _cardRotationForDepth(depth);
    final scale = _cardScaleForDepth(depth);
    final opacity = _cardOpacityForDepth(depth);

    Widget card = SizedBox(
      width: cardWidth,
      height: _stackHeight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: cardWidth,
          child: _buildCard(
            cards[cardIndex],
            cardWidth: cardWidth,
            isActive: isTop,
            showExportKey: isTop,
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
          child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: card),
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

  Widget _buildCard(
    CardDisplayData card, {
    required double cardWidth,
    required bool isActive,
    required bool showExportKey,
  }) {
    final initial = card.name.isNotEmpty ? card.name[0].toUpperCase() : '?';

    final Widget preview;
    final customDesign = card.printDesign;
    if (customDesign != null && customDesign.hasLayers) {
      // Warm cache so swipe frames don't decode base64 mid-animation.
      final bg = customDesign.backgroundImage;
      if (bg.isNotEmpty) cachedBytesForDesignImageSrc(bg);

      var design = customDesign;
      final needsQrSync = design.layers.any(
        (l) =>
            (l.type == DesignLayerType.qr || l.fieldKey == 'qr') &&
            l.qrData != card.profileUrl,
      );
      if (needsQrSync) {
        design = design.copy();
        design.setQrData(card.profileUrl);
      }
      preview = SizedBox(
        width: cardWidth,
        child: BusinessCardDesignRenderer(
          key: ValueKey('design_${card.id}'),
          design: design,
          interactive: false,
          borderRadius: 24,
        ),
      );
    } else {
      preview = TemplateBusinessCardPreview(
        key: ValueKey('template_${card.id}'),
        template: card.template,
        name: card.name,
        profileUrl: card.profileUrl,
        userInitial: initial,
        profilePhotoUrl: card.profilePhotoUrl,
        coverPhotoUrl: card.coverPhotoUrl,
        subtitle: card.subtitle,
        bio: card.bio,
        width: cardWidth,
      );
    }

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

    if (showExportKey) {
      return RepaintBoundary(
        key: widget.cardKey,
        child: DecoratedBox(decoration: decoration, child: preview),
      );
    }

    return DecoratedBox(decoration: decoration, child: preview);
  }
}

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;

  const _IconCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WaUi.scaffold,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: enabled ? WaUi.primaryText : WaUi.divider,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddOnlyCard extends StatelessWidget {
  final VoidCallback onAdd;

  _AddOnlyCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: WaUi.scaffold,
          borderRadius: BorderRadius.circular(WaUi.radiusLg),
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(WaUi.radiusLg),
            child: Container(
              width: double.infinity,
              height: 320,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WaUi.chipBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: WaUi.accent, size: 32),
                  ),
                  SizedBox(height: 14),
                  Text(context.l10n.createYourFirstCard, style: WaUi.title),
                  SizedBox(height: 4),
                  Text(
                    context.l10n.shareDifferentLinksOnEachCard,
                    style: WaUi.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
