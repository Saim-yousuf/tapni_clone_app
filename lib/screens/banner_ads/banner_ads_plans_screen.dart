import 'package:flutter/material.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/repository/explore_repo.dart';
import 'package:tapni_app/screens/banner_ads/banner_list_screen.dart';
import 'package:tapni_app/screens/banner_ads/create_banner_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Landing / pricing plans for Tools → Banner Ads.
class BannerAdsPlansScreen extends StatefulWidget {
  const BannerAdsPlansScreen({super.key});

  @override
  State<BannerAdsPlansScreen> createState() => _BannerAdsPlansScreenState();
}

class _BannerAdsPlansScreenState extends State<BannerAdsPlansScreen> {
  final _repo = ExploreRepo();
  List<BannerAdPlan> _plans = BannerAdPlan.defaults;
  bool _loading = true;
  int _myBannerCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _repo.getBannerPlans(),
      _repo.getMyBanners(),
    ]);
    if (!mounted) return;

    final plansRes = results[0];
    final mineRes = results[1];

    setState(() {
      _loading = false;
      if (plansRes.success) {
        _plans = _repo.parseBannerPlans(plansRes.data);
      }
      if (mineRes.success) {
        final parsed = _repo.parseMyBanners(mineRes.data);
        _myBannerCount = parsed.total;
      }
    });
  }

  Future<void> _choosePlan(BannerAdPlan plan) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateBannerScreen(plan: plan),
      ),
    );
    if (!mounted) return;
    if (created == true) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BannerListScreen()),
      );
    } else {
      _load();
    }
  }

  void _openList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BannerListScreen()),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            BarqodyTitleBar(
              title: 'Banner Ads',
              trailing: _myBannerCount > 0
                  ? CircleAssetButton(
                      asset: 'assets/images/png/icon-morehoriz.png',
                      iconSize: 16,
                      onTap: _openList,
                    )
                  : const SizedBox(width: 40),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/images/png/banner-img.png',
                            width: 168,
                            height: 140,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.campaign_outlined,
                              size: 88,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Show Your banner in the App & Get more Orders',
                          textAlign: TextAlign.center,
                          style: WaUi.toolsTitleOf(
                            size: 22,
                            weight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Promote your business profile reach thousands of new customers, increase visibility, and boost your sales daily.',
                          textAlign: TextAlign.center,
                          style: WaUi.body.copyWith(
                            fontSize: 13.5,
                            height: 1.45,
                            color: BarqodyChrome.secondaryText,
                          ),
                        ),
                        if (_myBannerCount > 0) ...[
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton(
                              onPressed: _openList,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                              child: Text(
                                'Manage my banners ($_myBannerCount)',
                                style: WaUi.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        ..._plans.map(
                          (plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _PlanCard(
                              plan: plan,
                              onChoose: () => _choosePlan(plan),
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

class _PlanCard extends StatelessWidget {
  final BannerAdPlan plan;
  final VoidCallback onChoose;

  const _PlanCard({required this.plan, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.label,
                style: WaUi.toolsTitleOf(
                  size: 16,
                  weight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (plan.popular)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Popular',
                    style: WaUi.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${plan.price.toStringAsFixed(0)}',
                style: WaUi.toolsTitleOf(
                  size: 32,
                  weight: FontWeight.w800,
                  color: Colors.black,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Per Plan',
                  style: WaUi.body.copyWith(
                    fontSize: 13,
                    color: BarqodyChrome.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.campaign_outlined,
                size: 16,
                color: BarqodyChrome.secondaryText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.feature,
                  style: WaUi.body.copyWith(
                    fontSize: 13,
                    color: BarqodyChrome.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PillButton(label: 'Choose Plan', onPressed: onChoose),
        ],
      ),
    );
  }
}
