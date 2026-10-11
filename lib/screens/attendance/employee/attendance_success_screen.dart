import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

enum AttendanceSuccessKind { checkIn, checkOut }

/// Figma Check In / Check Out success — fonts / colors / spacing / dividers.
class AttendanceSuccessScreen extends StatelessWidget {
  const AttendanceSuccessScreen({
    super.key,
    required this.kind,
    required this.companyName,
    required this.timestamp,
    required this.shiftStart,
    required this.shiftEnd,
    this.checkInTime,
    this.checkOutTime,
    this.lateMinutes = 0,
    this.onCheckOut,
  });

  final AttendanceSuccessKind kind;
  final String companyName;
  final DateTime timestamp;
  final String shiftStart;
  final String shiftEnd;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final int lateMinutes;
  final VoidCallback? onCheckOut;

  // Figma Check Success tokens (measured from frame).
  static const Color _labelGrey = Color(0xFF9095A0);
  static const Color _divider = Color(0xFFE5E7EB);
  static const Color _lateOrange = Color(0xFFFF8D28);
  static const Color _iconHalo = Color(0xFFF3F4F6);
  static const double _sidePad = 20;
  static const double _iconSize = 100;
  static const double _headlineSize = 22;
  static const double _subSize = 15;
  static const double _rowSize = 15;
  static const double _borderW = 1;
  static const double _rowGap = 18;
  static const double _blockPadV = 18;

  static String formatShiftRange(String start, String end) =>
      '${start.trim()} – ${end.trim()}';

  static String formatDurationHours(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '—';
    final diff = end.difference(start);
    if (diff.isNegative) return '—';
    if (diff.inMinutes >= 60) {
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      if (m == 0) return '${h}h';
      return '${h}h ${m}m';
    }
    return '${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isCheckIn = kind == AttendanceSuccessKind.checkIn;
    final title = isCheckIn ? 'Check In' : 'Check Out';
    final headline = isCheckIn ? "You're Checked In" : "You're Checked Out";
    final message = isCheckIn
        ? 'Your attendance has been recorded.'
        : 'Your attendance has been recorded successfully.';
    final timestampLabel =
        DateFormat('hh:mm a MMM d, y').format(timestamp.toLocal());

    final mainRows = isCheckIn ? _checkInMainRows() : _checkOutMainRows();
    final showLate = isCheckIn && lateMinutes > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(_sidePad, 8, _sidePad, 16),
                child: Column(
                  children: [
                    _SuccessIcon(isCheckIn: isCheckIn),
                    const SizedBox(height: 20),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: _headlineSize,
                        weight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        color: _labelGrey,
                        fontSize: _subSize,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timestampLabel,
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        color: _labelGrey,
                        fontSize: _subSize,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Figma: one top + one bottom divider; NO per-row dividers.
                    _DetailBlock(rows: mainRows),
                    if (showLate) ...[
                      const SizedBox(height: 16),
                      _DetailRowTile(
                        label: 'Late',
                        value: lateMinutes == 1
                            ? '1 minute'
                            : '$lateMinutes minutes',
                        labelColor: _lateOrange,
                        valueColor: _lateOrange,
                        labelWeight: FontWeight.w400,
                        valueWeight: FontWeight.w700,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_sidePad, 8, _sidePad, 16),
              child: isCheckIn
                  ? Column(
                      children: [
                        _FilledPillButton(
                          label: 'Go Home',
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 12),
                        _OutlinePillButton(
                          label: 'Check Out',
                          onPressed: () {
                            Navigator.pop(context);
                            onCheckOut?.call();
                          },
                        ),
                      ],
                    )
                  : _FilledPillButton(
                      label: 'Done',
                      onPressed: () => Navigator.pop(context),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_RowData> _checkInMainRows() {
    return [
      _RowData(label: 'Company', value: companyName),
      _RowData(
        label: 'Check In',
        value:
            DateFormat('hh:mm a').format((checkInTime ?? timestamp).toLocal()),
      ),
      _RowData(label: 'Shift', value: formatShiftRange(shiftStart, shiftEnd)),
    ];
  }

  List<_RowData> _checkOutMainRows() {
    return [
      _RowData(label: 'Company', value: companyName),
      if (checkInTime != null)
        _RowData(
          label: 'Check In',
          value: DateFormat('hh:mm a').format(checkInTime!.toLocal()),
        ),
      _RowData(
        label: 'Check Out',
        value: DateFormat('hh:mm a')
            .format((checkOutTime ?? timestamp).toLocal()),
      ),
      _RowData(label: 'Shift', value: formatShiftRange(shiftStart, shiftEnd)),
      _RowData(
        label: 'Total Hours',
        value: formatDurationHours(checkInTime, checkOutTime ?? timestamp),
        valueWeight: FontWeight.w700,
      ),
    ];
  }
}

class _RowData {
  const _RowData({
    required this.label,
    required this.value,
    this.valueWeight = FontWeight.w600,
  });

  final String label;
  final String value;
  final FontWeight valueWeight;
}

/// Top + bottom 1px divider; rows spaced with no internal dividers.
class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.rows});

  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(
          height: 1,
          thickness: AttendanceSuccessScreen._borderW,
          color: AttendanceSuccessScreen._divider,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AttendanceSuccessScreen._blockPadV,
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const SizedBox(height: AttendanceSuccessScreen._rowGap),
                _DetailRowTile(
                  label: rows[i].label,
                  value: rows[i].value,
                  valueWeight: rows[i].valueWeight,
                ),
              ],
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: AttendanceSuccessScreen._borderW,
          color: AttendanceSuccessScreen._divider,
        ),
      ],
    );
  }
}

class _DetailRowTile extends StatelessWidget {
  const _DetailRowTile({
    required this.label,
    required this.value,
    this.labelColor = AttendanceSuccessScreen._labelGrey,
    this.valueColor = Colors.black,
    this.labelWeight = FontWeight.w400,
    this.valueWeight = FontWeight.w600,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final FontWeight labelWeight;
  final FontWeight valueWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: WaUi.body.copyWith(
              color: labelColor,
              fontWeight: labelWeight,
              fontSize: AttendanceSuccessScreen._rowSize,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: WaUi.body.copyWith(
              color: valueColor,
              fontWeight: valueWeight,
              fontSize: AttendanceSuccessScreen._rowSize,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon({required this.isCheckIn});

  final bool isCheckIn;

  @override
  Widget build(BuildContext context) {
    const size = AttendanceSuccessScreen._iconSize;
    const check = 40.0;

    if (isCheckIn) {
      // Soft single halo (#F3F4F6) behind solid black — not double rings.
      return SizedBox(
        width: size + 8,
        height: size + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size + 8,
              height: size + 8,
              decoration: const BoxDecoration(
                color: AttendanceSuccessScreen._iconHalo,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/png/check-img.png',
                  width: check,
                  height: check,
                  color: Colors.white,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AttendanceSuccessScreen._iconHalo,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/png/waiting-icon.png',
          width: check,
          height: check,
          errorBuilder: (_, _, _) => Icon(
            Icons.schedule_rounded,
            size: check,
            color: AttendanceSuccessScreen._labelGrey,
          ),
        ),
      ),
    );
  }
}

class _FilledPillButton extends StatelessWidget {
  const _FilledPillButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final h = m.buttonH;
    final size = Size(double.infinity, h);
    return SizedBox(
      width: double.infinity,
      height: h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          minimumSize: size,
          maximumSize: size,
          fixedSize: size,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: WaUi.body.copyWith(
            fontSize: AuthUi.buttonLabelSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _OutlinePillButton extends StatelessWidget {
  const _OutlinePillButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final h = m.buttonH;
    final size = Size(double.infinity, h);
    return SizedBox(
      width: double.infinity,
      height: h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: Colors.black,
            width: AttendanceSuccessScreen._borderW,
          ),
          shape: const StadiumBorder(),
          minimumSize: size,
          maximumSize: size,
          fixedSize: size,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: WaUi.body.copyWith(
            fontSize: AuthUi.buttonLabelSize,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1,
          ),
        ),
      ),
    );
  }
}
