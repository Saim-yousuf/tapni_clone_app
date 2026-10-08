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
import 'package:tapni_app/widgets/barqody_chrome.dart';
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

  String _screenTitle(BuildContext context) {
    if (widget.employee != null) {
      return widget.employee!.employee.displayName;
    }
    if (widget.employeeName != null && widget.employeeName!.isNotEmpty) {
      return widget.employeeName!;
    }
    return 'Add Member';
  }

  Widget _buildMapPreview() {
    if (_latitude == null || _longitude == null) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BarqodyChrome.fieldFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/png/map.png',
              width: 40,
              height: 40,
              color: BarqodyChrome.secondaryText.withValues(alpha: 0.5),
              errorBuilder: (_, _, _) => Icon(
                Icons.map_outlined,
                size: 32,
                color: BarqodyChrome.secondaryText.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.locationNotSetYet,
              style: WaUi.body.copyWith(
                fontSize: 13,
                color: BarqodyChrome.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    final point = LatLng(_latitude!, _longitude!);
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: BarqodyChrome.fieldFill,
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
                  color: Colors.black.withValues(alpha: 0.08),
                  borderColor: Colors.black,
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
                    color: Colors.black,
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
    final dayNames = _dayNames(context);
    final hasFace = _facePhotoBase64 != null ||
        widget.employee?.facePhoto.isNotEmpty == true;
    final saveLabel = widget.employee != null
        ? context.l10n.saveSettings
        : context.l10n.sendInvitation;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: _screenTitle(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  BarqodyChrome.sidePad,
                  12,
                  BarqodyChrome.sidePad,
                  24,
                ),
                children: [
                  Row(
                    children: [
                      _ShiftTimeField(
                        label: '${context.l10n.start.toUpperCase()} SHIFT',
                        value: _formatTime(_shiftStart),
                        onTap: () => _pickTime(isStart: true),
                      ),
                      const SizedBox(width: 10),
                      _ShiftTimeField(
                        label: '${context.l10n.end.toUpperCase()} SHIFT',
                        value: _formatTime(_shiftEnd),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _BarqodySectionLabel(context.l10n.workLocation.toUpperCase()),
                  const SizedBox(height: 10),
                  _buildMapPreview(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactPillButton(
                          label: context.l10n.pickOnMap,
                          filled: false,
                          onPressed: _pickOnMap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CompactPillButton(
                          label: _latitude != null
                              ? context.l10n.updateGPSLocation
                              : context.l10n.useMyLocation,
                          filled: true,
                          loading: _isLoadingLocation,
                          onPressed:
                              _isLoadingLocation ? null : _useCurrentLocation,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BarqodySectionLabel('ADDRESS'),
                  const SizedBox(height: 8),
                  _BarqodyFilledField(
                    controller: _addressController,
                    hint: context.l10n.addressOptional,
                  ),
                  const SizedBox(height: 14),
                  _BarqodySectionLabel('RADIUS (KM)'),
                  const SizedBox(height: 8),
                  _BarqodyFilledField(
                    controller: _radiusController,
                    hint: context.l10n.allowedRadiusMeters,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  _BarqodySectionLabel(
                    context.l10n.weekendDays.toUpperCase(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final selected = _weekendDays.contains(index);
                      return _WeekendDayChip(
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
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  _BarqodySectionLabel(
                    context.l10n.employeeFacePhoto.toUpperCase(),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: BarqodyChrome.fieldFill,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _captureFace,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              hasFace
                                  ? 'assets/images/png/check-icon-1.png'
                                  : 'assets/images/png/person-icon.png',
                              width: 22,
                              height: 22,
                              errorBuilder: (_, _, _) => Icon(
                                hasFace
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.face_outlined,
                                size: 22,
                                color: hasFace
                                    ? Colors.black
                                    : BarqodyChrome.secondaryText,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hasFace
                                    ? context.l10n.facePhotoAdded
                                    : context.l10n.addFacePhoto,
                                style: WaUi.body.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: BarqodyChrome.secondaryText
                                  .withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BarqodyChrome.sidePad,
                8,
                BarqodyChrome.sidePad,
                12,
              ),
              child: SizedBox(
                width: double.infinity,
                height: WaUi.primaryButtonHeight,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.black.withValues(alpha: 0.35),
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          saveLabel,
                          style: WaUi.promoButton.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarqodySectionLabel extends StatelessWidget {
  final String text;

  const _BarqodySectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: WaUi.label.copyWith(
        fontSize: 11,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w600,
        color: BarqodyChrome.secondaryText,
      ),
    );
  }
}

class _ShiftTimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ShiftTimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WaUi.label.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                    color: BarqodyChrome.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: WaUi.toolsTitleOf(
                    size: 22,
                    weight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarqodyFilledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _BarqodyFilledField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: WaUi.body.copyWith(fontSize: 15, color: Colors.black),
      cursorColor: Colors.black,
      decoration: InputDecoration(
        filled: true,
        fillColor: BarqodyChrome.fieldFill,
        hintText: hint,
        hintStyle: WaUi.body.copyWith(
          fontSize: 15,
          color: BarqodyChrome.secondaryText,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _CompactPillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool loading;
  final VoidCallback? onPressed;

  const _CompactPillButton({
    required this.label,
    required this.filled,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : Colors.black,
            ),
          );

    if (filled) {
      return SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.black.withValues(alpha: 0.35),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: const StadiumBorder(),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
        ),
        child: child,
      ),
    );
  }
}

class _WeekendDayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WeekendDayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.white,
      elevation: selected ? 0 : 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? Colors.black : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Image.asset(
                    'assets/images/png/check-icon-1.png',
                    width: 14,
                    height: 14,
                    color: Colors.white,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_box_outline_blank,
                    size: 18,
                    color: BarqodyChrome.secondaryText.withValues(alpha: 0.7),
                  ),
                ),
              Text(
                label,
                style: WaUi.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
