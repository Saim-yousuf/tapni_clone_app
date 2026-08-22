import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/map_location_picker_screen.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';
import 'package:tapni_app/widgets/face_capture_sheet.dart';

class EmployeeSettingsScreen extends StatefulWidget {
  final AttendanceEmployee? employee;
  final String? employeeUserId;
  final String? employeeName;

  const EmployeeSettingsScreen({
    super.key,
    this.employee,
    this.employeeUserId,
    this.employeeName,
  });

  @override
  State<EmployeeSettingsScreen> createState() => _EmployeeSettingsScreenState();
}

class _EmployeeSettingsScreenState extends State<EmployeeSettingsScreen> {
  final _addressController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');

  TimeOfDay _shiftStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _shiftEnd = const TimeOfDay(hour: 18, minute: 0);
  final Set<int> _weekendDays = {0, 6};
  double? _latitude;
  double? _longitude;
  String? _facePhotoBase64;
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  List<String> _dayNames(BuildContext context) => [
        context.l10n.sunday,
        context.l10n.monday,
        context.l10n.tuesday,
        context.l10n.wednesday,
        context.l10n.thursday,
        context.l10n.friday,
        context.l10n.saturday,
      ];

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    if (employee != null) {
      _shiftStart = _parseTime(employee.shiftStart);
      _shiftEnd = _parseTime(employee.shiftEnd);
      _weekendDays
        ..clear()
        ..addAll(employee.weekendDays);
      _latitude = employee.location.latitude;
      _longitude = employee.location.longitude;
      _addressController.text = employee.location.address;
      _radiusController.text = employee.location.radiusMeters.toString();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  int get _radiusMeters => int.tryParse(_radiusController.text.trim()) ?? 100;

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 9, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _shiftStart : _shiftEnd,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _shiftStart = picked;
      } else {
        _shiftEnd = picked;
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    final location = await LocationHelper.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLoadingLocation = false);

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            context.l10n.couldNotGetLocationPleaseEnableGPSPermission,
            style: WaUi.body,
          ),
        ),
      );
      return;
    }

    setState(() {
      _latitude = location.latitude;
      _longitude = location.longitude;
    });
  }

  Future<void> _pickOnMap() async {
    final result = await MapLocationPickerScreen.open(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
      radiusMeters: _radiusMeters,
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _captureFace() async {
    final photo = await FaceCaptureSheet.show(
      context,
      title: context.l10n.employeeFacePhoto,
    );
    if (photo != null && photo.isNotEmpty) {
      setState(() => _facePhotoBase64 = photo);
    }
  }

  Future<void> _save() async {
    if (widget.employee == null && widget.employeeUserId == null) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            context.l10n.pleaseSetWorkLocationFirst,
            style: WaUi.body,
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final body = <String, dynamic>{
      'shiftStart': _formatTime(_shiftStart),
      'shiftEnd': _formatTime(_shiftEnd),
      'weekendDays': _weekendDays.toList()..sort(),
      'location': {
        'latitude': _latitude,
        'longitude': _longitude,
        'address': _addressController.text.trim(),
        'radiusMeters': _radiusMeters,
      },
      if (_facePhotoBase64 != null) 'facePhoto': _facePhotoBase64,
    };

    final ApiResponse res;
    if (widget.employee != null) {
      res = await AttendanceRepo().updateEmployee(widget.employee!.id, body);
    } else {
      res = await AttendanceRepo().addEmployee({
        ...body,
        'employeeId': widget.employeeUserId,
      });
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          res.success
              ? (widget.employee != null
                  ? context.l10n.employeeSettingsSaved
                  : context.l10n
                      .invitationSentEmployeeWillBeAddedAfterTheyAccept)
              : (res.message ?? context.l10n.failedToSave),
          style: WaUi.body,
        ),
      ),
    );

    if (res.success) Navigator.pop(context, true);
  }

  Widget _buildMapPreview() {
    if (_latitude == null || _longitude == null) {
      return Container(
        height: 148,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WaUi.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 28,
              color: WaUi.secondaryText.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.locationNotSetYet, style: WaUi.caption),
          ],
        ),
      );
    }

    final point = LatLng(_latitude!, _longitude!);
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WaUi.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.barqody.tapni_app',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: point,
                  radius: _radiusMeters.toDouble(),
                  useRadiusInMeter: true,
                  color: WaUi.buttonDark.withValues(alpha: 0.08),
                  borderColor: WaUi.buttonDark,
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 36,
                  height: 36,
                  child: const Icon(
                    Icons.location_on,
                    color: WaUi.buttonDark,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.employee?.employee.displayName ??
        widget.employeeName ??
        context.l10n.inviteEmployee;
    final dayNames = _dayNames(context);
    final hasFace = _facePhotoBase64 != null ||
        widget.employee?.facePhoto.isNotEmpty == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: WaUi.primaryText,
        title: Text(
          title,
          style: WaUi.headline.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _Section(
                  title: context.l10n.shiftTiming,
                  child: Row(
                    children: [
                      _TimeField(
                        label: context.l10n.start,
                        value: _formatTime(_shiftStart),
                        onTap: () => _pickTime(isStart: true),
                      ),
                      const SizedBox(width: 10),
                      _TimeField(
                        label: context.l10n.end,
                        value: _formatTime(_shiftEnd),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _Section(
                  title: context.l10n.workLocation,
                  child: Column(
                    children: [
                      _buildMapPreview(),
                      const SizedBox(height: 12),
                      CustomAppButton(
                        width: double.infinity,
                        text: context.l10n.pickOnMap,
                        icon: Icons.map_outlined,
                        backgroundColor: WaUi.buttonDark,
                        onTap: _pickOnMap,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: WaUi.primaryButtonHeight,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isLoadingLocation ? null : _useCurrentLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_outlined, size: 18),
                          label: Text(
                            _latitude != null
                                ? context.l10n.updateGPSLocation
                                : context.l10n.useMyLocation,
                            style: WaUi.bodyMedium,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WaUi.primaryText,
                            side: const BorderSide(color: WaUi.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(WaUi.radiusMd),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        style: WaUi.body,
                        decoration: WaUi.fieldDecoration(
                          labelText: context.l10n.addressOptional,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _radiusController,
                        keyboardType: TextInputType.number,
                        style: WaUi.body,
                        onChanged: (_) => setState(() {}),
                        decoration: WaUi.fieldDecoration(
                          labelText: context.l10n.allowedRadiusMeters,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _Section(
                  title: context.l10n.weekendDays,
                  child: Column(
                    children: List.generate(7, (index) {
                      final selected = _weekendDays.contains(index);
                      final isLast = index == 6;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                        child: _DayRow(
                          label: dayNames[index],
                          selected: selected,
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _weekendDays.remove(index);
                              } else {
                                _weekendDays.add(index);
                              }
                            });
                          },
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 22),
                _Section(
                  title: context.l10n.employeeFacePhoto,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _captureFace,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: WaUi.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasFace
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.face_outlined,
                              size: 22,
                              color: hasFace
                                  ? WaUi.navGreen
                                  : WaUi.secondaryText,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hasFace
                                    ? context.l10n.facePhotoAdded
                                    : context.l10n.addFacePhoto,
                                style: WaUi.listTitle,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: WaUi.secondaryText.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: WaUi.divider, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: CustomAppButton(
                  width: double.infinity,
                  text: widget.employee != null
                      ? context.l10n.saveSettings
                      : context.l10n.sendInvitation,
                  icon: widget.employee != null
                      ? Icons.check_rounded
                      : Icons.send_outlined,
                  backgroundColor: WaUi.buttonDark,
                  isLoading: _isSaving,
                  onTap: _save,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: WaUi.label.copyWith(
            color: WaUi.secondaryText,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WaUi.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: WaUi.label.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    color: WaUi.secondaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: WaUi.headline.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: WaUi.secondaryText.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? WaUi.buttonDark : WaUi.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
                size: 22,
                color: selected ? WaUi.buttonDark : WaUi.secondaryText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: WaUi.listTitle.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
