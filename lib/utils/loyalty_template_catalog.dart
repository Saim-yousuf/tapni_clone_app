import 'package:tapni_app/models/invitation_design.dart';
import 'package:tapni_app/models/loyalty_card_design.dart';

/// Curated loyalty stamp-card templates (choose → customize → publish).
class LoyaltyTemplateCatalog {
  LoyaltyTemplateCatalog._();

  static const categories = <Map<String, String>>[
    {'id': 'cafe', 'name': 'Cafe', 'nameAr': 'مقهى', 'icon': 'local_cafe'},
    {'id': 'restaurant', 'name': 'Restaurant', 'nameAr': 'مطعم', 'icon': 'restaurant'},
    {'id': 'retail', 'name': 'Retail', 'nameAr': 'تجزئة', 'icon': 'storefront'},
    {'id': 'salon', 'name': 'Salon', 'nameAr': 'صالون', 'icon': 'content_cut'},
    {'id': 'other', 'name': 'Other', 'nameAr': 'أخرى', 'icon': 'more_horiz'},
  ];

  static List<LoyaltyTemplate> get all => _templates;

  static List<LoyaltyTemplate> filter({String? category}) {
    return _templates.where((t) {
      if (category != null && category.isNotEmpty && t.category != category) {
        return false;
      }
      return true;
    }).toList();
  }

  static LoyaltyTemplate? byId(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  static final List<LoyaltyTemplate> _templates = [
    LoyaltyTemplate(
      id: 'teal_square_coffee',
      name: 'Island Brew',
      nameAr: 'جزيرة القهوة',
      category: 'cafe',
      previewColor: '#1B4332',
      accentColor: '#F4A261',
      build: _buildTealSquare,
    ),
    LoyaltyTemplate(
      id: 'mauve_circle_drinks',
      name: 'Soft Circles',
      nameAr: 'دوائر ناعمة',
      category: 'cafe',
      previewColor: '#D4A5A5',
      accentColor: '#5C4033',
      build: _buildMauveCircles,
    ),
    LoyaltyTemplate(
      id: 'botanical_blue_coffee',
      name: 'Botanical Cup',
      nameAr: 'كوب نباتي',
      category: 'cafe',
      previewColor: '#7BA3A8',
      accentColor: '#1A2744',
      build: _buildBotanicalBlue,
    ),
    LoyaltyTemplate(
      id: 'dark_retail_stamps',
      name: 'Night Retail',
      nameAr: 'تجزئة ليلية',
      category: 'retail',
      previewColor: '#121212',
      accentColor: '#E8B86D',
      build: _buildDarkRetail,
    ),
  ];

  static LoyaltyCardDesign _buildTealSquare() {
    final id = LoyaltyCardDesign.newId;
    return LoyaltyCardDesign(
      templateId: 'teal_square_coffee',
      category: 'cafe',
      backgroundColor: '#1B4332',
      stamps: 9,
      stampShape: 'square',
      stampColor: '#FFFFFF',
      stampBorderColor: '#FFFFFF',
      layers: [
        DesignLayer(
          id: id(),
          type: DesignLayerType.shape,
          shape: 'circle',
          color: '#2A6FDB',
          x: 0.32,
          y: 0.05,
          width: 0.36,
          height: 0.15,
          zIndex: 1,
          fieldKey: 'logoBg',
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'logo',
          text: 'YOUR LOGO',
          fontFamily: 'cairo',
          fontSize: 0.028,
          color: '#FFFFFF',
          x: 0.28,
          y: 0.09,
          width: 0.44,
          height: 0.08,
          zIndex: 2,
          bold: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'title',
          text: 'Buy 9 Coffees, Get 1 FREE',
          fontFamily: 'cairo',
          fontSize: 0.038,
          color: '#F4A261',
          x: 0.08,
          y: 0.23,
          width: 0.84,
          height: 0.07,
          zIndex: 3,
          bold: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.stampGrid,
          fieldKey: 'stampGrid',
          text: '9',
          shape: 'square',
          color: '#FFFFFF',
          borderColor: '#FFFFFF',
          x: 0.14,
          y: 0.34,
          width: 0.72,
          height: 0.34,
          zIndex: 4,
          locked: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'subtitle',
          text: 'FREE  ★  BREW',
          fontFamily: 'cairo',
          fontSize: 0.042,
          color: '#FFFFFF',
          x: 0.1,
          y: 0.74,
          width: 0.8,
          height: 0.08,
          zIndex: 5,
          bold: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'partnerText',
          text: 'IN PARTNERSHIP WITH',
          fontFamily: 'roboto',
          fontSize: 0.022,
          color: '#C8D5C0',
          x: 0.1,
          y: 0.88,
          width: 0.8,
          height: 0.05,
          zIndex: 6,
        ),
      ],
    );
  }

  static LoyaltyCardDesign _buildMauveCircles() {
    final id = LoyaltyCardDesign.newId;
    return LoyaltyCardDesign(
      templateId: 'mauve_circle_drinks',
      category: 'cafe',
      backgroundColor: '#D4A5A5',
      stamps: 6,
      stampShape: 'circle',
      stampColor: '#C48989',
      stampBorderColor: '#A86F6F',
      layers: [
        DesignLayer(
          id: id(),
          type: DesignLayerType.shape,
          shape: 'circle',
          color: '#00000000',
          borderColor: '#5C4033',
          borderWidth: 0.008,
          x: 0.38,
          y: 0.06,
          width: 0.12,
          height: 0.08,
          zIndex: 1,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.shape,
          shape: 'circle',
          color: '#00000000',
          borderColor: '#5C4033',
          borderWidth: 0.006,
          x: 0.46,
          y: 0.08,
          width: 0.16,
          height: 0.1,
          zIndex: 2,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.shape,
          shape: 'circle',
          color: '#00000000',
          borderColor: '#5C4033',
          borderWidth: 0.005,
          x: 0.42,
          y: 0.1,
          width: 0.1,
          height: 0.07,
          zIndex: 3,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'title',
          text: 'BUY 6 DRINKS GET 1 FREE',
          fontFamily: 'roboto',
          fontSize: 0.036,
          color: '#3D3D3D',
          x: 0.08,
          y: 0.24,
          width: 0.84,
          height: 0.08,
          zIndex: 4,
          bold: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.stampGrid,
          fieldKey: 'stampGrid',
          text: '6',
          shape: 'circle',
          color: '#C48989',
          borderColor: '#A86F6F',
          x: 0.14,
          y: 0.38,
          width: 0.72,
          height: 0.32,
          zIndex: 5,
          locked: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.shape,
          fieldKey: 'rewardIcon',
          shape: 'circle',
          color: '#C48989',
          borderColor: '#A86F6F',
          borderWidth: 0.01,
          x: 0.35,
          y: 0.76,
          width: 0.3,
          height: 0.16,
          zIndex: 6,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'subtitle',
          text: '☕',
          fontFamily: 'cairo',
          fontSize: 0.06,
          color: '#5C4033',
          x: 0.35,
          y: 0.79,
          width: 0.3,
          height: 0.1,
          zIndex: 7,
        ),
      ],
    );
  }

  static LoyaltyCardDesign _buildBotanicalBlue() {
    final id = LoyaltyCardDesign.newId;
    return LoyaltyCardDesign(
      templateId: 'botanical_blue_coffee',
      category: 'cafe',
      backgroundColor: '#7BA3A8',
      stamps: 8,
      stampShape: 'circle',
      stampColor: '#F5F5F5',
      stampBorderColor: '#1A2744',
      layers: [
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'logo',
          text: '9oz COFFEE',
          fontFamily: 'playfair',
          fontSize: 0.055,
          color: '#1A2744',
          x: 0.1,
          y: 0.06,
          width: 0.8,
          height: 0.1,
          zIndex: 1,
          bold: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'title',
          text: 'Collect stamps · Earn a free cup',
          fontFamily: 'cormorant',
          fontSize: 0.032,
          color: '#1A2744',
          x: 0.1,
          y: 0.18,
          width: 0.8,
          height: 0.06,
          zIndex: 2,
          italic: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.stampGrid,
          fieldKey: 'stampGrid',
          text: '8',
          shape: 'circle',
          color: '#F5F5F5',
          borderColor: '#1A2744',
          x: 0.12,
          y: 0.32,
          width: 0.76,
          height: 0.42,
          zIndex: 3,
          locked: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'subtitle',
          text: 'FREE DRINK',
          fontFamily: 'roboto',
          fontSize: 0.036,
          color: '#1A2744',
          x: 0.1,
          y: 0.82,
          width: 0.8,
          height: 0.08,
          zIndex: 4,
          bold: true,
        ),
      ],
    );
  }

  static LoyaltyCardDesign _buildDarkRetail() {
    final id = LoyaltyCardDesign.newId;
    return LoyaltyCardDesign(
      templateId: 'dark_retail_stamps',
      category: 'retail',
      backgroundColor: '#121212',
      stamps: 10,
      stampShape: 'circle',
      stampColor: '#E8B86D',
      stampBorderColor: '#E8B86D',
      layers: [
        DesignLayer(
          id: id(),
          type: DesignLayerType.logo,
          fieldKey: 'logo',
          x: 0.35,
          y: 0.05,
          width: 0.3,
          height: 0.12,
          zIndex: 1,
          shape: 'circle',
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'title',
          text: 'Buy 10 · Get 1 Free',
          fontFamily: 'cairo',
          fontSize: 0.042,
          color: '#E8B86D',
          x: 0.08,
          y: 0.2,
          width: 0.84,
          height: 0.08,
          zIndex: 2,
          bold: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.stampGrid,
          fieldKey: 'stampGrid',
          text: '10',
          shape: 'circle',
          color: '#2A2A2A',
          borderColor: '#E8B86D',
          x: 0.12,
          y: 0.34,
          width: 0.76,
          height: 0.4,
          zIndex: 3,
          locked: true,
        ),
        DesignLayer(
          id: id(),
          type: DesignLayerType.text,
          fieldKey: 'subtitle',
          text: 'REWARD UNLOCKED',
          fontFamily: 'roboto',
          fontSize: 0.03,
          color: '#FFFFFF',
          x: 0.1,
          y: 0.82,
          width: 0.8,
          height: 0.08,
          zIndex: 4,
          bold: true,
        ),
      ],
    );
  }
}

class LoyaltyTemplate {
  final String id;
  final String name;
  final String nameAr;
  final String category;
  final String previewColor;
  final String accentColor;
  final LoyaltyCardDesign Function() build;

  const LoyaltyTemplate({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.category,
    required this.previewColor,
    required this.accentColor,
    required this.build,
  });

  String displayName(bool preferAr) =>
      preferAr && nameAr.isNotEmpty ? nameAr : name;
}
