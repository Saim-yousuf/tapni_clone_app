import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/helper/link_entries_cache.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/contact_card_sheet.dart' as contact_card;
import 'package:tapni_app/widgets/link_platform_icon.dart';
import 'package:tapni_app/widgets/menu_catalog_sheet.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
import 'package:tapni_app/screens/catalog/document_link_form_screen.dart';
import 'package:tapni_app/screens/gallery_link_screen.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/utils/catalog_helper.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class _LinkEntryDraft {
  _LinkEntryDraft({
    String? id,
    String name = '',
    String value = '',
    this.logo = '',
    this.isPublic = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       nameController = TextEditingController(text: name),
       valueController = TextEditingController(text: value);

  final String id;
  final TextEditingController nameController;
  final TextEditingController valueController;
  String logo;
  bool isPublic;

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }

  LinkEntry toEntry() {
    return LinkEntry(
      id: id,
      name: nameController.text.trim(),
      value: valueController.text.trim(),
      logo: logo.isNotEmpty ? logo : null,
      isPublic: isPublic,
    );
  }
}

class LinkSheet {
  Future<void> showAddLinkBottomSheet(
    BuildContext context,
    ProfileProvider provider,
  ) {
    final parentContext = context;
    if (provider.linkCatalog.isEmpty && !provider.isLinkCatalogLoading) {
      provider.fetchLinkCatalog();
    }

    bool isSearching = false;
    return showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: BarqodyChrome.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            final searchController = TextEditingController();

            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    const SheetDragHandle(),
                    //Header Open
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          CircleBackButton(onTap: () => Navigator.pop(ctx)),
                          Expanded(
                            child: isSearching
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: TextField(
                                      controller: searchController,
                                      autofocus: true,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: ctx.l10n.searchLinks,
                                        hintStyle: const TextStyle(
                                          color: BarqodyChrome.secondaryText,
                                        ),
                                        filled: true,
                                        fillColor: BarqodyChrome.fieldFill,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (_) => setSheetState(() {}),
                                    ),
                                  )
                                : Text(
                                    ctx.l10n.addLink,
                                    textAlign: TextAlign.center,
                                    style: WaUi.toolsTitleOf(
                                      size: 20,
                                      weight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                          CircleAssetButton(
                            asset: 'assets/images/png/search-icon.png',
                            iconSize: 16,
                            child: isSearching
                                ? const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Colors.black,
                                  )
                                : null,
                            onTap: () {
                              setSheetState(() {
                                isSearching = !isSearching;
                                if (!isSearching) searchController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    //Header Close
                    Expanded(
                      child: Consumer<ProfileProvider>(
                        builder: (context, watchedProvider, _) {
                          if (watchedProvider.isLinkCatalogLoading &&
                              watchedProvider.linkCatalog.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2.5,
                              ),
                            );
                          }

                          if (watchedProvider.linkCatalog.isNotEmpty) {
                            final query = searchController.text
                                .trim()
                                .toLowerCase();
                            final countryFiltered = filterCatalogByUserCountry(
                              watchedProvider.linkCatalog,
                              _userCountry(watchedProvider),
                            );
                            final hasGallery = watchedProvider.profile.socialLinks
                                .any((link) => link.isGalleryLink);
                            final withoutDuplicateGallery = hasGallery
                                ? countryFiltered
                                    .map(
                                      (category) => category.copyWith(
                                        templates: category.templates
                                            .where(
                                              (template) =>
                                                  !isGalleryLinkTemplate(
                                                    template,
                                                  ),
                                            )
                                            .toList(),
                                      ),
                                    )
                                    .where(
                                      (category) =>
                                          category.templates.isNotEmpty,
                                    )
                                    .toList()
                                : countryFiltered;
                            final catalog = query.isEmpty
                                ? withoutDuplicateGallery
                                : withoutDuplicateGallery
                                      .map((category) {
                                        final templates = category.templates
                                            .where(
                                              (template) =>
                                                  template.label
                                                      .toLowerCase()
                                                      .contains(query) ||
                                                  category.name
                                                      .toLowerCase()
                                                      .contains(query),
                                            )
                                            .toList();
                                        return LinkCategory(
                                          id: category.id,
                                          name: category.name,
                                          templates: templates,
                                        );
                                      })
                                      .where(
                                        (category) =>
                                            category.templates.isNotEmpty,
                                      )
                                      .toList();

                            return SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                BarqodyChrome.sidePad,
                                4,
                                BarqodyChrome.sidePad,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...catalog
                                    .map(
                                      (category) => _buildTemplateCategory(
                                        parentContext,
                                        ctx,
                                        category,
                                        provider,
                                      ),
                                    )
                                    .toList(),
                                ],
                              ),
                            );
                          }

                          return Center(
                            child: Text(
                              context.l10n.noLinkTemplatesAvailable,
                              style: WaUi.body.copyWith(
                                fontSize: 16,
                                color: BarqodyChrome.secondaryText,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _openMenuCatalogFromTemplate(
    BuildContext context,
    LinkTemplate template,
    ProfileProvider provider, {
    SocialLink? existingLink,
  }) async {
    final ok = await ensureBusinessProfileComplete(context);
    if (!ok || !context.mounted) return;

    final catalogType = _resolveCatalogType(existingLink, template, provider);
    final catalogLabel = existingLink != null &&
            existingLink.platformName.isNotEmpty
        ? existingLink.platformName
        : template.label;
    final resolvedTemplate =
        _catalogTemplateMatchesType(template, catalogType)
            ? template
            : (_findCatalogTemplateByType(catalogType, provider) ?? template);

    showMenuCatalogSheet(
      context: context,
      catalogLabel: catalogLabel,
      catalogType: catalogType,
      provider: provider,
      existingLink: existingLink,
      template: resolvedTemplate,
    );
  }

  LinkTemplate? _findLinkTemplate(SocialLink link, ProfileProvider provider) {
    LinkTemplate? byId;
    if (link.templateId != null && link.templateId!.isNotEmpty) {
      for (final category in provider.linkCatalog) {
        for (final template in category.templates) {
          if (template.id == link.templateId) {
            byId = template;
            break;
          }
        }
        if (byId != null) break;
      }
    }

    final linkType = link.catalogType?.trim();
    if (linkType == null || linkType.isEmpty) return byId;

    LinkTemplate? byType;
    for (final category in provider.linkCatalog) {
      for (final template in category.templates) {
        if (linkType == 'documents' && isDocumentsLinkTemplate(template)) {
          return template;
        }
        if (template.actionType == 'menu_catalog' &&
            template.catalogType == linkType) {
          byType = template;
          break;
        }
      }
      if (byType != null) break;
    }

    return byType ?? byId;
  }

  LinkTemplate? _findCatalogTemplateByType(
    String catalogType,
    ProfileProvider provider,
  ) {
    for (final category in provider.linkCatalog) {
      for (final template in category.templates) {
        if (template.actionType == 'menu_catalog' &&
            template.catalogType == catalogType) {
          return template;
        }
      }
    }
    return null;
  }

  bool _catalogTemplateMatchesType(LinkTemplate template, String catalogType) {
    if (template.actionType != 'menu_catalog') return false;
    final type = template.catalogType?.trim();
    if (type == null || type.isEmpty) return catalogType == 'catalog';
    return type == catalogType;
  }

  String _resolveCatalogType(
    SocialLink? link,
    LinkTemplate? template,
    ProfileProvider provider,
  ) {
    final fromLink = link?.catalogType?.trim();
    if (fromLink != null && fromLink.isNotEmpty) return fromLink;

    final fromTemplate = template?.catalogType?.trim();
    if (fromTemplate != null && fromTemplate.isNotEmpty) return fromTemplate;

    return CatalogHelper.typeForCategory(provider.profile.businessCategory);
  }

  Future<void> _openCatalogLinkEditor(
    BuildContext context,
    SocialLink link,
    ProfileProvider provider, {
    LinkTemplate? template,
  }) async {
    final ok = await ensureBusinessProfileComplete(context);
    if (!ok || !context.mounted) return;

    final catalogType = _resolveCatalogType(link, template, provider);
    final catalogLabel = link.platformName.isNotEmpty
        ? link.platformName
        : (template?.label ??
            CatalogHelper.labelForCategory(
              provider.profile.businessCategory,
              context.l10n,
            ));
    final resolvedTemplate = template != null &&
            _catalogTemplateMatchesType(template, catalogType)
        ? template
        : _findCatalogTemplateByType(catalogType, provider);

    showMenuCatalogSheet(
      context: context,
      catalogLabel: catalogLabel,
      catalogType: catalogType,
      provider: provider,
      existingLink: link,
      template: resolvedTemplate,
    );
  }

  Widget _buildTemplateCategory(
    BuildContext context,
    BuildContext sheetContext,
    LinkCategory category,
    ProfileProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: WaUi.toolsTitleOf(
              size: 16,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(category.templates.length, (index) {
                final template = category.templates[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final isProUser = Provider.of<ProfileProvider>(
                        context,
                        listen: false,
                      ).isProUser;

                      if (template.isPro && !isProUser) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const ProUpgradeSheet(),
                        );
                        return;
                      }
                      if (isDocumentsLinkTemplate(template) ||
                          template.actionType == 'document') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentLinkFormScreen(
                              provider: provider,
                              template: template,
                            ),
                          ),
                        );
                      } else if (isGalleryLinkTemplate(template) ||
                          template.actionType == 'gallery') {
                        if (provider.profile.socialLinks
                            .any((link) => link.isGalleryLink)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.profileTabGallery,
                              ),
                            ),
                          );
                          return;
                        }
                        await provider.addGalleryLink(
                          template: template,
                          context: context,
                        );
                        if (context.mounted) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GalleryLinkScreen(
                                items: provider.profile.gallery,
                                isOwner: true,
                              ),
                            ),
                          );
                        }
                      } else if (template.actionType == 'menu_catalog') {
                        _openMenuCatalogFromTemplate(
                          context,
                          template,
                          provider,
                        );
                      } else if (template.actionType == 'contact_card') {
                        final existing = _findExistingLinkForTemplate(
                          provider,
                          template,
                        );
                        if (existing != null) {
                          await showExistingLinkBottomSheet(
                            context,
                            existing,
                            provider,
                          );
                        } else {
                          contact_card.showContactCardBottomSheet(
                            context,
                            template,
                            provider,
                          );
                        }
                      } else if (_isCustomTemplate(template)) {
                        _showCustomTemplateBottomSheet(
                          context,
                          template,
                          provider,
                        );
                      } else if (template.fieldType == 'bank') {
                        final existing = _findExistingLinkForTemplate(
                          provider,
                          template,
                        );
                        if (existing != null) {
                          await showExistingLinkBottomSheet(
                            context,
                            existing,
                            provider,
                          );
                        } else {
                          _showBankTemplateBottomSheet(
                            context,
                            template,
                            provider,
                          );
                        }
                      } else {
                        final existing = _findExistingLinkForTemplate(
                          provider,
                          template,
                        );
                        if (existing != null) {
                          await showExistingLinkBottomSheet(
                            context,
                            existing,
                            provider,
                          );
                        } else {
                          _showNewTemplateLinkBottomSheet(
                            context,
                            template,
                            provider,
                          );
                        }
                      }
                    },
                    child: SizedBox(
                      width: 130,
                      child: Column(
                        children: [
                          _buildTemplateLogo(
                            template.logo,
                            size: 130,
                            radius: 24,
                            isPro: template.isPro,
                            context: context,
                            template: template,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            template.label,
                            style: WaUi.body.copyWith(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String? _userCountry(ProfileProvider provider) {
    final fromProfile = provider.profile.country?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return regionKeyFromPhone(
      provider.profile.phone,
      regionOptions: Constants.countries,
    );
  }

  bool _isCustomTemplate(LinkTemplate template) {
    final label = template.label.toLowerCase();
    return template.isSystem &&
        (label.contains('custom link') || label.contains('custom bank'));
  }

  /// Find an already-added link for this catalog template (e.g. WhatsApp).
  /// Custom links are excluded so users can add multiple custom URLs.
  SocialLink? _findExistingLinkForTemplate(
    ProfileProvider provider,
    LinkTemplate template,
  ) {
    if (_isCustomTemplate(template)) return null;
    if (template.actionType == 'menu_catalog' ||
        template.actionType == 'gallery' ||
        template.actionType == 'document' ||
        isGalleryLinkTemplate(template) ||
        isDocumentsLinkTemplate(template)) {
      return null;
    }

    final links = provider.profile.socialLinks;
    final templateId = template.id.trim();
    if (templateId.isNotEmpty) {
      for (final link in links) {
        if (link.templateId == templateId) return link;
      }
    }

    final label = template.label.trim().toLowerCase();
    if (label.isEmpty) return null;

    for (final link in links) {
      if (link.isGalleryLink || link.isDocumentLink || link.isCatalogLink) {
        continue;
      }
      final linkLabel = link.platformName.trim().toLowerCase();
      if (linkLabel == label) return link;
      if (label.contains('whatsapp') &&
          (link.platform == SocialPlatform.whatsApp ||
              linkLabel.contains('whatsapp'))) {
        return link;
      }
    }
    return null;
  }

  Future<String> _pickLogoBase64() async {
    final file = await pickFile();
    if (file?.file == null) return '';
    return fileToBase64(File(file!.file!.path));
  }

  void _showCustomTemplateBottomSheet(
    BuildContext context,
    LinkTemplate template,
    ProfileProvider provider, {
    SocialLink? existingLink,
  }) {
    if (template.fieldType == 'bank') {
      _showBankTemplateBottomSheet(
        context,
        template,
        provider,
        allowCustomMeta: true,
        existingLink: existingLink,
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelController = TextEditingController(
      text: existingLink?.platformName ?? '',
    );
    final drafts = _draftsFromLink(existingLink);
    String logo = existingLink?.logoUrl ?? '';
    bool showLink = existingLink?.isPublic ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF111111) : Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SheetHeader(
                        title: ctx.l10n.customLink,
                        onBack: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final pickedLogo = await _pickLogoBase64();
                              if (pickedLogo.isNotEmpty) {
                                setState(() => logo = pickedLogo);
                              }
                            },
                            child: _selectedLogoTile(logo),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: _sheetTextField(
                              labelController,
                              context.l10n.label,
                              TextInputType.text,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      _buildMultiEntryEditors(
                        context: context,
                        drafts: drafts,
                        valueHint: context.l10n.link,
                        keyboardType: TextInputType.url,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      _showPublicToggle(
                        context: context,
                        isDark: isDark,
                        value: showLink,
                        onChanged: (value) =>
                            setState(() => showLink = value),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (existingLink != null) ...[
                            _deleteCircleButton(() async {
                              await provider.deleteSocialLink(
                                existingLink.id,
                                context,
                              );
                              Navigator.pop(ctx);
                            }),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: _saveButton(
                              context: context,
                              onPressed: () async {
                                final label = labelController.text.trim();
                                final entries = _entriesFromDrafts(drafts);
                                if (label.isEmpty || entries.isEmpty) return;
                                if (existingLink == null) {
                                  await provider.addCustomTemplateLink(
                                    template: template,
                                    label: label,
                                    value: entries.first.value,
                                    showLink: showLink,
                                    context: context,
                                    logo: logo,
                                    entries: entries,
                                  );
                                } else {
                                  await provider.updateCustomTemplateLink(
                                    link: existingLink,
                                    label: label,
                                    value: entries.first.value,
                                    showLink: showLink,
                                    context: context,
                                    logo: logo,
                                    entries: entries,
                                  );
                                }
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _selectedLogoTile(String logo) {
    Widget image;
    if (logo.isNotEmpty) {
      if (logo.startsWith('http://') || logo.startsWith('https://')) {
        image = ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            logo,
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _logoPlaceholder(true),
          ),
        );
      } else {
        try {
          image = ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              base64Decode(logo),
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _logoPlaceholder(true),
            ),
          );
        } catch (_) {
          image = _logoPlaceholder(true);
        }
      }
    } else {
      image = _logoPlaceholder(false);
    }

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          image,
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoPlaceholder(bool selected) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        selected ? Icons.check_rounded : Icons.add_photo_alternate,
        color: selected ? Colors.white : Colors.black54,
      ),
    );
  }

  Widget _deleteCircleButton(VoidCallback onPressed) {
    return Material(
      color: const Color(0xFFFF3B30),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Image.asset(
              'assets/images/png/trash-bin-icon.png',
              width: 20,
              height: 20,
              color: Colors.white,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.delete_outline,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBankTemplateBottomSheet(
    BuildContext context,
    LinkTemplate template,
    ProfileProvider provider, {
    bool allowCustomMeta = false,
    SocialLink? existingLink,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bankDetails = existingLink?.bankDetails ?? {};
    final labelController = TextEditingController(
      text:
          existingLink?.platformName ?? (allowCustomMeta ? '' : template.label),
    );
    final holderController = TextEditingController(
      text: bankDetails['accountHolderName'] ?? '',
    );
    final ibanController = TextEditingController(
      text: bankDetails['iban'] ?? '',
    );
    final accountController = TextEditingController(
      text: bankDetails['accountNumber'] ?? '',
    );
    String logo = existingLink?.logoUrl ?? '';
    bool showLink = existingLink?.isPublic ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF111111) : Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetHeader(
                      title: allowCustomMeta
                          ? context.l10n.customBank
                          : template.label,
                      onBack: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: allowCustomMeta
                              ? () async {
                                  final pickedLogo = await _pickLogoBase64();
                                  if (pickedLogo.isNotEmpty) {
                                    setState(() => logo = pickedLogo);
                                  }
                                }
                              : null,
                          child: allowCustomMeta
                              ? _selectedLogoTile(
                                  logo.isNotEmpty ? logo : template.logo,
                                )
                              : _buildTemplateLogo(
                                  logo.isNotEmpty ? logo : template.logo,
                                  size: 60,
                                  isPro: template.isPro,
                                  context: context,
                                ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _sheetTextField(
                            labelController,
                            context.l10n.label,
                            TextInputType.text,
                            readOnly: !allowCustomMeta,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    _sheetTextField(
                      holderController,
                      context.l10n.accountHolderName,
                      TextInputType.name,
                    ),
                    SizedBox(height: 12),
                    _sheetTextField(
                      ibanController,
                      context.l10n.ibanNumber,
                      TextInputType.text,
                    ),
                    SizedBox(height: 12),
                    _sheetTextField(
                      accountController,
                      context.l10n.accountNumber,
                      TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    _showPublicToggle(
                      context: context,
                      isDark: isDark,
                      value: showLink,
                      onChanged: (value) => setState(() => showLink = value),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (existingLink != null) ...[
                          _deleteCircleButton(() async {
                            await provider.deleteSocialLink(
                              existingLink.id,
                              context,
                            );
                            Navigator.pop(ctx);
                          }),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: _saveButton(
                            context: context,
                            onPressed: () async {
                              final label = labelController.text.trim();
                              final holder = holderController.text.trim();
                              final iban = ibanController.text.trim();
                              final account = accountController.text.trim();
                              if (label.isEmpty ||
                                  holder.isEmpty ||
                                  (iban.isEmpty && account.isEmpty)) {
                                return;
                              }
                              final details = {
                                'accountHolderName': holder,
                                'iban': iban,
                                'accountNumber': account,
                              };
                              if (existingLink == null) {
                                await provider.addCustomTemplateLink(
                                  template: template,
                                  label: label,
                                  value: iban.isNotEmpty ? iban : account,
                                  showLink: showLink,
                                  context: context,
                                  logo: logo,
                                  bankDetails: details,
                                );
                              } else {
                                await provider.updateCustomTemplateLink(
                                  link: existingLink,
                                  label: label,
                                  value: iban.isNotEmpty ? iban : account,
                                  showLink: showLink,
                                  context: context,
                                  logo: logo,
                                  bankDetails: details,
                                );
                              }
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Barqody-style light-grey rounded field (fill `#F2F2F7`, no border).
  InputDecoration _barqodyFieldDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? prefix,
    EdgeInsetsGeometry? contentPadding,
    double radius = 14,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 15,
        color: BarqodyChrome.secondaryText,
      ),
      filled: true,
      fillColor: BarqodyChrome.fieldFill,
      prefixIcon: prefixIcon,
      prefix: prefix,
      contentPadding:
          contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      disabledBorder: border,
    );
  }

  Widget _sheetTextField(
    TextEditingController controller,
    String hint,
    TextInputType keyboardType, {
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      decoration: _barqodyFieldDecoration(hintText: hint),
    );
  }

  Widget _showPublicToggle({
    required BuildContext context,
    required bool isDark,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.showLink,
            style: WaUi.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: Colors.black,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Light grey circle + black plus (Create New Link reference).
  Widget _addEntryCircleButton(VoidCallback onPressed) {
    return Material(
      color: BarqodyChrome.circleBtn,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Image.asset(
              'assets/images/png/plus-icon.png',
              width: 14,
              height: 14,
              color: Colors.black,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.add, size: 18, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: WaUi.primaryButtonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlack,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Text(
          context.l10n.save,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateLogo(
    String logo, {
    double size = 60,
    double radius = 14,
    required bool isPro,
    required BuildContext context,
    LinkTemplate? template,
  }) {
    final isProUser = Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).isProUser;
    final innerRadius = (radius - 1).clamp(0.0, radius);
    final isDocuments = template?.catalogType == 'documents' ||
        template?.label.trim().toLowerCase() == 'documents';
    final isGallery =
        template != null && isGalleryLinkTemplate(template);
    final isCustom = template != null && _isCustomTemplate(template);
    final isContactCard = template?.actionType == 'contact_card' ||
        (template?.label.toLowerCase().contains('contact') ?? false);
    final fit = isCustom ? BoxFit.contain : BoxFit.cover;
    final logoPadding = isCustom ? size * 0.1 : 0.0;

    Widget logoImage({required Widget errorWidget}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: logo.isEmpty
              ? errorWidget
              : Padding(
                  padding: EdgeInsets.all(logoPadding),
                  child: Image.network(
                    logo.replaceAll(" ", ""),
                    width: size,
                    height: size,
                    fit: fit,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => errorWidget,
                  ),
                ),
        ),
      );
    }

    final placeholder = isGallery
        ? ColoredBox(
            color: const Color(0xFFF1F5F9),
            child: Center(
              child: Icon(
                Icons.photo_library_rounded,
                color: const Color(0xFF0F172A),
                size: size * 0.42,
              ),
            ),
          )
        : isDocuments
        ? ColoredBox(
            color: const Color(0xFF1B4F72),
            child: Center(
              child: Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: size * 0.42,
              ),
            ),
          )
        : isContactCard
            ? Image.asset(
                SocialLink.getAssetPath(SocialPlatform.contact),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(Icons.person, size: size * 0.42),
                  ),
                ),
              )
        : isCustom &&
                (template?.label.toLowerCase().contains('bank') ?? false)
            ? ColoredBox(
                color: Colors.white,
                child: Center(
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: Colors.black87,
                    size: size * 0.42,
                  ),
                ),
              )
            : ColoredBox(
                color: Colors.grey.shade200,
                child: Center(child: Icon(Icons.link)),
              );

    final image = logoImage(errorWidget: placeholder);

    if (isPro && !isProUser) {
      return Stack(
        alignment: Alignment.topRight,
        clipBehavior: Clip.none,
        children: [
          image,
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.black,
            child: Image.asset(
              "assets/images/png/premium-icon2.png",
              width: 20,
              height: 20,
              fit: BoxFit.cover,
            ),
          ),
        ],
      );
    }

    return image;
  }

  List<_LinkEntryDraft> _draftsFromLink(SocialLink? link) {
    if (link == null) {
      return [_LinkEntryDraft()];
    }
    final existing = link.entries
        ?.where((e) => e.value.trim().isNotEmpty)
        .toList();
    if (existing != null && existing.isNotEmpty) {
      return existing
          .map(
            (e) => _LinkEntryDraft(
              id: e.id,
              name: e.name,
              value: e.value,
              logo: e.logo ?? '',
              isPublic: e.isPublic,
            ),
          )
          .toList();
    }
    return [
      _LinkEntryDraft(
        id: link.id,
        name: '',
        value: link.value,
        logo: '',
        isPublic: link.isPublic,
      ),
    ];
  }

  List<LinkEntry> _entriesFromDrafts(List<_LinkEntryDraft> drafts) {
    return drafts
        .map((d) => d.toEntry())
        .where((e) => e.value.isNotEmpty)
        .map(
          (e) => LinkEntry(
            id: e.id,
            name: e.name.isNotEmpty ? e.name : e.value,
            value: e.value,
            logo: e.logo,
            isPublic: e.isPublic,
          ),
        )
        .toList();
  }

  /// Link-level public if any child entry is public.
  bool _linkPublicFromEntries(List<LinkEntry> entries) =>
      entries.any((e) => e.isPublic);

  Widget _buildMultiEntryEditors({
    required BuildContext context,
    required List<_LinkEntryDraft> drafts,
    required String valueHint,
    required TextInputType keyboardType,
    required VoidCallback onChanged,
  }) {
    void addEntry() {
      drafts.add(_LinkEntryDraft());
      onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Enter the name & phone number below the feild',
                style: WaUi.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _addEntryCircleButton(addEntry),
          ],
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < drafts.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildEntryEditorRow(
            context: context,
            draft: drafts[i],
            index: i,
            valueHint: valueHint,
            keyboardType: keyboardType,
            canRemove: true,
            onRemove: () {
              drafts[i].dispose();
              drafts.removeAt(i);
              if (drafts.isEmpty) drafts.add(_LinkEntryDraft());
              onChanged();
            },
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }

  /// Dial code for phone fields (Figma shows `+1 |`). Defaults to `+1`.
  String? _dialPrefixFor(BuildContext context, TextInputType keyboardType) {
    if (keyboardType != TextInputType.phone) return null;
    try {
      final country = Provider.of<ProfileProvider>(context, listen: false)
          .profile
          .country
          ?.trim()
          .toLowerCase();
      if (country != null && country.isNotEmpty) {
        for (final dial in kCountryDialCodes) {
          if (dial.name.toLowerCase() == country) return dial.code;
        }
      }
    } catch (_) {}
    return '+1';
  }

  Widget _buildEntryEditorRow({
    required BuildContext context,
    required _LinkEntryDraft draft,
    required int index,
    required String valueHint,
    required TextInputType keyboardType,
    required bool canRemove,
    required VoidCallback onRemove,
    required VoidCallback onChanged,
  }) {
    // Figma: entry cards use person silhouette unless user picks a photo —
    // never fall back to the platform (WhatsApp/Facebook) logo.
    final displayLogo = draft.logo;
    final dialPrefix = _dialPrefixFor(context, keyboardType);
    final phoneHint = keyboardType == TextInputType.phone
        ? (valueHint.trim().isEmpty ? '202 555 0147' : valueHint)
        : valueHint;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await _pickLogoBase64();
                  if (picked.isNotEmpty) {
                    draft.logo = picked;
                    onChanged();
                  }
                },
                child: _selectedEntryAvatar(displayLogo),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _sheetTextField(
                  draft.nameController,
                  context.l10n.name,
                  TextInputType.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: draft.valueController,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            decoration: _barqodyFieldDecoration(
              hintText: phoneHint,
              prefix: dialPrefix == null
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dialPrefix,
                          style: WaUi.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 18,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: const Color(0xFFD1D1D6),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Public',
                style: WaUi.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: draft.isPublic,
                activeColor: Colors.white,
                activeTrackColor: Colors.black,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE5E5EA),
                onChanged: (val) {
                  draft.isPublic = val;
                  onChanged();
                },
              ),
              const Spacer(),
              if (canRemove) _deleteCircleButton(onRemove),
            ],
          ),
        ],
      ),
    );
  }

  /// Rounded-square avatar for a multi-entry row (Create New Link reference).
  Widget _selectedEntryAvatar(String logo, {double size = 48}) {
    const radius = 12.0;
    Widget content;
    if (logo.isEmpty) {
      content = Container(
        color: const Color(0xFF3A3A3C),
        alignment: Alignment.center,
        child: Image.asset(
          'assets/images/png/person-icon.png',
          width: size * 0.42,
          height: size * 0.42,
          color: Colors.white,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person,
            size: size * 0.48,
            color: Colors.white,
          ),
        ),
      );
    } else if (logo.startsWith('http://') || logo.startsWith('https://')) {
      content = Image.network(
        logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFF3A3A3C)),
      );
    } else {
      try {
        content = Image.memory(
          base64Decode(logo),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF3A3A3C)),
        );
      } catch (_) {
        content = Container(color: const Color(0xFF3A3A3C));
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: content),
    );
  }

  void _showNewTemplateLinkBottomSheet(
    BuildContext context,
    LinkTemplate template,
    ProfileProvider provider,
  ) {
    final drafts = <_LinkEntryDraft>[_LinkEntryDraft()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> doSave() async {
              final entries = _entriesFromDrafts(drafts);
              if (entries.isEmpty) return;
              await provider.addTemplateLink(
                template,
                entries.first.value,
                _linkPublicFromEntries(entries),
                context,
                entries: entries,
              );
              Navigator.pop(ctx);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.9,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(BarqodyChrome.sheetRadius),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SheetDragHandle(),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            CircleBackButton(onTap: () => Navigator.pop(ctx)),
                            Expanded(
                              child: Text(
                                ctx.l10n.createNewLink,
                                textAlign: TextAlign.center,
                                style: WaUi.toolsTitleOf(
                                  size: 20,
                                  weight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            // Balance back button; save is bottom Cancel/Save.
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _buildTemplateLogo(
                            template.logo,
                            size: 48,
                            isPro: template.isPro,
                            context: context,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 48,
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: BarqodyChrome.fieldFill,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                template.label,
                                style: WaUi.body.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMultiEntryEditors(
                        context: context,
                        drafts: drafts,
                        valueHint: template.fieldLabel,
                        keyboardType: _keyboardTypeFor(template.fieldType),
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: PillButton(
                              label: context.l10n.cancel,
                              filled: false,
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PillButton(
                              label: context.l10n.save,
                              onPressed: doSave,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetCheckButton(VoidCallback onTap) {
    return Material(
      color: Colors.black,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Image.asset(
              'assets/images/png/check-icon-1.png',
              width: 16,
              height: 16,
              color: Colors.white,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// App-bar delete for the whole social link (Link Settings).
  Widget _sheetDeleteLinkButton(VoidCallback onTap) {
    return Material(
      color: const Color(0xFFFF3B30),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Image.asset(
              'assets/images/png/trash-bin-icon.png',
              width: 20,
              height: 20,
              color: Colors.white,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.delete_outline,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextInputType _keyboardTypeFor(String fieldType) {
    switch (fieldType) {
      case 'phone':
        return TextInputType.phone;
      case 'email':
        return TextInputType.emailAddress;
      case 'url':
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  void _showNewLinkBottomSheet(
    BuildContext context,
    SocialPlatform platform,
    ProfileProvider provider,
  ) {
    final usernameController = TextEditingController();
    bool showLink = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> doSave() async {
              final value = usernameController.text.trim();
              if (value.isEmpty) return;
              await provider.addSocialLink(platform, value, showLink, context);
              Navigator.pop(ctx);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(BarqodyChrome.sheetRadius),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SheetDragHandle(),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          CircleBackButton(onTap: () => Navigator.pop(ctx)),
                          Expanded(
                            child: Text(
                              ctx.l10n.createNewLink,
                              textAlign: TextAlign.center,
                              style: WaUi.toolsTitleOf(
                                size: 20,
                                weight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon + Label row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.asset(
                            SocialLink.getAssetPath(platform),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.link, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 48,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: BarqodyChrome.fieldFill,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  SocialLink.getPlatformName(platform),
                                  style: WaUi.body.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ctx.l10n.setTextUnderTheLinkIcon,
                                style: WaUi.body.copyWith(
                                  fontSize: 13,
                                  color: BarqodyChrome.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Username field
                    _sheetTextField(
                      usernameController,
                      '${SocialLink.getPlatformName(platform)} username',
                      TextInputType.text,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.enterYourPlatformUsername(
                        SocialLink.getPlatformName(platform),
                      ),
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _showPublicToggle(
                      context: context,
                      isDark: false,
                      value: showLink,
                      onChanged: (val) => setState(() => showLink = val),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ctx.l10n.whenTurnedOffThisLinkWontBeShownOnYourProfile,
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            label: context.l10n.cancel,
                            filled: false,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PillButton(
                            label: context.l10n.save,
                            onPressed: doSave,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showGalleryLinkBottomSheet(
    BuildContext context,
    SocialLink link,
    ProfileProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool showLink = link.isPublic;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111111) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetHeader(
                      title: context.l10n.profileTabGallery,
                      onBack: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: WaUi.primaryButtonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GalleryLinkScreen(
                                items: provider.profile.gallery,
                                isOwner: true,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlack,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          context.l10n.profileTabGallery,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.showLink),
                      value: showLink,
                      onChanged: (value) {
                        setState(() => showLink = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _deleteCircleButton(() async {
                          await provider.deleteSocialLink(link.id, context);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: WaUi.primaryButtonHeight,
                            child: ElevatedButton(
                              onPressed: () async {
                                final updated = link.copyWith(
                                  isPublic: showLink,
                                  isActive: true,
                                );
                                final links = List<SocialLink>.from(
                                  provider.profile.socialLinks,
                                );
                                final index = links.indexWhere(
                                  (item) => item.id == link.id,
                                );
                                if (index != -1) {
                                  links[index] = updated;
                                  await provider.updateLinks(
                                    links: links,
                                    context: context,
                                  );
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlack,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                context.l10n.save,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> showExistingLinkBottomSheet(
    BuildContext context,
    SocialLink link,
    ProfileProvider provider,
  ) async {
    // Prefer latest provider copy + cached multi-entries.
    for (final item in provider.profile.socialLinks) {
      if (item.id == link.id ||
          (link.templateId != null &&
              link.templateId!.isNotEmpty &&
              item.templateId == link.templateId)) {
        link = item;
        break;
      }
    }
    link = await LinkEntriesCache.resolve(
      link,
      userId: provider.profile.id ?? '',
    );

    final catalogTemplate = _findLinkTemplate(link, provider);

    if (link.isGalleryLink ||
        (catalogTemplate != null && isGalleryLinkTemplate(catalogTemplate))) {
      _showGalleryLinkBottomSheet(context, link, provider);
      return;
    }

    final isCatalog = link.isCatalogLink ||
        catalogTemplate?.actionType == 'menu_catalog' ||
        link.url?.startsWith('catalog:') == true;

    if (link.isDocumentLink ||
        (catalogTemplate != null &&
            isDocumentsLinkTemplate(catalogTemplate))) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentLinkFormScreen(
            provider: provider,
            template: catalogTemplate ?? documentsLinkTemplate(),
            existingLink: link,
          ),
        ),
      );
      return;
    }

    if (isCatalog) {
      await _openCatalogLinkEditor(
        context,
        link,
        provider,
        template: catalogTemplate,
      );
      return;
    }

    final isCustomLink =
        link.isCustom ||
        (catalogTemplate?.isSystem == true &&
            catalogTemplate!.label.toLowerCase().contains('custom'));
    final template = LinkTemplate(
      id: link.templateId ?? '',
      categoryId: '',
      label: catalogTemplate?.label ?? link.platformName,
      fieldType:
          catalogTemplate?.fieldType ??
          link.fieldType ??
          (link.bankDetails != null
              ? 'bank'
              : link.contactCard != null
              ? 'contact_card'
              : 'url'),
      fieldLabel: catalogTemplate?.fieldLabel ?? link.fieldLabel ?? context.l10n.link,
      prefix: '',
      logo: link.logoUrl ?? catalogTemplate?.logo ?? '',
      isPro: false,
      isFeatured: false,
      isSystem: isCustomLink,
      actionType:
          catalogTemplate?.actionType ??
          (link.contactCard != null ? 'contact_card' : 'link'),
    );

    if (template.actionType == 'contact_card') {
      contact_card.showContactCardBottomSheet(
        context,
        template,
        provider,
        existingLink: link,
      );
      return;
    }

    if (template.fieldType == 'bank') {
      _showBankTemplateBottomSheet(
        context,
        template,
        provider,
        allowCustomMeta: isCustomLink,
        existingLink: link,
      );
      return;
    }

    if (isCustomLink) {
      _showCustomTemplateBottomSheet(
        context,
        template,
        provider,
        existingLink: link,
      );
      return;
    }

    final drafts = _draftsFromLink(link);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> doSave() async {
              final entries = _entriesFromDrafts(drafts);
              if (entries.isEmpty) return;
              final showLink = _linkPublicFromEntries(entries);
              if (link.templateId?.isNotEmpty == true) {
                await provider.updateTemplateLink(
                  link,
                  entries.first.value,
                  showLink,
                  context,
                  entries: entries,
                );
              } else {
                final updated = List<SocialLink>.from(
                  provider.profile.socialLinks,
                );
                final idx = updated.indexWhere((item) => item.id == link.id);
                if (idx != -1) {
                  updated[idx] = link.copyWith(
                    value: entries.first.value,
                    entries: entries,
                    isPublic: showLink,
                    isActive: true,
                  );
                  await provider.updateLinks(
                    links: updated,
                    context: context,
                  );
                }
              }
              Navigator.pop(ctx);
            }

            Future<void> doDeleteLink() async {
              await provider.deleteSocialLink(link.id, context);
              if (ctx.mounted) Navigator.pop(ctx);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.9,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(BarqodyChrome.sheetRadius),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SheetDragHandle(),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            CircleBackButton(onTap: () => Navigator.pop(ctx)),
                            Expanded(
                              child: Text(
                                ctx.l10n.linkSettings,
                                textAlign: TextAlign.center,
                                style: WaUi.toolsTitleOf(
                                  size: 20,
                                  weight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            _sheetDeleteLinkButton(doDeleteLink),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: LinkPlatformIcon(
                              link: link,
                              size: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 48,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: BarqodyChrome.fieldFill,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                link.platformName,
                                style: WaUi.body.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMultiEntryEditors(
                        context: context,
                        drafts: drafts,
                        valueHint: link.fieldLabel ??
                            '${SocialLink.getPlatformName(link.platform)} username',
                        keyboardType: _keyboardTypeFor(
                          link.fieldType ?? 'text',
                        ),
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: PillButton(
                              label: context.l10n.cancel,
                              filled: false,
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PillButton(
                              label: context.l10n.save,
                              onPressed: doSave,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
