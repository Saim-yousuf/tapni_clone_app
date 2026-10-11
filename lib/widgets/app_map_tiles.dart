import 'package:flutter_map/flutter_map.dart';

/// Free street-map tiles (no API key).
///
/// Uses Esri World Street Map — works reliably on mobile without keys.
/// OSM.org often blocks apps; some Carto paths now show "API key required".
class AppMapTiles {
  AppMapTiles._();

  static TileLayer street({double maxZoom = 19}) {
    return TileLayer(
      // Esri tile path is {z}/{y}/{x} (y before x).
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
      userAgentPackageName: 'com.barqody.tapni_app',
      maxZoom: maxZoom,
    );
  }
}
