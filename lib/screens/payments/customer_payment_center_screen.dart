import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:tapni_app/repository/payment_repo.dart';
import 'package:tapni_app/screens/payments/payment_detail_screen.dart';
import 'package:tapni_app/services/stripe_payment_service.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/payment_display.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/finance_ui.dart';

/// Customer Payment Center: saved cards + payment/refund history.
class CustomerPaymentCenterScreen extends StatefulWidget {
  const CustomerPaymentCenterScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CustomerPaymentCenterScreen> createState() =>
      _CustomerPaymentCenterScreenState();
}

class _CustomerPaymentCenterScreenState
    extends State<CustomerPaymentCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _repo = PaymentRepo();

  bool _cardsLoading = true;
  bool _historyLoading = true;
  String? _cardsError;
  String? _historyError;
  List<SavedCard> _cards = const [];
  List<Map<String, dynamic>> _payments = const [];
  String _historyFilter = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _loadCards();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() {
      _cardsLoading = true;
      _cardsError = null;
    });
    try {
      final cards = await _repo.listSavedCards();
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _cardsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cardsError = e.toString();
        _cardsLoading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    final res = await _repo.listMyPayments();
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _historyError = PaymentDisplay.sanitizeError(
          res.message,
          fallback: 'Could not load payment history',
        );
        _historyLoading = false;
      });
      return;
    }
    final data = res.data is Map && res.data['data'] is Map
        ? Map<String, dynamic>.from(res.data['data'] as Map)
        : <String, dynamic>{};
    final items = data['items'] is List
        ? (data['items'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    setState(() {
      _payments = items;
      _historyLoading = false;
    });
  }

  Future<void> _addCard() async {
    final ready = await StripePaymentService.instance.ensureInitialized();
    if (!ready) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            StripePaymentService.instance.nativeError ??
                'Stripe is not ready',
          ),
        ),
      );
      return;
    }
    final res = await _repo.createSetupIntent();
    if (!res.success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Could not start card setup')),
      );
      return;
    }
    final data = res.data is Map && res.data['data'] is Map
        ? Map<String, dynamic>.from(res.data['data'] as Map)
        : Map<String, dynamic>.from(res.data as Map);
    try {
      await StripePaymentService.instance.presentSetupSheet(
        clientSecret: data['clientSecret']?.toString() ?? '',
        customerId: data['customerId']?.toString() ?? '',
        ephemeralKey: data['ephemeralKey']?.toString() ?? '',
        merchantDisplayName: 'BarQody',
      );
      await _loadCards();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card saved')),
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.error.localizedMessage ?? 'Could not save card'),
        ),
      );
    }
  }

  Future<void> _removeCard(SavedCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove card',
          style: WaUi.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text('Remove ${card.label}?', style: WaUi.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: WaUi.body.copyWith(
                color: FinanceUi.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await _repo.removeCard(card.id);
    if (!mounted) return;
    if (res.success) {
      await _loadCards();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Could not remove card')),
      );
    }
  }

  Future<void> _setDefault(SavedCard card) async {
    final res = await _repo.setDefaultCard(card.id);
    if (!mounted) return;
    if (res.success) await _loadCards();
  }

  List<Map<String, dynamic>> get _visiblePayments {
    if (_historyFilter.isEmpty) return _payments;
    if (_historyFilter == 'refunded') {
      return _payments.where((p) {
        final status = (p['status']?.toString() ?? '').toLowerCase();
        final refund = (p['refundStatus']?.toString() ?? '').toLowerCase();
        return status.contains('refund') ||
            refund.contains('refund') ||
            ((p['refundedAmount'] as num?)?.toDouble() ?? 0) > 0;
      }).toList();
    }
    if (_historyFilter == 'failed') {
      return _payments.where((p) {
        final status = (p['status']?.toString() ?? '').toLowerCase();
        return status == 'failed' || status == 'canceled';
      }).toList();
    }
    if (_historyFilter == 'succeeded') {
      return _payments.where((p) {
        final status = (p['status']?.toString() ?? '').toLowerCase();
        final refund = (p['refundStatus']?.toString() ?? '').toLowerCase();
        return status == 'succeeded' &&
            !refund.contains('refund') &&
            ((p['refundedAmount'] as num?)?.toDouble() ?? 0) <= 0;
      }).toList();
    }
    return _payments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Payments'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FinanceUi.sidePad),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: BarqodyChrome.searchBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabs,
                  labelColor: Colors.black,
                  unselectedLabelColor: FinanceUi.muted,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  labelStyle: WaUi.caption.copyWith(fontWeight: FontWeight.w700),
                  unselectedLabelStyle: WaUi.caption,
                  tabs: const [
                    Tab(text: 'Cards'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildCardsTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsTab() {
    return RefreshIndicator(
      color: Colors.black,
      onRefresh: _loadCards,
      child: _cardsLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 140),
                Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FinanceUi.sidePad,
                16,
                FinanceUi.sidePad,
                32,
              ),
              children: [
                if (_cardsError != null)
                  FinanceErrorBlock(
                    message: _cardsError!,
                    onRetry: _loadCards,
                  ),
                if (_cards.isEmpty && _cardsError == null)
                  const FinanceEmptyState(
                    title: 'No saved cards',
                    subtitle:
                        'Add a card securely with Stripe for faster checkout.',
                    icon: Icons.credit_card_outlined,
                  ),
                ..._cards.map((card) {
                  final meta = [
                    if (card.expiryLabel.isNotEmpty) 'Exp ${card.expiryLabel}',
                    if (card.isDefault) 'Default',
                  ].join(' · ');
                  return FinanceSavedCardTile(
                    label: card.label,
                    meta: meta,
                    onMenu: (v) {
                      if (v == 'default') _setDefault(card);
                      if (v == 'remove') _removeCard(card);
                    },
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  height: WaUi.primaryButtonHeight,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addCard,
                    icon: const Icon(Icons.add_card_outlined),
                    label: const Text('Add card'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 1.5),
                      shape: const StadiumBorder(),
                      textStyle: WaUi.promoButton.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Card numbers and CVC are handled by Stripe. BarQody never stores them.',
                  style: WaUi.caption.copyWith(color: FinanceUi.muted),
                ),
              ],
            ),
    );
  }

  Widget _buildHistoryTab() {
    final items = _visiblePayments;
    return RefreshIndicator(
      color: Colors.black,
      onRefresh: _loadHistory,
      child: _historyLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 140),
                Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FinanceUi.sidePad,
                16,
                FinanceUi.sidePad,
                32,
              ),
              children: [
                if (_historyError != null)
                  FinanceErrorBlock(
                    message: _historyError!,
                    onRetry: _loadHistory,
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final opt in const [
                        ('All', ''),
                        ('Paid', 'succeeded'),
                        ('Refunds', 'refunded'),
                        ('Failed', 'failed'),
                      ])
                        FinanceFilterChip(
                          label: opt.$1,
                          selected: _historyFilter == opt.$2,
                          onTap: () {
                            setState(() => _historyFilter = opt.$2);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty && _historyError == null)
                  const FinanceEmptyState(
                    title: 'No payments yet',
                    subtitle:
                        'Orders you pay for will show up here with refund status.',
                    icon: Icons.receipt_long_outlined,
                  )
                else
                  ...items.map((p) {
                    final amount = (p['amount'] as num?)?.toDouble() ?? 0;
                    final currency = p['currency']?.toString() ?? 'SAR';
                    final biz = p['business'] is Map
                        ? Map<String, dynamic>.from(p['business'] as Map)
                        : <String, dynamic>{};
                    final purpose = p['purpose']?.toString() ?? 'order';
                    final apiTitle = p['title']?.toString().trim() ?? '';
                    final title = apiTitle.isNotEmpty
                        ? apiTitle
                        : purpose == 'subscription'
                            ? 'BarQody plan'
                            : (biz['name']?.toString().isNotEmpty == true
                                ? biz['name'].toString()
                                : 'Payment');
                    final refunded =
                        (p['refundedAmount'] as num?)?.toDouble() ?? 0;
                    final status = FinanceUi.paymentStatusLabel(p);
                    final date = FinanceUi.formatLedgerDate(
                      p['createdAt'] ?? p['paidAt'],
                    );
                    final publicRef = PaymentDisplay.friendlyRef(
                      publicRef: p['publicRef']?.toString(),
                      publicPaymentRef: p['order'] is Map
                          ? (p['order']['publicPaymentRef']?.toString())
                          : null,
                    );
                    final orderNo = p['order'] is Map
                        ? p['order']['tokenNumber']
                        : null;
                    final subtitle = [
                      if (date.isNotEmpty) date,
                      if (orderNo != null && '$orderNo'.trim().isNotEmpty)
                        '#$orderNo',
                      if (publicRef.isNotEmpty) publicRef,
                      if (refunded > 0)
                        'Refunded ${formatMoney(refunded, currency: currency)}',
                    ].join(' · ');
                    return FinanceTransactionTile(
                      title: title,
                      subtitle: subtitle.isEmpty ? status : subtitle,
                      amount: amount,
                      currency: currency,
                      statusLabel: status,
                      statusTone: FinanceUi.statusTone(status),
                      isDebit: status.toLowerCase().contains('fail') ||
                          status.toLowerCase().contains('refund'),
                      icon: status.toLowerCase().contains('refund')
                          ? Icons.undo_rounded
                          : status.toLowerCase().contains('fail')
                              ? Icons.error_outline
                              : Icons.north_east_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaymentDetailScreen(
                              paymentId: p['id']?.toString() ?? '',
                              orderId: p['orderId']?.toString(),
                            ),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
    );
  }
}
