import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/loyalty_points_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class StampHistoryScreen extends StatefulWidget {
  final RewardEnrollment enrollment;

  const StampHistoryScreen({super.key, required this.enrollment});

  @override
  State<StampHistoryScreen> createState() => _StampHistoryScreenState();
}

class _StampHistoryScreenState extends State<StampHistoryScreen> {
  static const _cardBg = Color(0xFFF5F5F5);
  static const _muted = Color(0xFF757575);
  static const _positiveGreen = Color(0xFF2E7D32);

  bool _loading = true;
  List<_StampHistoryItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res =
        await LoyaltyPointsRepo().getStampHistory(widget.enrollment.id);
    if (!mounted) return;

    var items = <_StampHistoryItem>[];
    if (res.success && res.data != null) {
      final raw = res.data is Map ? res.data['data'] ?? res.data : res.data;
      if (raw is List) {
        for (final row in raw.whereType<Map>()) {
          final m = Map<String, dynamic>.from(row);
          items.add(
            _StampHistoryItem(
              amountLabel: m['amountLabel']?.toString() ?? '+1 Stamp',
              merchant: m['merchant']?.toString() ?? 'Business',
              orderLabel: m['orderLabel']?.toString() ?? '',
              at: DateTime.tryParse(m['at']?.toString() ?? '') ??
                  DateTime.now(),
            ),
          );
        }
      }
    }

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Stamp History'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : _items.isEmpty
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
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              BarqodyChrome.sidePad,
                              16,
                              BarqodyChrome.sidePad,
                              28,
                            ),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                                      item.orderLabel.isEmpty
                                          ? item.merchant
                                          : '${item.merchant} · ${item.orderLabel}',
                                      style: WaUi.caption.copyWith(
                                        fontSize: 13,
                                        color: _muted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd-MM-yyyy  hh:mm a')
                                          .format(item.at.toLocal()),
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
            ),
          ],
        ),
      ),
    );
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
