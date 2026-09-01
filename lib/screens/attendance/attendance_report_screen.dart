import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/utils/attendance_utils.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';

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
  static const Color _absentTint = Color(0xFFE57373);
  static const Color _partialTint = Color(0xFFFFB74D);
  static const Color _hoursTint = Color(0xFF64B5F6);
  static const Color _neutralTint = Color(0xFF90A4AE);

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
        return WaUi.navGreen;
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

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final summary = _summary;
    final title = widget.isBusinessView && selected != null
        ? selected.employee.displayName
        : context.l10n.attendanceReport;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AttendanceUi.appBar(
        title,
        actions: [
          if (widget.isBusinessView && selected != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: context.l10n.manageEmployees,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EmployeeSettingsScreen(employee: selected),
                  ),
                );
                if (mounted) _loadSummary();
              },
            ),
        ],
      ),
      body: _isLoading && summary == null
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: WaUi.navGreen.withValues(alpha: 0.7),
              ),
            )
          : selected == null
              ? _emptyEmployers()
              : RefreshIndicator(
                  color: WaUi.navGreen,
                  backgroundColor: WaUi.surface,
                  onRefresh: _loadSummary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    children: [
                      if (!widget.isBusinessView && _employers.length > 1) ...[
                        _employerPicker(),
                        const SizedBox(height: 14),
                      ],
                      if (widget.isBusinessView) ...[
                        _businessHeader(selected),
                        const SizedBox(height: 14),
                      ],
                      _monthPicker(),
                      const SizedBox(height: 16),
                      if (summary != null) ...[
                        _summarySection(context, summary),
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 10),
                          child: Text(
                            context.l10n.dailyBreakdown,
                            style: WaUi.sectionHeader,
                          ),
                        ),
                        _calendarSection(context, summary),
                      ] else
                        _noData(),
                    ],
                  ),
                ),
    );
  }

  Widget _employerPicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AttendanceUi.softCard,
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
      decoration: AttendanceUi.softCard,
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

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(WaUi.radiusLg),
          border: Border.all(color: WaUi.divider),
          boxShadow: [
            BoxShadow(
              color: WaUi.primaryText.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _monthNavButton(
              icon: Icons.chevron_left_rounded,
              onPressed: () => _changeMonth(-1),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    DateFormat(context.l10n.mmmmYyyy).format(_month),
                    textAlign: TextAlign.center,
                    style: WaUi.listTitle,
                  ),
                  Text(
                    context.l10n.thisMonth,
                    style: WaUi.caption,
                  ),
                ],
              ),
            ),
            _monthNavButton(
              icon: Icons.chevron_right_rounded,
              onPressed: canGoForward ? () => _changeMonth(1) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthNavButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(WaUi.radiusPill),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: onPressed != null ? WaUi.navPill : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: onPressed != null
                ? WaUi.primaryText
                : WaUi.secondaryText.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _summarySection(BuildContext context, AttendanceSummary summary) {
    final totalHours = totalWorkedDuration(summary);
    final avg = averageWorkedDuration(summary);
    final rate = summary.totalWorkingDays > 0
        ? '${((summary.present / summary.totalWorkingDays) * 100).round()}%'
        : '0%';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _calendarBoxDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            decoration: AttendanceUi.thickCard,
            child: Row(
              children: [
                Expanded(
                  child: _dashboardMetric(
                    label: context.l10n.totalHours,
                    value: _formatDuration(context, totalHours),
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: WaUi.divider,
                ),
                Expanded(
                  child: _dashboardMetric(
                    label: context.l10n.avgHoursPerDay,
                    value: avg != null && summary.present > 0
                        ? _formatDuration(context, avg)
                        : '—',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _dashboardStat(context.l10n.present, '${summary.present}'),
              const SizedBox(width: 10),
              _dashboardStat(context.l10n.absent, '${summary.absent}'),
              const SizedBox(width: 10),
              _dashboardStat(context.l10n.partial, '${summary.partial}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _dashboardStat(context.l10n.offDays, '${summary.weekend}'),
              const SizedBox(width: 10),
              _dashboardStat(
                context.l10n.workingDays,
                '${summary.totalWorkingDays}',
              ),
              const SizedBox(width: 10),
              _dashboardStat(context.l10n.attendanceRate, rate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboardMetric({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: AttendanceUi.statNumber.copyWith(
            color: WaUi.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AttendanceUi.statLabel,
        ),
      ],
    );
  }

  Widget _dashboardStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: AttendanceUi.thickCard,
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: AttendanceUi.statNumber.copyWith(
                color: WaUi.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AttendanceUi.statLabel,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _calendarBoxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WaUi.radiusLg),
        border: Border.all(color: WaUi.divider),
        boxShadow: [
          BoxShadow(
            color: WaUi.primaryText.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
    final color = _statusColor(status);
    final isUpcoming = status == 'upcoming';
    final hasStatus = status != 'upcoming';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: hasStatus
                ? color.withValues(alpha: isSelected ? 0.28 : 0.14)
                : WaUi.searchBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? color
                  : isToday
                      ? WaUi.navGreen.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNum',
                style: WaUi.bodyMedium.copyWith(
                  color: isUpcoming
                      ? WaUi.secondaryText.withValues(alpha: 0.45)
                      : color,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (hasStatus) ...[
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendarLegend(BuildContext context) {
    final items = [
      ('present', context.l10n.present),
      ('absent', context.l10n.absent),
      ('partial', context.l10n.partial),
      ('weekend', context.l10n.statusWeekend),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        final color = _statusColor(item.$1);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(item.$2, style: WaUi.caption.copyWith(fontSize: 11)),
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
            AttendanceUi.softIconBox(
              icon: Icons.assessment_outlined,
              size: 64,
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.noEmployerFound,
              style: WaUi.sectionHeader,
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
      decoration: AttendanceUi.softCard,
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 36,
            color: WaUi.secondaryText.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.noAttendanceDataForMonth,
            textAlign: TextAlign.center,
            style: WaUi.listSubtitle,
          ),
        ],
      ),
    );
  }
}
