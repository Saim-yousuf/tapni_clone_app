import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/services/mock_data_service.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/glass_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = '7 Days';
  final Map<String, List<double>> _data = MockDataService.getAnalyticsData();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final profileViews = _data['profileViews'] ?? [];
    final qrScans = _data['qrScans'] ?? [];
    final leadsCollected = _data['leadsCollected'] ?? [];

    final totalViews = profileViews.fold<double>(0, (p, c) => p + c).toInt();
    final totalScans = qrScans.fold<double>(0, (p, c) => p + c).toInt();
    final totalLeads = leadsCollected.fold<double>(0, (p, c) => p + c).toInt();

    // calculate conversion rate (Leads/Views)
    final double conversionRate = totalViews > 0 ? (totalLeads / totalViews) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            onSelected: (val) {
              setState(() {
                _selectedPeriod = val;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Period changed to $val (Demo data remains the same)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: '24 Hours', child: Text('Last 24 Hours')),
              const PopupMenuItem(value: '7 Days', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30 Days', child: Text('Last 30 Days')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Performance overview',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedPeriod,
                      style: const TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Main Graphic: Bezier Curve Custom Painted
              GlassCard(
                blur: 15,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Views',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                            ),
                            Text(
                              '$totalViews',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+14.8%',
                            style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Custom Painted Chart
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: SparklinePainter(
                          points: profileViews,
                          lineColor: AppTheme.accentGold,
                          fillColor: AppTheme.accentGold.withOpacity(0.06),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Days Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Mon', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text('Tue', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text('Wed', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text('Thu', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text('Fri', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text('Sat', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text('Sun', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // secondary stats: Scans and Leads
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.qr_code_2, color: AppTheme.accentGold, size: 24),
                          const SizedBox(height: 12),
                          const Text(
                            'QR Scans',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            '$totalScans',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: CustomPaint(
                              painter: MiniBarChartPainter(
                                data: qrScans,
                                barColor: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.person_add_alt_1_rounded, color: Colors.green, size: 24),
                          const SizedBox(height: 12),
                          const Text(
                            'Captured Leads',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            '$totalLeads',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: CustomPaint(
                              painter: MiniBarChartPainter(
                                data: leadsCollected,
                                barColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Connection Conversion Rate Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.bolt, color: AppTheme.accentGold, size: 28),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conversion Rate',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${conversionRate.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Views converted to captured leads.',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Sparkline/Line Chart Painter
class SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final Color fillColor;

  SparklinePainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double widthStep = size.width / (points.length - 1);
    final double maxVal = points.reduce((a, b) => a > b ? a : b);
    final double minVal = points.reduce((a, b) => a < b ? a : b);
    final double heightRange = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final List<Offset> offsets = [];
    for (int i = 0; i < points.length; i++) {
      final double x = i * widthStep;
      // invert y because canvas origin is top-left
      final double y = size.height - ((points[i] - minVal) / heightRange * (size.height - 20) + 10);
      offsets.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      final controlPoint1 = Offset(p1.dx + widthStep / 2, p1.dy);
      final controlPoint2 = Offset(p2.dx - widthStep / 2, p2.dy);
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p2.dx, p2.dy,
      );
    }

    // Paint line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Create fill path
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw little circles at endpoints
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offsets.last, 6, pointPaint);
    canvas.drawCircle(offsets.last, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => true;
}

// Mini Bar Chart Painter
class MiniBarChartPainter extends CustomPainter {
  final List<double> data;
  final Color barColor;

  MiniBarChartPainter({
    required this.data,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double numBars = data.length.toDouble();
    final double spacing = 4.0;
    final double barWidth = (size.width - (spacing * (numBars - 1))) / numBars;
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double heightRange = maxVal == 0 ? 1.0 : maxVal;

    final paint = Paint()
      ..color = barColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final double x = i * (barWidth + spacing);
      final double barHeight = (data[i] / heightRange) * size.height;
      final double y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MiniBarChartPainter oldDelegate) => true;
}
