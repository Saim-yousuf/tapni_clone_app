import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/map_location_picker_screen.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/face_capture_sheet.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
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

  static const _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
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
    if (parts.length < 2) return TimeOfDay(hour: 9, minute: 0);
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
          content: Text(context.l10n.couldNotGetLocationPleaseEnableGPSPermission),
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
        SnackBar(content: Text(context.l10n.pleaseSetWorkLocationFirst)),
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
        content: Text(
          res.success
              ? (widget.employee != null
                  ? context.l10n.employeeSettingsSaved
                  : context.l10n.invitationSentEmployeeWillBeAddedAfterTheyAccept)
              : (res.message ?? context.l10n.failedToSave),
        ),
      ),
    );

    if (res.success) Navigator.pop(context, true);
  }

  Widget _buildMapPreview() {
    if (_latitude == null || _longitude == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: AttendanceUi.thickCard.copyWith(
          color: Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 40, color: WaUi.promoIconFg),
            SizedBox(height: 10),
            Text(context.l10n.locationNotSetYet, style: AttendanceUi.bodyMuted),
          ],
        ),
      );
    }

    final point = LatLng(_latitude!, _longitude!);
    return Container(
      height: 200,
      decoration: AttendanceUi.thickCard,
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
                  color: Colors.black.withValues(alpha: 0.12),
                  borderColor: Colors.black,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.black,
                    size: 40,
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

    return Scaffold(
      backgroundColor: AttendanceUi.scaffoldBg,
      appBar: AttendanceUi.appBar(title),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          AttendanceUi.sectionHeader(context.l10n.shiftTiming),
          Row(
            children: [
              AttendanceUi.timeChip(
                label: context.l10n.start,
                value: _formatTime(_shiftStart),
                onTap: () => _pickTime(isStart: true),
              ),
              SizedBox(width: 12),
              AttendanceUi.timeChip(
                label: context.l10n.end,
                value: _formatTime(_shiftEnd),
                onTap: () => _pickTime(isStart: false),
              ),
            ],
          ),
          SizedBox(height: 28),
          AttendanceUi.sectionHeader(context.l10n.workLocation),
          _buildMapPreview(),
          SizedBox(height: 14),
          AttendanceUi.primaryButton(
            label: context.l10n.pickOnMap,
            icon: Icons.map_outlined,
            onPressed: _pickOnMap,
          ),
          SizedBox(height: 12),
          AttendanceUi.secondaryButton(
            label: _latitude != null ? context.l10n.updateGPSLocation : context.l10n.useMyLocation,
            icon: Icons.my_location,
            loading: _isLoadingLocation,
            onPressed: _useCurrentLocation,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _addressController,
            style: AttendanceUi.body,
            decoration: AttendanceUi.inputDecoration(context.l10n.addressOptional),
          ),
          SizedBox(height: 14),
          TextField(
            controller: _radiusController,
            keyboardType: TextInputType.number,
            style: AttendanceUi.body,
            onChanged: (_) => setState(() {}),
            decoration: AttendanceUi.inputDecoration(context.l10n.allowedRadiusMeters),
          ),
          SizedBox(height: 28),
          AttendanceUi.sectionHeader(context.l10n.weekendDays),
          ...List.generate(7, (index) {
            final selected = _weekendDays.contains(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _weekendDays.remove(index);
                    } else {
                      _weekendDays.add(index);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(AttendanceUi.radius),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: selected
                      ? AttendanceUi.thickCardFilled()
                      : AttendanceUi.thickCard,
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: selected ? Colors.white : Colors.black,
                        size: 28,
                      ),
                      SizedBox(width: 14),
                      Text(
                        _dayNames[index],
                        style: AttendanceUi.cardTitle.copyWith(
                          color: selected ? Colors.white : Colors.black,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 12),
          AttendanceUi.secondaryButton(
            label: _facePhotoBase64 != null ||
                    widget.employee?.facePhoto.isNotEmpty == true
                ? context.l10n.facePhotoAdded
                : context.l10n.addFacePhoto,
            icon: Icons.face_retouching_natural,
            onPressed: _captureFace,
          ),
          SizedBox(height: 24),
          AttendanceUi.primaryButton(
            label: widget.employee != null ? context.l10n.saveSettings : context.l10n.sendInvitation,
            icon: widget.employee != null
                ? Icons.save_outlined
                : Icons.send_outlined,
            loading: _isSaving,
            onPressed: _save,
            height: 68,
          ),
        ],
      ),
    );
  }
}
