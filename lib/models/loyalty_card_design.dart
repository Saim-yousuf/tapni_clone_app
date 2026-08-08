import 'dart:convert';
import 'dart:math' as math;

import 'package:tapni_app/models/invitation_design.dart';

/// Full loyalty stamp-card design document (scene graph + program meta).
class LoyaltyCardDesign {
  String templateId;
  String category;
  String locale;
  bool rtl;
  double aspectRatio;
  String backgroundColor;
  String backgroundImage;
  List<DesignLayer> layers;

  /// Program meta synced with RewardProgram fields.
  int stamps;
  String stampShape; // circle | square
  String stampIcon;
  String unstampIcon;
  String logo;
  String stampColor;
  String stampBorderColor;
  String rewardIcon;

  LoyaltyCardDesign({
    this.templateId = '',
    this.category = 'cafe',
    this.locale = 'en',
    this.rtl = false,
    this.aspectRatio = 0.65,
    this.backgroundColor = '#1B4332',
    this.backgroundImage = '',
    List<DesignLayer>? layers,
    this.stamps = 9,
    this.stampShape = 'square',
    this.stampIcon = '',
    this.unstampIcon = '',
    this.logo = '',
    this.stampColor = '#FFFFFF',
    this.stampBorderColor = '#FFFFFF',
    this.rewardIcon = '',
  }) : layers = layers ?? [];

  LoyaltyCardDesign copy() {
    return LoyaltyCardDesign(
      templateId: templateId,
      category: category,
      locale: locale,
      rtl: rtl,
      aspectRatio: aspectRatio,
      backgroundColor: backgroundColor,
      backgroundImage: backgroundImage,
      layers: layers.map((e) => e.copyWith()).toList(),
      stamps: stamps,
      stampShape: stampShape,
      stampIcon: stampIcon,
      unstampIcon: unstampIcon,
      logo: logo,
      stampColor: stampColor,
      stampBorderColor: stampBorderColor,
      rewardIcon: rewardIcon,
    );
  }

  List<DesignLayer> get sortedLayers {
    final list = List<DesignLayer>.from(layers);
    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return list;
  }

  bool get hasLayers => layers.isNotEmpty;

  String? textForField(String key) {
    for (final layer in layers) {
      if (layer.fieldKey == key && layer.type == DesignLayerType.text) {
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

  void setImageForField(String key, String src) {
    for (var i = 0; i < layers.length; i++) {
      if (layers[i].fieldKey == key) {
        layers[i] = layers[i].copyWith(imageSrc: src);
      }
    }
    if (key == 'logo') logo = src;
    if (key == 'rewardIcon') rewardIcon = src;
  }

  void syncStampCount(int count) {
    stamps = count.clamp(1, 24);
    for (var i = 0; i < layers.length; i++) {
      if (layers[i].type == DesignLayerType.stampGrid ||
          layers[i].fieldKey == 'stampGrid') {
        layers[i] = layers[i].copyWith(text: stamps.toString());
      }
    }
  }

  String get titleText => textForField('title') ?? '';

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'category': category,
        'locale': locale,
        'rtl': rtl,
        'aspectRatio': aspectRatio,
        'backgroundColor': backgroundColor,
        'backgroundImage': backgroundImage,
        'layers': layers.map((e) => e.toJson()).toList(),
        'stamps': stamps,
        'stampShape': stampShape,
        'stampIcon': stampIcon,
        'unstampIcon': unstampIcon,
        'logo': logo,
        'stampColor': stampColor,
        'stampBorderColor': stampBorderColor,
        'rewardIcon': rewardIcon,
      };

  factory LoyaltyCardDesign.fromJson(Map<String, dynamic>? json) {
    if (json == null) return LoyaltyCardDesign.blank();
    final layersJson = json['layers'];
    return LoyaltyCardDesign(
      templateId: json['templateId'] as String? ?? '',
      category: json['category'] as String? ?? 'cafe',
      locale: json['locale'] as String? ?? 'en',
      rtl: json['rtl'] == true,
      aspectRatio: _d(json['aspectRatio'], 0.65),
      backgroundColor: json['backgroundColor'] as String? ?? '#1B4332',
      backgroundImage: json['backgroundImage'] as String? ?? '',
      layers: layersJson is List
          ? layersJson
              .whereType<Map>()
              .map((e) => DesignLayer.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      stamps: (json['stamps'] as num?)?.toInt() ?? 9,
      stampShape: json['stampShape'] as String? ?? 'square',
      stampIcon: json['stampIcon'] as String? ?? '',
      unstampIcon: json['unstampIcon'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      stampColor: json['stampColor'] as String? ?? '#FFFFFF',
      stampBorderColor: json['stampBorderColor'] as String? ?? '#FFFFFF',
      rewardIcon: json['rewardIcon'] as String? ?? '',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory LoyaltyCardDesign.fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return LoyaltyCardDesign.blank();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return LoyaltyCardDesign.fromJson(decoded);
      }
    } catch (_) {}
    return LoyaltyCardDesign.blank();
  }

  static double _d(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static String newId() {
    final r = math.Random();
    return 'LC${DateTime.now().microsecondsSinceEpoch}_${r.nextInt(9999)}';
  }

  static LoyaltyCardDesign blank({
    String category = 'cafe',
    String locale = 'en',
    bool rtl = false,
  }) {
    return LoyaltyCardDesign(
      templateId: 'blank',
      category: category,
      locale: locale,
      rtl: rtl,
      aspectRatio: 0.65,
      backgroundColor: '#1B4332',
      stamps: 9,
      stampShape: 'square',
      stampColor: '#FFFFFF',
      stampBorderColor: '#FFFFFF',
      layers: [
        DesignLayer(
          id: newId(),
          type: DesignLayerType.logo,
          fieldKey: 'logo',
          x: 0.32,
          y: 0.06,
          width: 0.36,
          height: 0.16,
          zIndex: 1,
          shape: 'circle',
        ),
        DesignLayer(
          id: newId(),
          type: DesignLayerType.text,
          fieldKey: 'title',
          text: 'Buy 9, Get 1 FREE',
          fontFamily: 'cairo',
          fontSize: 0.045,
          color: '#F4A261',
          x: 0.08,
          y: 0.24,
          width: 0.84,
          height: 0.08,
          zIndex: 2,
          bold: true,
        ),
        DesignLayer(
          id: newId(),
          type: DesignLayerType.stampGrid,
          fieldKey: 'stampGrid',
          text: '9',
          shape: 'square',
          x: 0.12,
          y: 0.36,
          width: 0.76,
          height: 0.36,
          zIndex: 3,
          locked: true,
          color: '#FFFFFF',
          borderColor: '#FFFFFF',
        ),
        DesignLayer(
          id: newId(),
          type: DesignLayerType.text,
          fieldKey: 'subtitle',
          text: 'FREE BREW',
          fontFamily: 'cairo',
          fontSize: 0.04,
          color: '#FFFFFF',
          x: 0.1,
          y: 0.78,
          width: 0.8,
          height: 0.08,
          zIndex: 4,
          bold: true,
        ),
      ],
    );
  }
}
