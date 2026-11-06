import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/bookable_resource.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/repository/booking_repo.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/utils/money_format.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/app_toast.dart';

class StayBookingResult {
  final String checkInDate;
  final String checkOutDate;
  final String resourceId;
  final String resourceName;
  final int nights;
  final bool bookNow;

  const StayBookingResult({
    required this.checkInDate,
    required this.checkOutDate,
    required this.resourceId,
    required this.resourceName,
    required this.nights,
    required this.bookNow,
  });
}

/// Opens stay booking when a matching room resource exists for [item].
Future<StayBookingResult?> showStayBookingSheet({
  required BuildContext context,
  required CatalogItem item,
  required String businessId,
  required String businessLinkId,
  required String businessName,
  String? currency,
  BookableResource? room,
}) {
  return showModalBottomSheet<StayBookingResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StayBookingSheet(
      item: item,
      businessId: businessId,
      businessLinkId: businessLinkId,
      businessName: businessName,
      currency: currency,
      initialRoom: room,
    ),
  );
}

Future<BookableResource?> findRoomResourceForItem({
  required String businessId,
  required CatalogItem item,
}) async {
  final rooms = await BookingRepo().listResources(
    businessId: businessId,
    type: 'room',
  );
  if (rooms.isEmpty) return null;
  final name = item.name.trim().toLowerCase();
  for (final r in rooms) {
    if (r.name.trim().toLowerCase() == name) return r;
  }
  // Hotel products catalog: any room resource means stay booking applies.
  return rooms.first;
}

/// True when this business has bookable rooms (hotel stay flow).
Future<bool> businessHasRoomResources(String businessId) async {
  final rooms = await BookingRepo().listResources(
    businessId: businessId,
    type: 'room',
  );
  return rooms.isNotEmpty;
}

class StayBookingSheet extends StatefulWidget {
  final CatalogItem item;
  final String businessId;
  final String businessLinkId;
  final String businessName;
  final String? currency;
  final BookableResource? initialRoom;

  const StayBookingSheet({
    super.key,
    required this.item,
    required this.businessId,
    required this.businessLinkId,
    required this.businessName,
    this.currency,
    this.initialRoom,
  });

  @override
  State<StayBookingSheet> createState() => _StayBookingSheetState();
}

class _StayBookingSheetState extends State<StayBookingSheet> {
  final _catalogRepo = CatalogRepo();
  final _bookingRepo = BookingRepo();

  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 2));
  List<BookableResource> _rooms = [];
  BookableResource? _room;
  bool _loading = true;
  bool _checking = false;
  bool? _available;
  int _nights = 1;

  String get _inStr => DateFormat('yyyy-MM-dd').format(_checkIn);
  String get _outStr => DateFormat('yyyy-MM-dd').format(_checkOut);

  @override
  void initState() {
    super.initState();
    _room = widget.initialRoom;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final rooms = await _bookingRepo.listResources(
      businessId: widget.businessId,
      type: 'room',
    );
    if (!mounted) return;
    BookableResource? selected = widget.initialRoom;
    if (selected == null) {
      final name = widget.item.name.trim().toLowerCase();
      for (final r in rooms) {
        if (r.name.trim().toLowerCase() == name) {
          selected = r;
          break;
        }
      }
      selected ??= rooms.isNotEmpty ? rooms.first : null;
    }
    setState(() {
      _rooms = rooms;
      _room = selected;
      _loading = false;
    });
    await _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    if (_room == null) {
      setState(() {
        _available = false;
        _nights = 0;
      });
      return;
    }
    setState(() => _checking = true);
    final data = await _catalogRepo.getStayAvailability(
      businessId: widget.businessId,
      resourceId: _room!.id,
      checkInDate: _inStr,
      checkOutDate: _outStr,
    );
    if (!mounted) return;
    setState(() {
      _checking = false;
      _available = data?['available'] == true;
      _nights = (data?['nights'] is num)
          ? (data!['nights'] as num).toInt()
          : _checkOut.difference(_checkIn).inDays;
    });
  }

  Future<void> _pickCheckIn() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkIn,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _checkIn = picked;
      if (!_checkOut.isAfter(_checkIn)) {
        _checkOut = _checkIn.add(const Duration(days: 1));
      }
    });
    await _checkAvailability();
  }

  Future<void> _pickCheckOut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOut.isAfter(_checkIn)
          ? _checkOut
          : _checkIn.add(const Duration(days: 1)),
      firstDate: _checkIn.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 400)),
    );
    if (picked == null) return;
    setState(() => _checkOut = picked);
    await _checkAvailability();
  }

  void _confirm({required bool bookNow}) {
    if (_room == null || _available != true || _nights < 1) {
      showAppToast(
            context,
            'Select available dates to continue',
            kind: AppToastKind.info,
          );
      return;
    }
    Navigator.of(context, rootNavigator: true).pop(
      StayBookingResult(
        checkInDate: _inStr,
        checkOutDate: _outStr,
        resourceId: _room!.id,
        resourceName: _room!.name,
        nights: _nights,
        bookNow: bookNow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final nightPrice = widget.item.displayPrice;
    final total = nightPrice * (_nights > 0 ? _nights : 0);
    final priceLabel = formatMoney(total, currency: widget.currency);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BarqodyChrome.sheetRadius),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const SheetDragHandle(),
              const SizedBox(height: 8),
              BarqodyTitleBar(
                title: 'Book stay',
                onBack: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: WaUi.toolsTitleOf(
                            size: 18,
                            weight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.businessName,
                          style: WaUi.body.copyWith(
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        if (_rooms.length > 1) ...[
                          const SizedBox(height: 20),
                          Text(
                            'ROOM',
                            style: WaUi.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: BarqodyChrome.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _rooms.map((r) {
                              final selected = _room?.id == r.id;
                              return ChoiceChip(
                                label: Text(r.name),
                                selected: selected,
                                onSelected: (_) async {
                                  setState(() => _room = r);
                                  await _checkAvailability();
                                },
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Text(
                          'CHECK-IN',
                          style: WaUi.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _DateTile(
                          label: DateFormat('EEE, d MMM yyyy').format(_checkIn),
                          onTap: _pickCheckIn,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CHECK-OUT',
                          style: WaUi.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _DateTile(
                          label:
                              DateFormat('EEE, d MMM yyyy').format(_checkOut),
                          onTap: _pickCheckOut,
                        ),
                        const SizedBox(height: 20),
                        if (_checking)
                          const LinearProgressIndicator(minHeight: 2)
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: BarqodyChrome.fieldFill,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _available == true
                                  ? '$_nights night${_nights == 1 ? '' : 's'} · $priceLabel'
                                  : 'Not available for these dates',
                              style: WaUi.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _available == true
                                    ? Colors.black
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PillButton(
                  label: 'Book stay',
                  enabled: _available == true && !_checking && _room != null,
                  onPressed: () => _confirm(bookNow: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: BarqodyChrome.fieldFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: WaUi.body.copyWith(
            fontSize: 15,
            color: BarqodyChrome.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
