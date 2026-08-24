import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/username_policy_models.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

class MyUsernameClaimsScreen extends StatefulWidget {
  const MyUsernameClaimsScreen({super.key});

  @override
  State<MyUsernameClaimsScreen> createState() => _MyUsernameClaimsScreenState();
}

class _MyUsernameClaimsScreenState extends State<MyUsernameClaimsScreen> {
  final _authRepo = AuthRepo();
  List<UsernameClaimItem> _claims = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await _authRepo.myUsernameClaims();
    if (!mounted) return;

    if (!response.success) {
      setState(() {
        _loading = false;
        _error = response.message ?? context.l10n.tryAgain;
      });
      return;
    }

    final data = response.data;
    final rawClaims = data is Map ? data['claims'] as List? ?? [] : [];
    final claims = rawClaims
        .whereType<Map>()
        .map((e) => UsernameClaimItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    setState(() {
      _claims = claims;
      _loading = false;
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return context.l10n.claimStatusApproved;
      case 'rejected':
        return context.l10n.claimStatusRejected;
      default:
        return context.l10n.claimStatusPending;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFF57C00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: WaUi.primaryText,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.l10n.myUsernameClaims, style: WaUi.headline),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: WaUi.body.copyWith(color: WaUi.secondaryText),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loadClaims,
                        child: Text(context.l10n.tryAgain),
                      ),
                    ],
                  ),
                ),
              )
            : _claims.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    context.l10n.noUsernameClaims,
                    textAlign: TextAlign.center,
                    style: WaUi.body.copyWith(color: WaUi.secondaryText),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadClaims,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: _claims.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final claim = _claims[index];
                    final dateText = claim.createdAt != null
                        ? DateFormat.yMMMd().format(claim.createdAt!.toLocal())
                        : '';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: WaUi.fieldBox,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '@${claim.username}',
                                  style: WaUi.title,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(claim.status).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _statusLabel(claim.status),
                                  style: WaUi.label.copyWith(
                                    color: _statusColor(claim.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (dateText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              dateText,
                              style: WaUi.label.copyWith(color: WaUi.secondaryText),
                            ),
                          ],
                          if (claim.reason.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              claim.reason,
                              style: WaUi.body.copyWith(color: WaUi.secondaryText),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
