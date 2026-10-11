import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/utils/attendance_utils.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class AttendanceReportScreen extends StatefulWidget {
  final AttendanceEmployee? employee;
  final bool isBusinessView;

  const AttendanceReportScreen({
    super.key,
    this.employee,
    this.isBusinessView = false,
  });

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  /// Figma Report surfaces / calendar tints (match Report screenshot).
  static const Color _cardBg = Color(0xFFF3F4F6);
  static const Color _presentFill = Color(0xFFEAF7EE);
  static const Color _presentBorder = Color(0xFFA8D5B5);
  static const Color _absentFill = Color(0xFFFDECEC);
  static const Color _absentBorder = Color(0xFFF0A8A8);
  static const Color _partialFill = Color(0xFFFFF4E5);
  static const Color _partialBorder = Color(0xFFF5C48A);
  static const Color _offDayBg = Color(0xFFE5E7EB);
  static const Color _dayBorder = Color(0xFFE5E7EB);
  static const Color _absentTint = Color(0xFFC62828);
  static const Color _partialTint = Color(0xFFE65100);
  static const Color _hoursTint = Color(0xFF64B5F6);
  static const Color _neutralTint = Color(0xFF90A4AE);
  static const Color _presentSolid = Color(0xFF1B8A4A);
  static const String _arrowAsset = AuthBackButton.asset;

  List<AttendanceEmployee> _employers = [];
  AttendanceEmployee? _selected;
  AttendanceSummary? _summary;
  late DateTime _month;
  bool _isLoading = true;
  AttendanceDailyStatus? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = widget.employee;
    _init();
  }

  Future<void> _init() async {
    if (widget.isBusinessView && widget.employee != null) {
      await _loadSummary();
      return;
    }

    setState(() => _isLoading = true);
    final res = await AttendanceRepo().getMyEmployers();
    if (!mounted) return;

    final employers = res.success
        ? parseAttendanceList(res.data, AttendanceEmployee.fromJson)
        : <AttendanceEmployee>[];

    AttendanceEmployee? selected = _selected;
    if (selected != null && !employers.any((e) => e.id == selected!.id)) {
      selected = null;
    }
    selected ??= employers.isNotEmpty ? employers.first : null;

    setState(() {
      _employers = employers;
      _selected = selected;
    });

    if (selected != null) {
      await _loadSummary();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSummary() async {
    final selected = _selected;
    if (selected == null) return;

    setState(() => _isLoading = true);
    final res = await AttendanceRepo().getSummary(
      employeeRefId: selected.id,
      month: _month.month,
      year: _month.year,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _summary = res.success
          ? AttendanceSummary.fromJson(unwrapAttendancePayload(res.data))
          : null;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = null;
    });
    _loadSummary();
  }

  String _formatDuration(BuildContext context, Duration duration) {
    final parts = splitDuration(duration);
    return context.l10n.hoursMinutesFormat(parts.hours, parts.minutes);
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'present':
        return context.l10n.present;
      case 'absent':
        return context.l10n.absent;
      case 'partial':
        return context.l10n.partial;
      case 'weekend':
        return context.l10n.statusWeekend;
      case 'upcoming':
        return context.l10n.statusUpcoming;
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return _presentSolid;
      case 'absent':
        return _absentTint;
      case 'partial':
        return _partialTint;
      case 'weekend':
        return _neutralTint;
      case 'upcoming':
        return WaUi.secondaryText.withValues(alpha: 0.55);
      default:
        return WaUi.secondaryText;
    }
  }

  String _titleBarLabel(AttendanceEmployee? selected) {
    if (selected == null) return context.l10n.attendanceReport;
    if (widget.isBusinessView) {
      return selected.employee.displayName;
    }
    final username = selected.employee.username;
    if (username.isNotEmpty) return '@$username';
    final name = selected.employee.displayName;
    return name.isNotEmpty ? name : context.l10n.attendanceReport;
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final side = m.s(BarqodyChrome.sidePad);
    final selected = _selected;
    final summary = _summary;
    final title = _titleBarLabel(selected);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: title,
              trailing: widget.isBusinessView && selected != null
                  ? CircleAssetButton(
                      asset: 'assets/images/png/settings-sliders.png',
                      iconSize: 18,
                      onTap: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EmployeeSettingsScreen(employee: selected),
                          ),
                        );
                        if (!mounted) return;
                        if (result != null && result.isNotEmpty) {
                          EmployeeSettingsScreen.showResultSnack(
                            context,
                            result,
                          );
                        }
                        _loadSummary();
                      },
                    )
                  : null,
            ),
            Expanded(
              child: _isLoading && summary == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : selected == null
                      ? _emptyEmployers()
                      : RefreshIndicator(
                          color: Colors.black,
                          backgroundColor: Colors.white,
                          onRefresh: _loadSummary,
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              side,
                              0,
                              side,
                              m.v(28),
                            ),
                            children: [
                              if (!widget.isBusinessView &&
                                  _employers.length > 1) ...[
                                _employerPicker(),
                                SizedBox(height: m.v(16)),
                              ],
                              if (widget.isBusinessView) ...[
                                _businessHeader(selected),
                                SizedBox(height: m.v(16)),
                              ],
                              _monthPicker(),
                              SizedBox(height: m.v(20)),
                              if (summary != null) ...[
                                _summarySection(context, summary),
                                SizedBox(height: m.v(24)),
                                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context.l10n.attendance,
                                    style: WaUi.toolsTitleOf(
                                      size: m.s(20),
                                      weight: FontWeight.w700,
                                      color: Colors.black,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                SizedBox(height: m.v(14)),
                                _calendarSection(context, summary),
                              ] else
                                _noData(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _employerPicker() {
    final m = AuthScale.of(context);
    return Container(
      padding: EdgeInsets.all(m.s(14)),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(m.s(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.selectCompany,
            style: WaUi.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ..._employers.map((employer) {
            final isSelected = _selected?.id == employer.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    setState(() => _selected = employer);
                    await _loadSummary();
                  },
                  borderRadius: BorderRadius.circular(WaUi.radiusMd),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? WaUi.chipBg
                          : WaUi.searchBg,
                      borderRadius: BorderRadius.circular(WaUi.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? WaUi.navGreen.withValues(alpha: 0.35)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        AttendanceUi.softIconBox(
                          icon: Icons.business_outlined,
                          bg: isSelected
                              ? WaUi.navGreen.withValues(alpha: 0.15)
                              : WaUi.promoIconBg,
                          fg: isSelected ? WaUi.navGreen : WaUi.promoIconFg,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            employer.business.displayName,
                            style: WaUi.listTitle,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: WaUi.navGreen,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _businessHeader(AttendanceEmployee employee) {
    final m = AuthScale.of(context);
    return Container(
      padding: EdgeInsets.all(m.s(14)),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(m.s(20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: WaUi.chipBg,
            backgroundImage: employee.employee.profilePhoto.isNotEmpty
                ? NetworkImage(employee.employee.profilePhoto)
                : null,
            child: employee.employee.profilePhoto.isEmpty
                ? Text(
                    employee.employee.displayName.isNotEmpty
                        ? employee.employee.displayName[0].toUpperCase()
                        : '?',
                    style: WaUi.avatarInitial,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.employee.displayName,
                  style: WaUi.listTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.shiftRange(
                    employee.shiftStart,
                    employee.shiftEnd,
                  ),
                  style: WaUi.listSubtitle,
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.l10n.weekendDays}: ${employee.weekendLabel}',
                  style: WaUi.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthPicker() {
    final m = AuthScale.of(context);
    final canGoForward = _month.year < DateTime.now().year ||
        (_month.year == DateTime.now().year &&
            _month.month < DateTime.now().month);

    return Container(
      height: m.s(52),
      padding: EdgeInsets.symmetric(horizontal: m.s(8)),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _monthNavButton(
            forward: false,
            onPressed: () => _changeMonth(-1),
          ),
          Expanded(
            child: Text(
              DateFormat(context.l10n.mmmmYyyy).format(_month),
              textAlign: TextAlign.center,
              style: WaUi.toolsTitleOf(
                size: m.s(16),
                weight: FontWeight.w700,
                color: Colors.black,
                height: 1.2,
              ),
            ),
          ),
          _monthNavButton(
            forward: true,
            onPressed: canGoForward ? () => _changeMonth(1) : null,
          ),
        ],
      ),
    );
  }

  /// White circle + 1px black border + arrow-back asset (mirrored for next).
  Widget _monthNavButton({
    required bool forward,
    VoidCallback? onPressed,
  }) {
    final m = AuthScale.of(context);
    final size = m.s(34);
    final iconSize = m.s(16);
    final enabled = onPressed != null;
    final iconColor = enabled
        ? Colors.black
        : BarqodyChrome.secondaryText.withValues(alpha: 0.35);

    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.black, width: 1),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Transform.flip(
              flipX: forward,
              child: Image.asset(
                _arrowAsset,
                width: iconSize,
                height: iconSize,
                color: iconColor,
                errorBuilder: (_, _, _) => Icon(
                  forward
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summarySection(BuildContext context, AttendanceSummary summary) {
    final m = AuthScale.of(context);
    final totalHours = totalWorkedDuration(summary);
    final rate = summary.totalWorkingDays > 0
        ? '${((summary.present / summary.totalWorkingDays) * 100).round()}%'
        : '0%';
    final hoursLabelStyle = WaUi.body.copyWith(
      fontSize: m.s(14),
      fontWeight: FontWeight.w400,
      color: BarqodyChrome.secondaryText,
      height: 1.3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDuration(context, totalHours),
          style: WaUi.toolsTitleOf(
            size: m.s(28),
            weight: FontWeight.w700,
            color: Colors.black,
            height: 1.15,
          ),
        ),
        SizedBox(height: m.v(6)),
        // Divider width matches the label text (Figma).
        IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Total hours & minutes', style: hoursLabelStyle),
              SizedBox(height: m.v(8)),
              Container(height: 1, color: const Color(0xFFE5E7EB)),
            ],
          ),
        ),
        SizedBox(height: m.v(16)),
        Row(
          children: [
            _dashboardStat(context.l10n.present, '${summary.present}'),
            SizedBox(width: m.s(10)),
            _dashboardStat(context.l10n.absent, '${summary.absent}'),
            SizedBox(width: m.s(10)),
            _dashboardStat(context.l10n.partial, '${summary.partial}'),
          ],
        ),
        SizedBox(height: m.v(10)),
        Row(
          children: [
            _dashboardStat(context.l10n.offDays, '${summary.weekend}'),
            SizedBox(width: m.s(10)),
            _dashboardStat(
              context.l10n.workingDays,
              '${summary.totalWorkingDays}',
            ),
            SizedBox(width: m.s(10)),
            _dashboardStat('Rate', rate),
          ],
        ),
      ],
    );
  }

  Widget _dashboardStat(String label, String value) {
    final m = AuthScale.of(context);
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: m.v(16), horizontal: m.s(6)),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(m.s(16)),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: WaUi.toolsTitleOf(
                size: m.s(20),
                weight: FontWeight.w700,
                color: Colors.black,
                height: 1.1,
              ),
            ),
            SizedBox(height: m.v(8)),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: WaUi.body.copyWith(
                fontSize: m.s(13),
                fontWeight: FontWeight.w400,
                color: BarqodyChrome.secondaryText,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _calendarBoxDecoration() {
    final m = AuthScale.of(context);
    return BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(m.s(20)),
    );
  }

  List<String> _weekdayLabels() {
    return List.generate(7, (i) {
      final ref = DateTime(2024, 1, 7 + i);
      return DateFormat('EEE').format(ref);
    });
  }

  Widget _calendarSection(BuildContext context, AttendanceSummary summary) {
    if (summary.daily.isEmpty) return _noData();

    final m = AuthScale.of(context);
    final dailyMap = {
      for (final day in summary.daily) day.date: day,
    };
    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    final startOffset =
        DateTime(_month.year, _month.month, 1).weekday % 7;
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(m.s(12), m.v(14), m.s(12), m.v(14)),
          decoration: _calendarBoxDecoration(),
          child: Column(
            children: [
              Row(
                children: _weekdayLabels()
                    .map(
                      (label) => Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: WaUi.body.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: m.s(11),
                            color: BarqodyChrome.secondaryText,
                            height: 1.2,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: m.v(10)),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: m.s(5),
                crossAxisSpacing: m.s(5),
                childAspectRatio: 1,
                children: [
                  ...List.generate(startOffset, (_) => const SizedBox.shrink()),
                  ...List.generate(daysInMonth, (index) {
                    final dayNum = index + 1;
                    final dateKey = DateFormat('yyyy-MM-dd').format(
                      DateTime(_month.year, _month.month, dayNum),
                    );
                    final dayStatus = dailyMap[dateKey];
                    final status = dayStatus?.status ?? 'upcoming';
                    final isSelected = _selectedDay?.date == dateKey;
                    final isToday = dateKey == todayKey;

                    return _calendarDayCell(
                      dayNum: dayNum,
                      status: status,
                      isSelected: isSelected,
                      isToday: isToday,
                      onTap: dayStatus == null
                          ? null
                          : () => setState(() => _selectedDay = dayStatus),
                    );
                  }),
                ],
              ),
              SizedBox(height: m.v(14)),
              _calendarLegend(context),
            ],
          ),
        ),
        if (_selectedDay != null) ...[
          SizedBox(height: m.v(12)),
          _selectedDayDetail(context, _selectedDay!),
        ],
      ],
    );
  }

  Widget _calendarDayCell({
    required int dayNum,
    required String status,
    required bool isSelected,
    required bool isToday,
    VoidCallback? onTap,
  }) {
    final m = AuthScale.of(context);
    final radius = m.s(8);

    Color bg;
    Color textColor = Colors.black;
    Border? border;

    if (isSelected) {
      bg = Colors.black;
      textColor = Colors.white;
      border = null;
    } else {
      switch (status) {
        case 'present':
          bg = _presentFill;
          border = Border.all(color: _presentBorder, width: 1);
        case 'absent':
          bg = _absentFill;
          border = Border.all(color: _absentBorder, width: 1);
        case 'partial':
          bg = _partialFill;
          border = Border.all(color: _partialBorder, width: 1);
        case 'weekend':
          // Off days — solid muted gray (Figma).
          bg = _offDayBg;
          border = null;
        case 'upcoming':
          // Unmarked — white + thin gray border.
          bg = Colors.white;
          border = Border.all(color: _dayBorder, width: 1);
          textColor = Colors.black;
        default:
          bg = Colors.white;
          border = Border.all(color: _dayBorder, width: 1);
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: border ??
                (isToday && !isSelected
                    ? Border.all(color: Colors.black.withValues(alpha: 0.18))
                    : null),
          ),
          alignment: Alignment.center,
          child: Text(
            '$dayNum',
            style: WaUi.body.copyWith(
              color: textColor,
              fontWeight:
                  isSelected || isToday ? FontWeight.w700 : FontWeight.w600,
              fontSize: m.s(12),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendarLegend(BuildContext context) {
    final m = AuthScale.of(context);
    // Figma: white fill + colored ring only.
    final items = <(String, Color)>[
      (context.l10n.present, _presentBorder),
      (context.l10n.absent, _absentBorder),
      (context.l10n.partial, _partialBorder),
      ('Off', const Color(0xFFD1D5DB)),
    ];

    return Wrap(
      spacing: m.s(16),
      runSpacing: m.v(8),
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: m.s(10),
              height: m.s(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: item.$2, width: 1.5),
              ),
            ),
            SizedBox(width: m.s(6)),
            Text(
              item.$1,
              style: WaUi.body.copyWith(
                fontSize: m.s(12),
                fontWeight: FontWeight.w400,
                color: BarqodyChrome.secondaryText,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _selectedDayDetail(
    BuildContext context,
    AttendanceDailyStatus day,
  ) {
    final date = DateTime.tryParse(day.date);
    final record = day.record;
    final worked = attendanceWorkedDuration(record);
    final statusColor = _statusColor(day.status);
    final dateLabel = date != null
        ? DateFormat('EEEE, MMMM d').format(date)
        : day.date;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _calendarBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(dateLabel, style: WaUi.listTitle),
              ),
              AttendanceUi.statusPill(
                label: _statusLabel(context, day.status),
                color: statusColor,
              ),
            ],
          ),
          if (day.status == 'weekend') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.beach_access_outlined,
                  size: 16,
                  color: _neutralTint,
                ),
                const SizedBox(width: 8),
                Text(context.l10n.scheduledOffDay, style: WaUi.caption),
              ],
            ),
          ] else if (day.status != 'upcoming') ...[
            const SizedBox(height: 12),
            if (record?.checkInTime != null)
              _detailRow(
                Icons.login_rounded,
                context.l10n.checkInColon,
                DateFormat('hh:mm a').format(record!.checkInTime!.toLocal()),
              ),
            if (record?.checkOutTime != null)
              _detailRow(
                Icons.logout_rounded,
                context.l10n.checkOutColon,
                DateFormat('hh:mm a').format(record!.checkOutTime!.toLocal()),
              )
            else if (record?.checkInTime != null)
              _detailRow(
                Icons.logout_rounded,
                context.l10n.checkOutColon,
                context.l10n.noCheckOutYet,
                valueColor: _partialTint,
              ),
            if (worked != null)
              _detailRow(
                Icons.schedule_rounded,
                '${context.l10n.totalHours}:',
                _formatDuration(context, worked),
                valueColor: _hoursTint,
              ),
            if (record?.checkInTime == null && day.status == 'absent')
              Text(
                context.l10n.notCheckedInYet,
                style: WaUi.caption.copyWith(color: _absentTint),
              ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: WaUi.secondaryText.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(label, style: WaUi.caption),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: WaUi.bodyMedium.copyWith(
                color: valueColor ?? WaUi.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyEmployers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/png/waiting-icon.png',
              width: 56,
              height: 56,
              errorBuilder: (_, _, _) => Icon(
                Icons.assessment_outlined,
                size: 52,
                color: BarqodyChrome.secondaryText.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.noEmployerFound,
              style: WaUi.toolsTitleOf(
                size: 17,
                weight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _noData() {
    final m = AuthScale.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: m.v(32), horizontal: m.s(20)),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(m.s(20)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 36,
            color: BarqodyChrome.secondaryText.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.noAttendanceDataForMonth,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: 14,
              color: BarqodyChrome.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}
