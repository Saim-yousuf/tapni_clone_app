import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/country_dial_codes.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/contact_card_sheet.dart' as contact_card;
import 'package:tapni_app/widgets/link_platform_icon.dart';
import 'package:tapni_app/widgets/menu_catalog_sheet.dart';
import 'package:tapni_app/widgets/business_completeness_sheet.dart';
import 'package:tapni_app/screens/catalog/document_link_form_screen.dart';
import 'package:tapni_app/screens/gallery_link_screen.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/utils/catalog_helper.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class LinkSheet {
  void showAddLinkBottomSheet(BuildContext context, ProfileProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parentContext = context;
    if (provider.linkCatalog.isEmpty && !provider.isLinkCatalogLoading) {
      provider.fetchLinkCatalog();
    }

    bool isSearching = false;
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    Container(
                      margin: EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    //Header Open
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_new, size: 24),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          Expanded(
                            child: isSearching
                                ? TextField(
                                    controller: searchController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: ctx.l10n.searchLinks,
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (_) => setSheetState(() {}),
                                  )
                                : Center(
                                    child: Text(
                                      ctx.l10n.addLink,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ),
                          IconButton(
                            icon: Icon(
                              isSearching
                                  ? Icons.close_rounded
                                  : Icons.search_rounded,
                              size: 24,
                            ),
                            onPressed: () {
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
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (watchedProvider.linkCatalog.isNotEmpty) {
                            final query = searchController.text
                                .trim()
                                .toLowerCase();
                            final countryFiltered = ensureGalleryLinkTemplate(
                              ensureProductCatalogTemplate(
                                ensureDocumentsCatalogTemplate(
                                  filterCatalogByUserCountry(
                                    watchedProvider.linkCatalog,
                                    _userCountry(watchedProvider),
                                  ),
                                ),
                              ),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
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
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.grey,
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
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
                        contact_card.showContactCardBottomSheet(
                          context,
                          template,
                          provider,
                        );
                      } else if (_isCustomTemplate(template)) {
                        _showCustomTemplateBottomSheet(
                          context,
                          template,
                          provider,
                        );
                      } else if (template.fieldType == 'bank') {
                        _showBankTemplateBottomSheet(
                          context,
                          template,
                          provider,
                        );
                      } else {
                        _showNewTemplateLinkBottomSheet(
                          context,
                          template,
                          provider,
                        );
                      }
                    },
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
                        const SizedBox(height: 4),
                        Text(
                          template.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryBlack,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
    final valueController = TextEditingController(
      text: existingLink?.value ?? '',
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
                    Container(
                      margin: EdgeInsets.only(top: 4, bottom: 14),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(ctx.l10n.customLink,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 20),
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
                    _sheetTextField(valueController, context.l10n.link, TextInputType.url),
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
                              final value = valueController.text.trim();
                              if (label.isEmpty || value.isEmpty) return;
                              if (existingLink == null) {
                                await provider.addCustomTemplateLink(
                                  template: template,
                                  label: label,
                                  value: value,
                                  showLink: showLink,
                                  context: context,
                                  logo: logo,
                                );
                              } else {
                                await provider.updateCustomTemplateLink(
                                  link: existingLink,
                                  label: label,
                                  value: value,
                                  showLink: showLink,
                                  context: context,
                                  logo: logo,
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

  Widget _selectedLogoTile(String logo) {
    if (logo.isNotEmpty) {
      if (logo.startsWith('http://') || logo.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            logo,
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _logoPlaceholder(true),
          ),
        );
      }

      try {
        return ClipRRect(
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
        return _logoPlaceholder(true);
      }
    }

    return _logoPlaceholder(false);
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
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: IconButton(
        icon: const Icon(Icons.delete_forever_outlined, size: 24),
        color: Colors.grey.shade600,
        onPressed: onPressed,
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
                    Container(
                      margin: EdgeInsets.only(top: 4, bottom: 14),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      allowCustomMeta ? context.l10n.customBank : template.label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
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
      decoration: WaUi.fieldDecoration(
        hintText: hint,
        radius: 10,
      ),
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
        color: isDark ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.showLink,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: Color(0xFF1E2022),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _saveButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: Text(context.l10n.save,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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

  void _showNewTemplateLinkBottomSheet(
    BuildContext context,
    LinkTemplate template,
    ProfileProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueController = TextEditingController();
    bool showLink = true;

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
                    Container(
                      margin: EdgeInsets.only(top: 4, bottom: 14),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(ctx.l10n.createNewLink,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTemplateLogo(
                          template.logo,
                          size: 60,

                          isPro: template.isPro,
                          context: context,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                readOnly: true,
                                initialValue: template.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: WaUi.fieldDecoration(
                                  hintText: ctx.l10n.label,
                                  radius: 10,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                ctx.l10n.setTextUnderTheLinkIcon,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: valueController,
                      autofocus: true,
                      keyboardType: _keyboardTypeFor(template.fieldType),
                      style: TextStyle(fontSize: 15),
                      decoration: WaUi.fieldDecoration(
                        hintText: template.fieldLabel,
                        radius: 10,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      template.fieldLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color(0xFF1E1E1E)
                            : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(ctx.l10n.showLink,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: showLink,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF1E2022),
                            onChanged: (val) => setState(() => showLink = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                    Row(
                      children: [
                        const SizedBox(width: 60),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () async {
                                final value = valueController.text.trim();
                                if (value.isNotEmpty) {
                                  await provider.addTemplateLink(
                                    template,
                                    value,
                                    showLink,
                                    context,
                                  );
                                  Navigator.pop(ctx);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlack,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: Text(context.l10n.save,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usernameController = TextEditingController();
    final labelController = TextEditingController(
      text: SocialLink.getPlatformName(platform),
    );
    bool showLink = true;

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
                    // Drag handle
                    Container(
                      margin: EdgeInsets.only(top: 4, bottom: 14),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    Text(ctx.l10n.createNewLink,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon + Label row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,

                          child: Image.asset(
                            SocialLink.getAssetPath(platform),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.link, size: 28),
                          ),
                        ),
                        SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                readOnly: true,

                                controller: labelController,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: WaUi.fieldDecoration(
                                  hintText: ctx.l10n.label,
                                  radius: 10,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                ctx.l10n.setTextUnderTheLinkIcon,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Username field
                    TextField(
                      controller: usernameController,
                      autofocus: true,
                      style: TextStyle(fontSize: 15),

                      decoration: WaUi.fieldDecoration(
                        hintText:
                            '${SocialLink.getPlatformName(platform)} username',
                        radius: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.enterYourPlatformUsername(
                        SocialLink.getPlatformName(platform),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 14),

                    // Show link toggle
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color(0xFF1E1E1E)
                            : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(ctx.l10n.showLink,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: showLink,
                            activeColor: Colors.white,
                            activeTrackColor: Color(0xFF1E2022),
                            onChanged: (val) => setState(() => showLink = val),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      ctx.l10n.whenTurnedOffThisLinkWontBeShownOnYourProfile,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 80),

                    // Bottom row: delete + save
                    Row(
                      children: [
                        // Delete button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFF5F5F5),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 0.5,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.delete_forever_outlined, size: 24),
                            color: Colors.grey.shade600,
                            onPressed: () async {
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Save button
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () async {
                                final value = usernameController.text.trim();
                                if (value.isNotEmpty) {
                                  await provider.addSocialLink(
                                    platform,
                                    value,
                                    showLink,
                                    context,
                                  );
                                  Navigator.pop(ctx);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlack,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: Text(context.l10n.save,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.photo_library_rounded,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            context.l10n.profileTabGallery,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          context.l10n.profileTabGallery,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
                            height: 48,
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Text(
                                context.l10n.save,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueController = TextEditingController(text: link.value);
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
                    // Drag handle
                    Container(
                      margin: EdgeInsets.only(top: 4, bottom: 14),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    Text(ctx.l10n.linkSettings,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon + Label row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,

                          child: LinkPlatformIcon(
                            link: link,
                            size: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                readOnly: true,

                                controller: TextEditingController(
                                  text: link.platformName,
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: WaUi.fieldDecoration(
                                  hintText: ctx.l10n.label,
                                  radius: 10,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                ctx.l10n.setTextUnderTheLinkIcon,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Username field
                    TextField(
                      controller: valueController,
                      autofocus: true,
                      style: TextStyle(fontSize: 15),

                      decoration: WaUi.fieldDecoration(
                        hintText:
                            link.fieldLabel ??
                            '${SocialLink.getPlatformName(link.platform)} username',
                        radius: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      link.fieldLabel ??
                          context.l10n.enterYourPlatformUsername(
                            SocialLink.getPlatformName(link.platform),
                          ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 14),

                    // Show link toggle
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color(0xFF1E1E1E)
                            : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(ctx.l10n.showLink,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: showLink,
                            activeColor: Colors.white,
                            activeTrackColor: Color(0xFF1E2022),
                            onChanged: (val) => setState(() => showLink = val),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      ctx.l10n.whenTurnedOffThisLinkWontBeShownOnYourProfile,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 80),

                    // Bottom row: delete + save
                    Row(
                      children: [
                        // Delete button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFF5F5F5),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 0.5,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.delete_forever_outlined, size: 24),
                            color: Colors.grey.shade600,
                            onPressed: () async {
                              await provider.deleteSocialLink(link.id, context);
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Save button
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () async {
                                final value = valueController.text.trim();
                                if (value.isNotEmpty) {
                                  if (link.templateId?.isNotEmpty == true) {
                                    await provider.updateTemplateLink(
                                      link,
                                      value,
                                      showLink,
                                      context,
                                    );
                                  } else {
                                    await provider.updateSocialLink(
                                      link.platform,
                                      value,
                                      showLink,
                                      context,
                                    );
                                  }
                                  Navigator.pop(ctx);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlack,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: Text(context.l10n.save,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
}
