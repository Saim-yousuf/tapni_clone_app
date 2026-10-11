import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/utils/app_fonts.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/widgets/app_map_tiles.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class MapLocationResult {
  final double latitude;
  final double longitude;
  final int radiusMeters;

  const MapLocationResult({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
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
    this.radiusMeters = 1000,
  });

  static Future<MapLocationResult?> open(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    int radiusMeters = 1000,
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

  /// Slider range in kilometers.
  static const double _minKm = 0.1;
  static const double _maxKm = 10.0;

  late LatLng _selectedPoint;
  late double _radiusKm;
  bool _isLoading = true;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _selectedPoint = _initialPoint();
    final meters = widget.radiusMeters.clamp(100, 10000);
    _radiusKm = (meters / 1000).clamp(_minKm, _maxKm);
    _initMapCenter();
  }

  LatLng _initialPoint() {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      return LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    return _defaultPoint;
  }

  int get _radiusMeters => (_radiusKm * 1000).round();

  String get _radiusLabel {
    if (_radiusKm < 1) {
      return '$_radiusMeters m';
    }
    final text = _radiusKm == _radiusKm.roundToDouble()
        ? _radiusKm.toStringAsFixed(0)
        : _radiusKm.toStringAsFixed(1);
    return '$text km';
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

    try {
      _mapController.move(_selectedPoint, _zoomForRadius());
    } catch (_) {}
  }

  double _zoomForRadius() {
    if (_radiusKm <= 0.3) return 17;
    if (_radiusKm <= 0.8) return 16;
    if (_radiusKm <= 2) return 15;
    if (_radiusKm <= 5) return 14;
    return 13;
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    final location = await LocationHelper.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLocating = false);

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.l10n.locationPermissionRequired),
        ),
      );
      return;
    }

    final point = LatLng(location.latitude, location.longitude);
    setState(() => _selectedPoint = point);
    _mapController.move(point, _zoomForRadius());
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedPoint = point);
  }

  void _onRadiusChanged(double km) {
    setState(() => _radiusKm = km);
    // Keep the radius circle readable on screen while dragging.
    try {
      _mapController.move(_selectedPoint, _zoomForRadius());
    } catch (_) {}
  }

  void _confirm() {
    Navigator.pop(
      context,
      MapLocationResult(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
        radiusMeters: _radiusMeters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(title: context.l10n.pickLocation),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'Tap the map to place the pin. Drag the slider to set check-in radius.',
                style: AppFonts.textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: BarqodyChrome.secondaryText,
                  height: 1.35,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedPoint,
                                initialZoom: _zoomForRadius(),
                                onTap: _onMapTap,
                              ),
                              children: [
                                AppMapTiles.street(),
                                CircleLayer(
                                  circles: [
                                    CircleMarker(
                                      point: _selectedPoint,
                                      radius: _radiusMeters.toDouble(),
                                      useRadiusInMeter: true,
                                      color: const Color(0xFFE53935)
                                          .withValues(alpha: 0.18),
                                      borderColor: const Color(0xFFE53935),
                                      borderStrokeWidth: 2.5,
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedPoint,
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.topCenter,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Color(0xFFE53935),
                                        size: 44,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                elevation: 2,
                                shadowColor:
                                    Colors.black.withValues(alpha: 0.15),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _isLocating ? null : _goToMyLocation,
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: _isLocating
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.my_location_rounded,
                                            color: Colors.black,
                                            size: 22,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Radius $_radiusLabel',
                                  style: AppFonts.textStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'RADIUS',
                        style: AppFonts.textStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: BarqodyChrome.secondaryText,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _radiusLabel,
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.black,
                      inactiveTrackColor: const Color(0xFFE5E5EA),
                      thumbColor: Colors.black,
                      overlayColor: Colors.black.withValues(alpha: 0.08),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _radiusKm,
                      min: _minKm,
                      max: _maxKm,
                      divisions: 99,
                      onChanged: _onRadiusChanged,
                    ),
                  ),
                  Text(
                    '${_selectedPoint.latitude.toStringAsFixed(5)}, '
                    '${_selectedPoint.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: context.l10n.confirmLocation,
                    onPressed: _confirm,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
