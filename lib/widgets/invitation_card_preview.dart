import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/models/invitation.dart';

class InvitationDraft {
  String? invitationId;
  String type;
  String title;
  String message;
  String venue;
  String address;
  DateTime? eventAt;
  String themeColor;
  File? coverImageFile;
  String? coverImageBase64;
  String? existingCoverUrl;

  /// When true, save/update must clear cover on the server.
  bool clearCoverImage;

  InvitationDraft({
    this.invitationId,
    this.type = 'birthday',
    this.title = '',
    this.message = '',
    this.venue = '',
    this.address = '',
    this.eventAt,
    this.themeColor = '#E85D2A',
    this.coverImageFile,
    this.coverImageBase64,
    this.existingCoverUrl,
    this.clearCoverImage = false,
  });

  factory InvitationDraft.fromInvitation(EventInvitation inv) {
    return InvitationDraft(
      invitationId: inv.id,
      type: inv.type,
      title: inv.title,
      message: inv.message,
      venue: inv.venue,
      address: inv.address,
      eventAt: inv.eventAt,
      themeColor: inv.themeColor,
      existingCoverUrl: inv.coverImage.isEmpty ? null : inv.coverImage,
    );
  }
}

Color invitationColorFromHex(String hex) {
  var value = hex.trim().replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return const Color(0xFFE85D2A);
  return Color(int.parse(value, radix: 16));
}

Color _lighten(Color c, [double amount = 0.18]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

Color _darken(Color c, [double amount = 0.18]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// Elegant invitation card — wallpaper fills the full background.
class InvitationCardPreview extends StatelessWidget {
  final String type;
  final String title;
  final String message;
  final String venue;
  final String address;
  final DateTime? eventAt;
  final String themeColor;
  final String? coverImageUrl;
  final File? coverImageFile;
  final String? senderName;
  final String? invitationId;
  final String? guestName;
  final String? guestEmail;
  final bool isPreview;

  const InvitationCardPreview({
    super.key,
    required this.type,
    required this.title,
    this.message = '',
    this.venue = '',
    this.address = '',
    this.eventAt,
    this.themeColor = '#E85D2A',
    this.coverImageUrl,
    this.coverImageFile,
    this.senderName,
    this.invitationId,
    this.guestName,
    this.guestEmail,
    this.isPreview = false,
  });

  factory InvitationCardPreview.fromInvitation(
    EventInvitation inv, {
    String? guestName,
    String? guestEmail,
  }) {
    return InvitationCardPreview(
      type: inv.type,
      title: inv.title,
      message: inv.message,
      venue: inv.venue,
      address: inv.address,
      eventAt: inv.eventAt,
      themeColor: inv.themeColor,
      coverImageUrl: inv.coverImage.isEmpty ? null : inv.coverImage,
      senderName: inv.sender.displayName,
      invitationId: inv.id,
      guestName: guestName,
      guestEmail: guestEmail,
    );
  }

  String? get _inviteCode {
    if (invitationId == null || invitationId!.length < 5) return null;
    return invitationId!.substring(invitationId!.length - 5).toUpperCase();
  }

  String get _qrData {
    if (invitationId != null && invitationId!.isNotEmpty) {
      return 'barqody://invitation/$invitationId';
    }
    return 'barqody://invitation/preview';
  }

  bool get _hasCover =>
      coverImageFile != null ||
      (coverImageUrl != null && coverImageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final primary = invitationColorFromHex(themeColor);
    final light = _lighten(primary, 0.22);
    final dark = _darken(primary, 0.22);
    final mid = _darken(primary, 0.06);

    final hasTitle = title.trim().isNotEmpty;
    final hasVenue = venue.trim().isNotEmpty;
    final hasAddress = address.trim().isNotEmpty;
    final hasGuest = guestName != null && guestName!.trim().isNotEmpty;
    final hasSender = senderName != null && senderName!.trim().isNotEmpty;
    final hasMessage = message.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 420),
        child: Stack(
          children: [
            // Wallpaper / theme background
            Positioned.fill(
              child: _Background(
                hasCover: _hasCover,
                file: coverImageFile,
                url: coverImageUrl,
                colors: [light, mid, dark],
              ),
            ),

            // Soft vignette — keeps photo visible, text readable
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.28, 0.55, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),

            // Subtle theme tint over wallpaper
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      primary.withValues(alpha: 0.12),
                      Colors.transparent,
                      dark.withValues(alpha: 0.25),
                    ],
                  ),
                ),
              ),
            ),

            // Inner decorative frame
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
              child: Column(
                children: [
                  Text(
                    EventInvitation.typeLabel(type).toUpperCase(),
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Ornament(color: Colors.white.withValues(alpha: 0.55)),
                  const SizedBox(height: 14),

                  Text(
                    hasTitle ? title.trim() : 'Your event title',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white.withValues(
                        alpha: hasTitle ? 1 : 0.45,
                      ),
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  if (hasGuest) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Cordially invites',
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guestName!.trim(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (guestEmail != null &&
                        guestEmail!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        guestEmail!.trim(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ] else if (isPreview) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Guest name appears when they open this invite',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  if (eventAt != null) ...[
                    Text(
                      DateFormat(
                        'EEEE',
                      ).format(eventAt!.toLocal()).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMMM d, y').format(eventAt!.toLocal()),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('h:mm a').format(eventAt!.toLocal()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Ornament(color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(height: 14),
                  ],

                  if (hasVenue || hasAddress) ...[
                    if (hasVenue)
                      Text(
                        venue.trim(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    if (hasAddress) ...[
                      if (hasVenue) const SizedBox(height: 4),
                      Text(
                        address.trim(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],

                  if (hasSender) ...[
                    Text(
                      'Hosted by ${senderName!.trim()}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (hasMessage) ...[
                    Text(
                      '“${message.trim()}”',
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const SizedBox(height: 20),
                  _GlassQr(
                    qrData: _qrData,
                    qrColor: dark,
                    inviteCode: _inviteCode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  final bool hasCover;
  final File? file;
  final String? url;
  final List<Color> colors;

  const _Background({
    required this.hasCover,
    required this.file,
    required this.url,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (hasCover) {
      if (file != null) {
        return Image.file(file!, fit: BoxFit.cover);
      }
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _ThemeBackdrop(colors: colors),
      );
    }
    return _ThemeBackdrop(colors: colors);
  }
}

class _ThemeBackdrop extends StatelessWidget {
  final List<Color> colors;

  const _ThemeBackdrop({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
        // Soft light bloom for depth when no wallpaper
        Positioned(
          top: -40,
          right: -30,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: -50,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.12),
            ),
          ),
        ),
      ],
    );
  }
}

class _Ornament extends StatelessWidget {
  final Color color;

  const _Ornament({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 36, height: 1, color: color),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.diamond_outlined, size: 10, color: color),
        ),
        Container(width: 36, height: 1, color: color),
      ],
    );
  }
}

class _GlassQr extends StatelessWidget {
  final String qrData;
  final Color qrColor;
  final String? inviteCode;

  const _GlassQr({
    required this.qrData,
    required this.qrColor,
    this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: qrColor),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: qrColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            inviteCode != null ? 'INV · $inviteCode' : 'Scan to open',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
