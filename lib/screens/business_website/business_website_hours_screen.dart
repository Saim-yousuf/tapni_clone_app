import 'package:flutter/material.dart';
import 'package:tapni_app/models/business_website/business_website_models.dart';
import 'package:tapni_app/repository/business_website_repo.dart';
import 'package:tapni_app/screens/business_website/business_presence_ui.dart';
import 'package:tapni_app/utils/app_motion.dart';
import 'package:tapni_app/widgets/app_toast.dart';
import 'package:tapni_app/widgets/auth_ui.dart';

/// Weekly open hours for menu storefronts.
class BusinessWebsiteHoursScreen extends StatefulWidget {
  final BusinessWebsite website;

  const BusinessWebsiteHoursScreen({super.key, required this.website});

  @override
  State<BusinessWebsiteHoursScreen> createState() =>
      _BusinessWebsiteHoursScreenState();
}

class _BusinessWebsiteHoursScreenState
    extends State<BusinessWebsiteHoursScreen> {
  final _repo = BusinessWebsiteRepo();
  late Map<String, WebsiteDayHours> _hours;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hours = Map<String, WebsiteDayHours>.from(
      widget.website.ordering.resolvedWeeklyHours,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final next = widget.website.ordering.copyWith(weeklyHours: _hours);
    final res = await _repo.updateWebsite(
      {'ordering': next.toJson()},
      websiteId: widget.website.id,
      websiteType: widget.website.websiteType,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!res.success) {
      showAppToast(
        context,
        res.message ?? 'Could not save hours',
        kind: AppToastKind.error,
      );
      return;
    }
    final website = _repo.parseWebsite(res.data);
    showAppToast(context, 'Hours saved', kind: AppToastKind.success);
    Navigator.pop(context, website ?? widget.website.copyWith(ordering: next));
  }

  @override
  Widget build(BuildContext context) {
    final keys = WebsiteOrdering.dayKeys;
    return BwPresenceScaffold(
      title: 'Hours',
      bottom: BwBottomCta(
        label: 'Save hours',
        loading: _saving,
        onPressed: _saving ? null : _save,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AppAppear(
            index: 0,
            child: const Text(
              'Customers see a closed banner outside these hours. They can browse, but cannot place orders.',
              style: TextStyle(
                fontSize: 14,
                color: AuthUi.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < keys.length; i++) ...[
            AppAppear(
              index: i + 1,
              maxStagger: 8,
              child: _dayCard(keys[i]),
            ),
            if (i < keys.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _dayCard(String key) {
    final day = _hours[key] ?? const WebsiteDayHours();
    final label = WebsiteOrdering.dayLabels[key] ?? key;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BwUi.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                day.closed ? 'Closed' : 'Open',
                style: const TextStyle(
                  fontSize: 13,
                  color: AuthUi.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch.adaptive(
                value: !day.closed,
                activeColor: Colors.black,
                onChanged: (open) {
                  setState(() {
                    _hours[key] = day.copyWith(closed: !open);
                  });
                },
              ),
            ],
          ),
          if (!day.closed) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _timeField(
                    label: 'Opens',
                    value: day.open,
                    onChanged: (v) => setState(() {
                      _hours[key] = day.copyWith(open: v);
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _timeField(
                    label: 'Closes',
                    value: day.close,
                    onChanged: (v) => setState(() {
                      _hours[key] = day.copyWith(close: v);
                    }),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final parts = value.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 11,
          minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
        );
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked == null) return;
        final hh = picked.hour.toString().padLeft(2, '0');
        final mm = picked.minute.toString().padLeft(2, '0');
        onChanged('$hh:$mm');
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AuthUi.fieldFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
