import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/theme.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isBusinessView ? context.l10n.orders : context.l10n.myOrders,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppTheme.primaryBlack,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlack,
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

    return RefreshIndicator(
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
                      Icons.receipt_long_outlined,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noStatusOrders(
                        CatalogHelper.statusLabel(widget.status, context.l10n)
                            .toLowerCase(),
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
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
  final CatalogOrder order;
  final bool isBusinessView;
  final VoidCallback onTap;

  const _OrderTile({
    required this.order,
    required this.isBusinessView,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = isBusinessView ? order.customerName : order.businessName;
    final subtitle = isBusinessView
        ? order.customerUsername.isNotEmpty
            ? '@${order.customerUsername}'
            : order.itemsSummary
        : order.businessUsername.isNotEmpty
            ? '@${order.businessUsername}'
            : order.itemsSummary;

    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isNotEmpty ? title : context.l10n.order,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.itemsSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (order.hasToken) ...[
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${order.tokenNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    context.l10n.rsAmount(order.totalAmount.toStringAsFixed(0)),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _StatusChip(status: order.status),
                  if (!order.isRead && isBusinessView) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.noShow:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        CatalogHelper.statusLabel(status, context.l10n),
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
