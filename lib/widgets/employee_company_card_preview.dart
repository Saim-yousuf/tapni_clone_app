import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tapni_app/models/card_template.dart';

/// Employee card — business template colors, employee profile QR and details.
class EmployeeCompanyCardPreview extends StatelessWidget {
  final CardTemplate template;
  final String employeeName;
  final String employeeId;
  final String employeeInitial;
  final String profileUrl;
  final String? employeePhotoUrl;
  final double width;

  const EmployeeCompanyCardPreview({
    super.key,
    required this.template,
    required this.employeeName,
    required this.employeeId,
    required this.employeeInitial,
    required this.profileUrl,
    this.employeePhotoUrl,
    this.width = 340,
  });

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
            offset: const Offset(0, 8),
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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
                          size: 16,
                          color: template.textColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'EMPLOYEE CARD',
                          style: TextStyle(
                            color: template.textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _avatar(employeePhotoUrl, employeeInitial, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    employeeName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: template.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    employeeId,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: template.labelColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: QrImageView(
                      data: profileUrl,
                      size: 132,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan employee profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: template.labelColor,
                      fontSize: 11,
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
