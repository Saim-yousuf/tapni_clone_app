import 'package:tapni_app/models/invitation_design.dart';

/// Customizable business card design (vertical Canva-style scene).
class BusinessCardDesign {
  /// Matches existing digital / invitation cards (portrait).
  static const double defaultAspectRatio = 0.7;

  String templateId;
  String category;
  String locale;
  bool rtl;
  double aspectRatio;
  String backgroundColor;
  String backgroundImage;
  List<DesignLayer> layers;

  BusinessCardDesign({
    this.templateId = '',
    this.category = 'professional',
    this.locale = 'en',
    this.rtl = false,
    this.aspectRatio = defaultAspectRatio,
    this.backgroundColor = '#0F172A',
    this.backgroundImage = '',
    List<DesignLayer>? layers,
  }) : layers = layers ?? [];

  BusinessCardDesign copy() {
    return BusinessCardDesign(
      templateId: templateId,
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

  bool get hasLayers => layers.isNotEmpty;

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

  void setImageForField(String key, String src) {
    for (var i = 0; i < layers.length; i++) {
      if (layers[i].fieldKey == key) {
        layers[i] = layers[i].copyWith(imageSrc: src);
      }
    }
  }

  void setQrData(String data) {
    for (var i = 0; i < layers.length; i++) {
      if (layers[i].type == DesignLayerType.qr || layers[i].fieldKey == 'qr') {
        layers[i] = layers[i].copyWith(qrData: data);
      }
    }
  }

  /// Reuse invitation renderer by converting to [InvitationDesign].
  InvitationDesign toInvitationDesign() {
    return InvitationDesign(
      templateId: templateId,
      countryCode: '',
      category: category,
      locale: locale,
      rtl: rtl,
      aspectRatio: aspectRatio,
      backgroundColor: backgroundColor,
      backgroundImage: backgroundImage,
      layers: layers.map((e) => e.copyWith()).toList(),
    );
  }

  static BusinessCardDesign fromInvitationDesign(InvitationDesign d) {
    return BusinessCardDesign(
      templateId: d.templateId,
      category: d.category,
      locale: d.locale,
      rtl: d.rtl,
      aspectRatio: d.aspectRatio,
      backgroundColor: d.backgroundColor,
      backgroundImage: d.backgroundImage,
      layers: d.layers.map((e) => e.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'category': category,
        'locale': locale,
        'rtl': rtl,
        'aspectRatio': aspectRatio,
        'backgroundColor': backgroundColor,
        'backgroundImage': backgroundImage,
        'layers': layers.map((e) => e.toJson()).toList(),
      };

  factory BusinessCardDesign.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return BusinessCardDesign.blank();
    final layersJson = json['layers'];
    return BusinessCardDesign(
      templateId: json['templateId'] as String? ?? '',
      category: json['category'] as String? ?? 'professional',
      locale: json['locale'] as String? ?? 'en',
      rtl: json['rtl'] == true,
      aspectRatio: _d(json['aspectRatio'], defaultAspectRatio),
      backgroundColor: json['backgroundColor'] as String? ?? '#0F172A',
      backgroundImage: json['backgroundImage'] as String? ?? '',
      layers: layersJson is List
          ? layersJson
              .whereType<Map>()
              .map((e) => DesignLayer.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }

  factory BusinessCardDesign.blank() => BusinessCardDesign();

  /// Seed common profile fields into an existing template.
  void applyProfileData({
    required String name,
    String? title,
    String? company,
    String? phone,
    String? email,
    String? website,
    required String profileUrl,
    String? photoSrc,
  }) {
    if (name.isNotEmpty) setTextForField('name', name);
    if (title != null && title.isNotEmpty) setTextForField('title', title);
    if (company != null && company.isNotEmpty) {
      setTextForField('company', company);
    }
    if (phone != null && phone.isNotEmpty) setTextForField('phone', phone);
    if (email != null && email.isNotEmpty) setTextForField('email', email);
    if (website != null && website.isNotEmpty) {
      setTextForField('website', website);
    }
    setQrData(profileUrl);
    if (photoSrc != null && photoSrc.isNotEmpty) {
      setImageForField('photo', photoSrc);
      setImageForField('logo', photoSrc);
    }
  }

  static double _d(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }
}

class BusinessCardTemplate {
  final String id;
  final String name;
  final String category;
  final BusinessCardDesign Function() build;

  const BusinessCardTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.build,
  });
}
