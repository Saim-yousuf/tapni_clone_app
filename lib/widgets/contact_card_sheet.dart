import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/link_template.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
void showContactCardBottomSheet(
  BuildContext context,
  LinkTemplate template,
  ProfileProvider provider, {
  SocialLink? existingLink,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (context) => ContactCardBottomSheet(
      template: template,
      provider: provider,
      existingLink: existingLink,
    ),
  );
}

class ContactCardBottomSheet extends StatefulWidget {
  final LinkTemplate template;
  final ProfileProvider provider;
  final SocialLink? existingLink;

  const ContactCardBottomSheet({
    super.key,
    required this.template,
    required this.provider,
    this.existingLink,
  });

  @override
  State<ContactCardBottomSheet> createState() => _ContactCardBottomSheetState();
}

class _ContactCardBottomSheetState extends State<ContactCardBottomSheet> {
  bool isPersonal = true;
  bool personalAddressExpanded = false;
  bool businessAddressExpanded = false;
  bool showLink = true;
  String _logo = '';
  final _scrollController = ScrollController();

  late final TextEditingController _labelCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _bioCtrl;

  late final List<TextEditingController> _personalPhoneCtrls;
  late final List<TextEditingController> _personalEmailCtrls;
  late final List<TextEditingController> _personalWebsiteCtrls;

  late final List<TextEditingController> _businessPhoneCtrls;
  late final List<TextEditingController> _businessEmailCtrls;
  late final List<TextEditingController> _businessWebsiteCtrls;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _faxCtrl;

  late final TextEditingController _personalAddressCtrl;
  late final TextEditingController _personalStreetCtrl;
  late final TextEditingController _personalNumberCtrl;
  late final TextEditingController _personalCityCtrl;
  late final TextEditingController _personalZipCtrl;
  late final TextEditingController _personalCountryCtrl;

  late final TextEditingController _businessAddressCtrl;
  late final TextEditingController _businessStreetCtrl;
  late final TextEditingController _businessNumberCtrl;
  late final TextEditingController _businessCityCtrl;
  late final TextEditingController _businessZipCtrl;
  late final TextEditingController _businessCountryCtrl;

  @override
  void initState() {
    super.initState();
    final details = widget.existingLink?.contactCard ?? {};
    isPersonal = (details['cardType'] ?? 'personal') != 'business';
    showLink = widget.existingLink?.isPublic ?? true;
    _logo = (widget.existingLink?.logoUrl?.trim().isNotEmpty == true
            ? widget.existingLink!.logoUrl!
            : widget.template.logo.trim());

    _labelCtrl = TextEditingController(
      text:
          details['label'] ??
          widget.existingLink?.platformName ??
          widget.template.label,
    );
    _firstNameCtrl = TextEditingController(text: details['firstName'] ?? '');
    _lastNameCtrl = TextEditingController(text: details['lastName'] ?? '');
    _bioCtrl = TextEditingController(text: details['bio'] ?? '');

    _personalPhoneCtrls = _controllersFromDetails(details, 'phone');
    _personalEmailCtrls = _controllersFromDetails(details, 'email');
    _personalWebsiteCtrls = _controllersFromDetails(details, 'website');
    _businessPhoneCtrls = _controllersFromDetails(details, 'businessPhone');
    _businessEmailCtrls = _controllersFromDetails(details, 'businessEmail');
    _businessWebsiteCtrls = _controllersFromDetails(details, 'businessWebsite');

    _companyCtrl = TextEditingController(text: details['company'] ?? '');
    _jobTitleCtrl = TextEditingController(text: details['jobTitle'] ?? '');
    _faxCtrl = TextEditingController(text: details['fax'] ?? '');

    _personalAddressCtrl = TextEditingController(
      text: details['address'] ?? '',
    );
    _personalStreetCtrl = TextEditingController(text: details['street'] ?? '');
    _personalNumberCtrl = TextEditingController(text: details['number'] ?? '');
    _personalCityCtrl = TextEditingController(text: details['city'] ?? '');
    _personalZipCtrl = TextEditingController(text: details['zip'] ?? '');
    _personalCountryCtrl = TextEditingController(
      text: details['country'] ?? '',
    );

    _businessAddressCtrl = TextEditingController(
      text: details['businessAddress'] ?? '',
    );
    _businessStreetCtrl = TextEditingController(
      text: details['businessStreet'] ?? '',
    );
    _businessNumberCtrl = TextEditingController(
      text: details['businessNumber'] ?? '',
    );
    _businessCityCtrl = TextEditingController(
      text: details['businessCity'] ?? '',
    );
    _businessZipCtrl = TextEditingController(
      text: details['businessZip'] ?? '',
    );
    _businessCountryCtrl = TextEditingController(
      text: details['businessCountry'] ?? '',
    );
  }

  List<TextEditingController> _controllersFromDetails(
    Map<String, String> details,
    String key,
  ) {
    final values = [
      details[key],
      details['${key}2'],
      details['${key}3'],
    ].where((value) => value?.isNotEmpty == true).cast<String>().toList();
    if (values.isEmpty) values.add('');
    return values.map((value) => TextEditingController(text: value)).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in [
      _labelCtrl,
      _firstNameCtrl,
      _lastNameCtrl,
      _bioCtrl,
      _companyCtrl,
      _jobTitleCtrl,
      _faxCtrl,
      _personalAddressCtrl,
      _personalStreetCtrl,
      _personalNumberCtrl,
      _personalCityCtrl,
      _personalZipCtrl,
      _personalCountryCtrl,
      _businessAddressCtrl,
      _businessStreetCtrl,
      _businessNumberCtrl,
      _businessCityCtrl,
      _businessZipCtrl,
      _businessCountryCtrl,
      ..._personalPhoneCtrls,
      ..._personalEmailCtrls,
      ..._personalWebsiteCtrls,
      ..._businessPhoneCtrls,
      ..._businessEmailCtrls,
      ..._businessWebsiteCtrls,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _ensureFieldVisible(BuildContext fieldContext) {
    // Wait for keyboard animation, then bring the focused field into view.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || !fieldContext.mounted) return;
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.15,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final sheetHeight = (media.size.height * 0.80)
        .clamp(0.0, media.size.height - keyboardInset);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SizedBox(
        height: sheetHeight,
        child: Material(
          color: AppTheme.secondaryWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildHandle(),
              _buildTitle(),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    const SizedBox(height: 12),
                    _buildAvatarRow(),
                    const SizedBox(height: 12),
                    _buildTextField(_firstNameCtrl, context.l10n.firstName),
                    const SizedBox(height: 10),
                    _buildTextField(_lastNameCtrl, context.l10n.lastName),
                    const SizedBox(height: 10),
                    _buildTextField(
                      _bioCtrl,
                      context.l10n.enterBioForTheContactCard,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _buildToggle(),
                    const SizedBox(height: 12),
                    if (isPersonal)
                      ..._buildPersonalFields()
                    else
                      ..._buildBusinessFields(),
                    const SizedBox(height: 10),
                    _buildAddressSection(),
                    const SizedBox(height: 16),
                    _buildShowLinkToggle(),
                    const SizedBox(height: 16),
                    _buildBottomBar(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() => Container(
    margin: EdgeInsets.only(top: 12, bottom: 8),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _buildTitle() => Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      context.l10n.contactCard,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildAvatarRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: _pickLogo,
        child: Stack(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildLogoPreview(),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 0.5),
                ),
                child: Icon(Icons.edit, size: 12, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_labelCtrl, context.l10n.saveContact2),
            SizedBox(height: 6),
            Text(
              context.l10n.setTextUnderTheLinkIcon,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildLogoPreview() {
    if (_logo.isNotEmpty) {
      if (_logo.startsWith('http://') || _logo.startsWith('https://')) {
        return Image.network(
          _logo,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultContactIcon(),
        );
      }
      try {
        return Image.memory(
          base64Decode(_logo),
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultContactIcon(),
        );
      } catch (_) {
        return _defaultContactIcon();
      }
    }
    return _defaultContactIcon();
  }

  Widget _defaultContactIcon() {
    return Image.asset(
      SocialLink.getAssetPath(SocialPlatform.contact),
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Colors.grey.shade200,
        child: Icon(Icons.person, size: 40, color: Colors.grey[500]),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final file = await pickFile();
    if (file?.file == null) return;
    final encoded = await fileToBase64(File(file!.file!.path));
    if (encoded.isEmpty || !mounted) return;
    setState(() => _logo = encoded);
  }

  Widget _buildToggle() => Container(
    height: 48,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        _toggleTab('Business', !isPersonal, () {
          setState(() => isPersonal = false);
        }),
        _toggleTab('Personal', isPersonal, () {
          setState(() => isPersonal = true);
        }),
      ],
    ),
  );

  Widget _toggleTab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ),
    ),
  );

  List<Widget> _buildPersonalFields() => [
    _buildMultiField(_personalPhoneCtrls, context.l10n.contactCardPhone),
    SizedBox(height: 10),
    _buildMultiField(_personalEmailCtrls, context.l10n.contactCardEmail),
    SizedBox(height: 10),
    _buildMultiField(_personalWebsiteCtrls, context.l10n.contactCardWebsite),
  ];

  List<Widget> _buildBusinessFields() => [
    _buildMultiField(_businessPhoneCtrls, context.l10n.businessPhoneNumber),
    SizedBox(height: 10),
    _buildMultiField(_businessEmailCtrls, context.l10n.businessEmailAddress),
    SizedBox(height: 10),
    _buildMultiField(_businessWebsiteCtrls, context.l10n.businessWebsite),
    SizedBox(height: 10),
    _buildTextField(_jobTitleCtrl, context.l10n.jobTitle2),
    SizedBox(height: 10),
    _buildTextField(_companyCtrl, context.l10n.contactCardCompanyName),
    SizedBox(height: 10),
    _buildTextField(_faxCtrl, context.l10n.businessFax),
  ];

  Widget _buildMultiField(
    List<TextEditingController> controllers,
    String hint,
  ) {
    return Column(
      children: List.generate(controllers.length, (index) {
        final isFirst = index == 0;
        final canAdd = isFirst && controllers.length < 3;
        final canRemove = !isFirst;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < controllers.length - 1 ? 10 : 0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (fieldContext) {
                    return TextField(
                      controller: controllers[index],
                      scrollPadding:
                          const EdgeInsets.fromLTRB(20, 80, 20, 120),
                      onTap: () => _ensureFieldVisible(fieldContext),
                      decoration: _inputDecoration(hint),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (canAdd) {
                    setState(() {
                      controllers.add(TextEditingController());
                    });
                  } else if (canRemove) {
                    setState(() {
                      controllers[index].dispose();
                      controllers.removeAt(index);
                    });
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    canRemove ? Icons.remove : Icons.add,
                    color: canAdd || canRemove
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAddressSection() {
    final expanded = isPersonal
        ? personalAddressExpanded
        : businessAddressExpanded;
    final addressCtrl = isPersonal
        ? _personalAddressCtrl
        : _businessAddressCtrl;
    final streetCtrl = isPersonal ? _personalStreetCtrl : _businessStreetCtrl;
    final numberCtrl = isPersonal ? _personalNumberCtrl : _businessNumberCtrl;
    final cityCtrl = isPersonal ? _personalCityCtrl : _businessCityCtrl;
    final zipCtrl = isPersonal ? _personalZipCtrl : _businessZipCtrl;
    final countryCtrl = isPersonal
        ? _personalCountryCtrl
        : _businessCountryCtrl;
    final hint = isPersonal
        ? context.l10n.contactCardHomeAddress
        : context.l10n.contactCardBusinessAddress;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(addressCtrl, hint),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isPersonal) {
                    personalAddressExpanded = !personalAddressExpanded;
                  } else {
                    businessAddressExpanded = !businessAddressExpanded;
                  }
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        AnimatedCrossFade(
          duration: Duration(milliseconds: 250),
          crossFadeState: expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: EdgeInsets.only(top: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTextField(streetCtrl, context.l10n.streetName)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: _buildTextField(numberCtrl, 'Number'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(cityCtrl, 'City')),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: _buildTextField(zipCtrl, 'ZIP'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(countryCtrl, 'Country'),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey[200]!)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () async {
              final existingLink = widget.existingLink;
              if (existingLink != null) {
                await widget.provider.deleteSocialLink(
                  existingLink.id,
                  context,
                );
              }
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saveContactCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(context.l10n.save,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildShowLinkToggle() => Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.showLink,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        Switch(
          value: showLink,
          onChanged: (value) => setState(() => showLink = value),
          activeThumbColor: Colors.white,
          activeTrackColor: Colors.black,
        ),
      ],
    ),
  );

  Future<void> _saveContactCard() async {
    final label = _labelCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _firstFilled(
      isPersonal ? _personalPhoneCtrls : _businessPhoneCtrls,
    );
    final email = _firstFilled(
      isPersonal ? _personalEmailCtrls : _businessEmailCtrls,
    );

    if (label.isEmpty || (firstName.isEmpty && lastName.isEmpty)) return;
    if (phone.isEmpty && email.isEmpty) return;

    final details = <String, String>{
      'label': label,
      'cardType': isPersonal ? 'personal' : 'business',
      'firstName': firstName,
      'lastName': lastName,
      'bio': _bioCtrl.text.trim(),
      ..._multiValues('phone', _personalPhoneCtrls),
      ..._multiValues('email', _personalEmailCtrls),
      ..._multiValues('website', _personalWebsiteCtrls),
      ..._multiValues('businessPhone', _businessPhoneCtrls),
      ..._multiValues('businessEmail', _businessEmailCtrls),
      ..._multiValues('businessWebsite', _businessWebsiteCtrls),
      'company': _companyCtrl.text.trim(),
      'jobTitle': _jobTitleCtrl.text.trim(),
      'fax': _faxCtrl.text.trim(),
      'address': _personalAddressCtrl.text.trim(),
      'street': _personalStreetCtrl.text.trim(),
      'number': _personalNumberCtrl.text.trim(),
      'city': _personalCityCtrl.text.trim(),
      'zip': _personalZipCtrl.text.trim(),
      'country': _personalCountryCtrl.text.trim(),
      'businessAddress': _businessAddressCtrl.text.trim(),
      'businessStreet': _businessStreetCtrl.text.trim(),
      'businessNumber': _businessNumberCtrl.text.trim(),
      'businessCity': _businessCityCtrl.text.trim(),
      'businessZip': _businessZipCtrl.text.trim(),
      'businessCountry': _businessCountryCtrl.text.trim(),
    };
    final value = email.isNotEmpty ? email : phone;
    final existingLink = widget.existingLink;

    if (existingLink == null) {
      await widget.provider.addCustomTemplateLink(
        template: widget.template,
        label: label,
        value: value,
        showLink: showLink,
        context: context,
        logo: _logo,
        contactCard: details,
      );
    } else {
      await widget.provider.updateCustomTemplateLink(
        link: existingLink,
        label: label,
        value: value,
        showLink: showLink,
        context: context,
        logo: _logo.isNotEmpty ? _logo : existingLink.logoUrl,
        contactCard: details,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  String _firstFilled(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      final value = controller.text.trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Map<String, String> _multiValues(
    String key,
    List<TextEditingController> controllers,
  ) {
    final values = controllers
        .map((controller) => controller.text.trim())
        .toList();
    return {
      key: values.isNotEmpty ? values[0] : '',
      '${key}2': values.length > 1 ? values[1] : '',
      '${key}3': values.length > 2 ? values[2] : '',
    };
  }

  InputDecoration _inputDecoration(String hint) => WaUi.fieldDecoration(
    hintText: hint,
    radius: 12,
  );

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return Builder(
      builder: (fieldContext) {
        return TextField(
          controller: ctrl,
          maxLines: maxLines,
          scrollPadding: const EdgeInsets.fromLTRB(20, 80, 20, 120),
          onTap: () => _ensureFieldVisible(fieldContext),
          decoration: _inputDecoration(hint),
        );
      },
    );
  }
}
