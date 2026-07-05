import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/contact_card_sheet.dart' as contact_card;
import 'package:tapni_app/widgets/menu_catalog_sheet.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/utils/catalog_helper.dart';

class LinkSheet {
  void showAddLinkBottomSheet(BuildContext context, ProfileProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (provider.linkCatalog.isEmpty && !provider.isLinkCatalogLoading) {
      provider.fetchLinkCatalog();
    }

    bool isSearching = false;
    showModalBottomSheet(
      context: context,
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
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    //Header Open
                    Padding(
                      padding: const EdgeInsets.symmetric(
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
                                    decoration: const InputDecoration(
                                      hintText: 'Search links',
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (_) => setSheetState(() {}),
                                  )
                                : const Center(
                                    child: Text(
                                      'Add Link',
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
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (watchedProvider.linkCatalog.isNotEmpty) {
                            final query = searchController.text
                                .trim()
                                .toLowerCase();
                            final catalog = query.isEmpty
                                ? watchedProvider.linkCatalog
                                : watchedProvider.linkCatalog
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...catalog
                                    .map(
                                      (category) => _buildTemplateCategory(
                                        context,
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

                          return const Center(
                            child: Text(
                              'No link templates available',
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
  }) {
    showMenuCatalogSheet(
      context: context,
      catalogLabel: template.label,
      catalogType: template.catalogType ?? 'catalog',
      provider: provider,
      existingLink: existingLink,
      template: template,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    onTap: () {
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
                      if (template.actionType == 'menu_catalog') {
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
                          radius: 30,
                          isPro: template.isPro,
                          context: context,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.label,
                          style: const TextStyle(
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
                      margin: const EdgeInsets.only(top: 4, bottom: 14),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Custom link',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: _sheetTextField(
                            labelController,
                            'Label',
                            TextInputType.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _sheetTextField(valueController, 'Link', TextInputType.url),
                    const SizedBox(height: 14),
                    _showPublicToggle(
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
                      margin: const EdgeInsets.only(top: 4, bottom: 14),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      allowCustomMeta ? 'Custom bank' : template.label,
                      style: const TextStyle(
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: _sheetTextField(
                            labelController,
                            'Label',
                            TextInputType.text,
                            readOnly: !allowCustomMeta,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _sheetTextField(
                      holderController,
                      'Account holder name',
                      TextInputType.name,
                    ),
                    const SizedBox(height: 12),
                    _sheetTextField(
                      ibanController,
                      'IBAN number',
                      TextInputType.text,
                    ),
                    const SizedBox(height: 12),
                    _sheetTextField(
                      accountController,
                      'Account number',
                      TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    _showPublicToggle(
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
      decoration: InputDecoration(
        hintText: hint,
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        border: InputBorder.none,
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _showPublicToggle({
    required bool isDark,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Show link',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF1E2022),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _saveButton({required VoidCallback onPressed}) {
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
        child: const Text(
          'Save',
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
  }) {
    final isProUser = Provider.of<ProfileProvider>(
      context,
      listen: false,
    ).isProUser;
    // log("Building template logo for$logo");
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Icon(Icons.link),
    );

    if (logo.isEmpty) return placeholder;

    if (isPro && !isProUser) {
      return Stack(
        alignment: Alignment.topRight,
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(
              logo.replaceAll(" ", ""),
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => placeholder,
            ),
          ),
          // Container(
          //   width: size,
          //   height: size,
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(radius),
          //     color: Colors.white.withOpacity(0.8),
          //   ),
          //   // child:
          // ),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        logo.replaceAll(" ", ""),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
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
                      margin: const EdgeInsets.only(top: 4, bottom: 14),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Create new link',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTemplateLogo(
                          template.logo,
                          size: 60,

                          isPro: template.isPro,
                          context: context,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                readOnly: true,
                                initialValue: template.label,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Label',
                                  fillColor: Color(0xFFF5F5F5),
                                  filled: true,
                                  border: InputBorder.none,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Set text under the link icon',
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
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: template.fieldLabel,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        fillColor: const Color(0xFFF5F5F5),
                        filled: true,
                        border: InputBorder.none,
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      template.fieldLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Show link',
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
                              child: const Text(
                                'Save',
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
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 14),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    const Text(
                      'Create new link',
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
                                const Icon(Icons.link, size: 28),
                          ),
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                readOnly: true,

                                controller: labelController,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Label',
                                  fillColor: const Color(0xFFF5F5F5),
                                  filled: true,
                                  border: InputBorder.none,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Set text under the link icon',
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
                      style: const TextStyle(fontSize: 15),

                      decoration: InputDecoration(
                        hintText:
                            '${SocialLink.getPlatformName(platform)} username',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        fillColor: const Color(0xFFF5F5F5),
                        filled: true,
                        border: InputBorder.none,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your ${SocialLink.getPlatformName(platform)} username',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Show link toggle
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Show link',
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
                    const SizedBox(height: 6),
                    Text(
                      "When turned off this link won't be shown on your profile",
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
                              child: const Text(
                                'Save',
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

  void showExistingLinkBottomSheet(
    BuildContext context,
    SocialLink link,
    ProfileProvider provider,
  ) {
    LinkTemplate? catalogTemplate;
    for (final category in provider.linkCatalog) {
      for (final template in category.templates) {
        if (template.id == link.templateId) {
          catalogTemplate = template;
          break;
        }
      }
      if (catalogTemplate != null) break;
    }

    final isMenuCatalog =
        link.fieldType == 'menu_catalog' ||
        link.catalogItems != null ||
        link.url?.startsWith('catalog:') == true;

    if (isMenuCatalog) {
      if (catalogTemplate?.actionType == 'menu_catalog') {
        _openMenuCatalogFromTemplate(
          context,
          catalogTemplate!,
          provider,
          existingLink: link,
        );
        return;
      }

      final label = link.platformName.isNotEmpty
          ? link.platformName
          : CatalogHelper.labelForCategory(provider.profile.businessCategory);
      final catalogType = link.catalogType ??
          CatalogHelper.typeForCategory(provider.profile.businessCategory);
      showMenuCatalogSheet(
        context: context,
        catalogLabel: label,
        catalogType: catalogType,
        provider: provider,
        existingLink: link,
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
      fieldLabel: catalogTemplate?.fieldLabel ?? link.fieldLabel ?? 'Link',
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
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 14),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    const Text(
                      'Link Settings',
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

                          child: link.logoUrl?.isNotEmpty == true
                              ? Image.network(
                                  link.logoUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.link, size: 28),
                                )
                              : Image.asset(
                                  SocialLink.getAssetPath(link.platform),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.link, size: 28),
                                ),
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                readOnly: true,

                                controller: TextEditingController(
                                  text: link.platformName,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Label',
                                  fillColor: const Color(0xFFF5F5F5),
                                  filled: true,
                                  border: InputBorder.none,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Set text under the link icon',
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
                      style: const TextStyle(fontSize: 15),

                      decoration: InputDecoration(
                        hintText:
                            link.fieldLabel ??
                            '${SocialLink.getPlatformName(link.platform)} username',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        fillColor: const Color(0xFFF5F5F5),
                        filled: true,
                        border: InputBorder.none,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      link.fieldLabel ??
                          'Enter your ${SocialLink.getPlatformName(link.platform)} username',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Show link toggle
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Show link',
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
                    const SizedBox(height: 6),
                    Text(
                      "When turned off this link won't be shown on your profile",
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
                              child: const Text(
                                'Save',
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
