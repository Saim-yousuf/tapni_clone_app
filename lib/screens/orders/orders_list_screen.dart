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

  /// empty = All; otherwise order | appointment | stay
  String _kindFilter = '';

  static const _tabs = [
    OrderStatus.held,
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.completed,
    OrderStatus.cancelled,
    OrderStatus.noShow,
  ];

  static const _kindChips = [
    ('', 'All'),
    ('order', 'Orders'),
    ('appointment', 'Appointments'),
    ('stay', 'Stays'),
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

  /// Claim a guest website order into this signed-in account (shared commerce API).
  Future<void> _claimGuestOrder() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Claim guest order'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Order Tracking Code',
              hintText: 'BK-XXXX-XXXX',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Claim'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (code == null || code.isEmpty || !mounted) return;

    final res = await CatalogRepo().claimGuestOrder(trackingCode: code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? (res.message ?? 'Order claimed')
              : (res.message ?? 'Could not claim order'),
        ),
      ),
    );
    if (!res.success) return;
    final orderId = CatalogOrder.idFromApi(res.data);
    if (orderId != null && orderId.isNotEmpty && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            orderId: orderId,
            isBusinessView: false,
          ),
        ),
      );
    }
  }

  List<String> _tabLabels(BuildContext context) {
    final l10n = context.l10n;
    return [
      l10n.pending,
      'Confirmed',
      l10n.completed,
      'Cancelled',
      'Missed',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isBusinessView ? 'Orders & Bookings' : 'My Orders & Bookings';

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(
              title: title,
              trailing: widget.isBusinessView
                  ? null
                  : IconButton(
                      tooltip: 'Claim guest order',
                      onPressed: _claimGuestOrder,
                      icon: const Icon(Icons.link_rounded, color: Colors.black),
                    ),
            ),
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
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _kindChips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (value, label) = _kindChips[i];
                  final selected = _kindFilter == value;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _kindFilter = value);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? Colors.black : BarqodyChrome.fieldFill,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected
                              ? Colors.black
                              : BarqodyChrome.divider,
                        ),
                      ),
                      child: Text(
                        label,
                        style: WaUi.label.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : BarqodyChrome.secondaryText,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs
                    .map(
                      (status) => _OrdersTabPage(
                        key: ValueKey('$status|$_kindFilter'),
                        status: status,
                        isBusinessView: widget.isBusinessView,
                        bookingKind: _kindFilter,
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
  final String bookingKind;

  const _OrdersTabPage({
    super.key,
    required this.status,
    required this.isBusinessView,
    this.bookingKind = '',
  });

  @override
  State<_OrdersTabPage> createState() => _OrdersTabPageState();
}

class _OrdersTabPageState extends State<_OrdersTabPage>
    with AutomaticKeepAliveClientMixin {
  final _repo = CatalogRepo();
  bool _isLoading = true;
  bool _loadFailed = false;
  List<CatalogOrder> _orders = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  String _emptyTitle(BuildContext context) {
    final status = CatalogHelper.statusLabel(widget.status, context.l10n)
        .toLowerCase();
    switch (widget.bookingKind) {
      case 'appointment':
        return 'No $status appointments';
      case 'stay':
        return 'No $status stays';
      case 'order':
        return 'No $status orders';
      default:
        return context.l10n.noStatusOrders(status);
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    final status = CatalogHelper.statusApiValue(widget.status);
    final kind =
        widget.bookingKind.trim().isEmpty ? null : widget.bookingKind.trim();
    final orders = widget.isBusinessView
        ? await _repo.getBusinessOrders(status: status, bookingKind: kind)
        : await _repo.getCustomerOrders(status: status, bookingKind: kind);
    if (!mounted) return;
    if (orders == null) {
      setState(() {
        _orders = [];
        _loadFailed = true;
        _isLoading = false;
      });
      return;
    }
    // Client-side fallback for older orders missing bookingKind.
    final filtered = kind == null
        ? orders
        : orders.where((o) => o.kind == kind).toList();
    setState(() {
      _orders = filtered;
      _loadFailed = false;
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
          : _loadFailed
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                    Image.asset(
                      'assets/images/png/order-history.png',
                      width: 64,
                      height: 64,
                      color: BarqodyChrome.secondaryText.withValues(alpha: 0.45),
                      errorBuilder: (_, _, _) => Icon(
                        Icons.wifi_off_rounded,
                        size: 56,
                        color: BarqodyChrome.secondaryText.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Couldn’t load bookings',
                      textAlign: TextAlign.center,
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: SizedBox(
                        width: 160,
                        child: PillButton(
                          label: context.l10n.tryAgain,
                          onPressed: _loadOrders,
                        ),
                      ),
                    ),
                  ],
                )
          : _orders.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                    Image.asset(
                      'assets/images/png/order-history.png',
                      width: 72,
                      height: 72,
                      color: BarqodyChrome.secondaryText.withValues(alpha: 0.4),
                      errorBuilder: (_, _, _) => Icon(
                        Icons.receipt_long_rounded,
                        size: 56,
                        color: BarqodyChrome.secondaryText.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _emptyTitle(context),
                      textAlign: TextAlign.center,
                      style: WaUi.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isBusinessView
                          ? 'New bookings will show up here.'
                          : 'When you place an order or book, it will appear here.',
                      textAlign: TextAlign.center,
                      style: WaUi.body.copyWith(
                        color: BarqodyChrome.secondaryText,
                      ),
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
                    if (order.whenLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        order.whenLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WaUi.caption.copyWith(
                          color: BarqodyChrome.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _KindChip(label: order.kindLabel),
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
                              '#${order.tokenNumber}',
                              style: WaUi.label.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Colors.white,
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

class _KindChip extends StatelessWidget {
  final String label;

  const _KindChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: BarqodyChrome.divider),
      ),
      child: Text(
        label,
        style: WaUi.label.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: Colors.black,
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
    final title = order.displayCustomerName.isNotEmpty
        ? order.displayCustomerName
        : (order.isGuest ? 'Guest' : context.l10n.order);
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
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                  Row(
                    children: [
                      _KindChip(label: order.kindLabel),
                      const Spacer(),
                      Text(
                        order.hasToken ? '#${order.tokenNumber}' : '—',
                        style: WaUi.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  if (order.whenLine.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _MetaRow(label: 'When', value: order.whenLine),
                  ],
                  const SizedBox(height: 8),
                  _MetaRow(label: 'Placed on', value: orderDate),
                  const SizedBox(height: 8),
                  _MetaRow(
                    label: order.isStay
                        ? 'Rooms'
                        : (order.isAppointment ? 'Services' : 'Total items'),
                    value: '$totalItems',
                  ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WaUi.body.copyWith(
            color: BarqodyChrome.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WaUi.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
