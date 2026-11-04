import 'package:flutter/material.dart';
import 'package:tapni_app/utils/preference_helper.dart';

/// One-shot entrance for the empty [BarqodyProfilePhoto] on first profile visit.
///
/// Fade + scale in, then a short float — only while [enabled] (no real photo).
/// Marked per [accountId] so it does not replay on every cold start.
class BarqodyAvatarWelcome extends StatefulWidget {
  const BarqodyAvatarWelcome({
    super.key,
    required this.child,
    required this.enabled,
    this.accountId,
  });

  final Widget child;
  final bool enabled;
  final String? accountId;

  @override
  State<BarqodyAvatarWelcome> createState() => _BarqodyAvatarWelcomeState();
}

class _BarqodyAvatarWelcomeState extends State<BarqodyAvatarWelcome>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _float;

  bool _played = false;

  static String _prefKey(String accountId) =>
      '${SharedPrefHelper.utils.profileAvatarWelcomeSeenPrefix}$accountId';

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _scale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0, 0.55, curve: Curves.easeOut),
      ),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _float = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Avoid a blank first frame when welcome already played.
    if (!widget.enabled || !_shouldPlayWelcome()) {
      _enterCtrl.value = 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeStart();
    });
  }

  bool _shouldPlayWelcome() {
    final pending = SharedPrefHelper.getBool(
      SharedPrefHelper.utils.profileAvatarWelcomePending,
    );
    if (pending) return true;
    final id = widget.accountId?.trim() ?? '';
    if (id.isEmpty) return false;
    return !SharedPrefHelper.getBool(_prefKey(id));
  }

  @override
  void didUpdateWidget(covariant BarqodyAvatarWelcome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.accountId != widget.accountId) {
      _maybeStart();
    }
  }

  Future<void> _maybeStart() async {
    if (!widget.enabled) {
      _enterCtrl.value = 1;
      _floatCtrl.stop();
      _floatCtrl.value = 0;
      return;
    }

    final id = widget.accountId?.trim() ?? '';
    final pending = SharedPrefHelper.getBool(
      SharedPrefHelper.utils.profileAvatarWelcomePending,
    );
    final alreadySeen =
        id.isNotEmpty && SharedPrefHelper.getBool(_prefKey(id));

    // Pending (just finished signup) always wins so welcome is visible once.
    if (!pending && alreadySeen) {
      _enterCtrl.value = 1;
      return;
    }

    if (_played) return;
    _played = true;

    // Start slightly invisible so first frame doesn't flash full size.
    _enterCtrl.value = 0;
    await _enterCtrl.forward();
    if (!mounted) return;

    await SharedPrefHelper.putBool(
      SharedPrefHelper.utils.profileAvatarWelcomePending,
      false,
    );
    if (id.isNotEmpty) {
      await SharedPrefHelper.putBool(_prefKey(id), true);
    }

    if (!mounted || !widget.enabled) return;
    _floatCtrl.repeat(reverse: true);
    await Future<void>.delayed(const Duration(milliseconds: 4800));
    if (!mounted || !widget.enabled) return;
    _floatCtrl.stop();
    await _floatCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: Listenable.merge([_enterCtrl, _floatCtrl]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _float.value),
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
