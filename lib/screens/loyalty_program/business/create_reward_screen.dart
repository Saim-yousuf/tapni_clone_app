import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/widgets/reward_stamp_slot.dart';

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

  Future<void> _pickStampIcon() =>
      _pickImage((base64) => _stampIconBase64 = base64);

  Future<void> _pickUnstampIcon() =>
      _pickImage((base64) => _unstampIconBase64 = base64);

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
      _showSnack('Please enter a valid number of stamps');
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
      _showSnack(res.message ?? 'Failed to save');
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Reward' : 'Create Reward',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              _sectionTitle('Logo'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildLogoWidget(),
                ),
              ),
              const SizedBox(height: 24),

              // Stamp Icons (optional)
              _sectionTitle('Stamp Icons (Optional)'),
              const SizedBox(height: 6),
              Text(
                'Custom images for stamped and unstamped slots. Defaults are used if not set.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _iconPickerTile(
                      label: 'Stamp Icon',
                      subtitle: 'Filled slot',
                      base64: _stampIconBase64,
                      existingUrl: _existingStampIconUrl,
                      onTap: _pickStampIcon,
                      onClear: () => setState(() {
                        _stampIconBase64 = null;
                        _existingStampIconUrl = null;
                      }),
                      preview: RewardStampSlot(
                        filled: true,
                        theme: _theme,
                        size: 32,
                        stampIconBase64: _stampIconBase64,
                        stampIconUrl: _existingStampIconUrl,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _iconPickerTile(
                      label: 'Unstamp Icon',
                      subtitle: 'Empty slot',
                      base64: _unstampIconBase64,
                      existingUrl: _existingUnstampIconUrl,
                      onTap: _pickUnstampIcon,
                      onClear: () => setState(() {
                        _unstampIconBase64 = null;
                        _existingUnstampIconUrl = null;
                      }),
                      preview: RewardStampSlot(
                        filled: false,
                        theme: _theme,
                        size: 32,
                        unstampIconBase64: _unstampIconBase64,
                        unstampIconUrl: _existingUnstampIconUrl,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Card Label Name
              _sectionTitle('Card Label Name'),
              const SizedBox(height: 8),
              _buildTextField(_labelController, 'e.g. Coffee Club', required: true),
              const SizedBox(height: 20),

              // Title
              _sectionTitle('Title'),
              const SizedBox(height: 8),
              _buildTextField(_titleController, 'e.g. Buy 10 Get 1 Free', required: true),
              const SizedBox(height: 20),

              // Description
              _sectionTitle('Description'),
              const SizedBox(height: 8),
              _buildTextField(_descController, 'Briefly describe this reward...', maxLines: 3),
              const SizedBox(height: 20),

              // Stamps
              _sectionTitle('Number of Stamps'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stampsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration('e.g. 10'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              // Card Theme
              _themeSectionTitle('Card Theme'),
              const SizedBox(height: 14),
              _colorRow('Background Color', _theme.cardBackgroundColor, (c) {
                setState(() => _theme = _theme.copyWith(cardBackgroundColor: c));
              }),
              const SizedBox(height: 12),
              _colorRow('Text Color', _theme.cardTextColor, (c) {
                setState(() => _theme = _theme.copyWith(cardTextColor: c));
              }),
              const SizedBox(height: 12),
              _colorRow('Stamp Color', _theme.stampColor, (c) {
                setState(() => _theme = _theme.copyWith(stampColor: c));
              }),
              const SizedBox(height: 12),
              _colorRow('Stamp Border Color', _theme.stampBorderColor, (c) {
                setState(() => _theme = _theme.copyWith(stampBorderColor: c));
              }),
              const SizedBox(height: 28),

              // Screen Theme
              _themeSectionTitle('Screen Theme'),
              const SizedBox(height: 14),
              _colorRow('Background Color', _theme.screenBackgroundColor, (c) {
                setState(() => _theme = _theme.copyWith(screenBackgroundColor: c));
              }),
              const SizedBox(height: 12),
              _colorRow('Text Color', _theme.screenTextColor, (c) {
                setState(() => _theme = _theme.copyWith(screenTextColor: c));
              }),
              const SizedBox(height: 32),

              // Live Card Preview
              _sectionTitle('Card Preview'),
              const SizedBox(height: 12),
              _buildCardPreview(),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          isEdit ? 'Save Changes' : 'Create Reward',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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

  Widget _logoPlaceholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.add_photo_alternate_outlined, size: 28, color: Colors.grey.shade400),
      const SizedBox(height: 4),
      Text('Add Logo', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
    ],
  );

  Widget _iconPickerTile({
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required Widget preview,
    String? base64,
    String? existingUrl,
  }) {
    final hasImage =
        (base64 != null && base64.isNotEmpty) ||
        (existingUrl != null && existingUrl.isNotEmpty);

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                preview,
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  hasImage ? 'Tap to change' : 'Tap to add image',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
        if (hasImage)
          TextButton(
            onPressed: onClear,
            child: Text(
              'Use default icon',
              style: TextStyle(fontSize: 12, color: Colors.red.shade400),
            ),
          ),
      ],
    );
  }

  Widget _buildCardPreview() {
    final stampCount = int.tryParse(_stampsController.text) ?? 10;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_existingLogoUrl!, width: 36, height: 36, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty) const SizedBox(width: 10),
            Text(
              _labelController.text.isEmpty ? 'Card Label' : _labelController.text,
              style: TextStyle(color: _theme.cardTextColor.withOpacity(0.6), fontSize: 12),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            _titleController.text.isEmpty ? 'Reward Title' : _titleController.text,
            style: TextStyle(color: _theme.cardTextColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(stampCount.clamp(1, 12), (i) {
              return RewardStampSlot(
                filled: i < 3,
                theme: _theme,
                size: 28,
                stampIconBase64: _stampIconBase64,
                stampIconUrl: _existingStampIconUrl,
                unstampIconBase64: _unstampIconBase64,
                unstampIconUrl: _existingUnstampIconUrl,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _colorRow(String label, Color current, ValueChanged<Color> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        GestureDetector(
          onTap: () => _showColorPicker(current, onChanged),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: current,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            '#${current.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(Color current, ValueChanged<Color> onChanged) {
    final hexController = TextEditingController(
      text: current.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase(),
    );
    final colors = [
      Colors.black, Colors.white, const Color(0xFFFFD700), const Color(0xFFFF6B35),
      const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFEF4444),
      const Color(0xFF8B5CF6), const Color(0xFFF59E0B), Colors.grey.shade200,
      const Color(0xFF1F2937), const Color(0xFFF0FDF4),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pick Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: colors.map((c) => GestureDetector(
                  onTap: () { onChanged(c); Navigator.pop(ctx); },
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Text('Hex: #', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: hexController,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9A-Fa-f]'))],
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    try {
                      final c = Color(int.parse('FF${hexController.text}', radix: 16));
                      onChanged(c);
                      Navigator.pop(ctx);
                    } catch (_) {}
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  child: const Text('Apply'),
                ),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15));

  Widget _themeSectionTitle(String t) => Row(children: [
    Container(width: 4, height: 18, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  ]);

  Widget _buildTextField(TextEditingController ctrl, String hint, {int maxLines = 1, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: _inputDecoration(hint),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black, width: 1.5)),
  );
}
