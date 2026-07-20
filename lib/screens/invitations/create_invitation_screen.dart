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
        scrolledUnderElevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text('New invitation', style: WaUi.sectionHeader),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _Section(
                    title: 'Event type',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _types.map((type) {
                        final selected = _type == type;
                        return ChoiceChip(
                          label: Text(EventInvitation.typeLabel(type)),
                          selected: selected,
                          onSelected: (_) => setState(() => _type = type),
                          selectedColor: WaUi.chipBg,
                          showCheckmark: false,
                          labelStyle: WaUi.caption.copyWith(
                            color: WaUi.primaryText,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          backgroundColor: WaUi.scaffold,
                          side: BorderSide(
                            color: selected ? WaUi.accent : WaUi.divider,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Details',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: _field('Title', required: true),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Title is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _venueController,
                          decoration: _field('Venue'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: _field(
                            'Address',
                            hint: 'Shown on the card',
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDateTime,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: _field('Date & time'),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _eventAt == null
                                        ? 'Optional'
                                        : '${MaterialLocalizations.of(context).formatMediumDate(_eventAt!)} · ${TimeOfDay.fromDateTime(_eventAt!).format(context)}',
                                    style: WaUi.body.copyWith(
                                      color: _eventAt == null
                                          ? WaUi.secondaryText
                                          : WaUi.primaryText,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: WaUi.secondaryText,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: _field('Message', hint: 'Optional note'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _BottomBar(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WaUi.buttonDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Next · Customize card'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _field(String label, {String? hint, bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,
      filled: true,
      fillColor: WaUi.scaffold,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WaUi.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: WaUi.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: WaUi.bodyMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: WaUi.surface,
        border: Border(top: BorderSide(color: WaUi.divider)),
      ),
      child: child,
    );
  }
}
