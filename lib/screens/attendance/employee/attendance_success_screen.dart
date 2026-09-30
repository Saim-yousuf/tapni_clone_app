import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

enum AttendanceSuccessKind { checkIn, checkOut }

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

  static String formatShiftRange(String start, String end) => '$start - $end';

  static String formatDurationHours(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '—';
    final diff = end.difference(start);
    if (diff.isNegative) return '—';
    final hours = diff.inMinutes / 60.0;
    if (hours >= 1) {
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
        : 'Your attendance has been recorded.';

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  24,
                  BarqodyChrome.sidePad,
                  16,
                ),
                child: Column(
                  children: [
                    _SuccessIcon(isCheckIn: isCheckIn),
                    const SizedBox(height: 24),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 22,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('EEE, MMM d · hh:mm a').format(timestamp),
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        color: BarqodyChrome.bodyText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _DetailCard(
                      rows: isCheckIn
                          ? _checkInRows()
                          : _checkOutRows(),
                    ),
                    const SizedBox(height: 28),
                    if (isCheckIn) ...[
                      PillButton(
                        label: 'Go Home',
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      PillButton(
                        label: 'Check Out',
                        filled: false,
                        onPressed: () {
                          Navigator.pop(context);
                          onCheckOut?.call();
                        },
                      ),
                    ] else
                      PillButton(
                        label: 'Done',
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_DetailRow> _checkInRows() {
    final shift = formatShiftRange(shiftStart, shiftEnd);
    final lateLabel = lateMinutes > 0 ? '${lateMinutes} min' : 'On time';
    return [
      _DetailRow(label: 'Company', value: companyName),
      _DetailRow(
        label: 'Check In',
        value: DateFormat('hh:mm a').format(checkInTime ?? timestamp),
      ),
      _DetailRow(label: 'Shift', value: shift),
      _DetailRow(
        label: 'Late',
        value: lateLabel,
        valueColor: lateMinutes > 0 ? const Color(0xFFFF9500) : null,
      ),
    ];
  }

  List<_DetailRow> _checkOutRows() {
    final shift = formatShiftRange(shiftStart, shiftEnd);
    final total = formatDurationHours(checkInTime, checkOutTime ?? timestamp);
    return [
      _DetailRow(label: 'Company', value: companyName),
      if (checkInTime != null)
        _DetailRow(
          label: 'Check In',
          value: DateFormat('hh:mm a').format(checkInTime!.toLocal()),
        ),
      _DetailRow(
        label: 'Check Out',
        value: DateFormat('hh:mm a').format((checkOutTime ?? timestamp).toLocal()),
      ),
      _DetailRow(label: 'Shift', value: shift),
      _DetailRow(
        label: 'Total Hours',
        value: total,
        valueBold: true,
      ),
    ];
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon({required this.isCheckIn});

  final bool isCheckIn;

  @override
  Widget build(BuildContext context) {
    if (isCheckIn) {
      return Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            'assets/images/png/check-img.png',
            width: 48,
            height: 48,
            color: Colors.white,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 56,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/png/waiting-icon.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => Icon(
            Icons.schedule_rounded,
            size: 48,
            color: BarqodyChrome.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.rows});

  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: BarqodyChrome.divider.withValues(alpha: 0.8),
                indent: 16,
                endIndent: 16,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: WaUi.body.copyWith(
                        color: BarqodyChrome.secondaryText,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.end,
                      style: WaUi.body.copyWith(
                        fontSize: 15,
                        fontWeight:
                            rows[i].valueBold ? FontWeight.w700 : FontWeight.w600,
                        color: rows[i].valueColor ?? Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
