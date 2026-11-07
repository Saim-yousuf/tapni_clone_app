import 'package:tapni_app/utils/app_page_transitions.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/catalog_order.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/screens/orders/order_detail_screen.dart';
import 'package:tapni_app/utils/catalog_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/order_ui.dart';
import 'package:tapni_app/widgets/app_toast.dart';

/// Primary status groups shown as tabs (backend statuses unchanged).
enum _StatusGroup { all, active, completed, cancelled }

class OrdersListScreen extends StatefulWidget {
  final bool isBusinessView;

  /// When true, no outer [SafeArea] and title bar has no back (suite tab).
  final bool embedded;

  const OrdersListScreen({
    super.key,
    required this.isBusinessView,
    this.embedded = false,
  });

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final _repo = CatalogRepo();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  bool _failed = false;
  List<CatalogOrder> _orders = const [];

  _StatusGroup _group = _StatusGroup.all;
  String _search = '';

  // Applied advanced filters
  String _catalogType = ''; // menu|products|services|'' ; stay uses bookingKind
  bool _stayOnly = false;
  String _paymentStatus = '';
  String _sort = 'newest';
  _DatePreset _datePreset = _DatePreset.all;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    var n = 0;
    if (_catalogType.isNotEmpty || _stayOnly) n++;
    if (_paymentStatus.isNotEmpty) n++;
    if (_datePreset != _DatePreset.all) n++;
    if (_sort != 'newest') n++;
    return n;
  }

  bool get _hasAdvancedFilters => _activeFilterCount > 0;

  DateTimeRange? get _resolvedRange {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_datePreset) {
      case _DatePreset.all:
        return null;
      case _DatePreset.last7:
        return DateTimeRange(
          start: end.subtract(const Duration(days: 6)),
          end: end,
        );
      case _DatePreset.last30:
        return DateTimeRange(
          start: end.subtract(const Duration(days: 29)),
          end: end,
        );
      case _DatePreset.custom:
        return _customRange;
    }
  }

  String? _iso(DateTime? d) => d?.toUtc().toIso8601String();

  bool _matchesGroup(CatalogOrder o) {
    switch (_group) {
      case _StatusGroup.all:
        return true;
      case _StatusGroup.active:
        return o.status == OrderStatus.held ||
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.confirmed;
      case _StatusGroup.completed:
        return o.status == OrderStatus.completed;
      case _StatusGroup.cancelled:
        return o.status == OrderStatus.cancelled ||
            o.status == OrderStatus.noShow;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final range = _resolvedRange;
    final bookingKind = _stayOnly ? 'stay' : null;
    final catalogType = _stayOnly
        ? null
        : (_catalogType.isEmpty ? null : _catalogType);

    final orders = widget.isBusinessView
        ? await _repo.getBusinessOrders(
            bookingKind: bookingKind,
            catalogType: catalogType,
            paymentStatus: _paymentStatus.isEmpty ? null : _paymentStatus,
            q: _search.isEmpty ? null : _search,
            from: _iso(range?.start),
            to: range == null
                ? null
                : _iso(range.end.add(const Duration(days: 1))),
            sort: _sort,
          )
        : await _repo.getCustomerOrders(
            bookingKind: bookingKind,
            catalogType: catalogType,
            paymentStatus: _paymentStatus.isEmpty ? null : _paymentStatus,
            q: _search.isEmpty ? null : _search,
            from: _iso(range?.start),
            to: range == null
                ? null
                : _iso(range.end.add(const Duration(days: 1))),
            sort: _sort,
          );

    if (!mounted) return;
    if (orders == null) {
      setState(() {
        _orders = const [];
        _failed = true;
        _loading = false;
      });
      return;
    }

    setState(() {
      _orders = orders.where(_matchesGroup).toList();
      _failed = false;
      _loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _search = value.trim());
      _load();
    });
    setState(() {});
  }

  void _resetAdvancedFilters() {
    setState(() {
      _catalogType = '';
      _stayOnly = false;
      _paymentStatus = '';
      _sort = 'newest';
      _datePreset = _DatePreset.all;
      _customRange = null;
    });
    _load();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_OrdersFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _OrdersFiltersSheet(
        initial: _OrdersFilterDraft(
          catalogType: _catalogType,
          stayOnly: _stayOnly,
          paymentStatus: _paymentStatus,
          sort: _sort,
          datePreset: _datePreset,
          customRange: _customRange,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final d = result.draft;
    setState(() {
      _catalogType = d.catalogType;
      _stayOnly = d.stayOnly;
      _paymentStatus = d.paymentStatus;
      _sort = d.sort;
      _datePreset = d.datePreset;
      _customRange = d.customRange;
    });
    await _load();
  }

  Future<void> _claimGuestOrder() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Claim guest order',
            style: WaUi.headline.copyWith(fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: WaUi.fieldDecoration(
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
    showAppToast(
          context,
          res.success
                  ? (res.message ?? 'Order claimed')
                  : (res.message ?? 'Could not claim order'),
          kind: res.success ? AppToastKind.success : AppToastKind.error,
        );
    if (!res.success) return;
    final orderId = CatalogOrder.idFromApi(res.data);
    if (orderId != null && orderId.isNotEmpty && mounted) {
      await Navigator.of(context).push(
        AppPageRoute(
          builder: (_) => OrderDetailScreen(
            orderId: orderId,
            isBusinessView: false,
          ),
        ),
      );
      _load();
    }
  }

  String _emptyTitle() {
    switch (_group) {
      case _StatusGroup.all:
        return 'No orders or bookings yet';
      case _StatusGroup.active:
        return 'No active items';
      case _StatusGroup.completed:
        return 'No completed items';
      case _StatusGroup.cancelled:
        return 'No cancelled items';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isBusinessView ? 'Orders & Bookings' : 'My Orders & Bookings';

    final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(
              title: title,
              onBack: widget.embedded
                  ? () => Navigator.of(context).maybePop()
                  : null,
              trailing: !widget.isBusinessView
                  ? SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Claim guest order',
                        onPressed: _claimGuestOrder,
                        icon: const Icon(
                          Icons.link_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OrderUi.sidePad,
                0,
                OrderUi.sidePad,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: WaUi.body,
                      decoration: InputDecoration(
                        hintText: widget.isBusinessView
                            ? 'Search customer, #order, item…'
                            : 'Search business, #order, item…',
                        hintStyle: WaUi.caption.copyWith(color: OrderUi.muted),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: OrderUi.muted,
                          size: 20,
                        ),
                        suffixIcon: _searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                  _load();
                                },
                                icon: const Icon(Icons.clear, size: 18),
                              ),
                        filled: true,
                        fillColor: BarqodyChrome.searchBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FiltersButton(
                    count: _activeFilterCount,
                    onTap: _openFilters,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: OrderUi.sidePad),
              child: _StatusGroupTabs(
                group: _group,
                onChanged: (g) {
                  HapticFeedback.selectionClick();
                  setState(() => _group = g);
                  _load();
                },
              ),
            ),
            if (_hasAdvancedFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  OrderUi.sidePad,
                  10,
                  OrderUi.sidePad,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _resetAdvancedFilters,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear filters',
                      style: WaUi.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                color: Colors.black,
                onRefresh: _load,
                child: _loading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 160),
                          Center(
                            child:
                                CircularProgressIndicator(color: Colors.black),
                          ),
                        ],
                      )
                    : _failed
                        ? OrderErrorState(onRetry: _load)
                        : _orders.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  OrderEmptyState(
                                    title: _emptyTitle(),
                                    subtitle: widget.isBusinessView
                                        ? 'New customer orders and bookings will appear here.'
                                        : 'When you place an order or book, it will appear here.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  OrderUi.sidePad,
                                  0,
                                  OrderUi.sidePad,
                                  28,
                                ),
                                itemCount: _orders.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  return OrderListCard(
                                    order: order,
                                    isBusinessView: widget.isBusinessView,
                                    statusLabel: CatalogHelper.statusLabel(
                                      order.status,
                                      context.l10n,
                                      isDelivery: order.isDelivery,
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        AppPageRoute(
                                          builder: (_) => OrderDetailScreen(
                                            orderId: order.id,
                                            isBusinessView:
                                                widget.isBusinessView,
                                          ),
                                        ),
                                      );
                                      _load();
                                    },
                                  );
                                },
                              ),
              ),
            ),
          ],
    );

    if (widget.embedded) {
      return ColoredBox(color: BarqodyChrome.scaffold, child: content);
    }

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(child: content),
    );
  }
}

enum _DatePreset { all, last7, last30, custom }

class _OrdersFilterDraft {
  final String catalogType;
  final bool stayOnly;
  final String paymentStatus;
  final String sort;
  final _DatePreset datePreset;
  final DateTimeRange? customRange;

  const _OrdersFilterDraft({
    this.catalogType = '',
    this.stayOnly = false,
    this.paymentStatus = '',
    this.sort = 'newest',
    this.datePreset = _DatePreset.all,
    this.customRange,
  });

  _OrdersFilterDraft copyWith({
    String? catalogType,
    bool? stayOnly,
    String? paymentStatus,
    String? sort,
    _DatePreset? datePreset,
    DateTimeRange? customRange,
    bool clearCustomRange = false,
  }) {
    return _OrdersFilterDraft(
      catalogType: catalogType ?? this.catalogType,
      stayOnly: stayOnly ?? this.stayOnly,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      sort: sort ?? this.sort,
      datePreset: datePreset ?? this.datePreset,
      customRange:
          clearCustomRange ? null : (customRange ?? this.customRange),
    );
  }
}

class _OrdersFilterResult {
  final _OrdersFilterDraft draft;

  const _OrdersFilterResult.apply(this.draft);
}

class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Material(
      color: active ? Colors.black : BarqodyChrome.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? Colors.black : OrderUi.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: active ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 6),
              Text(
                'Filters',
                style: WaUi.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : Colors.black,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$count',
                    style: WaUi.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusGroupTabs extends StatelessWidget {
  const _StatusGroupTabs({
    required this.group,
    required this.onChanged,
  });

  final _StatusGroup group;
  final ValueChanged<_StatusGroup> onChanged;

  static const _tabs = <(_StatusGroup, String)>[
    (_StatusGroup.all, 'All'),
    (_StatusGroup.active, 'Active'),
    (_StatusGroup.completed, 'Completed'),
    (_StatusGroup.cancelled, 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BarqodyChrome.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final tab in _tabs)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(tab.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: group == tab.$1 ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    tab.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WaUi.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: group == tab.$1
                          ? Colors.white
                          : BarqodyChrome.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrdersFiltersSheet extends StatefulWidget {
  const _OrdersFiltersSheet({required this.initial});

  final _OrdersFilterDraft initial;

  @override
  State<_OrdersFiltersSheet> createState() => _OrdersFiltersSheetState();
}

class _OrdersFiltersSheetState extends State<_OrdersFiltersSheet> {
  late _OrdersFilterDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _draft.customRange,
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
    setState(() {
      _draft = _draft.copyWith(
        datePreset: _DatePreset.custom,
        customRange: picked,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.78;
    final customLabel = _draft.customRange == null
        ? 'Custom range'
        : '${DateFormat('MMM d').format(_draft.customRange!.start)} – ${DateFormat('MMM d').format(_draft.customRange!.end)}';

    // Fixed height is required: Expanded cannot sit inside SheetHandleThen's
    // min-sized Column with only maxHeight (sheet collapses → grey barrier only).
    return SizedBox(
      height: sheetHeight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHandleThen(
              afterHandleGap: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filters',
                          style: WaUi.toolsTitleOf(
                            size: 20,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      CircleCloseButton(
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  _SheetSection(
                    title: 'Business type',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SheetChip(
                          label: 'All',
                          selected: !_draft.stayOnly && _draft.catalogType.isEmpty,
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(
                              catalogType: '',
                              stayOnly: false,
                            );
                          }),
                        ),
                        _SheetChip(
                          label: 'Menu',
                          selected: !_draft.stayOnly && _draft.catalogType == 'menu',
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(
                              catalogType: 'menu',
                              stayOnly: false,
                            );
                          }),
                        ),
                        _SheetChip(
                          label: 'Products',
                          selected:
                              !_draft.stayOnly && _draft.catalogType == 'products',
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(
                              catalogType: 'products',
                              stayOnly: false,
                            );
                          }),
                        ),
                        _SheetChip(
                          label: 'Services',
                          selected:
                              !_draft.stayOnly && _draft.catalogType == 'services',
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(
                              catalogType: 'services',
                              stayOnly: false,
                            );
                          }),
                        ),
                        _SheetChip(
                          label: 'Stay',
                          selected: _draft.stayOnly,
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(
                              stayOnly: true,
                              catalogType: '',
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  _SheetSection(
                    title: 'Payment status',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final opt in const [
                          ('', 'All'),
                          ('paid', 'Paid'),
                          ('pending', 'Unpaid'),
                          ('partially_refunded', 'Partially refunded'),
                          ('refunded', 'Refunded'),
                        ])
                          _SheetChip(
                            label: opt.$2,
                            selected: _draft.paymentStatus == opt.$1,
                            onTap: () => setState(() {
                              _draft = _draft.copyWith(paymentStatus: opt.$1);
                            }),
                          ),
                      ],
                    ),
                  ),
                  _SheetSection(
                    title: 'Date range',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SheetChip(
                          label: 'All time',
                          selected: _draft.datePreset == _DatePreset.all,
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(
                              datePreset: _DatePreset.all,
                              clearCustomRange: true,
                            );
                          }),
                        ),
                        _SheetChip(
                          label: 'Last 7 days',
                          selected: _draft.datePreset == _DatePreset.last7,
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(
                              datePreset: _DatePreset.last7,
                              clearCustomRange: true,
                            );
                          }),
                        ),
                        _SheetChip(
                          label: 'Last 30 days',
                          selected: _draft.datePreset == _DatePreset.last30,
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(
                              datePreset: _DatePreset.last30,
                              clearCustomRange: true,
                            );
                          }),
                        ),
                        _SheetChip(
                          label: customLabel,
                          selected: _draft.datePreset == _DatePreset.custom,
                          onTap: _pickCustomRange,
                        ),
                      ],
                    ),
                  ),
                  _SheetSection(
                    title: 'Sort',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SheetChip(
                          label: 'Newest first',
                          selected: _draft.sort == 'newest',
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(sort: 'newest');
                          }),
                        ),
                        _SheetChip(
                          label: 'Oldest first',
                          selected: _draft.sort == 'oldest',
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(sort: 'oldest');
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: WaUi.primaryButtonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _draft = const _OrdersFilterDraft();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black, width: 1.4),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Reset',
                          style: WaUi.body.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: WaUi.primaryButtonHeight,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _OrdersFilterResult.apply(_draft),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: WaUi.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WaUi.sectionHeader.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.white,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? Colors.black : OrderUi.border,
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
    );
  }
}
