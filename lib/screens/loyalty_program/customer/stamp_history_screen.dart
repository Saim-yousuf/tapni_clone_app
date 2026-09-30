import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class StampHistoryScreen extends StatelessWidget {
  final RewardEnrollment enrollment;

  const StampHistoryScreen({super.key, required this.enrollment});

  static const _cardBg = Color(0xFFF5F5F5);
  static const _muted = Color(0xFF757575);
  static const _positiveGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final businessName =
        enrollment.program?.displayBusinessName ?? 'Business';
    final items = _buildHistoryItems(businessName);

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Stamp History'),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Text(
                          'No stamp history yet',
                          textAlign: TextAlign.center,
                          style: WaUi.body.copyWith(
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        BarqodyChrome.sidePad,
                        16,
                        BarqodyChrome.sidePad,
                        28,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.amountLabel,
                                style: WaUi.bodyMedium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _positiveGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.merchant} · ${item.orderLabel}',
                                style: WaUi.caption.copyWith(
                                  fontSize: 13,
                                  color: _muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd-MM-yyyy  hh:mm a')
                                    .format(item.at),
                                style: WaUi.caption.copyWith(
                                  fontSize: 12,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_StampHistoryItem> _buildHistoryItems(String businessName) {
    final count = enrollment.stamps;
    if (count <= 0) return const [];

    final base = enrollment.program?.createdAt ?? DateTime.now();
    return List.generate(count, (i) {
      final orderNo = 1024 - i;
      return _StampHistoryItem(
        amountLabel: '+1 Stamp',
        merchant: businessName,
        orderLabel: 'Order #$orderNo',
        at: base.subtract(Duration(hours: i * 9 + 2)),
      );
    });
  }
}

class _StampHistoryItem {
  final String amountLabel;
  final String merchant;
  final String orderLabel;
  final DateTime at;

  const _StampHistoryItem({
    required this.amountLabel,
    required this.merchant,
    required this.orderLabel,
    required this.at,
  });
}
