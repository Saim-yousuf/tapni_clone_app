import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/attendance.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/screens/attendance/business/map_location_picker_screen.dart';
import 'package:tapni_app/services/push_notification_service.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';
import 'package:tapni_app/widgets/app_map_tiles.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/face_capture_sheet.dart';

/// Must match [AttendanceDashboardScreen.routeName].
const _kAttendanceDashboardRoute = 'attendance_dashboard';

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

  /// Show save/invite result on a stable scaffold (after this route pops).
  static void showResultSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    showSnackBar(context, message, isError: isError);
  }

  @override
  State<EmployeeSettingsScreen> createState() => _EmployeeSettingsScreenState();
}

class _EmployeeSettingsScreenState extends State<EmployeeSettingsScreen> {
  static const _fieldFill = Color(0xFFF5F5F5);
  static const _labelColor = Color(0xFF8E8E93);
  static const _fieldRadius = 16.0;

  final _addressController = TextEditingController();
  final _radiusController = TextEditingController();

  TimeOfDay _shiftStart = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _shiftEnd = const TimeOfDay(hour: 9, minute: 0);
  final Set<int> _weekendDays = {0, 6}; // Sunday + Saturday
  double? _latitude;
  double? _longitude;
  String? _facePhotoBase64;
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  bool get _isAddFlow => widget.employee == null;

  List<String> get _dayNames => const [
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
      final meters = employee.location.radiusMeters;
      // UI is KM; backend stores meters.
      final km = meters >= 1000
          ? (meters / 1000).toStringAsFixed(
              meters % 1000 == 0 ? 0 : 1,
            )
          : (meters / 1000).toString();
      _radiusController.text = km;
    } else {
      // Add Member: load GPS so the map preview is visible (Figma-style).
      _bootstrapCurrentLocation();
    }
  }

  Future<void> _bootstrapCurrentLocation() async {
    final location = await LocationHelper.getCurrentLocation();
    if (!mounted || location == null) return;
    if (_latitude != null && _longitude != null) return;
    setState(() {
      _latitude = location.latitude;
      _longitude = location.longitude;
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  /// Convert KM input → meters for API. Default 1 km when empty.
  int get _radiusMeters {
    final km = double.tryParse(_radiusController.text.trim());
    if (km == null || km <= 0) return 1000;
    return (km * 1000).round();
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 9, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.hour}:$minute';
  }

  String _formatTimeApi(TimeOfDay time) {
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
      _showSnack(context.l10n.couldNotGetLocationPleaseEnableGPSPermission);
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
      final km = result.radiusMeters / 1000.0;
      final kmText = km == km.roundToDouble()
          ? km.toStringAsFixed(0)
          : km.toStringAsFixed(1);
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _radiusController.text = kmText;
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
      _showSnack(context.l10n.pleaseSetWorkLocationFirst, isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final body = <String, dynamic>{
      'shiftStart': _formatTimeApi(_shiftStart),
      'shiftEnd': _formatTimeApi(_shiftEnd),
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

    if (!res.success) {
      _showSnack(
        res.message?.trim().isNotEmpty == true
            ? res.message!.trim()
            : context.l10n.failedToSave,
        isError: true,
      );
      return;
    }

    final message = widget.employee != null
        ? context.l10n.employeeSettingsSaved
        : context.l10n.invitationSentEmployeeWillBeAddedAfterTheyAccept;

    if (_isAddFlow) {
      // Close Add Member → Scan → Scan-to-invite; land on Team dashboard.
      Navigator.of(context).popUntil(
        (route) =>
            route.settings.name == _kAttendanceDashboardRoute || route.isFirst,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = PushNotificationService.navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          EmployeeSettingsScreen.showResultSnack(ctx, message);
        }
      });
      return;
    }

    Navigator.pop(context, message);
  }

  void _showSnack(String message, {bool isError = false}) {
    EmployeeSettingsScreen.showResultSnack(
      context,
      message,
      isError: isError,
    );
  }

  String _screenTitle(BuildContext context) {
    if (_isAddFlow) return 'Add Member';
    return widget.employee!.employee.displayName;
  }

  static const _fallbackPoint = LatLng(31.5204, 74.3587); // Lahore

  Widget _buildMapPreview() {
    final hasLocation = _latitude != null && _longitude != null;
    final point = hasLocation
        ? LatLng(_latitude!, _longitude!)
        : _fallbackPoint;
    final radiusM = _radiusMeters.toDouble();

    return Material(
      color: _fieldFill,
      borderRadius: BorderRadius.circular(_fieldRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _pickOnMap,
        child: SizedBox(
          height: 168,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: FlutterMap(
                  key: ValueKey(
                    'preview-${point.latitude.toStringAsFixed(5)}-'
                    '${point.longitude.toStringAsFixed(5)}-$radiusM',
                  ),
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: hasLocation ? 15 : 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    AppMapTiles.street(),
                    if (hasLocation) ...[
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: point,
                            radius: radiusM,
                            useRadiusInMeter: true,
                            color: const Color(0xFFE53935)
                                .withValues(alpha: 0.15),
                            borderColor: const Color(0xFFE53935),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFE53935),
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!hasLocation)
                ColoredBox(
                  color: Colors.white.withValues(alpha: 0.55),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 28,
                          color: _labelColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.locationNotSetYet,
                          style: AppFonts.textStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _labelColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to pick on map',
                          style: AppFonts.textStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Tap to edit',
                      style: AppFonts.textStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final hasFace = _facePhotoBase64 != null ||
        widget.employee?.facePhoto.isNotEmpty == true;
    final saveLabel = _isAddFlow ? 'Save' : context.l10n.saveSettings;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: _screenTitle(context)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(m.s(20), 0, m.s(20), m.v(24)),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LabeledTapField(
                          label: 'START SHIFT',
                          value: _formatTime(_shiftStart),
                          onTap: () => _pickTime(isStart: true),
                        ),
                      ),
                      SizedBox(width: m.s(12)),
                      Expanded(
                        child: _LabeledTapField(
                          label: 'END SHIFT',
                          value: _formatTime(_shiftEnd),
                          onTap: () => _pickTime(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: m.v(22)),
                  const _SectionLabel('LOCATION'),
                  SizedBox(height: m.v(10)),
                  _buildMapPreview(),
                  SizedBox(height: m.v(12)),
                  Row(
                    children: [
                      _MapActionButton(
                        label: 'Pick On Map',
                        filled: false,
                        onPressed: _pickOnMap,
                      ),
                      SizedBox(width: m.s(8)),
                      _MapActionButton(
                        label: 'Current Location',
                        filled: true,
                        loading: _isLoadingLocation,
                        onPressed:
                            _isLoadingLocation ? null : _useCurrentLocation,
                      ),
                    ],
                  ),
                  SizedBox(height: m.v(18)),
                  const _SectionLabel('ADDRESS'),
                  SizedBox(height: m.v(8)),
                  _FilledTextField(
                    controller: _addressController,
                    hint: 'e.g. 123 Main Street, City',
                  ),
                  SizedBox(height: m.v(14)),
                  const _SectionLabel('RADIUS (KM)'),
                  SizedBox(height: m.v(8)),
                  _FilledTextField(
                    controller: _radiusController,
                    hint: 'e.g. 5',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: m.v(22)),
                  const _SectionLabel('WEEKEND DAYS'),
                  SizedBox(height: m.v(12)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final selected = _weekendDays.contains(index);
                      return _WeekendDayChip(
                        label: _dayNames[index],
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
                  // Face photo only when editing an existing employee.
                  if (!_isAddFlow) ...[
                    SizedBox(height: m.v(22)),
                    const _SectionLabel('EMPLOYEE FACE PHOTO'),
                    SizedBox(height: m.v(10)),
                    Material(
                      color: _fieldFill,
                      borderRadius: BorderRadius.circular(_fieldRadius),
                      child: InkWell(
                        onTap: _captureFace,
                        borderRadius: BorderRadius.circular(_fieldRadius),
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
                                      : Icons.person_outline,
                                  size: 22,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  hasFace
                                      ? context.l10n.facePhotoAdded
                                      : context.l10n.addFacePhoto,
                                  style: AppFonts.textStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: _labelColor.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(m.s(20), m.v(8), m.s(20), m.v(16)),
              child: PillButton(
                label: _isSaving ? '…' : saveLabel,
                enabled: !_isSaving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.textStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _EmployeeSettingsScreenState._labelColor,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _LabeledTapField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LabeledTapField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        Material(
          color: _EmployeeSettingsScreenState._fieldFill,
          borderRadius: BorderRadius.circular(
            _EmployeeSettingsScreenState._fieldRadius,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(
              _EmployeeSettingsScreenState._fieldRadius,
            ),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    value,
                    style: AppFonts.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _FilledTextField({
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
      style: AppFonts.textStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      cursorColor: Colors.black,
      decoration: InputDecoration(
        filled: true,
        fillColor: _EmployeeSettingsScreenState._fieldFill,
        hintText: hint,
        hintStyle: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: _EmployeeSettingsScreenState._labelColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            _EmployeeSettingsScreenState._fieldRadius,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            _EmployeeSettingsScreenState._fieldRadius,
          ),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            _EmployeeSettingsScreenState._fieldRadius,
          ),
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

class _MapActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool loading;
  final VoidCallback? onPressed;

  const _MapActionButton({
    required this.label,
    required this.filled,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: filled ? Colors.white : Colors.black,
            ),
          )
        : Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : Colors.black,
            ),
          );

    return Container(
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black.withValues(alpha: 0.35),
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: const StadiumBorder(),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black, width: 1),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
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
                    color: _EmployeeSettingsScreenState._labelColor
                        .withValues(alpha: 0.7),
                  ),
                ),
              Text(
                label,
                style: AppFonts.textStyle(
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
