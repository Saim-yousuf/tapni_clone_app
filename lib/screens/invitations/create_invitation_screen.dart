import 'package:flutter/material.dart';
import 'package:tapni_app/models/invitation.dart';
import 'package:tapni_app/screens/invitations/customize_invitation_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/invitation_card_preview.dart';

class CreateInvitationScreen extends StatefulWidget {
  const CreateInvitationScreen({super.key});

  @override
  State<CreateInvitationScreen> createState() => _CreateInvitationScreenState();
}

class _CreateInvitationScreenState extends State<CreateInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _venueController = TextEditingController();
  final _addressController = TextEditingController();

  String _type = 'birthday';
  DateTime? _eventAt;

  static const _types = [
    'wedding',
    'anniversary',
    'birthday',
    'business_meeting',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventAt ?? now.add(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventAt ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _eventAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    final draft = InvitationDraft(
      type: _type,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      venue: _venueController.text.trim(),
      address: _addressController.text.trim(),
      eventAt: _eventAt,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomizeInvitationScreen(draft: draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.scaffold,
      appBar: AppBar(
        backgroundColor: WaUi.surface,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text('Create invitation', style: WaUi.sectionHeader),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('Type', style: WaUi.bodyMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) {
                final selected = _type == type;
                return ChoiceChip(
                  label: Text(EventInvitation.typeLabel(type)),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = type),
                  selectedColor: WaUi.chipBg,
                  labelStyle: WaUi.caption.copyWith(
                    color: WaUi.primaryText,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  backgroundColor: WaUi.surface,
                  side: BorderSide(
                    color: selected ? WaUi.accent : WaUi.divider,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('Title *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _venueController,
              decoration: _inputDecoration('Venue / place name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: _inputDecoration(
                'Full address (shown on card)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _inputDecoration('Date & time'),
                child: Text(
                  _eventAt == null
                      ? 'Select date & time'
                      : '${MaterialLocalizations.of(context).formatFullDate(_eventAt!)} · ${TimeOfDay.fromDateTime(_eventAt!).format(context)}',
                  style: WaUi.body.copyWith(
                    color: _eventAt == null
                        ? WaUi.secondaryText
                        : WaUi.primaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              decoration: _inputDecoration('Message'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Text('Preview', style: WaUi.bodyMedium),
            const SizedBox(height: 12),
            InvitationCardPreview(
              type: _type,
              title: _titleController.text.trim(),
              message: _messageController.text.trim(),
              venue: _venueController.text.trim(),
              address: _addressController.text.trim(),
              eventAt: _eventAt,
              isPreview: true,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WaUi.buttonDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Customize card'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: WaUi.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WaUi.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WaUi.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WaUi.accent, width: 1.5),
      ),
    );
  }
}
