import 'dart:convert';
import 'dart:math' as math;

/// Layer kinds supported on the invitation canvas (Canva-style).
enum DesignLayerType { text, image, logo, iconField, qr, shape, ornament }

enum DesignTextAlign { left, center, right }

/// A single editable element on the invitation design canvas.
/// Positions/sizes are normalized 0–1 relative to canvas size.
class DesignLayer {
  String id;
  DesignLayerType type;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  int zIndex;
  bool locked;
  bool visible;

  /// Semantic key used to sync with invitation fields
  /// (title, message, venue, address, date, time, host, custom…).
  String fieldKey;

  // Text
  String text;
  String fontFamily;
  double fontSize;
  String color;
  DesignTextAlign align;
  bool bold;
  bool italic;

  // Image / logo (url or base64)
  String imageSrc;
  String boxFit; // cover | contain | fill

  // Icon field
  String iconName; // calendar | clock | location | custom

  // QR
  String qrData;
  String qrColor;

  // Shape / ornament
  String shape; // rect | circle | line | diamond | divider
  double opacity;
  double borderWidth;
  String borderColor;
  double borderRadius;

  DesignLayer({
    required this.id,
    required this.type,
    this.x = 0.1,
    this.y = 0.1,
    this.width = 0.8,
    this.height = 0.08,
    this.rotation = 0,
    this.zIndex = 0,
    this.locked = false,
    this.visible = true,
    this.fieldKey = '',
    this.text = '',
    this.fontFamily = 'cairo',
    this.fontSize = 0.045,
    this.color = '#FFFFFF',
    this.align = DesignTextAlign.center,
    this.bold = false,
    this.italic = false,
    this.imageSrc = '',
    this.boxFit = 'cover',
    this.iconName = 'calendar',
    this.qrData = '',
    this.qrColor = '#000000',
    this.shape = 'rect',
    this.opacity = 1,
    this.borderWidth = 0,
    this.borderColor = '#FFFFFF',
    this.borderRadius = 0,
  });

  DesignLayer copyWith({
    String? id,
    DesignLayerType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? zIndex,
    bool? locked,
    bool? visible,
    String? fieldKey,
    String? text,
    String? fontFamily,
    double? fontSize,
    String? color,
    DesignTextAlign? align,
    bool? bold,
    bool? italic,
    String? imageSrc,
    String? boxFit,
    String? iconName,
    String? qrData,
    String? qrColor,
    String? shape,
    double? opacity,
    double? borderWidth,
    String? borderColor,
    double? borderRadius,
  }) {
    return DesignLayer(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      locked: locked ?? this.locked,
      visible: visible ?? this.visible,
      fieldKey: fieldKey ?? this.fieldKey,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      align: align ?? this.align,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      imageSrc: imageSrc ?? this.imageSrc,
      boxFit: boxFit ?? this.boxFit,
      iconName: iconName ?? this.iconName,
      qrData: qrData ?? this.qrData,
      qrColor: qrColor ?? this.qrColor,
      shape: shape ?? this.shape,
      opacity: opacity ?? this.opacity,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'zIndex': zIndex,
        'locked': locked,
        'visible': visible,
        'fieldKey': fieldKey,
        'text': text,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'color': color,
        'align': align.name,
        'bold': bold,
        'italic': italic,
        'imageSrc': imageSrc,
        'boxFit': boxFit,
        'iconName': iconName,
        'qrData': qrData,
        'qrColor': qrColor,
        'shape': shape,
        'opacity': opacity,
        'borderWidth': borderWidth,
        'borderColor': borderColor,
        'borderRadius': borderRadius,
      };

  factory DesignLayer.fromJson(Map<String, dynamic> json) {
    return DesignLayer(
      id: (json['id'] ?? '').toString(),
      type: _parseType(json['type']?.toString()),
      x: _d(json['x'], 0.1),
      y: _d(json['y'], 0.1),
      width: _d(json['width'], 0.8),
      height: _d(json['height'], 0.08),
      rotation: _d(json['rotation'], 0),
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      locked: json['locked'] == true,
      visible: json['visible'] != false,
      fieldKey: json['fieldKey'] as String? ?? '',
      text: json['text'] as String? ?? '',
      fontFamily: json['fontFamily'] as String? ?? 'cairo',
      fontSize: _d(json['fontSize'], 0.045),
      color: json['color'] as String? ?? '#FFFFFF',
      align: _parseAlign(json['align']?.toString()),
      bold: json['bold'] == true,
      italic: json['italic'] == true,
      imageSrc: json['imageSrc'] as String? ?? '',
      boxFit: json['boxFit'] as String? ?? 'cover',
      iconName: json['iconName'] as String? ?? 'calendar',
      qrData: json['qrData'] as String? ?? '',
      qrColor: json['qrColor'] as String? ?? '#000000',
      shape: json['shape'] as String? ?? 'rect',
      opacity: _d(json['opacity'], 1),
      borderWidth: _d(json['borderWidth'], 0),
      borderColor: json['borderColor'] as String? ?? '#FFFFFF',
      borderRadius: _d(json['borderRadius'], 0),
    );
  }

  static DesignLayerType _parseType(String? v) {
    return DesignLayerType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => DesignLayerType.text,
    );
  }

  static DesignTextAlign _parseAlign(String? v) {
    return DesignTextAlign.values.firstWhere(
      (e) => e.name == v,
      orElse: () => DesignTextAlign.center,
    );
  }

  static double _d(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }
}

/// Full invitation design document (scene graph).
class InvitationDesign {
  String templateId;
  String countryCode;
  String category;
  String locale;
  bool rtl;
  double aspectRatio; // width / height
  String backgroundColor;
  String backgroundImage;
  List<DesignLayer> layers;

  InvitationDesign({
    this.templateId = '',
    this.countryCode = 'SA',
    this.category = 'wedding',
    this.locale = 'ar',
    this.rtl = true,
    this.aspectRatio = 0.7,
    this.backgroundColor = '#000000',
    this.backgroundImage = '',
    List<DesignLayer>? layers,
  }) : layers = layers ?? [];

  InvitationDesign copy() {
    return InvitationDesign(
      templateId: templateId,
      countryCode: countryCode,
      category: category,
      locale: locale,
      rtl: rtl,
      aspectRatio: aspectRatio,
      backgroundColor: backgroundColor,
      backgroundImage: backgroundImage,
      layers: layers.map((e) => e.copyWith()).toList(),
    );
  }

  List<DesignLayer> get sortedLayers {
    final list = List<DesignLayer>.from(layers);
    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return list;
  }

  String? textForField(String key) {
    for (final layer in layers) {
      if (layer.fieldKey == key &&
          (layer.type == DesignLayerType.text ||
              layer.type == DesignLayerType.iconField)) {
        return layer.text;
      }
    }
    return null;
  }

  void setTextForField(String key, String value) {
    for (var i = 0; i < layers.length; i++) {
      if (layers[i].fieldKey == key) {
        layers[i] = layers[i].copyWith(text: value);
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'countryCode': countryCode,
        'category': category,
        'locale': locale,
        'rtl': rtl,
        'aspectRatio': aspectRatio,
        'backgroundColor': backgroundColor,
        'backgroundImage': backgroundImage,
        'layers': layers.map((e) => e.toJson()).toList(),
      };

  factory InvitationDesign.fromJson(Map<String, dynamic>? json) {
    if (json == null) return InvitationDesign();
    final layersJson = json['layers'];
    return InvitationDesign(
      templateId: json['templateId'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? 'SA',
      category: json['category'] as String? ?? 'wedding',
      locale: json['locale'] as String? ?? 'ar',
      rtl: json['rtl'] != false,
      aspectRatio: DesignLayer._d(json['aspectRatio'], 0.7),
      backgroundColor: json['backgroundColor'] as String? ?? '#000000',
      backgroundImage: json['backgroundImage'] as String? ?? '',
      layers: layersJson is List
          ? layersJson
              .whereType<Map<String, dynamic>>()
              .map(DesignLayer.fromJson)
              .toList()
          : [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory InvitationDesign.fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return InvitationDesign();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return InvitationDesign.fromJson(decoded);
      }
    } catch (_) {}
    return InvitationDesign();
  }

  static String newId() {
    final r = math.Random();
    return 'L${DateTime.now().microsecondsSinceEpoch}_${r.nextInt(9999)}';
  }

  static InvitationDesign blank({
    String countryCode = 'US',
    String category = 'other',
    String locale = 'en',
    bool rtl = false,
  }) {
    return InvitationDesign(
      templateId: 'blank',
      countryCode: countryCode,
      category: category,
      locale: locale,
      rtl: rtl,
      aspectRatio: 0.7,
      backgroundColor: '#1A1A2E',
      layers: [
        DesignLayer(
          id: newId(),
          type: DesignLayerType.text,
          fieldKey: 'title',
          text: rtl ? 'عنوان الدعوة' : 'Event Title',
          fontFamily: rtl ? 'cairo' : 'playfair',
          fontSize: 0.07,
          color: '#FFFFFF',
          x: 0.08,
          y: 0.35,
          width: 0.84,
          height: 0.12,
          zIndex: 1,
          bold: true,
        ),
        DesignLayer(
          id: newId(),
          type: DesignLayerType.text,
          fieldKey: 'message',
          text: rtl
              ? 'يسعدنا دعوتكم لحضور مناسبتنا'
              : 'You are cordially invited',
          fontFamily: rtl ? 'cairo' : 'cormorant',
          fontSize: 0.035,
          color: '#E0E0E0',
          x: 0.1,
          y: 0.5,
          width: 0.8,
          height: 0.08,
          zIndex: 2,
          italic: true,
        ),
      ],
    );
  }
}

/// Catalog entry for a ready-made invitation template.
class InvitationTemplate {
  final String id;
  final String name;
  final String nameAr;
  final String countryCode;
  final String category;
  final String locale;
  final bool rtl;
  final String previewColor;
  final String accentColor;
  final InvitationDesign Function() build;

  const InvitationTemplate({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.countryCode,
    required this.category,
    required this.locale,
    required this.rtl,
    required this.previewColor,
    required this.accentColor,
    required this.build,
  });

  String displayName(bool preferAr) =>
      preferAr && nameAr.isNotEmpty ? nameAr : name;
}
