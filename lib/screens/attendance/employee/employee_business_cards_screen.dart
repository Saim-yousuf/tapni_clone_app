import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/company_business_card.dart';
import 'package:tapni_app/repository/wallet_repo.dart';
import 'package:tapni_app/utils/card_template_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/business_card_share_sheet.dart';
import 'package:tapni_app/widgets/employee_card_template_sheet.dart';

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

  Future<void> _customizeCard(CompanyBusinessCard card) async {
    await EmployeeCardTemplateSheet.show(
      context,
      card: card,
      onApplied: _updateCard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AttendanceUi.appBar(context.l10n.companyEmployeeCard),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : RefreshIndicator(
              color: WaUi.accent,
              backgroundColor: Colors.white,
              onRefresh: _load,
              child: _cards.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.badge_outlined,
                                  size: 52,
                                  color: WaUi.secondaryText
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  context.l10n.noEmployeeCardsYet,
                                  style: AttendanceUi.sectionTitle,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.l10n
                                      .whenABusinessAddsYouAsEmployeeYourEmployeeCardWillAppearHereYouCanCustomizeItsDe,
                                  textAlign: TextAlign.center,
                                  style: AttendanceUi.bodyMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Text(
                          context.l10n.yourEmployeeCardsFromEmployers,
                          style: AttendanceUi.bodyMuted,
                        ),
                        const SizedBox(height: 14),
                        ..._cards.map(_buildCard),
                      ],
                    ),
            ),
    );
  }

  Widget _buildCard(CompanyBusinessCard card) {
    final template = CardTemplateCatalog.byId(card.cardTemplateId);
    final employeeLabel =
        card.employeeName.isNotEmpty ? card.employeeName : context.l10n.you;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AttendanceUi.radius),
          border: Border.all(color: WaUi.divider),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => BusinessCardShareSheet.showForCompanyCard(
                context,
                card,
                onTemplateChanged: _updateCard,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AttendanceUi.radius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AttendanceUi.tileBg,
                      backgroundImage: card.employeePhoto.isNotEmpty
                          ? NetworkImage(card.employeePhoto)
                          : null,
                      child: card.employeePhoto.isEmpty
                          ? Text(
                              employeeLabel.isNotEmpty
                                  ? employeeLabel[0].toUpperCase()
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
                          Text(
                            employeeLabel,
                            style: AttendanceUi.cardTitle,
                          ),
                          if (card.employeeDisplayId.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              card.employeeDisplayId,
                              style: AttendanceUi.bodyMuted,
                            ),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            '${card.displayName} · ${template.name}',
                            style: WaUi.caption.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: WaUi.secondaryText.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: WaUi.divider),
            InkWell(
              onTap: () => _customizeCard(card),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AttendanceUi.radius),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.palette_outlined,
                      size: 18,
                      color: WaUi.buttonDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.customizeDesign,
                      style: WaUi.bodyMedium,
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
