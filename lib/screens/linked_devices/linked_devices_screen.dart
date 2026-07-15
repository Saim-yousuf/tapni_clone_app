import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/linked_devices/link_device_scan_screen.dart';
import 'package:tapni_app/services/account_storage.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class LinkedDevicesScreen extends StatefulWidget {
  const LinkedDevicesScreen({super.key});

  @override
  State<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends State<LinkedDevicesScreen> {
  final AuthRepo _repo = AuthRepo();
  bool _loading = true;
  List<Map<String, dynamic>> _devices = [];
  String? _localDeviceName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Resolve + push real phone name before listing sessions.
    final localName = await AccountStorage.defaultDeviceName();
    if (!mounted) return;
    _localDeviceName = localName;

    try {
      await context.read<AuthProvider>().ensureDeviceSessionRegistered();
    } catch (_) {}

    if (!mounted) return;
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

  String _deviceLabel(Map<String, dynamic> device) {
    final serverName = device['deviceName']?.toString() ?? 'Device';
    final isCurrent = device['isCurrent'] == true;
    final local = _localDeviceName;
    if (isCurrent &&
        local != null &&
        !AccountStorage.isGenericDeviceName(local)) {
      return local;
    }
    return serverName;
  }

  Future<void> _linkDevice() async {
    final linked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LinkDeviceScanScreen()),
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
        title: Text(context.l10n.logOutDevice, style: WaUi.title),
        content: Text(
          '“${_deviceLabel(device)}” will be removed from your account.',
          style: WaUi.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel, style: WaUi.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.logOut2,
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
      ShowAlert.success(message: context.l10n.deviceLoggedOut, context: context);
      _load();
    } else {
      ShowAlert.error(
        message: res.message ?? context.l10n.couldNotLogOutDevice,
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
    if (diff.inMinutes < 2) return context.l10n.activeNow;
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
        title: Text(context.l10n.linkedDevices, style: WaUi.headline),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: WaUi.accent),
            )
          : RefreshIndicator(
              color: WaUi.accent,
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.only(bottom: 32),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Text(
                      context.l10n.useBarqodyOnOtherPhonesOrTabletsYouStayInControlLogOutAnyDeviceAnytime,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: WaUi.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.l10n.linkADevice, style: WaUi.listTitle),
                                    SizedBox(height: 2),
                                    Text(
                                      context.l10n.scanQRShownOnTheOtherDevice,
                                      style: WaUi.listSubtitle,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
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
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 8),
                    child: Text(context.l10n.deviceStatus, style: WaUi.sectionHeader),
                  ),
                  if (_devices.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Text(
                        context.l10n.onlyThisPhoneIsUsingYourAccountRightNow,
                        style: WaUi.caption,
                      ),
                    )
                  else
                    ..._devices.map((device) {
                      final isCurrent = device['isCurrent'] == true;
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
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
                          _deviceLabel(device),
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
                                context.l10n.active,
                                style: WaUi.caption.copyWith(
                                  color: WaUi.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  Icons.logout,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => _logoutDevice(device),
                              ),
                      );
                    }),
                  Divider(height: 32),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      context.l10n.keepYourAccountSafeOnlyScanQRCodesWhenYouWantToLinkADeviceYouTrust,
                      style: WaUi.caption,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
