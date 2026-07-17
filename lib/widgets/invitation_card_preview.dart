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
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

Color _darken(Color c, [double amount = 0.12]) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

/// Polished invitation card — address text shows on card when set.
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
    final light = _lighten(primary);
    final dark = _darken(primary);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [light, dark],
    );

    final hasTitle = title.trim().isNotEmpty;
    final hasVenue = venue.trim().isNotEmpty;
    final hasAddress = address.trim().isNotEmpty;
    final hasGuest = guestName != null && guestName!.trim().isNotEmpty;
    final hasSender = senderName != null && senderName!.trim().isNotEmpty;
    final hasMessage = message.trim().isNotEmpty;

    final titleStyle = GoogleFonts.playfairDisplay(
      color: Colors.white,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover / header
          Stack(
            children: [
              if (_hasCover)
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: coverImageFile != null
                      ? Image.file(coverImageFile!, fit: BoxFit.cover)
                      : Image.network(
                          coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: primary),
                        ),
                )
              else
                Container(
                  height: 130,
                  decoration: BoxDecoration(gradient: gradient),
                ),
              if (_hasCover)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        EventInvitation.typeLabel(type).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasTitle ? title.trim() : 'Your event title',
                      style: titleStyle.copyWith(
                        color: Colors.white.withValues(alpha: hasTitle ? 1 : 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_inviteCode != null) ...[
                  Text(
                    'INV · $_inviteCode',
                    style: TextStyle(
                      color: dark.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Venue + Address block (address text always visible when set)
                if (hasVenue || hasAddress) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.place_rounded, size: 18, color: dark),
                            const SizedBox(width: 6),
                            Text(
                              'Location',
                              style: TextStyle(
                                color: dark,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (hasVenue) ...[
                          const SizedBox(height: 8),
                          Text(
                            venue.trim(),
                            style: TextStyle(
                              color: dark,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (hasAddress) ...[
                          const SizedBox(height: 6),
                          Text(
                            address.trim(),
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.72),
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (eventAt != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _chip(
                          icon: Icons.calendar_month_rounded,
                          label: DateFormat('EEE, MMM d').format(eventAt!.toLocal()),
                          color: dark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _chip(
                          icon: Icons.access_time_rounded,
                          label: DateFormat('h:mm a').format(eventAt!.toLocal()),
                          color: dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                if (hasSender)
                  _chip(
                    icon: Icons.person_rounded,
                    label: 'Host · ${senderName!.trim()}',
                    color: dark,
                    fullWidth: true,
                  ),

                if (hasGuest) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dear',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          guestName!.trim(),
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (guestEmail != null &&
                            guestEmail!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            guestEmail!.trim(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (isPreview) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Guest name appears automatically when they open this invite',
                    style: TextStyle(
                      color: dark.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 132,
                    height: 132,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: dark,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: dark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (hasMessage)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(gradient: gradient),
              child: Text(
                message.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
    bool fullWidth = false,
  }) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: child) : child;
  }
}
