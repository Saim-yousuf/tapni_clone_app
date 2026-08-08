import 'package:flutter/material.dart';
import 'package:tapni_app/models/business_card_design.dart';
import 'package:tapni_app/models/invitation_design.dart';
import 'package:tapni_app/widgets/invitation_design_renderer.dart';

  /// Renders a [BusinessCardDesign] with full-bleed background image support.
class BusinessCardDesignRenderer extends StatelessWidget {
  final BusinessCardDesign design;
  final bool interactive;
  final String? selectedLayerId;
  final void Function(String layerId)? onLayerTap;
  final void Function(String layerId, Offset deltaNorm)? onLayerDrag;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final double borderRadius;

  const BusinessCardDesignRenderer({
    super.key,
    required this.design,
    this.interactive = false,
    this.selectedLayerId,
    this.onLayerTap,
    this.onLayerDrag,
    this.border,
    this.shadows,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    // When a background photo is set, drop large opaque fill shapes so the
    // image covers the whole card (not just the sides around a white panel).
    final invitation = design.toInvitationDesign();
    if (design.backgroundImage.isNotEmpty) {
      invitation.layers = invitation.layers.map((l) {
        if (l.type == DesignLayerType.shape &&
            l.width >= 0.7 &&
            l.height >= 0.7 &&
            l.opacity > 0.15 &&
            l.borderWidth <= 0) {
          return l.copyWith(opacity: 0, visible: false);
        }
        if (l.type == DesignLayerType.shape &&
            l.width >= 0.7 &&
            l.height >= 0.7 &&
            l.opacity > 0.15 &&
            l.borderWidth > 0) {
          // Keep frame border only — transparent fill.
          return l.copyWith(opacity: 0);
        }
        return l;
      }).toList();
    }

    return InvitationDesignRenderer(
      design: invitation,
      interactive: interactive,
      selectedLayerId: selectedLayerId,
      onLayerTap: onLayerTap,
      onLayerDrag: onLayerDrag,
      border: border,
      shadows: shadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
    );
  }
}
