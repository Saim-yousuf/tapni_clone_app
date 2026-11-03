import 'package:flutter/material.dart';
import 'package:tapni_app/repository/payment_repo.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/payment_display.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/finance_ui.dart';

class PaymentDetailScreen extends StatefulWidget {
  const PaymentDetailScreen({
    super.key,
    this.paymentId,
    this.orderId,
  });

  final String? paymentId;
  final String? orderId;

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final _repo = PaymentRepo();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _payment;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.paymentId != null && widget.paymentId!.isNotEmpty) {
        final res = await _repo.getMyPaymentDetail(widget.paymentId!);
        if (!res.success) {
          setState(() {
            _error = PaymentDisplay.sanitizeError(
              res.message,
              fallback: 'Could not load payment',
            );
            _loading = false;
          });
          return;
        }
        final data = res.data is Map && res.data['data'] is Map
            ? Map<String, dynamic>.from(res.data['data'] as Map)
            : <String, dynamic>{};
        setState(() {
          _payment = data;
          _order = data['order'] is Map
              ? Map<String, dynamic>.from(data['order'] as Map)
              : null;
          _loading = false;
        });
        return;
      }

      if (widget.orderId != null && widget.orderId!.isNotEmpty) {
        final res = await _repo.getPaymentByOrder(widget.orderId!);
        if (!res.success) {
          setState(() {
            _error = PaymentDisplay.sanitizeError(
              res.message,
              fallback: 'Could not load payment',
            );
            _loading = false;
          });
          return;
        }
        final data = res.data is Map && res.data['data'] is Map
            ? Map<String, dynamic>.from(res.data['data'] as Map)
            : <String, dynamic>{};
        setState(() {
          _order = data['order'] is Map
              ? Map<String, dynamic>.from(data['order'] as Map)
              : null;
          _payment = data['payment'] is Map
              ? Map<String, dynamic>.from(data['payment'] as Map)
              : null;
          _loading = false;
        });
        return;
      }

      setState(() {
        _error = 'Could not load payment';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = PaymentDisplay.sanitizeError(
          e.toString(),
          fallback: 'Could not load payment',
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _payment ?? {};
    final o = _order ?? {};
    final currency =
        p['currency']?.toString() ?? o['currency']?.toString() ?? 'SAR';
    final amount = (p['amount'] as num?)?.toDouble() ??
        (o['totalAmount'] as num?)?.toDouble() ??
        0;
    final refunded = (p['refundedAmount'] as num?)?.toDouble() ??
        (o['refundedAmount'] as num?)?.toDouble() ??
        0;
    final fee = (p['stripeFeeAmount'] as num?)?.toDouble() ??
        (o['stripeFeeAmount'] as num?)?.toDouble() ??
        0;
    final statusLabel = FinanceUi.paymentStatusLabel({
      ...p,
      if ((p['status']?.toString() ?? '').isEmpty &&
          (o['paymentStatus']?.toString() ?? '').isNotEmpty)
        'status': o['paymentStatus'],
      if ((p['refundStatus']?.toString() ?? '').isEmpty &&
          (o['refundStatus']?.toString() ?? '').isNotEmpty)
        'refundStatus': o['refundStatus'],
    });
    final refundStatus =
        (p['refundStatus'] ?? o['refundStatus'] ?? 'none').toString();
    final paidAt = FinanceUi.formatLedgerDate(
      p['paidAt'] ?? p['succeededAt'] ?? p['createdAt'],
    );
    final publicRef = () {
      final direct = PaymentDisplay.friendlyRef(
        publicRef: p['publicRef']?.toString(),
        publicPaymentRef: o['publicPaymentRef']?.toString(),
      );
      if (direct.isNotEmpty) return direct;
      return PaymentDisplay.fromSeed(
        p['id']?.toString().isNotEmpty == true
            ? p['id']?.toString()
            : o['id']?.toString(),
      );
    }();
    final orderLabel = PaymentDisplay.orderLabel(
      tokenNumber: o['tokenNumber'] ?? p['order']?['tokenNumber'],
      publicRef: publicRef,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Payment details'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : RefreshIndicator(
                      color: Colors.black,
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          FinanceUi.sidePad,
                          0,
                          FinanceUi.sidePad,
                          32,
                        ),
                        children: [
                          if (_error != null)
                            FinanceErrorBlock(
                              message: _error!,
                              onRetry: _load,
                            ),
                          if (_error == null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: FinanceUi.cardDecoration(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Amount',
                                    style: WaUi.caption.copyWith(
                                      color: FinanceUi.bodyMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatMoney(amount, currency: currency),
                                    style: WaUi.toolsTitleOf(
                                      size: 32,
                                      weight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FinanceStatusChip(
                                    label: statusLabel,
                                    tone: FinanceUi.statusTone(statusLabel),
                                  ),
                                  if (paidAt.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      paidAt,
                                      style: WaUi.caption.copyWith(
                                        color: FinanceUi.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const FinanceSectionHeader(title: 'Summary'),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: FinanceUi.cardDecoration(),
                              child: Column(
                                children: [
                                  if (publicRef.isNotEmpty)
                                    FinanceDetailRow(
                                      label: 'Reference',
                                      value: publicRef,
                                    ),
                                  if (orderLabel.isNotEmpty)
                                    FinanceDetailRow(
                                      label: 'Order',
                                      value: orderLabel,
                                    ),
                                  FinanceDetailRow(
                                    label: 'Refund status',
                                    value: refundStatus.replaceAll('_', ' '),
                                  ),
                                  if (refunded > 0)
                                    FinanceDetailRow(
                                      label: 'Refunded amount',
                                      value: formatMoney(
                                        refunded,
                                        currency: currency,
                                      ),
                                    ),
                                  if (fee > 0)
                                    FinanceDetailRow(
                                      label: 'Processing fee',
                                      value: formatMoney(
                                        fee,
                                        currency: currency,
                                      ),
                                    ),
                                  FinanceDetailRow(
                                    label: 'Platform fee',
                                    value: formatMoney(0, currency: currency),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Refunds return to the original payment method. BarQody does not hold a customer cash wallet.',
                              style: WaUi.caption.copyWith(
                                color: FinanceUi.muted,
                              ),
                            ),
                          ],
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
