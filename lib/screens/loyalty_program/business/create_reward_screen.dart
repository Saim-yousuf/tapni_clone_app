import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class CreateRewardScreen extends StatefulWidget {
  final RewardProgram? existing;
  const CreateRewardScreen({super.key, this.existing});

  @override
  State<CreateRewardScreen> createState() => _CreateRewardScreenState();
}

class _CreateRewardScreenState extends State<CreateRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _stampsController = TextEditingController();
  String? _logoBase64;
  String? _existingLogoUrl;
  String? _stampIconBase64;
  String? _existingStampIconUrl;
  String? _unstampIconBase64;
  String? _existingUnstampIconUrl;
  RewardTheme _theme = RewardTheme();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final p = widget.existing!;
      _labelController.text = p.label;
      _titleController.text = p.title;
      _descController.text = p.description;
      _stampsController.text = p.stamps.toString();
      _theme = p.theme;
      _existingLogoUrl = p.logo;
      _existingStampIconUrl = p.stampIcon;
      _existingUnstampIconUrl = p.unstampIcon;
    } else {
      _stampsController.text = '10';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _stampsController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() => _pickImage((base64) => _logoBase64 = base64);

  Future<void> _pickImage(void Function(String base64) onPicked) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 200,
    );
    if (picked == null) return;
    final bytes = await File(picked.path).readAsBytes();
    final base64Str = base64Encode(bytes);
    final ext = picked.path.split('.').last.toLowerCase();
    setState(() => onPicked('data:image/$ext;base64,$base64Str'));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final stamps = int.tryParse(_stampsController.text.trim());
    if (stamps == null || stamps < 1) {
      _showSnack(context.l10n.pleaseEnterAValidNumberOfStamps);
      return;
    }

    setState(() => _isLoading = true);

    final body = {
      'label': _labelController.text.trim(),
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'stamps': stamps,
      'theme': _theme.toJson(),
      if (_logoBase64 != null) 'logo': _logoBase64,
      if (_logoBase64 == null && _existingLogoUrl != null) 'logo': _existingLogoUrl,
    };

    if (widget.existing != null) {
      body['stampIcon'] = _stampIconBase64 ?? _existingStampIconUrl ?? '';
      body['unstampIcon'] = _unstampIconBase64 ?? _existingUnstampIconUrl ?? '';
    } else {
      if (_stampIconBase64 != null) body['stampIcon'] = _stampIconBase64;
      if (_unstampIconBase64 != null) body['unstampIcon'] = _unstampIconBase64;
    }

    final repo = RewardRepo();
    ApiResponse res;
    if (widget.existing != null) {
      res = await repo.updateProgram(widget.existing!.id, body);
    } else {
      res = await repo.createProgram(body);
    }

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (res.success) {
      Navigator.pop(context, true);
    } else {
      _showSnack(res.message ?? context.l10n.failedToSave);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              BarqodyTitleBar(
                title: isEdit ? context.l10n.editReward : 'Create Program',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _barqodyLabel('Reward Program Name'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _labelController,
                        'e.g. Coffee Rewards',
                        required: true,
                      ),
                      const SizedBox(height: 20),
                      _barqodyLabel('Stamps Required'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _stampsController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _barqodyFieldDecoration('e.g. 5'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? context.l10n.required
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _barqodyLabel('Reward'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _titleController,
                        'e.g. Free Coffee',
                        required: true,
                      ),
                      const SizedBox(height: 20),
                      _barqodyLabel('Reward Sub Title'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _descController,
                        'e.g. Buy 5 Coffes . Get 6 free',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      _barqodyLabel('Reward Item (Optional)'),
                      const SizedBox(height: 8),
                      Material(
                        color: BarqodyChrome.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: _pickLogo,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: _buildLogoWidget(),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    _logoBase64 != null ||
                                            (_existingLogoUrl != null &&
                                                _existingLogoUrl!.isNotEmpty)
                                        ? context.l10n.tapToChange
                                        : 'Select Item from menu',
                                    style: WaUi.body.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: BarqodyChrome.secondaryText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: PillButton(
                  label: isEdit
                      ? context.l10n.saveChanges
                      : context.l10n.continueLabel,
                  enabled: !_isLoading,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barqodyLabel(String text) {
    return Text(
      text,
      style: WaUi.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: BarqodyChrome.secondaryText,
      ),
    );
  }

  InputDecoration _barqodyFieldDecoration(String hint) {
    return WaUi.fieldDecoration(hintText: hint, radius: 14);
  }

  Widget _buildLogoWidget() {
    if (_logoBase64 != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.memory(base64Decode(_logoBase64!.split(',').last), fit: BoxFit.cover),
      );
    }
    if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(_existingLogoUrl!, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _logoPlaceholder()),
      );
    }
    return _logoPlaceholder();
  }

  Widget _logoPlaceholder() => Icon(
        Icons.add_photo_alternate_outlined,
        size: 22,
        color: Colors.grey.shade400,
      );

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: _barqodyFieldDecoration(hint),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? context.l10n.required : null
          : null,
    );
  }
}
