import 'package:flutter/material.dart';
import 'package:tapni_app/repository/pos_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Connect Barqody orders to an external POS (Foodics/Dinevo).
/// Public menu templates stay on Barqody — POS only receives order push.
class PosConnectionScreen extends StatefulWidget {
  const PosConnectionScreen({super.key});

  @override
  State<PosConnectionScreen> createState() => _PosConnectionScreenState();
}

class _PosConnectionScreenState extends State<PosConnectionScreen> {
  final _repo = PosRepo();
  final _tenantCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  PosConnectionInfo _info = const PosConnectionInfo();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tenantCtrl.dispose();
    _baseUrlCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final info = await _repo.getConnection();
    if (!mounted) return;
    _tenantCtrl.text = info.posTenantId;
    _baseUrlCtrl.text = info.posBaseUrl;
    _branchCtrl.text = info.defaultBranchId;
    setState(() {
      _info = info;
      _loading = false;
    });
  }

  Future<void> _save({required String status}) async {
    setState(() => _saving = true);
    final res = await _repo.upsertConnection(
      status: status,
      posTenantId: _tenantCtrl.text.trim(),
      posBaseUrl: _baseUrlCtrl.text.trim(),
      defaultBranchId: _branchCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Could not save')),
      );
      return;
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'active'
              ? 'POS connected — new Barqody orders will push'
              : 'Saved',
        ),
      ),
    );
  }

  Future<void> _disconnect() async {
    setState(() => _saving = true);
    await _repo.disconnect();
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('POS disconnected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _info.status;
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'POS connect',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        Text(
                          'Your public menu link and website template stay on Barqody. Connecting POS only sends kitchen orders — it does not change the design customers see.',
                          style: WaUi.body.copyWith(
                            color: BarqodyChrome.secondaryText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: BarqodyChrome.fieldFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                status == 'active'
                                    ? Icons.check_circle_outline
                                    : Icons.link_off_outlined,
                                color: status == 'active'
                                    ? Colors.green.shade700
                                    : BarqodyChrome.secondaryText,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Status: $status',
                                  style: WaUi.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_info.lastError.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            _info.lastError,
                            style: WaUi.caption.copyWith(
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        _Field(
                          label: 'POS tenant ID',
                          controller: _tenantCtrl,
                          hint: 'Foodics / Dinevo business id',
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          label: 'POS base URL',
                          controller: _baseUrlCtrl,
                          hint: 'https://pos.example.com',
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          label: 'Default branch ID',
                          controller: _branchCtrl,
                          hint: 'Optional',
                        ),
                        const SizedBox(height: 28),
                        PillButton(
                          label: status == 'active'
                              ? 'Update connection'
                              : 'Connect POS',
                          enabled: !_saving,
                          onPressed: () => _save(status: 'active'),
                        ),
                        const SizedBox(height: 12),
                        if (status == 'active' || status == 'pending')
                          PillButton(
                            label: 'Disconnect',
                            filled: false,
                            enabled: !_saving,
                            onPressed: _disconnect,
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _Field({
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
          label.toUpperCase(),
          style: WaUi.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: BarqodyChrome.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: BarqodyChrome.fieldFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
