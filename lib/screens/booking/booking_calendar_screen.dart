import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/repository/booking_repo.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Busy blocks only — no revenue / stats (multi-vertical calendar sync).
class BookingCalendarScreen extends StatefulWidget {
  final String? businessId;
  final bool mineOnly;
  final String title;

  const BookingCalendarScreen({
    super.key,
    this.businessId,
    this.mineOnly = false,
    this.title = 'Booking calendar',
  });

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  final _repo = BookingRepo();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _blocks = [];

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
    final now = DateTime.now();
    final from = DateFormat('yyyy-MM-dd').format(now);
    final to = DateFormat('yyyy-MM-dd').format(
      now.add(const Duration(days: 60)),
    );
    try {
      final blocks = await _repo.calendarBusy(
        businessId: widget.mineOnly ? null : widget.businessId,
        mine: widget.mineOnly,
        from: from,
        to: to,
      );
      if (!mounted) return;
      setState(() {
        _blocks = blocks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('EEE d MMM · HH:mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: widget.title,
              onBack: () => Navigator.of(context).pop(),
              trailing: IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Only busy times are shown. Revenue and stats stay private to each account.',
                style: WaUi.caption.copyWith(
                  color: BarqodyChrome.secondaryText,
                  height: 1.35,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: WaUi.body.copyWith(color: Colors.red),
                          ),
                        )
                      : _blocks.isEmpty
                          ? Center(
                              child: Text(
                                'No bookings in the next 60 days',
                                style: WaUi.body.copyWith(
                                  color: BarqodyChrome.secondaryText,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: _blocks.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final b = _blocks[i];
                                final kind =
                                    (b['kind']?.toString() ?? 'appointment')
                                        .replaceAll('_', ' ');
                                final status = b['status']?.toString() ?? '';
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: BarqodyChrome.fieldFill,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        kind.toUpperCase(),
                                        style: WaUi.caption.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: BarqodyChrome.secondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _fmt(b['start']?.toString()),
                                        style: WaUi.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '→ ${_fmt(b['end']?.toString())}',
                                        style: WaUi.body.copyWith(
                                          color: BarqodyChrome.secondaryText,
                                        ),
                                      ),
                                      if (status.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          status,
                                          style: WaUi.caption.copyWith(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
