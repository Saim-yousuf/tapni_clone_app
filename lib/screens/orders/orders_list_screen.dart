import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

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
    OrderStatus.confirmed,
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

  void _selectTab(int index) {
    if (_tabController.index == index && !_tabController.indexIsChanging) {
      return;
    }
    HapticFeedback.selectionClick();
    _tabController.animateTo(index);
  }

  List<String> _tabLabels(BuildContext context) {
    final l10n = context.l10n;
    return [
      l10n.pending,
      'Confirmed',
      l10n.completed,
      'Cancel',
      'Missed',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isBusinessView ? 'Booking' : 'My Booking';

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(title: title),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, _) {
                  return _SegmentedTabs(
                    position: _tabController.animation!.value,
                    labels: _tabLabels(context),
                    onChanged: _selectTab,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final double position;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.position,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final max = (labels.length - 1).toDouble();
    final t = position.clamp(0.0, max);
    final selected = t.round().clamp(0, labels.length - 1);

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              Positioned(
                left: t * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.body.copyWith(
                              fontSize: labels.length > 4 ? 11 : 13,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              color: i == selected
                                  ? Colors.white
                                  : BarqodyChrome.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
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
      color: Colors.black,
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
                      color: BarqodyChrome.secondaryText.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noStatusOrders(
                        CatalogHelper.statusLabel(widget.status, context.l10n)
                            .toLowerCase(),
                      ),
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(color: BarqodyChrome.secondaryText),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: _orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
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

  Color _avatarColor(String seed) {
    if (seed.isEmpty) return WaUi.avatarPalette.last;
    return WaUi.avatarPalette[seed.hashCode.abs() % WaUi.avatarPalette.length];
  }

  int get _totalItems =>
      order.items.fold<int>(0, (sum, item) => sum + item.quantity);

  String _orderDate() {
    if (order.createdAt != null) {
      final d = order.createdAt!.toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    if (order.bookingDate != null && order.bookingDate!.isNotEmpty) {
      return order.bookingDate!;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    if (isBusinessView) {
      return _BusinessOrderCard(
        order: order,
        onTap: onTap,
        avatarColor: _avatarColor,
        totalItems: _totalItems,
        orderDate: _orderDate(),
      );
    }
    return _CustomerOrderCard(
      order: order,
      onTap: onTap,
      avatarColor: _avatarColor,
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  final CatalogOrder order;
  final VoidCallback onTap;
  final Color Function(String seed) avatarColor;

  const _CustomerOrderCard({
    required this.order,
    required this.onTap,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        order.businessName.isNotEmpty ? order.businessName : context.l10n.order;
    final username = order.businessUsername;
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';
    final photo = order.businessPhoto;
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Material(
      color: BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: avatarColor(title),
                backgroundImage: hasPhoto ? NetworkImage(photo) : null,
                child: hasPhoto ? null : Text(initial, style: WaUi.avatarInitial),
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
                            text: title,
                            style: WaUi.listTitle.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (username.isNotEmpty)
                            TextSpan(
                              text: ' (@$username)',
                              style: WaUi.listSubtitle.copyWith(
                                color: BarqodyChrome.secondaryText,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.caption.copyWith(
                        color: BarqodyChrome.bodyText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (order.hasToken)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '#BK${order.tokenNumber}',
                          style: WaUi.label.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
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
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: BarqodyChrome.secondaryText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessOrderCard extends StatelessWidget {
  final CatalogOrder order;
  final VoidCallback onTap;
  final Color Function(String seed) avatarColor;
  final int totalItems;
  final String orderDate;

  const _BusinessOrderCard({
    required this.order,
    required this.onTap,
    required this.avatarColor,
    required this.totalItems,
    required this.orderDate,
  });

  @override
  Widget build(BuildContext context) {
    final title = order.customerName.isNotEmpty
        ? order.customerName
        : context.l10n.order;
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';
    final photo = order.customerPhoto;
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Material(
      color: BarqodyChrome.fieldFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: BarqodyChrome.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: avatarColor(title),
                        backgroundImage:
                            hasPhoto ? NetworkImage(photo) : null,
                        child: hasPhoto
                            ? null
                            : Text(initial, style: WaUi.avatarInitial),
                      ),
                      if (!order.isRead)
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF6B6B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child:                     Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/png/verified-badge.png',
                    width: 18,
                    height: 18,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: BarqodyChrome.star,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: BarqodyChrome.secondaryText,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: BarqodyChrome.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                children: [
                  _MetaRow(
                    label: 'Booking',
                    value: order.hasToken ? '#BK${order.tokenNumber}' : '—',
                  ),
                  const SizedBox(height: 8),
                  _MetaRow(label: 'Order Date', value: orderDate),
                  const SizedBox(height: 8),
                  _MetaRow(label: 'Total Services', value: '$totalItems'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: BarqodyChrome.divider),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Total amount',
                    style: WaUi.body.copyWith(
                      color: BarqodyChrome.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatMoney(
                      order.totalAmount,
                      currency: order.currency,
                    ),
                    style: WaUi.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: WaUi.body.copyWith(
            color: BarqodyChrome.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
