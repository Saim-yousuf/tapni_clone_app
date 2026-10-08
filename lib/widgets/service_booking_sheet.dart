import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/service_schedule.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

class ServiceBookingResult {
  final String bookingDate;
  final String bookingTime;
  final bool bookNow;

  const ServiceBookingResult({
    required this.bookingDate,
    required this.bookingTime,
    required this.bookNow,
  });
}

Future<ServiceBookingResult?> showServiceBookingSheet({
  required BuildContext context,
  required CatalogItem item,
  required String businessId,
  required String businessLinkId,
  required String businessName,
  String? currency,
}) {
  return showModalBottomSheet<ServiceBookingResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ServiceBookingSheet(
      item: item,
      businessId: businessId,
      businessLinkId: businessLinkId,
      businessName: businessName,
      currency: currency,
    ),
  );
}

class ServiceBookingSheet extends StatefulWidget {
  final CatalogItem item;
  final String businessId;
  final String businessLinkId;
  final String businessName;
  final String? currency;

  const ServiceBookingSheet({
    super.key,
    required this.item,
    required this.businessId,
    required this.businessLinkId,
    required this.businessName,
    this.currency,
  });

  @override
  State<ServiceBookingSheet> createState() => _ServiceBookingSheetState();
}

class _ServiceBookingSheetState extends State<ServiceBookingSheet> {
  final _repo = CatalogRepo();
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<TimeSlot> _slots = [];
  bool _loadingSlots = false;

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _selectedTime = null;
    });
    final slots = await _repo.getAvailability(
      businessId: widget.businessId,
      businessLinkId: widget.businessLinkId,
      date: _dateStr,
    );
    if (mounted) {
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadSlots();
    }
  }

  void _popResult({required bool bookNow}) {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseSelectATimeSlot)),
      );
      return;
    }
    Navigator.of(context, rootNavigator: true).pop(
      ServiceBookingResult(
        bookingDate: _dateStr,
        bookingTime: _selectedTime!,
        bookNow: bookNow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                title: 'Book Service',
                onBack: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT DATE',
                        style: WaUi.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: BarqodyChrome.fieldFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            dateLabel,
                            style: WaUi.body.copyWith(
                              fontSize: 15,
                              color: BarqodyChrome.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'CHOOSE A TIME',
                        style: WaUi.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: BarqodyChrome.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingSlots)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_slots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            context.l10n.noSlotsAvailableOnThisDay,
                            style: WaUi.body.copyWith(
                              color: BarqodyChrome.secondaryText,
                            ),
                          ),
                        )
                      else
                        _TimeSlotGrid(
                          slots: _slots,
                          selectedTime: _selectedTime,
                          onSelect: (time) =>
                              setState(() => _selectedTime = time),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: 'Later',
                        filled: false,
                        onPressed: () => _popResult(bookNow: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PillButton(
                        label: 'Book Now',
                        enabled: _selectedTime != null,
                        onPressed: () => _popResult(bookNow: true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSlotGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final String? selectedTime;
  final ValueChanged<String> onSelect;

  const _TimeSlotGrid({
    required this.slots,
    required this.selectedTime,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final tileW = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: slots.map((slot) {
            final selected = selectedTime == slot.time;
            final enabled = slot.available;
            return SizedBox(
              width: tileW,
              child: _TimeSlotTile(
                time: slot.time,
                selected: selected,
                enabled: enabled,
                onTap: enabled ? () => onSelect(slot.time) : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TimeSlotTile extends StatelessWidget {
  final String time;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _TimeSlotTile({
    required this.time,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = !enabled
        ? BarqodyChrome.fieldFill
        : selected
            ? Colors.black
            : Colors.white;
    final fg = !enabled
        ? BarqodyChrome.secondaryText
        : selected
            ? Colors.white
            : Colors.black;

    return Material(
      color: bg,
      elevation: enabled && !selected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: enabled && !selected
                ? Border.all(color: BarqodyChrome.divider)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  time,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
                size: 20,
                color: !enabled
                    ? BarqodyChrome.secondaryText.withValues(alpha: 0.5)
                    : fg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
