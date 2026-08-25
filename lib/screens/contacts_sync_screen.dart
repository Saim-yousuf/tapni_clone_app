import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/services/contacts_sync_service.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

class ContactsSyncScreen extends StatefulWidget {
  const ContactsSyncScreen({
    super.key,
    this.isOnboarding = false,
    this.fromSettings = false,
  });

  final bool isOnboarding;
  final bool fromSettings;

  @override
  State<ContactsSyncScreen> createState() => _ContactsSyncScreenState();
}

class _ContactsSyncScreenState extends State<ContactsSyncScreen> {
  bool _syncing = false;
  double? _progress;
  String? _error;

  String get _userId =>
      context.read<AuthProvider>().activeAccount?.userId ?? '';

  Future<void> _finish({bool synced = false}) async {
    await ContactsSyncService.markPrompted(_userId);
    if (!mounted) return;
    if (widget.isOnboarding) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
      return;
    }
    Navigator.of(context).pop(synced);
  }

  Future<void> _allowAndSync() async {
    setState(() {
      _error = null;
      _syncing = true;
      _progress = null;
    });

    final status = await ContactsSyncService.requestPermission();
    if (!mounted) return;

    if (!status.isGranted) {
      setState(() {
        _syncing = false;
        _error = status.isPermanentlyDenied
            ? context.l10n.contactsPermissionDeniedOpenSettings
            : context.l10n.contactsPermissionRequired;
      });
      await ContactsSyncService.markPrompted(_userId);
      return;
    }

    final result = await ContactsSyncService.syncAll(
      onProgress: (done, total) {
        if (!mounted || total == 0) return;
        setState(() => _progress = done / total);
      },
    );

    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _syncing = false;
        _error = result.message ?? context.l10n.contactsSyncFailed;
      });
      return;
    }

    await ContactsSyncService.markPrompted(_userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.contactsSyncedCount(result.uploaded)),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _finish(synced: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isOnboarding,
        leading: widget.isOnboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: _syncing ? null : () => _finish()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: WaUi.promoIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.contacts_outlined,
                          size: 40,
                          color: WaUi.promoIconFg,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        context.l10n.syncContactsTitle,
                        textAlign: TextAlign.center,
                        style: WaUi.headline.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.l10n.syncContactsDisclosure,
                        textAlign: TextAlign.center,
                        style: WaUi.body.copyWith(color: WaUi.secondaryText),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: WaUi.body.copyWith(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _syncing
                              ? null
                              : () => openAppSettings(),
                          child: Text(context.l10n.openSettings),
                        ),
                      ],
                      if (_syncing) ...[
                        const SizedBox(height: 28),
                        LinearProgressIndicator(
                          value: _progress,
                          color: AppTheme.primaryBlack,
                          backgroundColor: WaUi.navPill,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.syncingContacts,
                          style: WaUi.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _syncing ? null : _allowAndSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppTheme.primaryBlack.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WaUi.radiusPill),
                    ),
                  ),
                  child: _syncing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.l10n.allowAndSync,
                          style: WaUi.promoButton.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _syncing ? null : () => _finish(),
                child: Text(
                  widget.fromSettings
                      ? context.l10n.cancel
                      : context.l10n.skip,
                  style: WaUi.bodyMedium.copyWith(color: WaUi.secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
