import 'package:tapni_app/utils/app_page_transitions.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/repository/payment_repo.dart';
import 'package:tapni_app/screens/payments/payment_detail_screen.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/finance_ui.dart';

/// Business financial dashboard (ledger-backed). No withdrawals.
class BusinessEarningsWalletScreen extends StatefulWidget {
  const BusinessEarningsWalletScreen({super.key});

  @override
  State<BusinessEarningsWalletScreen> createState() =>
      _BusinessEarningsWalletScreenState();
}

class _BusinessEarningsWalletScreenState
    extends State<BusinessEarningsWalletScreen> {
  final _repo = PaymentRepo();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  bool _loading = true;
  bool _analyticsLoading = false;
  String? _error;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _analytics;
  List<dynamic> _ledger = const [];
  DateTimeRange? _range;
  String _typeFilter = '';
  String _chartRange = 'month';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String? _iso(DateTime? d) => d?.toUtc().toIso8601String();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([
      _repo.getBusinessWallet(),
      _repo.getBusinessWalletAnalytics(range: _chartRange),
      _repo.getBusinessWalletLedger(
        from: _iso(_range?.start),
        to: _range == null
            ? null
            : _iso(_range!.end.add(const Duration(days: 1))),
        type: _typeFilter.isEmpty ? null : _typeFilter,
        q: _search.isEmpty ? null : _search,
      ),
    ]);
    if (!mounted) return;

    final walletRes = results[0];
    final analyticsRes = results[1];
    final ledgerRes = results[2];

    if (!walletRes.success) {
      setState(() {
        _loading = false;
        _error = walletRes.message ?? 'Could not load wallet';
      });
      return;
    }

    final summary = walletRes.data is Map && walletRes.data['data'] is Map
        ? Map<String, dynamic>.from(walletRes.data['data'] as Map)
        : <String, dynamic>{};
    final analytics =
        analyticsRes.success &&
                analyticsRes.data is Map &&
                analyticsRes.data['data'] is Map
            ? Map<String, dynamic>.from(analyticsRes.data['data'] as Map)
            : <String, dynamic>{};
    final ledgerPayload =
        ledgerRes.data is Map && ledgerRes.data['data'] is Map
            ? Map<String, dynamic>.from(ledgerRes.data['data'] as Map)
            : <String, dynamic>{};

    setState(() {
      _summary = summary;
      _analytics = analytics;
      _ledger = ledgerPayload['items'] is List
          ? List<dynamic>.from(ledgerPayload['items'] as List)
          : const [];
      _loading = false;
    });
  }

  Future<void> _reloadAnalytics(String range) async {
    setState(() {
      _chartRange = range;
      _analyticsLoading = true;
    });
    final res = await _repo.getBusinessWalletAnalytics(range: range);
    if (!mounted) return;
    setState(() {
      _analyticsLoading = false;
      if (res.success && res.data is Map && res.data['data'] is Map) {
        _analytics = Map<String, dynamic>.from(res.data['data'] as Map);
      }
    });
  }

  Future<void> _reloadLedgerOnly() async {
    final ledgerRes = await _repo.getBusinessWalletLedger(
      from: _iso(_range?.start),
      to: _range == null
          ? null
          : _iso(_range!.end.add(const Duration(days: 1))),
      type: _typeFilter.isEmpty ? null : _typeFilter,
      q: _search.isEmpty ? null : _search,
    );
    if (!mounted) return;
    final ledgerPayload =
        ledgerRes.data is Map && ledgerRes.data['data'] is Map
            ? Map<String, dynamic>.from(ledgerRes.data['data'] as Map)
            : <String, dynamic>{};
    setState(() {
      _ledger = ledgerPayload['items'] is List
          ? List<dynamic>.from(ledgerPayload['items'] as List)
          : const [];
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _range,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _range = picked);
    await _reloadLedgerOnly();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _search = value.trim());
      _reloadLedgerOnly();
    });
    setState(() {});
  }

  List<Map<String, dynamic>> _seriesMaps() {
    final raw = _analytics?['series'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> _breakdownMaps() {
    final raw = _analytics?['breakdown'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = _summary?['currency']?.toString() ??
        _analytics?['currency']?.toString() ??
        'SAR';
    final rangeLabel = _range == null
        ? 'All dates'
        : '${DateFormat('MMM d').format(_range!.start)} – ${DateFormat('MMM d, yyyy').format(_range!.end)}';
    final totals = _analytics?['totals'] is Map
        ? Map<String, dynamic>.from(_analytics!['totals'] as Map)
        : <String, dynamic>{};
    final periodRevenue = (totals['revenue'] as num?)?.toDouble() ?? 0;
    final periodRefunds = (totals['refunds'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Earnings',
              trailing: SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Filter dates',
                  onPressed: _pickRange,
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : _error != null && _summary == null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            FinanceErrorBlock(
                              message: _error!,
                              onRetry: _load,
                            ),
                          ],
                        )
                      : RefreshIndicator(
                          color: Colors.black,
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              FinanceUi.sidePad,
                              0,
                              FinanceUi.sidePad,
                              40,
                            ),
                            children: [
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    _error!,
                                    style: WaUi.caption.copyWith(
                                      color: FinanceUi.danger,
                                    ),
                                  ),
                                ),
                              const FinanceSectionHeader(
                                title: 'Financial overview',
                              ),
                              FinanceMetricCard(
                                label: 'Net revenue',
                                value: formatMoney(
                                  (_summary?['netRevenue'] as num?)
                                          ?.toDouble() ??
                                      0,
                                  currency: currency,
                                ),
                                large: true,
                                emphasize: true,
                                subtitle: 'Lifetime minus refunds',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FinanceMetricCard(
                                      label: 'Total revenue',
                                      value: formatMoney(
                                        (_summary?['totalEarnings'] as num?)
                                                ?.toDouble() ??
                                            0,
                                        currency: currency,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FinanceMetricCard(
                                      label: 'Available',
                                      value: formatMoney(
                                        (_summary?['availableBalance'] as num?)
                                                ?.toDouble() ??
                                            0,
                                        currency: currency,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: FinanceMetricCard(
                                      label: 'Pending',
                                      value: formatMoney(
                                        (_summary?['pendingBalance'] as num?)
                                                ?.toDouble() ??
                                            0,
                                        currency: currency,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FinanceMetricCard(
                                      label: 'Refunded',
                                      value: formatMoney(
                                        (_summary?['totalRefunded'] as num?)
                                                ?.toDouble() ??
                                            0,
                                        currency: currency,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              FinanceMetricCard(
                                label: 'Stripe processing fees',
                                value: formatMoney(
                                  (_summary?['totalStripeFees'] as num?)
                                          ?.toDouble() ??
                                      0,
                                  currency: currency,
                                ),
                                subtitle:
                                    'BarQody takes no commission · Withdrawals not available yet',
                              ),
                              const SizedBox(height: 28),
                              FinanceSectionHeader(
                                title: 'Analytics',
                                trailing: _analyticsLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : null,
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final opt in const [
                                      ('Day', 'day'),
                                      ('Week', 'week'),
                                      ('Month', 'month'),
                                      ('Year', 'year'),
                                    ])
                                      FinanceFilterChip(
                                        label: opt.$1,
                                        selected: _chartRange == opt.$2,
                                        onTap: () => _reloadAnalytics(opt.$2),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Revenue trend',
                                style: WaUi.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: FinanceUi.bodyMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: const [
                                  FinanceLegendDot(
                                    color: Colors.black,
                                    label: 'Revenue',
                                  ),
                                  SizedBox(width: 16),
                                  FinanceLegendDot(
                                    color: FinanceUi.danger,
                                    label: 'Refunds',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              FinanceRevenueTrendChart(
                                series: _seriesMaps(),
                                bucket:
                                    _analytics?['bucket']?.toString() ?? 'day',
                                currency: currency,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Payments vs refunds',
                                style: WaUi.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: FinanceUi.bodyMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FinancePaymentsRefundsChart(
                                revenue: periodRevenue,
                                refunds: periodRefunds,
                                currency: currency,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Earnings breakdown',
                                style: WaUi.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: FinanceUi.bodyMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FinanceBreakdownList(
                                items: _breakdownMaps(),
                                currency: currency,
                              ),
                              const SizedBox(height: 28),
                              FinanceSectionHeader(
                                title: 'Transactions',
                                trailing: Text(
                                  rangeLabel,
                                  style: WaUi.caption.copyWith(
                                    color: FinanceUi.muted,
                                  ),
                                ),
                              ),
                              FinanceSearchField(
                                controller: _searchCtrl,
                                onChanged: _onSearchChanged,
                                onClear: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                  _reloadLedgerOnly();
                                },
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    FinanceFilterChip(
                                      label: 'All',
                                      selected: _typeFilter.isEmpty,
                                      onTap: () {
                                        setState(() => _typeFilter = '');
                                        _reloadLedgerOnly();
                                      },
                                    ),
                                    FinanceFilterChip(
                                      label: 'Payments',
                                      selected:
                                          _typeFilter == 'payment_credit',
                                      onTap: () {
                                        setState(
                                          () =>
                                              _typeFilter = 'payment_credit',
                                        );
                                        _reloadLedgerOnly();
                                      },
                                    ),
                                    FinanceFilterChip(
                                      label: 'Refunds',
                                      selected: _typeFilter == 'refund_debit',
                                      onTap: () {
                                        setState(
                                          () => _typeFilter = 'refund_debit',
                                        );
                                        _reloadLedgerOnly();
                                      },
                                    ),
                                    FinanceFilterChip(
                                      label: 'Partial',
                                      selected: _typeFilter ==
                                          'partial_refund_debit',
                                      onTap: () {
                                        setState(
                                          () => _typeFilter =
                                              'partial_refund_debit',
                                        );
                                        _reloadLedgerOnly();
                                      },
                                    ),
                                    if (_range != null)
                                      TextButton(
                                        onPressed: () {
                                          setState(() => _range = null);
                                          _reloadLedgerOnly();
                                        },
                                        child: Text(
                                          'Clear dates',
                                          style: WaUi.caption.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_ledger.isEmpty)
                                const FinanceEmptyState(
                                  title: 'No transactions yet',
                                  subtitle:
                                      'Payments and refunds will appear here as they settle.',
                                )
                              else
                                ..._ledger.map((raw) {
                                  final e = raw is Map
                                      ? Map<String, dynamic>.from(raw)
                                      : <String, dynamic>{};
                                  final amount =
                                      (e['amount'] as num?)?.toDouble() ?? 0;
                                  final type = e['type']?.toString() ?? '';
                                  final orderId = e['order']?.toString();
                                  final paymentId = e['payment']?.toString();
                                  final debit = FinanceUi.isDebitType(type) ||
                                      amount < 0;
                                  final orderNo = e['orderNumber'];
                                  final publicRef =
                                      e['publicRef']?.toString() ?? '';
                                  final note = e['note']?.toString() ?? '';
                                  final subtitle = [
                                    FinanceUi.formatLedgerDate(e['createdAt']),
                                    if (orderNo != null &&
                                        '$orderNo'.trim().isNotEmpty)
                                      '#$orderNo',
                                    if (publicRef.isNotEmpty) publicRef,
                                    if (note.isNotEmpty) note,
                                  ].where((s) => s.isNotEmpty).join(' · ');
                                  return FinanceTransactionTile(
                                    title: FinanceUi.ledgerTypeLabel(type),
                                    subtitle: subtitle.isEmpty
                                        ? 'Ledger entry'
                                        : subtitle,
                                    amount: amount,
                                    currency: currency,
                                    isDebit: debit,
                                    statusLabel: debit ? 'Debit' : 'Credit',
                                    statusTone: debit
                                        ? FinanceStatusTone.refunded
                                        : FinanceStatusTone.success,
                                    onTap: () {
                                      if ((paymentId == null ||
                                              paymentId.isEmpty) &&
                                          (orderId == null ||
                                              orderId.isEmpty)) {
                                        return;
                                      }
                                      Navigator.of(context).push(
                                        AppPageRoute(
                                          builder: (_) => PaymentDetailScreen(
                                            paymentId: paymentId,
                                            orderId: orderId,
                                          ),
                                        ),
                                      );
                                    },
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
}
