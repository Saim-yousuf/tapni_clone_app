import 'package:flutter/material.dart';
import 'package:tapni_app/models/company_business_card.dart';
import 'package:tapni_app/repository/wallet_repo.dart';
import 'package:tapni_app/utils/card_template_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/employee_card_template_sheet.dart';
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
      backgroundColor: AttendanceUi.scaffoldBg,
      appBar: AttendanceUi.appBar('Employee Cards'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _cards.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: AttendanceUi.thickCard,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.business_center_outlined,
                                    size: 48,
                                    color: WaUi.promoIconFg,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No employee cards yet',
                                    style: AttendanceUi.sectionTitle,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'When a business adds you as employee, your employee card will appear here. You can customize its design anytime.',
                                    textAlign: TextAlign.center,
                                    style: AttendanceUi.bodyMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Text(
                          'Your employee cards from employers',
                          style: AttendanceUi.bodyMuted,
                        ),
                        const SizedBox(height: 16),
                        ..._cards.map(_buildCard),
                      ],
                    ),
            ),
    );
  }

  Widget _buildCard(CompanyBusinessCard card) {
    final template = CardTemplateCatalog.byId(card.cardTemplateId);
    final employeeLabel =
        card.employeeName.isNotEmpty ? card.employeeName : 'You';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: AttendanceUi.thickCard,
        child: Column(
          children: [
            InkWell(
              onTap: () => BusinessCardShareSheet.showForCompanyCard(
                context,
                card,
                onTemplateChanged: _updateCard,
              ),
              borderRadius: BorderRadius.circular(AttendanceUi.radius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: WaUi.navPill,
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
                        Positioned(
                          right: -4,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: template.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WaUi.divider,
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Employee Card',
                            style: AttendanceUi.bodyMuted,
                          ),
                          const SizedBox(height: 2),
                          Text(employeeLabel, style: AttendanceUi.cardTitle),
                          const SizedBox(height: 4),
                          if (card.employeeDisplayId.isNotEmpty)
                            Text(
                              card.employeeDisplayId,
                              style: AttendanceUi.bodyMuted,
                            ),
                          const SizedBox(height: 2),
                          Text(
                            '${card.displayName} • ${template.name}',
                            style: AttendanceUi.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.wallet_outlined,
                      size: 24,
                      color: WaUi.promoIconFg,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: WaUi.divider),
            InkWell(
              onTap: () => _customizeCard(card),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AttendanceUi.radius),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: WaUi.promoIconFg,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Customize Design',
                      style: WaUi.button.copyWith(color: WaUi.primaryText),
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
