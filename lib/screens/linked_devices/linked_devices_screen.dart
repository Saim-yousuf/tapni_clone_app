import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/linked_devices/link_device_scan_screen.dart';
import 'package:tapni_app/services/account_storage.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/alert.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

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
    final serverName = device['deviceName']?.toString() ?? context.l10n.device;
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
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(BarqodyChrome.modalRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: CircleCloseButton(
                  onTap: () => Navigator.pop(ctx, false),
                ),
              ),
              AssetIcon(
                'assets/images/png/logout-icon.png',
                size: 48,
                color: Colors.black,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.logOutDevice,
                textAlign: TextAlign.center,
                style: WaUi.toolsTitleOf(
                  size: 18,
                  weight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '“${_deviceLabel(device)}” will be removed from your account.',
                textAlign: TextAlign.center,
                style: WaUi.body.copyWith(
                  color: BarqodyChrome.bodyText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              PillButton(
                label: context.l10n.cancel,
                filled: false,
                onPressed: () => Navigator.pop(ctx, false),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: context.l10n.logOut2,
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ),
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
      final time = diff.inHours == 0 ? '${diff.inMinutes}m' : '${diff.inHours}h';
      return context.l10n.lastActiveAgo(time);
    }
    return context.l10n.lastActiveAt(DateFormat('d MMM, h:mm a').format(dt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const CircleBackButton(),
                  Expanded(
                    child: Text(
                      context.l10n.linkedDevices,
                      textAlign: TextAlign.center,
                      style: WaUi.toolsTitleOf(
                        size: 18,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : RefreshIndicator(
                      color: Colors.black,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        children: [
                          Text(
                            context.l10n
                                .useBarqodyOnOtherPhonesOrTabletsYouStayInControlLogOutAnyDeviceAnytime,
                            style: WaUi.body.copyWith(
                              color: BarqodyChrome.bodyText,
                              height: 1.45,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Material(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: _linkDevice,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        'assets/images/png/scan-icon-1.png',
                                        width: 24,
                                        height: 24,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.qr_code_scanner,
                                          color: Colors.black,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.l10n.linkADevice,
                                            style: WaUi.body.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            context
                                                .l10n.scanQRShownOnTheOtherDevice,
                                            style: WaUi.caption.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            context.l10n.deviceStatus,
                            style: WaUi.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_devices.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                context.l10n
                                    .onlyThisPhoneIsUsingYourAccountRightNow,
                                style: WaUi.caption.copyWith(
                                  color: BarqodyChrome.secondaryText,
                                ),
                              ),
                            )
                          else
                            ..._devices.map((device) {
                              final isCurrent = device['isCurrent'] == true;
                              return InkWell(
                                onTap: isCurrent
                                    ? null
                                    : () => _logoutDevice(device),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: const BoxDecoration(
                                          color: BarqodyChrome.circleBtn,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Image.asset(
                                          'assets/images/png/scan-icon-2.png',
                                          width: 22,
                                          height: 22,
                                          color: Colors.black,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.phone_android,
                                            color: Colors.black,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _deviceLabel(device),
                                              style: WaUi.body.copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isCurrent
                                                  ? context.l10n
                                                      .thisDeviceWithName(
                                                      _formatActive(
                                                        device['lastActiveAt'],
                                                      ),
                                                    )
                                                  : _formatActive(
                                                      device['lastActiveAt'],
                                                    ),
                                              style: WaUi.caption.copyWith(
                                                color:
                                                    BarqodyChrome.secondaryText,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isCurrent)
                                        Text(
                                          context.l10n.active,
                                          style: WaUi.body.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 16),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: BarqodyChrome.divider,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n
                                .keepYourAccountSafeOnlyScanQRCodesWhenYouWantToLinkADeviceYouTrust,
                            style: WaUi.body.copyWith(
                              fontSize: 13,
                              color: BarqodyChrome.bodyText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
