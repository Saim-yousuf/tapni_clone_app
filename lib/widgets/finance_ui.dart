import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/connection_error_state.dart';

/// Shared BarQody finance chrome — black/white, minimal cards, consistent status.
class FinanceUi {
  FinanceUi._();

  static const Color border = Color(0xFFE5E5EA);
  static const Color muted = Color(0xFF8E8E93);
  static const Color bodyMuted = Color(0xFF71717A);
  static const Color success = Color(0xFF1B7F4E);
  static const Color successBg = Color(0xFFE8F5EE);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerBg = Color(0xFFFDECEA);
  static const Color warning = Color(0xFF9A6700);
  static const Color warningBg = Color(0xFFFFF4D6);
  static const Color pending = Color(0xFF54656F);
  static const Color pendingBg = Color(0xFFF0F2F5);
  static const double radius = 16;
  static const double sidePad = 20;

  static BoxDecoration cardDecoration({Color? fill}) => BoxDecoration(
        color: fill ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      );

  static String ledgerTypeLabel(String type) {
    switch (type) {
      case 'payment_credit':
        return 'Payment';
      case 'refund_debit':
        return 'Refund';
      case 'partial_refund_debit':
        return 'Partial refund';
      case 'dispute_hold':
        return 'Dispute hold';
      case 'dispute_release':
        return 'Dispute release';
      case 'dispute_loss':
        return 'Dispute loss';
      case 'fee_adjustment':
        return 'Fee adjustment';
      case 'manual_adjustment':
        return 'Adjustment';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  static bool isDebitType(String type) {
    return type.contains('refund') ||
        type == 'dispute_loss' ||
        type == 'dispute_hold' ||
        type == 'fee_adjustment';
  }

  static FinanceStatusTone statusTone(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.contains('fail') || s == 'canceled' || s == 'cancelled') {
      return FinanceStatusTone.failed;
    }
    if (s.contains('refund') && s.contains('process')) {
      return FinanceStatusTone.pending;
    }
    if (s.contains('partial')) return FinanceStatusTone.warning;
    if (s.contains('refund')) return FinanceStatusTone.refunded;
    if (s == 'succeeded' || s == 'paid' || s == 'available') {
      return FinanceStatusTone.success;
    }
    if (s == 'pending' || s == 'processing' || s == 'requires_action') {
      return FinanceStatusTone.pending;
    }
    return FinanceStatusTone.neutral;
  }

  static String paymentStatusLabel(Map<String, dynamic> p) {
    final status = (p['status']?.toString() ?? '').toLowerCase();
    final refund = (p['refundStatus']?.toString() ?? '').toLowerCase();
    if (refund == 'processing') return 'Refund processing';
    if (status == 'refunded' || refund == 'refunded') return 'Refunded';
    if (status == 'partially_refunded' || refund == 'partially_refunded') {
      return 'Partially refunded';
    }
    if (refund == 'failed') return 'Refund failed';
    if (status == 'succeeded') return 'Paid';
    if (status == 'failed') return 'Failed';
    if (status == 'canceled') return 'Cancelled';
    if (status.isEmpty) return 'Pending';
    return status.replaceAll('_', ' ');
  }

  static String formatLedgerDate(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('h:mm a').format(dt);
    }
    if (dt.year == now.year) return DateFormat('MMM d · h:mm a').format(dt);
    return DateFormat('MMM d, yyyy').format(dt);
  }

  static String shortBucketLabel(String key, String bucket) {
    try {
      if (bucket == 'hour') {
        final h = int.tryParse(key.split('T').last) ?? 0;
        return DateFormat('ha').format(DateTime(2000, 1, 1, h));
      }
      if (bucket == 'month') {
        final parts = key.split('-');
        if (parts.length >= 2) {
          final y = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          return DateFormat('MMM').format(DateTime(y, m));
        }
      }
      final parts = key.split('-');
      if (parts.length >= 3) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return DateFormat('d').format(DateTime(y, m, d));
      }
    } catch (_) {}
    return key;
  }
}

enum FinanceStatusTone { success, failed, refunded, warning, pending, neutral }

class FinanceStatusChip extends StatelessWidget {
  const FinanceStatusChip({super.key, required this.label, this.tone});

  final String label;
  final FinanceStatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final t = tone ?? FinanceUi.statusTone(label);
    late Color fg;
    late Color bg;
    late IconData icon;
    switch (t) {
      case FinanceStatusTone.success:
        fg = FinanceUi.success;
        bg = FinanceUi.successBg;
        icon = Icons.check_circle_outline;
        break;
      case FinanceStatusTone.failed:
        fg = FinanceUi.danger;
        bg = FinanceUi.dangerBg;
        icon = Icons.error_outline;
        break;
      case FinanceStatusTone.refunded:
        fg = FinanceUi.danger;
        bg = FinanceUi.dangerBg;
        icon = Icons.undo_rounded;
        break;
      case FinanceStatusTone.warning:
        fg = FinanceUi.warning;
        bg = FinanceUi.warningBg;
        icon = Icons.info_outline;
        break;
      case FinanceStatusTone.pending:
        fg = FinanceUi.pending;
        bg = FinanceUi.pendingBg;
        icon = Icons.schedule_outlined;
        break;
      case FinanceStatusTone.neutral:
        fg = FinanceUi.bodyMuted;
        bg = FinanceUi.pendingBg;
        icon = Icons.circle_outlined;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: WaUi.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class FinanceMetricCard extends StatelessWidget {
  const FinanceMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.large = false,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final bool large;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(large ? 18 : 14),
      decoration: FinanceUi.cardDecoration(
        fill: emphasize ? Colors.black : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: WaUi.caption.copyWith(
              color: emphasize ? Colors.white70 : FinanceUi.bodyMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: WaUi.toolsTitleOf(
              size: large ? 28 : 18,
              weight: FontWeight.w800,
              color: emphasize ? Colors.white : Colors.black,
              letterSpacing: large ? -0.6 : -0.2,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: WaUi.caption.copyWith(
                color: emphasize ? Colors.white60 : FinanceUi.muted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FinanceSectionHeader extends StatelessWidget {
  const FinanceSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: WaUi.sectionHeader.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class FinanceFilterChip extends StatelessWidget {
  const FinanceFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: selected ? Colors.black : FinanceUi.border,
              ),
            ),
            child: Text(
              label,
              style: WaUi.caption.copyWith(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FinanceEmptyState extends StatelessWidget {
  const FinanceEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.receipt_long_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: FinanceUi.cardDecoration(fill: const Color(0xFFFAFAFA)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: FinanceUi.muted, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: WaUi.caption.copyWith(color: FinanceUi.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class FinanceErrorBlock extends StatelessWidget {
  const FinanceErrorBlock({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: ConnectionErrorState(message: message, onRetry: onRetry),
    );
  }
}

class FinanceAmountText extends StatelessWidget {
  const FinanceAmountText({
    super.key,
    required this.amount,
    this.currency = 'SAR',
    this.signed = false,
    this.size = 16,
  });

  final double amount;
  final String currency;
  final bool signed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isNeg = amount < 0 || (signed && amount < 0);
    final display = signed && amount > 0
        ? '+${formatMoney(amount, currency: currency)}'
        : formatMoney(amount.abs(), currency: currency);
    final prefix = signed && amount < 0 ? '−' : '';
    return Text(
      '$prefix$display',
      style: WaUi.body.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: size,
        color: isNeg ? FinanceUi.danger : Colors.black,
        letterSpacing: -0.2,
      ),
    );
  }
}

class FinanceTransactionTile extends StatelessWidget {
  const FinanceTransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    this.statusLabel,
    this.statusTone,
    this.icon,
    this.isDebit = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final String? statusLabel;
  final FinanceStatusTone? statusTone;
  final IconData? icon;
  final bool isDebit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final debit = isDebit || amount < 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FinanceUi.radius),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: FinanceUi.cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: debit ? FinanceUi.dangerBg : FinanceUi.pendingBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon ??
                      (debit
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded),
                  size: 18,
                  color: debit ? FinanceUi.danger : Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.caption.copyWith(color: FinanceUi.muted),
                    ),
                    if (statusLabel != null && statusLabel!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      FinanceStatusChip(
                        label: statusLabel!,
                        tone: statusTone,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${debit && amount >= 0 ? '−' : ''}${formatMoney(amount.abs(), currency: currency)}',
                style: WaUi.body.copyWith(
                  fontWeight: FontWeight.w800,
                  color: debit ? FinanceUi.danger : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinanceSavedCardTile extends StatelessWidget {
  const FinanceSavedCardTile({
    super.key,
    required this.label,
    required this.meta,
    this.onMenu,
  });

  final String label;
  final String meta;
  final void Function(String value)? onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: FinanceUi.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.credit_card_outlined, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WaUi.listTitle.copyWith(fontWeight: FontWeight.w700),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: WaUi.caption.copyWith(color: FinanceUi.muted),
                  ),
                ],
              ],
            ),
          ),
          if (onMenu != null)
            PopupMenuButton<String>(
              onSelected: onMenu,
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'default',
                  child: Text('Set as default'),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class FinanceDetailRow extends StatelessWidget {
  const FinanceDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: WaUi.caption.copyWith(color: FinanceUi.bodyMuted),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dual-series revenue vs refunds line chart from backend analytics series.
class FinanceRevenueTrendChart extends StatelessWidget {
  const FinanceRevenueTrendChart({
    super.key,
    required this.series,
    required this.bucket,
    required this.currency,
    this.height = 200,
  });

  final List<Map<String, dynamic>> series;
  final String bucket;
  final String currency;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return FinanceEmptyState(
        title: 'No activity in this period',
        subtitle: 'Revenue trends appear once payments settle.',
        icon: Icons.show_chart_rounded,
      );
    }

    final revenueSpots = <FlSpot>[];
    final refundSpots = <FlSpot>[];
    double maxY = 0;
    for (var i = 0; i < series.length; i++) {
      final r = (series[i]['revenue'] as num?)?.toDouble() ?? 0;
      final f = (series[i]['refunds'] as num?)?.toDouble() ?? 0;
      revenueSpots.add(FlSpot(i.toDouble(), r));
      refundSpots.add(FlSpot(i.toDouble(), f));
      if (r > maxY) maxY = r;
      if (f > maxY) maxY = f;
    }
    if (maxY <= 0) maxY = 1;
    final labelEvery = (series.length / 6).ceil().clamp(1, 99);

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: FinanceUi.cardDecoration(),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY * 1.15,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: FinanceUi.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: maxY / 4,
                getTitlesWidget: (v, _) {
                  if (v <= 0) return const SizedBox.shrink();
                  return Text(
                    NumberFormat.compact().format(v),
                    style: WaUi.caption.copyWith(
                      fontSize: 10,
                      color: FinanceUi.muted,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final i = v.round();
                  if (i < 0 || i >= series.length) {
                    return const SizedBox.shrink();
                  }
                  if (i % labelEvery != 0 && i != series.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final key = series[i]['key']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      FinanceUi.shortBucketLabel(key, bucket),
                      style: WaUi.caption.copyWith(
                        fontSize: 10,
                        color: FinanceUi.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final label = s.barIndex == 0 ? 'Revenue' : 'Refunds';
                return LineTooltipItem(
                  '$label\n${formatMoney(s.y, currency: currency)}',
                  WaUi.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: revenueSpots,
              isCurved: true,
              color: Colors.black,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ),
            LineChartBarData(
              spots: refundSpots,
              isCurved: true,
              color: FinanceUi.danger,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Payments vs refunds bar comparison for the selected range.
class FinancePaymentsRefundsChart extends StatelessWidget {
  const FinancePaymentsRefundsChart({
    super.key,
    required this.revenue,
    required this.refunds,
    required this.currency,
    this.height = 160,
  });

  final double revenue;
  final double refunds;
  final String currency;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (revenue <= 0 && refunds <= 0) {
      return const FinanceEmptyState(
        title: 'No payments or refunds',
        subtitle: 'Comparisons show once ledger activity exists.',
        icon: Icons.bar_chart_rounded,
      );
    }
    final maxY = [revenue, refunds, 1.0].reduce((a, b) => a > b ? a : b);

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: FinanceUi.cardDecoration(),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final label = v.toInt() == 0 ? 'Payments' : 'Refunds';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: WaUi.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: FinanceUi.bodyMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: revenue,
                        width: 36,
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: refunds,
                        width: 36,
                        borderRadius: BorderRadius.circular(8),
                        color: FinanceUi.danger,
                      ),
                    ],
                  ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = group.x == 0 ? 'Payments' : 'Refunds';
                      return BarTooltipItem(
                        '$label\n${formatMoney(rod.toY, currency: currency)}',
                        WaUi.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                formatMoney(revenue, currency: currency),
                style: WaUi.caption.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                formatMoney(refunds, currency: currency),
                style: WaUi.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: FinanceUi.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple earnings breakdown bars (payments / refunds / net).
class FinanceBreakdownList extends StatelessWidget {
  const FinanceBreakdownList({
    super.key,
    required this.items,
    required this.currency,
  });

  final List<Map<String, dynamic>> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const FinanceEmptyState(
        title: 'No breakdown yet',
        icon: Icons.pie_chart_outline_rounded,
      );
    }
    final maxAmt = items
        .map((e) => (e['amount'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final denom = maxAmt <= 0 ? 1.0 : maxAmt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FinanceUi.cardDecoration(),
      child: Column(
        children: items.map((e) {
          final label = e['label']?.toString() ?? e['key']?.toString() ?? '';
          final amount = (e['amount'] as num?)?.toDouble() ?? 0;
          final key = e['key']?.toString() ?? '';
          final color = key == 'refunds' ? FinanceUi.danger : Colors.black;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: WaUi.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: FinanceUi.bodyMuted,
                        ),
                      ),
                    ),
                    Text(
                      formatMoney(amount, currency: currency),
                      style: WaUi.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (amount / denom).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: FinanceUi.pendingBg,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FinanceLegendDot extends StatelessWidget {
  const FinanceLegendDot({
    super.key,
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: WaUi.caption.copyWith(color: FinanceUi.muted),
        ),
      ],
    );
  }
}

class FinanceSearchField extends StatelessWidget {
  const FinanceSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search transactions',
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: WaUi.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: WaUi.caption.copyWith(color: FinanceUi.muted),
        prefixIcon: const Icon(Icons.search, color: FinanceUi.muted, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear, size: 18),
              ),
        filled: true,
        fillColor: BarqodyChrome.searchBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
