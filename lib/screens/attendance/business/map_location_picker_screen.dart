import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class MapLocationResult {
  final double latitude;
  final double longitude;

  const MapLocationResult({
    required this.latitude,
    required this.longitude,
  });
}

class MapLocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final int radiusMeters;

  const MapLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.radiusMeters = 100,
  });

  static Future<MapLocationResult?> open(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    int radiusMeters = 100,
  }) {
    return Navigator.push<MapLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          radiusMeters: radiusMeters,
        ),
      ),
    );
  }

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final MapController _mapController = MapController();
  static const _defaultPoint = LatLng(31.5204, 74.3587);

  late LatLng _selectedPoint;
  bool _isLoading = true;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _selectedPoint = _initialPoint();
    _initMapCenter();
  }

  LatLng _initialPoint() {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      return LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    return _defaultPoint;
  }

  Future<void> _initMapCenter() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      setState(() => _isLoading = false);
      return;
    }

    final location = await LocationHelper.getCurrentLocation();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (location != null) {
        _selectedPoint = LatLng(location.latitude, location.longitude);
      }
    });

    _mapController.move(_selectedPoint, 16);
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    final location = await LocationHelper.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLocating = false);

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.locationPermissionRequired)),
      );
      return;
    }

    final point = LatLng(location.latitude, location.longitude);
    setState(() => _selectedPoint = point);
    _mapController.move(point, 16);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedPoint = point);
  }

  void _confirm() {
    Navigator.pop(
      context,
      MapLocationResult(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AttendanceUi.scaffoldBg,
      appBar: AttendanceUi.appBar(context.l10n.pickLocation),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    context.l10n.tapOnTheMapOrUseYourCurrentLocation,
                    style: AttendanceUi.body,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: AttendanceUi.thickCard,
                      clipBehavior: Clip.antiAlias,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedPoint,
                          initialZoom: 16,
                          onTap: _onMapTap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.barqody.tapni_app',
                          ),
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _selectedPoint,
                                radius: widget.radiusMeters.toDouble(),
                                useRadiusInMeter: true,
                                color: Colors.black.withValues(alpha: 0.12),
                                borderColor: Colors.black,
                                borderStrokeWidth: 3,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedPoint,
                                width: 56,
                                height: 56,
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.black,
                                  size: 48,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: AttendanceUi.thickCard,
                        child: Text(
                          '${context.l10n.lat}: ${_selectedPoint.latitude.toStringAsFixed(5)}\n'
                          '${context.l10n.lng}: ${_selectedPoint.longitude.toStringAsFixed(5)}',
                          style: AttendanceUi.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      AttendanceUi.secondaryButton(
                        label: context.l10n.myLocation,
                        icon: Icons.my_location,
                        loading: _isLocating,
                        onPressed: _goToMyLocation,
                      ),
                      SizedBox(height: 12),
                      AttendanceUi.primaryButton(
                        label: context.l10n.confirmLocation,
                        icon: Icons.check_rounded,
                        onPressed: _confirm,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
