import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/employee_settings_screen.dart';
import 'package:tapni_app/screens/attendance/business/scan_to_invite_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

enum _MemberFilter { active, inactive, pending, declined }

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<AttendanceEmployee> _employees = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  _MemberFilter _filter = _MemberFilter.active;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await AttendanceRepo().getBusinessEmployees();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success) {
        _employees = parseAttendanceList(
          res.data,
          AttendanceEmployee.fromJson,
        );
      }
    });
  }

  Future<void> _scanToInvite() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanToInviteScreen()),
    );
    _load();
  }

  Future<void> _openSettings(AttendanceEmployee employee) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeSettingsScreen(employee: employee),
      ),
    );
    _load();
  }

  Future<void> _removeEmployee(AttendanceEmployee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WaUi.radiusLg),
        ),
        title: Text(
          context.l10n.removeEmployee,
          style: AttendanceUi.sectionTitle,
        ),
        content: Text(
          context.l10n.removeEmployeeFromTeam(employee.employee.displayName),
          style: AttendanceUi.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel, style: WaUi.bodyMedium),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WaUi.radiusMd),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.remove, style: AttendanceUi.buttonLabel),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await AttendanceRepo().removeEmployee(employee.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          res.success
              ? context.l10n.employeeRemoved
              : (res.message ?? context.l10n.failedToRemove),
          style: WaUi.body,
        ),
      ),
    );
    if (res.success) _load();
  }

  bool _matchesFilter(AttendanceEmployee employee) {
    switch (_filter) {
      case _MemberFilter.active:
        return employee.isAccepted && employee.isActive;
      case _MemberFilter.inactive:
        return employee.isAccepted && !employee.isActive;
      case _MemberFilter.pending:
        return employee.isPendingInvitation;
      case _MemberFilter.declined:
        return employee.invitationStatus == 'declined';
    }
  }

  bool _matchesSearch(AttendanceEmployee employee) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    final name = employee.employee.displayName.toLowerCase();
    final username = employee.employee.username.toLowerCase();
    return name.contains(query) || username.contains(query);
  }

  List<AttendanceEmployee> get _visibleEmployees => _employees
      .where((e) => _matchesFilter(e) && _matchesSearch(e))
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Members',
              trailing: CircleAssetButton(
                asset: 'assets/images/png/plus-icon.png',
                iconSize: 16,
                onTap: _scanToInvite,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BarqodyChrome.sidePad),
              child: _MembersSearchField(
                controller: _searchController,
                hintText: 'Search by name or username',
                onChanged: (_) => setState(() {}),
                onClear: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: BarqodyChrome.sidePad),
                children: [
                  _FilterChip(
                    label: l10n.active,
                    selected: _filter == _MemberFilter.active,
                    onTap: () => setState(() => _filter = _MemberFilter.active),
                  ),
                  _FilterChip(
                    label: l10n.inactive,
                    selected: _filter == _MemberFilter.inactive,
                    onTap: () => setState(() => _filter = _MemberFilter.inactive),
                  ),
                  _FilterChip(
                    label: l10n.pending,
                    selected: _filter == _MemberFilter.pending,
                    onTap: () => setState(() => _filter = _MemberFilter.pending),
                  ),
                  _FilterChip(
                    label: 'Declined',
                    selected: _filter == _MemberFilter.declined,
                    onTap: () => setState(() => _filter = _MemberFilter.declined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : RefreshIndicator(
                      color: WaUi.accent,
                      backgroundColor: Colors.white,
                      onRefresh: _load,
                      child: _employees.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.35,
                                  child: _EmptyMembersState(
                                    title: l10n.noEmployeesAdded,
                                    subtitle: l10n
                                        .scanAnyUserOrBusinessQRToAddEmployee,
                                  ),
                                ),
                              ],
                            )
                          : _visibleEmployees.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height * 0.3,
                                      child: _EmptyMembersState(
                                        title: l10n.noEmployeesYet,
                                        subtitle: l10n.searchByUsername,
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    BarqodyChrome.sidePad,
                                    4,
                                    BarqodyChrome.sidePad,
                                    8,
                                  ),
                                  itemCount: _visibleEmployees.length,
                                  separatorBuilder: (_, _) => const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: BarqodyChrome.divider,
                                  ),
                                  itemBuilder: (_, i) {
                                    final employee = _visibleEmployees[i];
                                    return _EmployeeRow(
                                      employee: employee,
                                      onTap: () => _openSettings(employee),
                                      onEdit: () => _openSettings(employee),
                                      onRemove: () => _removeEmployee(employee),
                                    );
                                  },
                                ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BarqodyChrome.sidePad,
                8,
                BarqodyChrome.sidePad,
                12,
              ),
              child: PillButton(
                label: l10n.scanToInvite,
                onPressed: _scanToInvite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _MembersSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: WaUi.body.copyWith(fontSize: 15, color: Colors.black),
        cursorColor: Colors.black,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: true,
          fillColor: BarqodyChrome.searchBg,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 15,
            color: BarqodyChrome.secondaryText,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 6),
            child: Image.asset(
              'assets/images/png/search-icon.png',
              width: 18,
              height: 18,
              color: BarqodyChrome.secondaryText,
              errorBuilder: (_, _, _) => const Icon(
                Icons.search,
                size: 20,
                color: BarqodyChrome.secondaryText,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 44,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: BarqodyChrome.secondaryText,
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Colors.black : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? Colors.black : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                style: WaUi.body.copyWith(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF6B6B6B),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMembersState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyMembersState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/png/multiple-users.png',
            width: 56,
            height: 56,
            color: BarqodyChrome.secondaryText.withValues(alpha: 0.45),
            errorBuilder: (_, _, _) => Icon(
              Icons.person_search_outlined,
              size: 48,
              color: BarqodyChrome.secondaryText.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: WaUi.toolsTitleOf(
              size: 17,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: 14,
              height: 1.35,
              color: BarqodyChrome.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final AttendanceEmployee employee;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _EmployeeRow({
    required this.employee,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = employee.employee.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final username = employee.employee.username;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: BarqodyChrome.fieldFill,
                backgroundImage: employee.employee.profilePhoto.isNotEmpty
                    ? NetworkImage(employee.employee.profilePhoto)
                    : null,
                child: employee.employee.profilePhoto.isEmpty
                    ? Text(initial, style: WaUi.avatarInitial)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: WaUi.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: WaUi.body.copyWith(
                          fontSize: 14,
                          color: BarqodyChrome.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Image.asset(
                  'assets/images/png/icon-morehoriz.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.more_horiz_rounded,
                    color: BarqodyChrome.secondaryText.withValues(alpha: 0.85),
                  ),
                ),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'remove') onRemove();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      context.l10n.editSettings,
                      style: AttendanceUi.body,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      context.l10n.remove,
                      style: AttendanceUi.body.copyWith(
                        color: const Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
