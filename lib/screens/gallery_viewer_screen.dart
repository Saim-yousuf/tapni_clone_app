import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/gallery_item.dart';

/// Full-screen gallery: left/right swipe between photos, pinch-to-zoom,
/// close (X) in the top corner, delete for owner.
class GalleryViewerScreen extends StatefulWidget {
  final List<GalleryItem> items;
  final int initialIndex;
  final bool isOwner;
  final Future<bool> Function(GalleryItem item)? onDelete;

  const GalleryViewerScreen({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.isOwner = false,
    this.onDelete,
  });

  @override
  State<GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<GalleryViewerScreen> {
  late PageController _pageController;
  late List<GalleryItem> _items;
  late int _index;
  bool _busy = false;
  bool _showChrome = true;
  /// When a photo is zoomed, block horizontal page swipes.
  bool _pageScrollEnabled = true;

  @override
  void initState() {
    super.initState();
    _items = List<GalleryItem>.from(widget.items);
    _index = widget.initialIndex.clamp(
      0,
      _items.isEmpty ? 0 : _items.length - 1,
    );
    _pageController = PageController(initialPage: _index);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _deleteCurrent() async {
    if (_busy || widget.onDelete == null || _items.isEmpty) return;
    final item = _items[_index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deletePhoto),
        content: Text(context.l10n.deletePhotoConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.deletePhoto),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final ok = await widget.onDelete!(item);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotDeletePhoto)),
      );
      return;
    }

    setState(() {
      _items.removeAt(_index);
      if (_items.isEmpty) {
        _index = 0;
      } else if (_index >= _items.length) {
        _index = _items.length - 1;
      }
    });

    if (_items.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(_index);
    });
  }

  void _toggleChrome() {
    setState(() => _showChrome = !_showChrome);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    final item = _items[_index];
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            allowImplicitScrolling: true,
            physics: _pageScrollEnabled
                ? const AlwaysScrollableScrollPhysics(
                    parent: PageScrollPhysics(),
                  )
                : const NeverScrollableScrollPhysics(),
            onPageChanged: (value) {
              setState(() {
                _index = value;
                _pageScrollEnabled = true;
              });
            },
            itemBuilder: (context, i) {
              return _ZoomablePhoto(
                key: ValueKey(_items[i].id),
                item: _items[i],
                onTap: _toggleChrome,
                onScaleChanged: (scale) {
                  final allowSwipe = scale <= 1.05;
                  if (allowSwipe != _pageScrollEnabled) {
                    setState(() => _pageScrollEnabled = allowSwipe);
                  }
                },
              );
            },
          ),

          // Close (X) — always top-right corner
          Positioned(
            top: topPad + 4,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.35),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                color: Colors.white,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom caption + delete (owner)
          AnimatedOpacity(
            opacity: _showChrome ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !_showChrome,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 16 + bottomPad),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Color(0x00000000)],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.caption.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            item.caption,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (widget.isOwner && widget.onDelete != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _busy ? null : _deleteCurrent,
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red.shade300,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.l10n.deletePhoto,
                                    style: TextStyle(
                                      color: Colors.red.shade300,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinch-to-zoom photo that does not steal 1-finger horizontal swipes
/// from [PageView] when at 1x scale.
class _ZoomablePhoto extends StatefulWidget {
  final GalleryItem item;
  final VoidCallback onTap;
  final ValueChanged<double> onScaleChanged;

  const _ZoomablePhoto({
    super.key,
    required this.item,
    required this.onTap,
    required this.onScaleChanged,
  });

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with AutomaticKeepAliveClientMixin {
  double _scale = 1;
  Offset _offset = Offset.zero;
  final Map<int, Offset> _pointers = {};
  double? _pinchStartDistance;
  double _pinchStartScale = 1;
  Offset? _panStart;
  Offset _panStartOffset = Offset.zero;

  @override
  bool get wantKeepAlive => true;

  double? _distanceBetweenPointers() {
    if (_pointers.length < 2) return null;
    final pts = _pointers.values.toList();
    return (pts[0] - pts[1]).distance;
  }

  void _resetIfNearOne() {
    if (_scale < 1.05) {
      setState(() {
        _scale = 1;
        _offset = Offset.zero;
      });
      widget.onScaleChanged(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final zoomed = _scale > 1.05;

    // Listener (not GestureDetector scale) so 1-finger horizontal swipes
    // reach PageView. Pinch (2 fingers) and pan-when-zoomed handled here.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        _pointers[e.pointer] = e.position;
        if (_pointers.length == 2) {
          _pinchStartDistance = _distanceBetweenPointers();
          _pinchStartScale = _scale;
        } else if (_pointers.length == 1 && zoomed) {
          _panStart = e.position;
          _panStartOffset = _offset;
        }
      },
      onPointerMove: (e) {
        if (!_pointers.containsKey(e.pointer)) return;
        _pointers[e.pointer] = e.position;

        if (_pointers.length >= 2 && _pinchStartDistance != null) {
          final dist = _distanceBetweenPointers();
          if (dist == null || _pinchStartDistance! <= 0) return;
          final next =
              (_pinchStartScale * (dist / _pinchStartDistance!)).clamp(1.0, 4.0);
          setState(() => _scale = next);
          widget.onScaleChanged(next);
          return;
        }

        if (zoomed && _pointers.length == 1 && _panStart != null) {
          final delta = e.position - _panStart!;
          setState(() => _offset = _panStartOffset + delta);
        }
      },
      onPointerUp: (e) {
        _pointers.remove(e.pointer);
        if (_pointers.length < 2) {
          _pinchStartDistance = null;
        }
        if (_pointers.isEmpty) {
          _panStart = null;
          _resetIfNearOne();
        } else if (_pointers.length == 1 && _scale > 1.05) {
          _panStart = _pointers.values.first;
          _panStartOffset = _offset;
        }
      },
      onPointerCancel: (e) {
        _pointers.remove(e.pointer);
        if (_pointers.isEmpty) {
          _panStart = null;
          _pinchStartDistance = null;
          _resetIfNearOne();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(_offset.dx, _offset.dy)
            ..scale(_scale),
          filterQuality: FilterQuality.medium,
          child: Center(
            child: Hero(
              tag: 'gallery-${widget.item.id}',
              child: Image.network(
                widget.item.url,
                fit: BoxFit.contain,
                width: MediaQuery.sizeOf(context).width,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
