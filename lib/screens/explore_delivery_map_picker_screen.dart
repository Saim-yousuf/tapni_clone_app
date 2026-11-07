import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/utils/location_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/app_map_tiles.dart';
import 'package:tapni_app/widgets/app_toast.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class DeliveryMapPickResult {
  final double latitude;
  final double longitude;
  final String label;

  const DeliveryMapPickResult({
    required this.latitude,
    required this.longitude,
    this.label = '',
  });
}

/// Delivery pin picker — search address, tap map to drop pin. No radius.
class ExploreDeliveryMapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialQuery;

  const ExploreDeliveryMapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialQuery,
  });

  static Future<DeliveryMapPickResult?> open(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String? initialQuery,
  }) {
    return Navigator.push<DeliveryMapPickResult>(
      context,
      AppPageRoute(
        builder: (_) => ExploreDeliveryMapPickerScreen(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          initialQuery: initialQuery,
        ),
      ),
    );
  }

  @override
  State<ExploreDeliveryMapPickerScreen> createState() =>
      _ExploreDeliveryMapPickerScreenState();
}

class _SearchHit {
  final String title;
  final String subtitle;
  final LatLng point;

  const _SearchHit({
    required this.title,
    required this.subtitle,
    required this.point,
  });
}

class _ExploreDeliveryMapPickerScreenState
    extends State<ExploreDeliveryMapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  static const _defaultPoint = LatLng(31.5204, 74.3587);

  late LatLng _selectedPoint;
  String _selectedLabel = '';
  bool _loading = true;
  bool _locating = false;
  bool _searching = false;
  List<_SearchHit> _hits = const [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedPoint = _initialPoint();
    final q = (widget.initialQuery ?? '').trim();
    if (q.isNotEmpty && !q.toLowerCase().startsWith('pin ')) {
      _searchCtrl.text = q;
      _selectedLabel = q;
    }
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  LatLng _initialPoint() {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      return LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    return _defaultPoint;
  }

  Future<void> _bootstrap() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final location = await LocationHelper.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (location != null) {
        _selectedPoint = LatLng(location.latitude, location.longitude);
      }
    });
    _moveTo(_selectedPoint, 16);
  }

  void _moveTo(LatLng point, double zoom) {
    try {
      _mapController.move(point, zoom);
    } catch (_) {}
  }

  /// Short readable address: "Street, Area, City, Region"
  static String formatDisplayName(String display) {
    final parts = display
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return display.trim();
    final take = parts.length >= 4 ? 4 : parts.length;
    return parts.take(take).join(', ');
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    final location = await LocationHelper.getCurrentLocation();
    if (!mounted) return;
    if (location == null) {
      setState(() => _locating = false);
      showAppToast(
        context,
        'Location permission required',
        kind: AppToastKind.warning,
      );
      return;
    }
    final point = LatLng(location.latitude, location.longitude);
    setState(() {
      _selectedPoint = point;
      _selectedLabel = 'Finding address…';
      _hits = const [];
      _searchFocus.unfocus();
    });
    _moveTo(point, 16.5);
    await _reverseLabel(point, fillSearch: true);
    if (mounted) setState(() => _locating = false);
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() {
      _selectedPoint = point;
      _selectedLabel = 'Finding address…';
      _hits = const [];
      _searchFocus.unfocus();
    });
    _reverseLabel(point, fillSearch: true);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 3) {
      setState(() {
        _hits = const [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 420), () {
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() => _searching = true);
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '6',
        },
      );
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'BarQodyDeliveryMap/1.0',
          'Accept': 'application/json',
        },
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _searching = false;
          _hits = const [];
        });
        return;
      }
      final raw = jsonDecode(res.body);
      if (raw is! List) {
        setState(() {
          _searching = false;
          _hits = const [];
        });
        return;
      }
      final hits = <_SearchHit>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final lat = double.tryParse('${item['lat']}');
        final lon = double.tryParse('${item['lon']}');
        if (lat == null || lon == null) continue;
        final display = '${item['display_name'] ?? ''}'.trim();
        if (display.isEmpty) continue;
        final parts = display.split(',');
        final title = parts.first.trim();
        final subtitle = parts.length > 1
            ? parts.skip(1).take(3).map((e) => e.trim()).join(', ')
            : '';
        hits.add(
          _SearchHit(
            title: title,
            subtitle: subtitle,
            point: LatLng(lat, lon),
          ),
        );
      }
      setState(() {
        _hits = hits;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _hits = const [];
      });
    }
  }

  Future<void> _reverseLabel(
    LatLng point, {
    bool fillSearch = false,
  }) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'lat': '${point.latitude}',
          'lon': '${point.longitude}',
          'format': 'json',
          'addressdetails': '1',
        },
      );
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'BarQodyDeliveryMap/1.0',
          'Accept': 'application/json',
        },
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _selectedLabel =
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
          if (fillSearch) _searchCtrl.text = _selectedLabel;
        });
        return;
      }
      final raw = jsonDecode(res.body);
      if (raw is! Map) return;
      final display = '${raw['display_name'] ?? ''}'.trim();
      final formatted = display.isEmpty
          ? '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}'
          : formatDisplayName(display);
      setState(() {
        _selectedLabel = formatted;
        if (fillSearch) _searchCtrl.text = formatted;
      });
    } catch (_) {
      if (!mounted) return;
      final fallback =
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      setState(() {
        _selectedLabel = fallback;
        if (fillSearch) _searchCtrl.text = fallback;
      });
    }
  }

  void _selectHit(_SearchHit hit) {
    final formatted = [
      hit.title,
      if (hit.subtitle.isNotEmpty) hit.subtitle,
    ].join(', ');
    setState(() {
      _selectedPoint = hit.point;
      _selectedLabel = formatted;
      _searchCtrl.text = formatted;
      _hits = const [];
      _searchFocus.unfocus();
    });
    _moveTo(hit.point, 16.5);
  }

  void _confirm() {
    final label = _selectedLabel.trim().isNotEmpty
        ? _selectedLabel.trim()
        : _searchCtrl.text.trim();
    Navigator.pop(
      context,
      DeliveryMapPickResult(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
        label: label,
      ),
    );
  }

  void _zoomBy(double delta) {
    try {
      final cam = _mapController.camera;
      final next = (cam.zoom + delta).clamp(3.0, 19.0);
      _mapController.move(cam.center, next);
    } catch (_) {}
  }

  Widget _mapRoundBtn({
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Pick location'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BarqodyChrome.sidePad,
                0,
                BarqodyChrome.sidePad,
                10,
              ),
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) {
                    setState(() {});
                    _onSearchChanged(v);
                  },
                  onSubmitted: (v) {
                    final q = v.trim();
                    if (q.length >= 3) _runSearch(q);
                  },
                  style: WaUi.body.copyWith(fontSize: 15, color: Colors.black),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: BarqodyChrome.searchBg,
                    hintText: 'Search an address',
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
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            ),
                          )
                        : (_searchCtrl.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _hits = const []);
                                  _onSearchChanged('');
                                },
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: BarqodyChrome.secondaryText,
                                ),
                              )
                            : null),
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
                      vertical: 0,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final resultsMaxH =
                            (constraints.maxHeight * 0.55).clamp(160.0, 320.0);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: _selectedPoint,
                                          initialZoom: 15.5,
                                          onTap: _onMapTap,
                                        ),
                                        children: [
                                          AppMapTiles.street(),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: _selectedPoint,
                                                width: 48,
                                                height: 48,
                                                alignment: Alignment.topCenter,
                                                child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.black,
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
                                        child: Column(
                                          children: [
                                            _mapRoundBtn(
                                              onTap: _locating
                                                  ? null
                                                  : _goToMyLocation,
                                              child: _locating
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.black,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .my_location_rounded,
                                                      color: Colors.black,
                                                      size: 22,
                                                    ),
                                            ),
                                            const SizedBox(height: 10),
                                            _mapRoundBtn(
                                              onTap: () => _zoomBy(1),
                                              child: const Icon(
                                                Icons.add,
                                                color: Colors.black,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _mapRoundBtn(
                                              onTap: () => _zoomBy(-1),
                                              child: const Icon(
                                                Icons.remove,
                                                color: Colors.black,
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        left: 12,
                                        right: 12,
                                        bottom: 12,
                                        child: Container(
                                          padding: const EdgeInsets.fromLTRB(
                                            14,
                                            12,
                                            14,
                                            12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.96),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.08),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            _selectedLabel.trim().isNotEmpty
                                                ? _selectedLabel
                                                : 'Tap the map to drop a pin',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: WaUi.body.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_hits.isNotEmpty)
                              Positioned(
                                top: 0,
                                left: BarqodyChrome.sidePad,
                                right: BarqodyChrome.sidePad,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 8,
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(16),
                                  clipBehavior: Clip.antiAlias,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: resultsMaxH,
                                    ),
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      itemCount: _hits.length,
                                      separatorBuilder: (_, _) =>
                                          const Divider(
                                        height: 1,
                                        color: BarqodyChrome.divider,
                                      ),
                                      itemBuilder: (context, i) {
                                        final hit = _hits[i];
                                        return InkWell(
                                          onTap: () => _selectHit(hit),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              14,
                                              12,
                                              14,
                                              12,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 2),
                                                  child: Icon(
                                                    Icons.place_outlined,
                                                    color: Colors.black87,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        hit.title,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: WaUi.body
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      if (hit.subtitle
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          hit.subtitle,
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style: WaUi.label
                                                              .copyWith(
                                                            color: BarqodyChrome
                                                                .secondaryText,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                BarqodyChrome.sidePad,
                14,
                BarqodyChrome.sidePad,
                12 + bottomInset,
              ),
              child: PillButton(
                label: 'Confirm location',
                onPressed: _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
