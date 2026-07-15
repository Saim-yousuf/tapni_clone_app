import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/service_schedule.dart';
import 'package:tapni_app/repository/catalog_repo.dart';
import 'package:tapni_app/utils/theme.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
Future<bool?> showServiceBookingSheet({
  required BuildContext context,
  required CatalogItem item,
  required String businessId,
  required String businessLinkId,
  required String businessName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ServiceBookingSheet(
      item: item,
      businessId: businessId,
      businessLinkId: businessLinkId,
      businessName: businessName,
    ),
  );
}

class ServiceBookingSheet extends StatefulWidget {
  final CatalogItem item;
  final String businessId;
  final String businessLinkId;
  final String businessName;

  const ServiceBookingSheet({
    super.key,
    required this.item,
    required this.businessId,
    required this.businessLinkId,
    required this.businessName,
  });

  @override
  State<ServiceBookingSheet> createState() => _ServiceBookingSheetState();
}

class _ServiceBookingSheetState extends State<ServiceBookingSheet> {
  final _repo = CatalogRepo();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<TimeSlot> _slots = [];
  bool _loadingSlots = false;
  bool _isBooking = false;

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
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
      lastDate: DateTime.now().add(Duration(days: 60)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadSlots();
    }
  }

  Future<void> _book() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseSelectATimeSlot)),
      );
      return;
    }

    setState(() => _isBooking = true);

    final res = await _repo.placeOrder(
      businessId: widget.businessId,
      businessLinkId: widget.businessLinkId,
      catalogType: 'services',
      bookingDate: _dateStr,
      bookingTime: _selectedTime,
      items: [
        {
          'name': widget.item.name,
          'price': widget.item.price,
          'quantity': 1,
          'notes': _notesCtrl.text.trim(),
        },
      ],
    );

    if (!mounted) return;
    setState(() => _isBooking = false);

    if (res.success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booked ${widget.item.name} with ${widget.businessName}!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? context.l10n.bookingFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF111111) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Book ${widget.item.name}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.price > 0
                            ? 'Rs ${widget.item.price.toStringAsFixed(0)}'
                            : 'Free',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(context.l10n.selectDate,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Color(0xFF1E1E1E)
                                : Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_outlined),
                              SizedBox(width: 12),
                              Text(
                                DateFormat(context.l10n.eeeDMMMYyyy).format(_selectedDate),
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Spacer(),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(context.l10n.availableSlots,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10),
                      if (_loadingSlots)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_slots.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            context.l10n.noSlotsAvailableOnThisDay,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _slots.map((slot) {
                            final selected = _selectedTime == slot.time;
                            final enabled = slot.available;
                            return ChoiceChip(
                              label: Text(slot.time),
                              selected: selected,
                              onSelected: enabled
                                  ? (val) => setState(
                                        () => _selectedTime =
                                            val ? slot.time : null,
                                      )
                                  : null,
                              selectedColor: AppTheme.primaryBlack,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : enabled
                                        ? Colors.black87
                                        : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              backgroundColor: isDark
                                  ? Color(0xFF1E1E1E)
                                  : Color(0xFFF5F5F5),
                              disabledColor: Colors.grey.shade200,
                            );
                          }).toList(),
                        ),
                      SizedBox(height: 20),
                      Text(context.l10n.notesOptional,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: context.l10n.anySpecialRequests,
                          filled: true,
                          fillColor: isDark
                              ? Color(0xFF1E1E1E)
                              : const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isBooking || _selectedTime == null ? null : _book,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isBooking
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(context.l10n.confirmBooking,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
