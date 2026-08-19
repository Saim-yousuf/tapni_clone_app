import 'package:flutter/material.dart';
import 'package:tapni_app/models/card_template.dart';
import 'package:tapni_app/widgets/branded_qr_image.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
/// Employee card — business template colors, employee profile QR and details.
class EmployeeCompanyCardPreview extends StatelessWidget {
  final CardTemplate template;
  final String employeeName;
  final String employeeId;
  final String employeeInitial;
  final String profileUrl;
  final String? employeePhotoUrl;
  final double width;
  final bool compact;

  const EmployeeCompanyCardPreview({
    super.key,
    required this.template,
    required this.employeeName,
    required this.employeeId,
    required this.employeeInitial,
    required this.profileUrl,
    this.employeePhotoUrl,
    this.width = 340,
    this.compact = false,
  });

  double get _avatarSize => compact ? 56 : 80;
  double get _qrSize => compact ? 100 : 132;
  double get _nameFontSize => compact ? 20 : 24;
  double get _idFontSize => compact ? 13 : 15;
  EdgeInsets get _contentPadding => compact
      ? const EdgeInsets.fromLTRB(14, 14, 14, 16)
      : const EdgeInsets.fromLTRB(20, 20, 20, 22);

  @override
  Widget build(BuildContext context) {
    final accentPanel = template.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: template.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: template.textColor.withValues(alpha: 0.35),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 6,
            color: template.brandingColor.withValues(alpha: 0.85),
          ),
          Padding(
            padding: _contentPadding,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 12,
                      vertical: compact ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentPanel,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: template.textColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: compact ? 14 : 16,
                          color: template.textColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          context.l10n.employeeCARD,
                          style: TextStyle(
                            color: template.textColor,
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 20),
                  _avatar(employeePhotoUrl, employeeInitial, size: _avatarSize),
                  SizedBox(height: compact ? 10 : 16),
                  Text(
                    employeeName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: template.textColor,
                      fontSize: _nameFontSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  Text(
                    employeeId,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: template.labelColor,
                      fontSize: _idFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 20),
                  Container(
                    padding: EdgeInsets.all(compact ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(compact ? 12 : 14),
                    ),
                    child: BrandedQrImage(
                      data: profileUrl,
                      size: _qrSize,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    context.l10n.scanEmployeeProfile,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: template.labelColor,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? photoUrl, String initial, {required double size}) {
    final photo = photoUrl?.trim();
    if (photo != null && photo.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: template.textColor.withValues(alpha: 0.25),
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(photo),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: template.isDark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.black.withValues(alpha: 0.08),
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          color: template.textColor,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
