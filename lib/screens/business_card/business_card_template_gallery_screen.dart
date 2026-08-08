import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/business_card_design.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/screens/business_card/business_card_design_editor_screen.dart';
import 'package:tapni_app/utils/business_card_design_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/business_card_design_renderer.dart';

/// Starter designs → full Canva-style business card editor.
class BusinessCardTemplateGalleryScreen extends StatelessWidget {
  final String? cardId;
  final BusinessCardDesign? existingDesign;
  final bool createNewCard;

  const BusinessCardTemplateGalleryScreen({
    super.key,
    this.cardId,
    this.existingDesign,
    this.createNewCard = false,
  });

  void _openEditor(BuildContext context, BusinessCardDesign design) {
    final provider = context.read<ProfileProvider>();
    final profile = provider.profile;
    final active = provider.activeCardDisplay;
    final seeded = design.copy();
    seeded.applyProfileData(
      name: active.name.isNotEmpty ? active.name : profile.name,
      title: active.subtitle ??
          (profile.designation.isNotEmpty ? profile.designation : null),
      company: profile.company.isNotEmpty
          ? profile.company
          : profile.businessName,
      phone: profile.phone.isNotEmpty ? profile.phone : null,
      email: profile.email.isNotEmpty ? profile.email : null,
      website: profile.website.isNotEmpty ? profile.website : null,
      profileUrl: active.profileUrl,
      photoSrc: active.profilePhotoUrl ?? profile.profilePhotoUrl,
    );

    final newId = createNewCard
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : cardId;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessCardDesignEditorScreen(
          design: seeded,
          cardId: newId,
          createNewCard: createNewCard,
        ),
      ),
    ).then((saved) {
      if (saved == true && context.mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final templates = BusinessCardDesignCatalog.all;

    return Scaffold(
      backgroundColor: WaUi.scaffold,
      appBar: AppBar(
        title: Text(
          createNewCard ? 'Choose a starting design' : 'Card designs',
        ),
        backgroundColor: WaUi.scaffold,
        foregroundColor: WaUi.primaryText,
        elevation: 0,
        actions: [
          if (existingDesign != null && existingDesign!.hasLayers)
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BusinessCardDesignEditorScreen(
                      design: existingDesign!.copy(),
                      cardId: cardId,
                      createNewCard: createNewCard,
                    ),
                  ),
                ).then((saved) {
                  if (saved == true && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                });
              },
              child: const Text('Edit current'),
            ),
          TextButton(
            onPressed: () {
              // Blank canvas with profile-seeded defaults
              _openEditor(
                context,
                BusinessCardDesignCatalog.byId('bc_navy'),
              );
            },
            child: const Text('Blank'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Pick a layout, then fully customize like an invitation card.',
              style: WaUi.caption,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final t = templates[index];
                final design = t.build();
                return GestureDetector(
                  onTap: () => _openEditor(context, design),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BusinessCardDesignRenderer(design: design),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.name,
                        style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(t.category, style: WaUi.caption),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
