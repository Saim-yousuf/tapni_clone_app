import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/company_business_card.dart';
import 'package:tapni_app/repository/wallet_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/business_card_share_sheet.dart';

class EmployeeBusinessCardsScreen extends StatefulWidget {
  const EmployeeBusinessCardsScreen({super.key});

  @override
  State<EmployeeBusinessCardsScreen> createState() =>
      _EmployeeBusinessCardsScreenState();
}

class _EmployeeBusinessCardsScreenState
    extends State<EmployeeBusinessCardsScreen> {
  List<CompanyBusinessCard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await WalletRepo().getMyCompanyCards();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success) {
        _cards = parseCompanyCardList(res.data);
      }
    });
  }

  void _updateCard(CompanyBusinessCard updated) {
    setState(() {
      final index =
          _cards.indexWhere((c) => c.employeeRefId == updated.employeeRefId);
      if (index >= 0) {
        _cards[index] = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(title: l10n.employeeCard),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : RefreshIndicator(
                      color: Colors.black,
                      backgroundColor: Colors.white,
                      onRefresh: _load,
                      child: _cards.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: const _EmptyEmployeeCardsState(),
                                ),
                              ],
                            )
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                BarqodyChrome.sidePad,
                                8,
                                BarqodyChrome.sidePad,
                                24,
                              ),
                              children: [
                                Text(
                                  l10n.selectCompany,
                                  style: WaUi.toolsTitleOf(
                                    size: 22,
                                    weight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Choose a company to view your employee card.',
                                  style: WaUi.body.copyWith(
                                    fontSize: 14,
                                    height: 1.35,
                                    color: BarqodyChrome.bodyText,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ...List.generate(_cards.length, (index) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildCompanyRow(_cards[index]),
                                      if (index < _cards.length - 1)
                                        const Divider(
                                          height: 1,
                                          color: BarqodyChrome.divider,
                                        ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyRow(CompanyBusinessCard card) {
    final subtitle = _rowSubtitle(card);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => BusinessCardShareSheet.showForCompanyCard(
          context,
          card,
          onTemplateChanged: _updateCard,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: BarqodyChrome.fieldFill,
                backgroundImage: card.profilePhoto.isNotEmpty
                    ? NetworkImage(card.profilePhoto)
                    : null,
                child: card.profilePhoto.isEmpty
                    ? Text(
                        card.displayName.isNotEmpty
                            ? card.displayName[0].toUpperCase()
                            : '?',
                        style: WaUi.avatarInitial,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            card.displayName,
                            style: WaUi.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_showVerifiedBadge(card)) ...[
                          const SizedBox(width: 6),
                          _VerifiedBadge(),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: WaUi.body.copyWith(
                          fontSize: 14,
                          color: BarqodyChrome.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: BarqodyChrome.secondaryText.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _showVerifiedBadge(CompanyBusinessCard card) {
    return card.username.isNotEmpty ||
        card.businessName.isNotEmpty ||
        card.profileUrl.isNotEmpty;
  }

  String _rowSubtitle(CompanyBusinessCard card) {
    if (card.employeeDisplayId.isNotEmpty) return card.employeeDisplayId;
    if (card.username.isNotEmpty) return '@${card.username}';
    return '${card.shiftStart} – ${card.shiftEnd}';
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: BarqodyChrome.star,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/png/check-icon.png',
          width: 10,
          height: 10,
          color: Colors.white,
          errorBuilder: (_, _, _) => const Icon(
            Icons.check_rounded,
            size: 11,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _EmptyEmployeeCardsState extends StatelessWidget {
  const _EmptyEmployeeCardsState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/png/card-icon.png',
              width: 56,
              height: 56,
              errorBuilder: (_, _, _) => Icon(
                Icons.badge_outlined,
                size: 52,
                color: BarqodyChrome.secondaryText.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noEmployeeCardsYet,
              style: WaUi.toolsTitleOf(
                size: 17,
                weight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n
                  .whenABusinessAddsYouAsEmployeeYourEmployeeCardWillAppearHereYouCanCustomizeItsDe,
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(
                fontSize: 14,
                height: 1.35,
                color: BarqodyChrome.bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
