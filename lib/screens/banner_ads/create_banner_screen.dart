import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tapni_app/helper/image_helper.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/repository/explore_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class CreateBannerScreen extends StatefulWidget {
  final BannerAdPlan plan;
  final ExploreBanner? existing;

  const CreateBannerScreen({
    super.key,
    required this.plan,
    this.existing,
  });

  @override
  State<CreateBannerScreen> createState() => _CreateBannerScreenState();
}

class _CreateBannerScreenState extends State<CreateBannerScreen> {
  final _repo = ExploreRepo();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _buttonCtrl = TextEditingController();

  bool _showOnExplore = true;
  bool _saving = false;
  String? _imageDataUri;
  String? _existingImageUrl;
  File? _pickedFile;

  /// green | red | amber
  String _colorTheme = 'green';
  String _actionType = 'none';

  static const _themes = <String, Color>{
    'green': Color(0xFF0F766E),
    'red': Color(0xFFDC2626),
    'amber': Color(0xFFD97706),
  };

  static const _actions = <({String value, String label})>[
    (value: 'none', label: 'None'),
    (value: 'become_business', label: 'Open Business PRO upgrade'),
    (value: 'offers', label: 'Open Rewards offer'),
    (value: 'page_services', label: 'Open services'),
    (value: 'business', label: 'Open sepcific business'),
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _subtitleCtrl.text = e.subtitle;
      _buttonCtrl.text = e.buttonText;
      _existingImageUrl = e.image.isNotEmpty ? e.image : null;
      _showOnExplore = e.isActive;
      _actionType = e.actionType;
      _colorTheme = _themeFromGradient(e.gradientStart);
    }
  }

  String _themeFromGradient(String start) {
    final s = start.toUpperCase();
    if (s.contains('DC26') || s.contains('EF44') || s.contains('B91C')) {
      return 'red';
    }
    if (s.contains('D977') || s.contains('F59E') || s.contains('FBBF')) {
      return 'amber';
    }
    return 'green';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _buttonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await pickFile();
    if (picked?.file == null) return;
    final file = picked!.file!;
    final dataUri = await fileToDataUri(file);
    setState(() {
      _pickedFile = file;
      _imageDataUri = dataUri;
      _existingImageUrl = null;
    });
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final hasImage =
        (_imageDataUri != null && _imageDataUri!.isNotEmpty) ||
        (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
    if (title.isEmpty && !hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a banner image or a title')),
      );
      return;
    }

    setState(() => _saving = true);

    final body = <String, dynamic>{
      'title': title,
      'subtitle': _subtitleCtrl.text.trim(),
      'buttonText': _buttonCtrl.text.trim(),
      'colorTheme': _colorTheme,
      'actionType': _actionType,
      'planId': widget.plan.id,
      'showOnExplore': _showOnExplore,
      if (_imageDataUri != null) 'image': _imageDataUri,
    };

    final res = _isEdit
        ? await _repo.updateMyBanner(widget.existing!.id, body)
        : await _repo.createMyBanner(body);

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? (_isEdit ? 'Banner updated' : 'Banner created')
              : (res.message ?? 'Could not save banner'),
        ),
      ),
    );
    if (res.success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Banner Ads'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    _isEdit ? 'Edit Banner' : 'Create Banner',
                    style: WaUi.toolsTitleOf(
                      size: 24,
                      weight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set up a beautiful carousel slide for the Explore screen in your mobile app.',
                    style: WaUi.body.copyWith(
                      fontSize: 13.5,
                      height: 1.4,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.plan.label} · \$${widget.plan.price.toStringAsFixed(0)}',
                    style: WaUi.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Basic information',
                    subtitle:
                        'Optional text. Leave blank for an image-only banner.',
                    child: Column(
                      children: [
                        _LabeledField(
                          label: 'TITLE',
                          controller: _titleCtrl,
                          hint: 'Become a business (optional)',
                        ),
                        const SizedBox(height: 12),
                        _LabeledField(
                          label: 'SUBTITLE',
                          controller: _subtitleCtrl,
                          hint: 'Optional supporting text',
                        ),
                        const SizedBox(height: 12),
                        _LabeledField(
                          label: 'BUTTON TEXT',
                          controller: _buttonCtrl,
                          hint: 'Optional leave empty to hide',
                        ),
                        const SizedBox(height: 16),
                        _ShowOnExploreToggle(
                          value: _showOnExplore,
                          onChanged: (v) => setState(() => _showOnExplore = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Appearance',
                    subtitle:
                        'Upload an image for a full-bleed banner, or use a color theme with text.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BANNER IMAGE',
                          style: WaUi.label.copyWith(
                            fontSize: 11,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ImageUploadBox(
                          file: _pickedFile,
                          networkUrl: _existingImageUrl,
                          onTap: _pickImage,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '• 1200 x 560 px (best) — landscape ~2.1:1\n'
                          '• Minimum: 800 x 375 px\n'
                          '• Format: JPG or PNG — keep under 1 MB\n'
                          '• Keep important content in the center — edges may crop on some phones.',
                          style: WaUi.body.copyWith(
                            fontSize: 11.5,
                            height: 1.45,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'COLOR THEME',
                          style: WaUi.label.copyWith(
                            fontSize: 11,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: _themes.entries.map((e) {
                            final selected = _colorTheme == e.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _colorTheme = e.key),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: e.value,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.black
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Used only when there is no image.',
                          style: WaUi.body.copyWith(
                            fontSize: 12,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Tap action',
                    subtitle: 'Choose where users go when they tap.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTION',
                          style: WaUi.label.copyWith(
                            fontSize: 11,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ActionDropdown(
                          value: _actionType,
                          options: _actions,
                          onChanged: (v) => setState(() => _actionType = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          label: 'Cancel',
                          filled: false,
                          onPressed: _saving
                              ? () {}
                              : () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PillButton(
                          label: _isEdit ? 'Save' : 'Create Banner',
                          enabled: !_saving,
                          onPressed: _saving ? () {} : _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WaUi.toolsTitleOf(
              size: 16,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: WaUi.body.copyWith(
              fontSize: 12.5,
              height: 1.35,
              color: BarqodyChrome.secondaryText,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WaUi.label.copyWith(
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
            color: BarqodyChrome.secondaryText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: WaUi.body.copyWith(fontSize: 14, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WaUi.body.copyWith(
              fontSize: 14,
              color: const Color(0xFFB0B0B5),
            ),
            filled: true,
            fillColor: BarqodyChrome.fieldFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShowOnExploreToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ShowOnExploreToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SHOW ON EXPLORE',
                style: WaUi.label.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Display this banner in the app carousel.',
                style: WaUi.body.copyWith(
                  fontSize: 12,
                  color: BarqodyChrome.secondaryText,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: Colors.black,
          activeThumbColor: Colors.white,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  final File? file;
  final String? networkUrl;
  final VoidCallback onTap;

  const _ImageUploadBox({
    required this.file,
    required this.networkUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = file != null || (networkUrl != null && networkUrl!.isNotEmpty);

    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: 148,
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: file != null
                      ? Image.file(file!, fit: BoxFit.cover)
                      : Image.network(networkUrl!, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/png/add-camera.png',
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.add_a_photo_outlined,
                        size: 32,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Upload banner image PNG or JPG',
                      style: WaUi.body.copyWith(
                        fontSize: 13,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ActionDropdown extends StatelessWidget {
  final String value;
  final List<({String value, String label})> options;
  final ValueChanged<String> onChanged;

  const _ActionDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.any((o) => o.value == value) ? value : 'none',
          isExpanded: true,
          icon: Image.asset(
            'assets/images/png/downward-icon.png',
            width: 14,
            height: 14,
            color: Colors.black,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          style: WaUi.body.copyWith(fontSize: 14, color: Colors.black),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          items: options
              .map(
                (o) => DropdownMenuItem(
                  value: o.value,
                  child: Text(o.label),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
