import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/linked_devices/link_device_scan_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';

class LinkedDevicesScreen extends StatefulWidget {
  const LinkedDevicesScreen({super.key});

  @override
  State<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends State<LinkedDevicesScreen> {
  final AuthRepo _repo = AuthRepo();
  bool _loading = true;
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.listDeviceSessions();
    if (!mounted) return;

    final list = <Map<String, dynamic>>[];
    if (res.success && res.data is Map) {
      final devices = (res.data as Map)['devices'];
      if (devices is List) {
        for (final d in devices) {
          if (d is Map) {
            list.add(Map<String, dynamic>.from(d));
          }
        }
      }
    }

    setState(() {
      _devices = list;
      _loading = false;
    });
  }

  Future<void> _linkDevice() async {
    final linked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LinkDeviceScanScreen()),
    );
    if (linked == true) _load();
  }

  Future<void> _logoutDevice(Map<String, dynamic> device) async {
    final id = device['id']?.toString();
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WaUi.radiusLg),
        ),
        title: Text('Log out device?', style: WaUi.title),
        content: Text(
          '“${device['deviceName'] ?? 'Device'}” will be removed from your account.',
          style: WaUi.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: WaUi.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Log out',
              style: WaUi.bodyMedium.copyWith(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await _repo.revokeDeviceSession(id);
    if (!mounted) return;
    if (res.success) {
      ShowAlert.success(message: 'Device logged out', context: context);
      _load();
    } else {
      ShowAlert.error(
        message: res.message ?? 'Could not log out device',
        context: context,
      );
    }
  }

  String _formatActive(dynamic value) {
    if (value == null) return '';
    final dt = DateTime.tryParse(value.toString())?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 2) return 'Active now';
    if (diff.inHours < 24) {
      return 'Last active ${diff.inHours == 0 ? '${diff.inMinutes}m' : '${diff.inHours}h'} ago';
    }
    return 'Last active ${DateFormat('d MMM, h:mm a').format(dt)}';
  }

  IconData _platformIcon(String? platform) {
    final p = (platform ?? '').toLowerCase();
    if (p.contains('ios') || p.contains('iphone')) return Icons.phone_iphone;
    if (p.contains('android')) return Icons.phone_android;
    if (p.contains('web') || p.contains('desktop')) return Icons.laptop_mac;
    return Icons.devices_other_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        foregroundColor: WaUi.primaryText,
        title: Text('Linked devices', style: WaUi.headline),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: WaUi.accent),
            )
          : RefreshIndicator(
              color: WaUi.accent,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Text(
                      'Use Barqody on other phones or tablets. You stay in control — log out any device anytime.',
                      style: WaUi.body.copyWith(color: WaUi.secondaryText),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Material(
                      color: WaUi.chipBg,
                      borderRadius: BorderRadius.circular(WaUi.radiusLg),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(WaUi.radiusLg),
                        onTap: _linkDevice,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: WaUi.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Link a device', style: WaUi.listTitle),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Scan QR shown on the other device',
                                      style: WaUi.listSubtitle,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: WaUi.secondaryText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                    child: Text('Device status', style: WaUi.sectionHeader),
                  ),
                  if (_devices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Text(
                        'Only this phone is using your account right now.',
                        style: WaUi.caption,
                      ),
                    )
                  else
                    ..._devices.map((device) {
                      final isCurrent = device['isCurrent'] == true;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: WaUi.navPill,
                          child: Icon(
                            _platformIcon(device['platform']?.toString()),
                            color: WaUi.promoIconFg,
                          ),
                        ),
                        title: Text(
                          device['deviceName']?.toString() ?? 'Device',
                          style: WaUi.listTitle,
                        ),
                        subtitle: Text(
                          isCurrent
                              ? 'This device · ${_formatActive(device['lastActiveAt'])}'
                              : _formatActive(device['lastActiveAt']),
                          style: WaUi.listSubtitle,
                        ),
                        trailing: isCurrent
                            ? Text(
                                'Active',
                                style: WaUi.caption.copyWith(
                                  color: WaUi.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => _logoutDevice(device),
                              ),
                      );
                    }),
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Keep your account safe. Only scan QR codes when you want to link a device you trust.',
                      style: WaUi.caption,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
