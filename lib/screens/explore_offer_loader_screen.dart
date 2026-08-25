import 'package:flutter/material.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_program_details_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/explore_detail_shimmers.dart';

class ExploreOfferLoaderScreen extends StatefulWidget {
  final ExploreOffer offer;

  const ExploreOfferLoaderScreen({super.key, required this.offer});

  @override
  State<ExploreOfferLoaderScreen> createState() =>
      _ExploreOfferLoaderScreenState();
}

class _ExploreOfferLoaderScreenState extends State<ExploreOfferLoaderScreen> {
  bool _loading = true;
  String? _error;
  RewardEnrollment? _enrollment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.offer.id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Invalid offer';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = RewardRepo();
      final mine = await repo.getMyEnrollments();
      if (!mounted) return;

      RewardEnrollment? existing;
      if (mine.success && mine.data != null) {
        final list = mine.data is List
            ? mine.data as List
            : (mine.data['data'] as List? ?? []);
        for (final raw in list) {
          if (raw is! Map) continue;
          final enrollment =
              RewardEnrollment.fromJson(Map<String, dynamic>.from(raw));
          if (enrollment.programId == widget.offer.id ||
              enrollment.program?.id == widget.offer.id) {
            existing = enrollment;
            break;
          }
        }
      }

      if (existing != null) {
        setState(() {
          _loading = false;
          _enrollment = existing;
        });
        return;
      }

      final enrollRes = await repo.selfEnroll(widget.offer.id);
      if (!mounted) return;

      if (!enrollRes.success || enrollRes.data == null) {
        setState(() {
          _loading = false;
          _error = enrollRes.message ?? 'Could not enroll in this reward program';
        });
        return;
      }

      final payload = enrollRes.data is Map
          ? (enrollRes.data['data'] ?? enrollRes.data)
          : enrollRes.data;
      if (payload is! Map) {
        setState(() {
          _loading = false;
          _error = 'Invalid enrollment response';
        });
        return;
      }

      setState(() {
        _loading = false;
        _enrollment =
            RewardEnrollment.fromJson(Map<String, dynamic>.from(payload));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CustomerProgramDetailShimmer();
    }

    if (_error != null || _enrollment == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor:
            isDark ? AppTheme.primaryBlack : WaUi.toolsScaffold,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppTheme.primaryBlack : WaUi.toolsScaffold,
          foregroundColor: isDark ? Colors.white : WaUi.primaryText,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ?? 'Could not open offer',
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    color: isDark ? Colors.white70 : WaUi.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CustomerProgramDetailsScreen(enrollment: _enrollment!);
  }
}
