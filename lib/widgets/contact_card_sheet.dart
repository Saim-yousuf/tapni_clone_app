import 'package:flutter/material.dart';
import 'package:tapni_app/utils/theme.dart';

void showContactCardBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.secondaryWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const ContactCardBottomSheet(),
  );
}

// ── App list item model ──────────────────────────────────────────────────────
class AppItem {
  final String name;
  final Color color;
  final IconData icon;
  bool enabled;

  AppItem({
    required this.name,
    required this.color,
    required this.icon,
    this.enabled = true,
  });
}

// ── Main BottomSheet ─────────────────────────────────────────────────────────
class ContactCardBottomSheet extends StatefulWidget {
  const ContactCardBottomSheet({super.key});

  @override
  State<ContactCardBottomSheet> createState() => _ContactCardBottomSheetState();
}

class _ContactCardBottomSheetState extends State<ContactCardBottomSheet> {
  bool isPersonal = true;
  bool addressExpanded = false;

  // Common fields
  final _labelCtrl = TextEditingController(text: 'Save contact');
  final _firstNameCtrl = TextEditingController(text: 'Saim');
  final _lastNameCtrl = TextEditingController(text: 'Y');
  final _bioCtrl = TextEditingController();

  // Personal-only fields
  final _personalPhoneCtrl = TextEditingController();
  final _personalEmailCtrl = TextEditingController();
  final _personalWebsiteCtrl = TextEditingController();

  // Business-only fields
  final _businessPhoneCtrl = TextEditingController();
  final _businessEmailCtrl = TextEditingController();
  final _businessWebsiteCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();

  // Address fields (shared)
  final _addressCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  // App toggles
  final List<AppItem> _apps = [
    AppItem(name: 'Saim Y', color: Colors.blue, icon: Icons.person),
    AppItem(name: 'WhatsApp', color: Colors.green, icon: Icons.message),
    AppItem(
      name: 'Telegram',
      color: Colors.lightBlue,
      icon: Icons.send,
      enabled: false,
    ),
  ];

  @override
  void dispose() {
    for (final c in [
      _labelCtrl,
      _firstNameCtrl,
      _lastNameCtrl,
      _bioCtrl,
      _personalPhoneCtrl,
      _personalEmailCtrl,
      _personalWebsiteCtrl,
      _businessPhoneCtrl,
      _businessEmailCtrl,
      _businessWebsiteCtrl,
      _companyCtrl,
      _jobTitleCtrl,
      _addressCtrl,
      _streetCtrl,
      _numberCtrl,
      _cityCtrl,
      _zipCtrl,
      _countryCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) {
        return Column(
          children: [
            _buildHandle(),
            _buildTitle(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildAvatarRow(),
                    const SizedBox(height: 12),
                    _buildTextField(_firstNameCtrl, 'First name'),
                    const SizedBox(height: 10),
                    _buildTextField(_lastNameCtrl, 'Last name'),
                    const SizedBox(height: 10),
                    _buildTextField(
                      _bioCtrl,
                      'Enter bio for the contact card',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _buildToggle(),
                    const SizedBox(height: 12),

                    // ── Tab-specific fields ──
                    if (isPersonal)
                      ..._buildPersonalFields()
                    else
                      ..._buildBusinessFields(),

                    const SizedBox(height: 10),

                    // ── Address expandable ──
                    _buildAddressSection(),

                    const SizedBox(height: 16),

                    // ── App toggles ──
                    ..._apps.map((app) => _buildAppToggle(app)),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        );
      },
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildHandle() => Container(
    margin: const EdgeInsets.only(top: 12, bottom: 8),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _buildTitle() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'Contact card',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildAvatarRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Avatar
      Stack(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.person, size: 48, color: Colors.grey[500]),
                  Container(
                    height: 12,
                    color: Colors.green,
                    width: double.infinity,
                  ),
                ],
              ),
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
              child: const Icon(Icons.edit, size: 12, color: Colors.black),
            ),
          ),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_labelCtrl, 'Save contact'),
            const SizedBox(height: 6),
            Text(
              'Set text under the link icon',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildToggle() => Container(
    height: 48,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        _toggleTab(
          'Business',
          !isPersonal,
          () => setState(() => isPersonal = false),
        ),
        _toggleTab(
          'Personal',
          isPersonal,
          () => setState(() => isPersonal = true),
        ),
      ],
    ),
  );

  Widget _toggleTab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
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

  // ── Personal Fields ────────────────────────────────────────────────────────
  List<Widget> _buildPersonalFields() => [
    _buildFieldWithPlus(_personalPhoneCtrl, 'Contact card phone'),
    const SizedBox(height: 10),
    _buildFieldWithPlus(_personalEmailCtrl, 'Contact card email'),
    const SizedBox(height: 10),
    _buildFieldWithPlus(_personalWebsiteCtrl, 'Contact card website'),
  ];

  // ── Business Fields ────────────────────────────────────────────────────────
  List<Widget> _buildBusinessFields() => [
    const _MultiFieldRow(hint: 'Business phone number'),
    const SizedBox(height: 10),
    const _MultiFieldRow(hint: 'Business email address'),
    const SizedBox(height: 10),
    _buildTextField(_jobTitleCtrl, 'Job title'),
    const SizedBox(height: 10),
    _buildTextField(_companyCtrl, 'Contact card company name'),
    const SizedBox(height: 10),
    _buildTextField(_companyCtrl, 'Business fax'),
  ];

  // ── Address expandable section ─────────────────────────────────────────────
  Widget _buildAddressSection() => Column(
    children: [
      // Header row — tap to expand/collapse
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addressCtrl,
              decoration: _inputDecoration('Contact card home address'),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => addressExpanded = !addressExpanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                addressExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_up,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),

      // Expanded sub-fields
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 250),
        crossFadeState: addressExpanded
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        firstChild: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildTextField(_streetCtrl, 'Street name')),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 120,
                    child: _buildTextField(_numberCtrl, 'Number'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextField(_cityCtrl, 'City')),
                  const SizedBox(width: 10),
                  SizedBox(width: 120, child: _buildTextField(_zipCtrl, 'ZIP')),
                ],
              ),
              const SizedBox(height: 10),
              _buildTextField(_countryCtrl, 'Country'),
            ],
          ),
        ),
        secondChild: const SizedBox.shrink(),
      ),
    ],
  );

  // ── App toggle row ─────────────────────────────────────────────────────────
  Widget _buildAppToggle(AppItem app) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      children: [
        // Icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: app.color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(app.icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            app.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        Switch(
          value: app.enabled,
          onChanged: (v) => setState(() => app.enabled = v),
          activeColor: Colors.white,
          activeTrackColor: Colors.black,
        ),
      ],
    ),
  );

  // ── Bottom bar ─────────────────────────────────────────────────────────────
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
            icon: const Icon(Icons.delete_outline),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Helper builders ────────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    decoration: _inputDecoration(hint),
  );

  Widget _buildFieldWithPlus(
    TextEditingController ctrl,
    String hint, {
    IconData icon = Icons.add,
  }) => Row(
    children: [
      Expanded(
        child: TextField(controller: ctrl, decoration: _inputDecoration(hint)),
      ),
      const SizedBox(width: 8),
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
    ],
  );
}

class _MultiFieldRow extends StatefulWidget {
  final String hint;
  const _MultiFieldRow({required this.hint});

  @override
  State<_MultiFieldRow> createState() => _MultiFieldRowState();
}

class _MultiFieldRowState extends State<_MultiFieldRow> {
  final List<TextEditingController> _controllers = [TextEditingController()];

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  void _addField() {
    if (_controllers.length >= 3) return;
    setState(
      () => _controllers.insert(_controllers.length, TextEditingController()),
    );
  }

  void _removeField(int index) {
    if (_controllers.length <= 1) return; // min 1
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_controllers.length, (i) {
       final isFirst = i == 0;
        return Padding(
          padding: EdgeInsets.only(
            bottom: i < _controllers.length - 1 ? 10 : 0,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // + button
              GestureDetector(
                onTap: isFirst ? _addField : () => _removeField(i),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFirst ? Icons.add : Icons.remove,
                    color: Colors.grey[700],
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
}
