import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/providers/connectivity_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/curved_bottom_nav.dart';
import 'package:tapni_app/widgets/notification_icon_button.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/profile_screen_shimmer.dart';
import 'package:tapni_app/widgets/wa_chats_widgets.dart';

enum _AnalyticsRange { today, d7, d30, all }

extension on _AnalyticsRange {
  String get apiValue {
    switch (this) {
      case _AnalyticsRange.today:
        return 'today';
      case _AnalyticsRange.d7:
        return '7d';
      case _AnalyticsRange.d30:
        return '30d';
      case _AnalyticsRange.all:
        return 'all';
    }
  }

  String label(BuildContext context) {
    switch (this) {
      case _AnalyticsRange.today:
        return 'Today';
      case _AnalyticsRange.d7:
        return '7 days';
      case _AnalyticsRange.d30:
        return '30 days';
      case _AnalyticsRange.all:
        return 'All';
    }
  }

  String get compareLabel {
    switch (this) {
      case _AnalyticsRange.today:
        return 'vs yesterday';
      case _AnalyticsRange.d7:
        return 'vs last week';
      case _AnalyticsRange.d30:
        return 'vs prior 30 days';
      case _AnalyticsRange.all:
        return 'vs prior period';
    }
  }
}

class AnalyticsScreen extends StatefulWidget {
  final bool showBackButton;
  const AnalyticsScreen({super.key, this.showBackButton = false});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  _AnalyticsRange _range = _AnalyticsRange.d7;
  int _selectedListTab = 0; // 0 viewers, 1 scanners

  int _profileViews = 0;
  int _cardScans = 0;
  int _uniqueViewers = 0;
  int _guestViews = 0;
  int _userViews = 0;
  int _viewsChangePct = 0;
  int _scansChangePct = 0;
  List<Map<String, dynamic>> _insights = [];
  List<Map<String, dynamic>> _trend = [];
  List<dynamic> _profileViewers = [];
  List<dynamic> _scanners = [];
  int _lastReconnectTick = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final response = await AuthRepo().getAnalytics(range: _range.apiValue);
      if (!mounted) return;
      if (response.success && response.data != null) {
        final root = response.data;
        final analytics = root is Map
            ? (root['analytics'] as Map? ?? root)
            : <String, dynamic>{};
        final totals = analytics['totals'] is Map
            ? Map<String, dynamic>.from(analytics['totals'] as Map)
            : <String, dynamic>{};
        final comparison = analytics['comparison'] is Map
            ? Map<String, dynamic>.from(analytics['comparison'] as Map)
            : <String, dynamic>{};

        setState(() {
          _profileViews = _asInt(
            totals['profileViews'] ?? analytics['totalProfileViews'],
          );
          _cardScans = _asInt(
            totals['cardScans'] ?? analytics['totalCardScans'],
          );
          _uniqueViewers = _asInt(totals['uniqueViewers']);
          _guestViews = _asInt(totals['guestViews']);
          _userViews = _asInt(totals['userViews']);
          _viewsChangePct = _asInt(comparison['viewsChangePct']);
          _scansChangePct = _asInt(comparison['scansChangePct']);
          _insights = _asMapList(analytics['insights']);
          _trend = _asMapList(analytics['trend']);
          _profileViewers = analytics['profileViews'] as List? ?? [];
          _scanners = analytics['cardScans'] as List? ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat(context.l10n.mmmDYyyyHMmA).format(date);
    } catch (_) {
      return '';
    }
  }

  void _setRange(_AnalyticsRange range) {
    if (_range == range) return;
    setState(() => _range = range);
    _fetchAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final reconnectTick = context.watch<ConnectivityProvider>().reconnectTick;
    if (reconnectTick != _lastReconnectTick) {
      _lastReconnectTick = reconnectTick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchAnalytics();
      });
    }

    final profile = Provider.of<ProfileProvider>(context).profile;
    final bottomPad = CurvedBottomNav.fabOverhang() + 16;
    final isPro = profile.isPro;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WaChatsHeader(
              title: context.l10n.analyticsDashboard,
              actions: [NotificationIconButton()],
            ),
            Expanded(
              child: !isPro
                  ? _LockedAnalyticsPreview(bottomPad: bottomPad)
                  : _isLoading
                  ? _AnalyticsShimmer(bottomPad: bottomPad)
                  : RefreshIndicator(
                      color: WaUi.buttonDark,
                      onRefresh: _fetchAnalytics,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
                        children: [
                          _RangeChips(selected: _range, onSelected: _setRange),
                          const SizedBox(height: 18),
                          if (_insights.isNotEmpty) ...[
                            _InsightStrip(
                              insights: _insights,
                              compareLabel: _range.compareLabel,
                            ),
                            const SizedBox(height: 20),
                          ],
                          _MetricsGrid(
                            profileViews: _profileViews,
                            cardScans: _cardScans,
                            uniqueViewers: _uniqueViewers,
                            guestViews: _guestViews,
                            userViews: _userViews,
                            viewsChangePct: _viewsChangePct,
                            scansChangePct: _scansChangePct,
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Text('Activity', style: WaUi.sectionHeader),
                              const Spacer(),
                              _LegendDot(
                                color: WaUi.primaryText,
                                label: 'Views',
                              ),
                              const SizedBox(width: 12),
                              _LegendDot(
                                color: const Color(0xFF10A375),
                                label: 'Scans',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _TrendChart(points: _trend),
                          const SizedBox(height: 28),
                          _ListTabs(
                            selected: _selectedListTab,
                            viewersCount: _profileViewers.length,
                            scannersCount: _scanners.length,
                            onChanged: (i) =>
                                setState(() => _selectedListTab = i),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedListTab == 0)
                            ..._buildPeopleList(
                              items: _profileViewers,
                              emptyLabel:
                                  context.l10n.noOneHasViewedYourProfileYet,
                              isScan: false,
                            )
                          else
                            ..._buildPeopleList(
                              items: _scanners,
                              emptyLabel: 'No QR scans in this period yet.',
                              isScan: true,
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPeopleList({
    required List<dynamic> items,
    required String emptyLabel,
    required bool isScan,
  }) {
    if (items.isEmpty) {
      return [_EmptyState(message: emptyLabel)];
    }
    return List.generate(items.length, (index) {
      final item = items[index];
      if (item is! Map) return const SizedBox.shrink();
      final isGuest = item['isGuest'] == true;
      final person = isScan
          ? (item['scannerId'] ?? item['viewerId'])
          : item['viewerId'];
      final timestamp = item['timestamp'] != null
          ? _formatDate('${item['timestamp']}')
          : '';

      var title = context.l10n.guestUser;
      var subtitle = timestamp;
      String? photoUrl;
      String? username;
      String? userId;

      if (!isGuest && person is Map) {
        title = person['name']?.toString() ?? context.l10n.unknownUser;
        username = person['username']?.toString();
        userId = person['_id']?.toString() ?? person['id']?.toString();
        if (username != null && username.isNotEmpty) {
          subtitle = '@$username • $timestamp';
        }
        photoUrl = person['profilePhoto']?.toString();
      } else if (!isGuest && person != null) {
        userId = person.toString();
        title = context.l10n.user;
      }

      final canOpen =
          !isGuest &&
          ((username != null && username.isNotEmpty) ||
              (userId != null && userId.isNotEmpty));

      return _ViewerTile(
        title: title,
        subtitle: subtitle,
        isGuest: isGuest,
        photoUrl: photoUrl,
        onTap: canOpen
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => username != null && username!.isNotEmpty
                        ? ScannedProfileScreen(username: username)
                        : ScannedProfileScreen(user: userId),
                  ),
                );
              }
            : null,
      );
    });
  }
}

class _RangeChips extends StatelessWidget {
  final _AnalyticsRange selected;
  final ValueChanged<_AnalyticsRange> onSelected;

  const _RangeChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _AnalyticsRange.values
            .map(
              (range) => WaPillFilterChip(
                label: range.label(context),
                selected: selected == range,
                onTap: () => onSelected(range),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InsightStrip extends StatelessWidget {
  final List<Map<String, dynamic>> insights;
  final String compareLabel;

  const _InsightStrip({required this.insights, required this.compareLabel});

  String _text(Map<String, dynamic> insight) {
    final metric = insight['metric']?.toString() ?? '';
    final kind = insight['kind']?.toString() ?? 'info';
    final pct = insight['changePct'] is num
        ? (insight['changePct'] as num).toInt()
        : 0;

    if (metric == 'audience') {
      final guestPct = insight['guestPct'] is num
          ? (insight['guestPct'] as num).toInt()
          : 0;
      return '$guestPct% views from guests';
    }

    final label = metric == 'scans' ? 'Scans' : 'Views';
    if (kind == 'up') return '$label up $pct% $compareLabel';
    if (kind == 'down') return '$label down $pct% $compareLabel';
    return '$label steady $compareLabel';
  }

  Color _tint(Map<String, dynamic> insight) {
    final kind = insight['kind']?.toString() ?? 'info';
    if (kind == 'up') return const Color(0xFF0B7A56);
    if (kind == 'down') return const Color(0xFFD14343);
    return WaUi.secondaryText;
  }

  IconData _icon(Map<String, dynamic> insight) {
    final kind = insight['kind']?.toString() ?? 'info';
    if (kind == 'up') return Icons.arrow_upward_rounded;
    if (kind == 'down') return Icons.arrow_downward_rounded;
    return Icons.people_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final insight = insights[index];
          final tint = _tint(insight);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon(insight), size: 16, color: tint),
                const SizedBox(width: 6),
                Text(
                  _text(insight),
                  style: WaUi.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tint,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final int profileViews;
  final int cardScans;
  final int uniqueViewers;
  final int guestViews;
  final int userViews;
  final int viewsChangePct;
  final int scansChangePct;

  const _MetricsGrid({
    required this.profileViews,
    required this.cardScans,
    required this.uniqueViewers,
    required this.guestViews,
    required this.userViews,
    required this.viewsChangePct,
    required this.scansChangePct,
  });

  @override
  Widget build(BuildContext context) {
    final audienceTotal = guestViews + userViews;
    final guestFrac = audienceTotal == 0 ? 0.0 : guestViews / audienceTotal;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetricCell(
                label: context.l10n.profileViews,
                value: '$profileViews',
                deltaPct: viewsChangePct,
              ),
            ),
            Container(width: 1, height: 72, color: WaUi.divider),
            Expanded(
              child: _MetricCell(
                label: context.l10n.qrScans,
                value: '$cardScans',
                deltaPct: scansChangePct,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(height: 1, color: WaUi.divider),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetricCell(
                label: 'Unique viewers',
                value: '$uniqueViewers',
              ),
            ),
            Container(width: 1, height: 72, color: WaUi.divider),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest vs Users',
                      style: WaUi.caption.copyWith(
                        color: WaUi.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      audienceTotal == 0 ? '—' : '$guestViews · $userViews',
                      style: WaUi.toolsTitleOf(
                        size: 24,
                        weight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: audienceTotal == 0 ? 0 : guestFrac,
                        minHeight: 5,
                        backgroundColor: WaUi.primaryText,
                        color: const Color(0xFF98A2AB),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Guest share ${audienceTotal == 0 ? 0 : (guestFrac * 100).round()}%',
                      style: WaUi.label.copyWith(
                        color: WaUi.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final int? deltaPct;

  const _MetricCell({required this.label, required this.value, this.deltaPct});

  @override
  Widget build(BuildContext context) {
    final delta = deltaPct;
    final up = (delta ?? 0) >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: WaUi.caption.copyWith(
              color: WaUi.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: WaUi.toolsTitleOf(
              size: 32,
              weight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: 6),
            Text(
              '${up ? '▲' : '▼'} ${up ? '+' : ''}$delta%',
              style: WaUi.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: up ? const Color(0xFF0B7A56) : const Color(0xFFD14343),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> points;

  const _TrendChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final views = points
        .map((p) => (p['views'] is num) ? (p['views'] as num).toDouble() : 0.0)
        .toList();
    final scans = points
        .map((p) => (p['scans'] is num) ? (p['scans'] as num).toDouble() : 0.0)
        .toList();
    final maxY = [...views, ...scans, 1.0].reduce((a, b) => a > b ? a : b);

    if (points.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Share your card to start seeing trends',
            style: WaUi.caption.copyWith(color: WaUi.secondaryText),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendLinePainter(views: views, scans: scans, maxY: maxY),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(points.length, (i) {
            final date = points[i]['date']?.toString() ?? '';
            final show =
                points.length <= 7 ||
                i == 0 ||
                i == points.length - 1 ||
                i % ((points.length / 4).ceil().clamp(1, 99)) == 0;
            return Expanded(
              child: Text(
                show && date.length >= 10 ? date.substring(5) : '',
                textAlign: TextAlign.center,
                style: WaUi.label.copyWith(
                  fontSize: 10,
                  color: WaUi.secondaryText,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> views;
  final List<double> scans;
  final double maxY;

  _TrendLinePainter({
    required this.views,
    required this.scans,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (views.isEmpty) return;

    // Soft horizontal guides — no outer box
    final guidePaint = Paint()
      ..color = const Color(0xFFE9EDEF)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    _drawSeries(
      canvas,
      size,
      views,
      color: const Color(0xFF111B21),
      fill: true,
    );
    _drawSeries(
      canvas,
      size,
      scans,
      color: const Color(0xFF10A375),
      fill: false,
    );
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double> values, {
    required Color color,
    required bool fill,
  }) {
    if (values.isEmpty) return;
    final n = values.length;
    final dx = n == 1 ? size.width / 2 : size.width / (n - 1);

    Offset pointAt(int i) {
      final x = n == 1 ? size.width / 2 : dx * i;
      final y = size.height - (values[i] / maxY) * (size.height * 0.88);
      return Offset(x, y.clamp(4, size.height - 2));
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < n; i++) {
      final prev = pointAt(i - 1);
      final curr = pointAt(i);
      final c1 = Offset(prev.dx + (curr.dx - prev.dx) * 0.4, prev.dy);
      final c2 = Offset(curr.dx - (curr.dx - prev.dx) * 0.4, curr.dy);
      line.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, curr.dx, curr.dy);
    }

    if (fill) {
      final fillPath = Path.from(line)
        ..lineTo(pointAt(n - 1).dx, size.height)
        ..lineTo(pointAt(0).dx, size.height)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line, stroke);

    // End dots
    final last = pointAt(n - 1);
    canvas.drawCircle(last, 4.5, Paint()..color = color);
    canvas.drawCircle(last, 2.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.views != views ||
        oldDelegate.scans != scans ||
        oldDelegate.maxY != maxY;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: WaUi.caption.copyWith(fontSize: 12, color: WaUi.secondaryText),
        ),
      ],
    );
  }
}

class _ListTabs extends StatelessWidget {
  final int selected;
  final int viewersCount;
  final int scannersCount;
  final ValueChanged<int> onChanged;

  const _ListTabs({
    required this.selected,
    required this.viewersCount,
    required this.scannersCount,
    required this.onChanged,
  });

  void _select(int index) {
    if (selected == index) return;
    HapticFeedback.selectionClick();
    onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: selected == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: SizedBox(
                  width: tabWidth,
                  height: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _AnalyticsSegTab(
                      selected: selected == 0,
                      icon: Icons.remove_red_eye_outlined,
                      label: '${context.l10n.profileViewers} ($viewersCount)',
                      onTap: () => _select(0),
                    ),
                  ),
                  Expanded(
                    child: _AnalyticsSegTab(
                      selected: selected == 1,
                      icon: Icons.qr_code_2_rounded,
                      label: 'Scanners ($scannersCount)',
                      onTap: () => _select(1),
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

class _AnalyticsSegTab extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AnalyticsSegTab({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            letterSpacing: selected ? -0.2 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey<bool>(selected),
                  size: 17,
                  color: selected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isGuest;
  final String? photoUrl;
  final VoidCallback? onTap;

  const _ViewerTile({
    required this.title,
    required this.subtitle,
    required this.isGuest,
    required this.photoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final clickable = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: WaUi.navPill,
                backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                child: hasPhoto
                    ? null
                    : Icon(
                        isGuest ? Icons.person_outline_rounded : Icons.person,
                        color: WaUi.secondaryText,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: WaUi.listTitle),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: WaUi.caption.copyWith(fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (clickable)
                Icon(
                  Icons.chevron_right_rounded,
                  color: WaUi.secondaryText.withValues(alpha: 0.7),
                )
              else
                Text(
                  isGuest ? context.l10n.guest : context.l10n.user,
                  style: WaUi.label.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: WaUi.secondaryText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 36,
            color: WaUi.secondaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: WaUi.body.copyWith(color: WaUi.secondaryText, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsShimmer extends StatelessWidget {
  final double bottomPad;

  const _AnalyticsShimmer({required this.bottomPad});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
        children: [
          Row(
            children: const [
              ShimmerBox(width: 72, height: 34, borderRadius: 99),
              SizedBox(width: 8),
              ShimmerBox(width: 78, height: 34, borderRadius: 99),
              SizedBox(width: 8),
              ShimmerBox(width: 86, height: 34, borderRadius: 99),
              SizedBox(width: 8),
              ShimmerBox(width: 56, height: 34, borderRadius: 99),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              ShimmerBox(width: 160, height: 34, borderRadius: 99),
              SizedBox(width: 8),
              ShimmerBox(width: 140, height: 34, borderRadius: 99),
            ],
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 80, height: 12, borderRadius: 6),
                    SizedBox(height: 10),
                    ShimmerBox(width: 56, height: 30, borderRadius: 6),
                    SizedBox(height: 8),
                    ShimmerBox(width: 40, height: 12, borderRadius: 6),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 70, height: 12, borderRadius: 6),
                    SizedBox(height: 10),
                    ShimmerBox(width: 48, height: 30, borderRadius: 6),
                    SizedBox(height: 8),
                    ShimmerBox(width: 40, height: 12, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(height: 1, color: Color(0xFFE9EDEF)),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 90, height: 12, borderRadius: 6),
                    SizedBox(height: 10),
                    ShimmerBox(width: 48, height: 28, borderRadius: 6),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 100, height: 12, borderRadius: 6),
                    SizedBox(height: 10),
                    ShimmerBox(width: 70, height: 28, borderRadius: 6),
                    SizedBox(height: 10),
                    ShimmerBox(
                      width: double.infinity,
                      height: 5,
                      borderRadius: 99,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Row(
            children: [
              ShimmerBox(width: 70, height: 16, borderRadius: 6),
              Spacer(),
              ShimmerBox(width: 50, height: 12, borderRadius: 6),
              SizedBox(width: 12),
              ShimmerBox(width: 50, height: 12, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerBox(
            width: double.infinity,
            height: 180,
            borderRadius: 8,
          ),
          const SizedBox(height: 28),
          const ShimmerBox(
            width: double.infinity,
            height: 46,
            borderRadius: 24,
          ),
          const SizedBox(height: 16),
          const _ShimmerViewerRow(),
          const SizedBox(height: 8),
          const _ShimmerViewerRow(),
          const SizedBox(height: 8),
          const _ShimmerViewerRow(),
        ],
      ),
    );
  }
}

class _ShimmerViewerRow extends StatelessWidget {
  const _ShimmerViewerRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ShimmerBox(width: 44, height: 44, shape: BoxShape.circle),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 120, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 160, height: 11, borderRadius: 6),
              ],
            ),
          ),
          ShimmerBox(width: 40, height: 12, borderRadius: 6),
        ],
      ),
    );
  }
}

/// Blurred fake dashboard + upgrade CTA for free users.
class _LockedAnalyticsPreview extends StatelessWidget {
  final double bottomPad;

  const _LockedAnalyticsPreview({required this.bottomPad});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Opacity(
              opacity: 0.55,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 120),
                children: const [
                  _FakeInsight(),
                  SizedBox(height: 18),
                  _FakeMetrics(),
                  SizedBox(height: 24),
                  _FakeChart(),
                  SizedBox(height: 20),
                  _FakeRow(),
                  SizedBox(height: 8),
                  _FakeRow(),
                  SizedBox(height: 8),
                  _FakeRow(),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPad > 24 ? 24 : 16),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: WaUi.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: WaUi.searchBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: WaUi.divider),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlock Analytics',
                  style: WaUi.title.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'See trends, unique viewers, guest vs users, QR scanners, and weekly insights.',
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    color: WaUi.secondaryText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => SubcriptionSheet.show(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.l10n.goBusiness,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FakeInsight extends StatelessWidget {
  const _FakeInsight();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ShimmerBox(width: 150, height: 34, borderRadius: 99),
        SizedBox(width: 8),
        ShimmerBox(width: 120, height: 34, borderRadius: 99),
      ],
    );
  }
}

class _FakeMetrics extends StatelessWidget {
  const _FakeMetrics();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: ShimmerBox(width: 80, height: 64, borderRadius: 8)),
            SizedBox(width: 24),
            Expanded(child: ShimmerBox(width: 80, height: 64, borderRadius: 8)),
          ],
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: ShimmerBox(width: 80, height: 64, borderRadius: 8)),
            SizedBox(width: 24),
            Expanded(child: ShimmerBox(width: 80, height: 64, borderRadius: 8)),
          ],
        ),
      ],
    );
  }
}

class _FakeChart extends StatelessWidget {
  const _FakeChart();

  @override
  Widget build(BuildContext context) {
    return const ShimmerBox(
      width: double.infinity,
      height: 180,
      borderRadius: 8,
    );
  }
}

class _FakeRow extends StatelessWidget {
  const _FakeRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ShimmerBox(width: 44, height: 44, shape: BoxShape.circle),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 120, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 160, height: 11, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
