import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/utils/attendance_utils.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
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
  static const Color _absentTint = Color(0xFFC62828);
  static const Color _partialTint = Color(0xFFE65100);
  static const Color _hoursTint = Color(0xFF64B5F6);
  static const Color _neutralTint = Color(0xFF90A4AE);
  static const Color _statCardBg = Color(0xFFF2F2F7);
  static const Color _presentFill = Color(0xFF1B8A4A);

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
        return _presentFill;
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
    final selected = _selected;
    final summary = _summary;
    final title = _titleBarLabel(selected);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
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
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EmployeeSettingsScreen(employee: selected),
                          ),
                        );
                        if (mounted) _loadSummary();
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
                            padding: const EdgeInsets.fromLTRB(
                              BarqodyChrome.sidePad,
                              8,
                              BarqodyChrome.sidePad,
                              28,
                            ),
                            children: [
                              if (!widget.isBusinessView &&
                                  _employers.length > 1) ...[
                                _employerPicker(),
                                const SizedBox(height: 16),
                              ],
                              if (widget.isBusinessView) ...[
                                _businessHeader(selected),
                                const SizedBox(height: 16),
                              ],
                              _monthPicker(),
                              const SizedBox(height: 20),
                              if (summary != null) ...[
                                _summarySection(context, summary),
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context.l10n.attendance,
                                    style: WaUi.toolsTitleOf(
                                      size: 17,
                                      weight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _statCardBg,
        borderRadius: BorderRadius.circular(20),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _statCardBg,
        borderRadius: BorderRadius.circular(20),
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
    final canGoForward = _month.year < DateTime.now().year ||
        (_month.year == DateTime.now().year &&
            _month.month < DateTime.now().month);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _monthNavButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () => _changeMonth(-1),
          ),
          Expanded(
            child: Text(
              DateFormat(context.l10n.mmmmYyyy).format(_month),
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          _monthNavButton(
            icon: Icons.chevron_right_rounded,
            onPressed: canGoForward ? () => _changeMonth(1) : null,
          ),
        ],
      ),
    );
  }

  Widget _monthNavButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 22,
            color: onPressed != null
                ? Colors.black
                : BarqodyChrome.secondaryText.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _summarySection(BuildContext context, AttendanceSummary summary) {
    final totalHours = totalWorkedDuration(summary);
    final rate = summary.totalWorkingDays > 0
        ? '${((summary.present / summary.totalWorkingDays) * 100).round()}%'
        : '0%';

    return Column(
      children: [
        Text(
          _formatDuration(context, totalHours),
          textAlign: TextAlign.center,
          style: WaUi.toolsTitleOf(
            size: 36,
            weight: FontWeight.w700,
            color: Colors.black,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Total hours & minutes',
          textAlign: TextAlign.center,
          style: WaUi.body.copyWith(
            fontSize: 14,
            color: BarqodyChrome.secondaryText,
          ),
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: BarqodyChrome.divider),
        const SizedBox(height: 16),
        Row(
          children: [
            _dashboardStat(context.l10n.present, '${summary.present}'),
            const SizedBox(width: 8),
            _dashboardStat(context.l10n.absent, '${summary.absent}'),
            const SizedBox(width: 8),
            _dashboardStat(context.l10n.partial, '${summary.partial}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _dashboardStat(context.l10n.offDays, '${summary.weekend}'),
            const SizedBox(width: 8),
            _dashboardStat(
              context.l10n.workingDays,
              '${summary.totalWorkingDays}',
            ),
            const SizedBox(width: 8),
            _dashboardStat(context.l10n.attendanceRate, rate),
          ],
        ),
      ],
    );
  }

  Widget _dashboardStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: _statCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: WaUi.toolsTitleOf(
                size: 22,
                weight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: WaUi.body.copyWith(
                fontSize: 12,
                color: BarqodyChrome.secondaryText,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _calendarBoxDecoration() => BoxDecoration(
        color: _statCardBg,
        borderRadius: BorderRadius.circular(20),
      );

  List<String> _weekdayLabels() {
    return List.generate(7, (i) {
      final ref = DateTime(2024, 1, 7 + i);
      return DateFormat('EEE').format(ref);
    });
  }

  Widget _calendarSection(BuildContext context, AttendanceSummary summary) {
    if (summary.daily.isEmpty) return _noData();

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
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
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
                          style: WaUi.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
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
              const SizedBox(height: 12),
              _calendarLegend(context),
            ],
          ),
        ),
        if (_selectedDay != null) ...[
          const SizedBox(height: 12),
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
    final isUpcoming = status == 'upcoming';
    final isWeekend = status == 'weekend';
    final color = _statusColor(status);

    Color bg;
    Color textColor;
    Border? border;

    if (isSelected) {
      bg = Colors.black;
      textColor = Colors.white;
    } else if (isWeekend) {
      bg = Colors.white;
      textColor = Colors.black;
      border = Border.all(color: BarqodyChrome.divider);
    } else if (isUpcoming) {
      bg = Colors.transparent;
      textColor = BarqodyChrome.secondaryText.withValues(alpha: 0.45);
    } else {
      bg = color;
      textColor = Colors.white;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: border ??
                (isToday && !isSelected
                    ? Border.all(color: Colors.black.withValues(alpha: 0.25))
                    : null),
          ),
          alignment: Alignment.center,
          child: Text(
            '$dayNum',
            style: WaUi.bodyMedium.copyWith(
              color: textColor,
              fontWeight:
                  isSelected || isToday ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendarLegend(BuildContext context) {
    final items = [
      ('present', context.l10n.present, _presentFill),
      ('absent', context.l10n.absent, _absentTint),
      ('partial', context.l10n.partial, _partialTint),
      ('weekend', context.l10n.statusWeekend, Colors.white),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        final isWeekend = item.$1 == 'weekend';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.$3,
                shape: BoxShape.circle,
                border: isWeekend
                    ? Border.all(color: BarqodyChrome.divider)
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.$2,
              style: WaUi.body.copyWith(
                fontSize: 11,
                color: BarqodyChrome.bodyText,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: _statCardBg,
        borderRadius: BorderRadius.circular(20),
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
