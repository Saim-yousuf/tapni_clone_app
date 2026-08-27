import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class OrdersListScreen extends StatefulWidget {
  final bool isBusinessView;

  const OrdersListScreen({super.key, required this.isBusinessView});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    OrderStatus.pending,
    OrderStatus.completed,
    OrderStatus.cancelled,
    OrderStatus.noShow,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.isBusinessView
              ? context.l10n.customerOrders
              : context.l10n.myOrders,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: isDark ? Colors.white : WaUi.primaryText,
          unselectedLabelColor: WaUi.secondaryText,
          indicatorColor: WaUi.navGreen,
          labelStyle: WaUi.label.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : WaUi.primaryText,
          ),
          unselectedLabelStyle: WaUi.label,
          tabs: _tabs
              .map((s) => Tab(text: CatalogHelper.statusLabel(s, context.l10n)))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map(
              (status) => _OrdersTabPage(
                status: status,
                isBusinessView: widget.isBusinessView,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _OrdersTabPage extends StatefulWidget {
  final OrderStatus status;
  final bool isBusinessView;

  const _OrdersTabPage({
    required this.status,
    required this.isBusinessView,
  });

  @override
  State<_OrdersTabPage> createState() => _OrdersTabPageState();
}

class _OrdersTabPageState extends State<_OrdersTabPage>
    with AutomaticKeepAliveClientMixin {
  final _repo = CatalogRepo();
  bool _isLoading = true;
  List<CatalogOrder> _orders = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final status = CatalogHelper.statusApiValue(widget.status);
    final orders = widget.isBusinessView
        ? await _repo.getBusinessOrders(status: status)
        : await _repo.getCustomerOrders(status: status);
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: WaUi.navGreen,
      onRefresh: _loadOrders,
      child: _isLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : _orders.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 56,
                      color: isDark
                          ? Colors.white24
                          : WaUi.secondaryText.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noStatusOrders(
                        CatalogHelper.statusLabel(widget.status, context.l10n)
                            .toLowerCase(),
                      ),
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(color: WaUi.secondaryText),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _OrderTile(
                    order: _orders[index],
                    isBusinessView: widget.isBusinessView,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(
                            orderId: _orders[index].id,
                            isBusinessView: widget.isBusinessView,
                          ),
                        ),
                      );
                      _loadOrders();
                    },
                  ),
                ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  static const double _radius = 18;
  static const Color _priceSoft = Color(0xFFEA580C);

  final CatalogOrder order;
  final bool isBusinessView;
  final VoidCallback onTap;

  const _OrderTile({
    required this.order,
    required this.isBusinessView,
    required this.onTap,
  });

  Color _avatarColor(String seed) {
    if (seed.isEmpty) return WaUi.avatarPalette.last;
    return WaUi.avatarPalette[seed.hashCode.abs() % WaUi.avatarPalette.length];
  }

  String? get _photoUrl =>
      isBusinessView ? order.customerPhoto : order.businessPhoto;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = isBusinessView ? order.customerName : order.businessName;
    final username =
        isBusinessView ? order.customerUsername : order.businessUsername;
    final displayTitle = title.isNotEmpty ? title : context.l10n.order;
    final initial =
        displayTitle.isNotEmpty ? displayTitle[0].toUpperCase() : '?';
    final photo = _photoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final titleColor = isDark ? Colors.white : WaUi.primaryText;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : WaUi.surface,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE8E8E8),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: _avatarColor(displayTitle),
                      backgroundImage:
                          hasPhoto ? NetworkImage(photo) : null,
                      child: hasPhoto
                          ? null
                          : Text(initial, style: WaUi.avatarInitial),
                    ),
                    if (!order.isRead && isBusinessView)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF6B6B),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: displayTitle,
                              style: WaUi.listTitle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                            if (username.isNotEmpty)
                              TextSpan(
                                text: ' (@$username)',
                                style: WaUi.listSubtitle.copyWith(
                                  color: isDark
                                      ? Colors.white54
                                      : WaUi.secondaryText,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.itemsSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.caption.copyWith(
                          color: isDark
                              ? Colors.white54
                              : WaUi.secondaryText.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusChip(status: order.status),
                          if (order.hasToken)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.14)
                                    : WaUi.primaryText,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '#${order.tokenNumber}',
                                style: WaUi.label.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoney(
                        order.totalAmount,
                        currency: order.currency,
                      ),
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFFB923C) : _priceSoft,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark ? Colors.white38 : WaUi.secondaryText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  ({Color bg, Color fg}) get _colors {
    switch (status) {
      case OrderStatus.pending:
        return (bg: const Color(0xFFFFEDD5), fg: const Color(0xFFC2410C));
      case OrderStatus.completed:
        return (bg: const Color(0xFFECFDF5), fg: const Color(0xFF047857));
      case OrderStatus.cancelled:
        return (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C));
      case OrderStatus.noShow:
        return (bg: const Color(0xFFF0F2F5), fg: const Color(0xFF667781));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? colors.fg.withValues(alpha: 0.18) : colors.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        CatalogHelper.statusLabel(status, context.l10n),
        style: WaUi.label.copyWith(
          color: isDark ? colors.fg.withValues(alpha: 0.95) : colors.fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
