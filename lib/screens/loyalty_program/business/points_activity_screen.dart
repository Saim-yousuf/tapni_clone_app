import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/repository/loyalty_points_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/points_flow_models.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class PointsActivityScreen extends StatefulWidget {
  const PointsActivityScreen({super.key});

  @override
  State<PointsActivityScreen> createState() => _PointsActivityScreenState();
}

class _PointsActivityScreenState extends State<PointsActivityScreen> {
  static const _tabs = ['ALL', 'PURCHASED', 'REDEEMED', 'AWARDS'];
  int _tabIndex = 0;
  bool _loading = true;
  List<PointsActivityItem> _all = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await LoyaltyPointsRepo().getBusinessActivity();
    if (!mounted) return;
    var items = <PointsActivityItem>[];
    if (res.success && res.data != null) {
      final raw = res.data is Map ? res.data['data'] ?? res.data : res.data;
      if (raw is List) {
        items = raw
            .whereType<Map>()
            .map((e) => PointsActivityItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  List<PointsActivityItem> get _filtered {
    switch (_tabIndex) {
      case 1:
        return _all
            .where((e) => e.kind == PointsActivityKind.purchased)
            .toList();
      case 2:
        return _all
            .where((e) => e.kind == PointsActivityKind.redeemed)
            .toList();
      case 3:
        return _all
            .where((e) => e.kind == PointsActivityKind.stampAward)
            .toList();
      default:
        return _all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BarqodyTitleBar(title: 'Points Activity'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BarqodyChrome.sidePad,
                8,
                BarqodyChrome.sidePad,
                0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = _tabIndex == i;
                    return Padding(
                      padding:
                          EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                      child: Material(
                        color:
                            selected ? Colors.black : BarqodyChrome.fieldFill,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: () => setState(() => _tabIndex = i),
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              _tabs[i],
                              style: WaUi.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : BarqodyChrome.bodyText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : items.isEmpty
                      ? Center(
                          child: Text(
                            'No activity yet',
                            style: WaUi.body.copyWith(
                              color: BarqodyChrome.secondaryText,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              BarqodyChrome.sidePad,
                              8,
                              BarqodyChrome.sidePad,
                              28,
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final positive = item.delta >= 0;
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: BarqodyChrome.fieldFill,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: WaUi.body.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (item.subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              item.subtitle,
                                              style: WaUi.caption.copyWith(
                                                color:
                                                    BarqodyChrome.secondaryText,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            dateFmt.format(item.at.toLocal()),
                                            style: WaUi.caption.copyWith(
                                              fontSize: 11,
                                              color:
                                                  BarqodyChrome.secondaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${positive ? '+' : '−'}${formatPoints(item.delta.abs())}',
                                      style: WaUi.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: positive
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFC62828),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
