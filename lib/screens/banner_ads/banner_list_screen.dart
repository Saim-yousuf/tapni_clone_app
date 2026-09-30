import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/repository/explore_repo.dart';
import 'package:tapni_app/screens/banner_ads/banner_ads_plans_screen.dart';
import 'package:tapni_app/screens/banner_ads/create_banner_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/banner_delete_dialog.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

class BannerListScreen extends StatefulWidget {
  const BannerListScreen({super.key});

  @override
  State<BannerListScreen> createState() => _BannerListScreenState();
}

class _BannerListScreenState extends State<BannerListScreen> {
  final _repo = ExploreRepo();
  List<ExploreBanner> _banners = [];
  int _liveCount = 0;
  bool _loading = true;
  String? _error;

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
    final res = await _repo.getMyBanners();
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load banners';
      });
      return;
    }
    final parsed = _repo.parseMyBanners(res.data);
    setState(() {
      _loading = false;
      _banners = parsed.banners;
      _liveCount = parsed.liveCount;
    });
  }

  Future<void> _addBanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BannerAdsPlansScreen()),
    );
    if (mounted) _load();
  }

  Future<void> _delete(ExploreBanner banner) async {
    final ok = await showBannerDeleteDialog(context);
    if (!ok || !mounted) return;
    final res = await _repo.deleteMyBanner(banner.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? 'Banner deleted'
              : (res.message ?? 'Could not delete banner'),
        ),
      ),
    );
    if (res.success) _load();
  }

  Future<void> _toggleLive(ExploreBanner banner) async {
    final res = await _repo.updateMyBanner(banner.id, {
      'showOnExplore': !banner.isLive,
    });
    if (!mounted) return;
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _banners.length;
    final subtitle = total == 0
        ? 'No banners yet'
        : '$_liveCount of $total banners';

    return Scaffold(
      backgroundColor: BarqodyChrome.scaffold,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 4, bottom: 8),
        child: Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _addBanner,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Text(
                'Add Banner',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const BarqodyTitleBar(title: 'Banner List'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: WaUi.body.copyWith(
                                color: BarqodyChrome.secondaryText,
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            children: [
                              Text(
                                'Banner List',
                                style: WaUi.toolsTitleOf(
                                  size: 22,
                                  weight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: WaUi.body.copyWith(
                                  fontSize: 13,
                                  color: BarqodyChrome.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_banners.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 48),
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        'assets/images/png/banner-img.png',
                                        width: 120,
                                        height: 100,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.campaign_outlined,
                                          size: 64,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Create your first explore banner',
                                        style: WaUi.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._banners.map(
                                  (b) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _BannerListCard(
                                      banner: b,
                                      onDelete: () => _delete(b),
                                      onToggle: () => _toggleLive(b),
                                      onEdit: () async {
                                        final plan = BannerAdPlan.defaults
                                            .firstWhere(
                                          (p) => p.id == b.planId,
                                          orElse: () =>
                                              BannerAdPlan.defaults.first,
                                        );
                                        final updated =
                                            await Navigator.of(context)
                                                .push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => CreateBannerScreen(
                                              plan: plan,
                                              existing: b,
                                            ),
                                          ),
                                        );
                                        if (updated == true && mounted) {
                                          _load();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight leftover removed — Add Banner opens plans directly.


class _BannerListCard extends StatelessWidget {
  final ExploreBanner banner;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _BannerListCard({
    required this.banner,
    required this.onDelete,
    required this.onToggle,
    required this.onEdit,
  });

  Color _parseHex(String hex, Color fallback) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return fallback;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final live = banner.isLive;
    final date = banner.createdAt ?? banner.startsAt;
    final dateLabel =
        date != null ? DateFormat('MMM d, y').format(date.toLocal()) : '';
    final handle = banner.businessUsername.isNotEmpty
        ? '@${banner.businessUsername}'
        : banner.businessName;
    final store = banner.businessName.isNotEmpty
        ? banner.businessName
        : (banner.businessUsername.isNotEmpty
            ? banner.businessUsername
            : 'Business');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: banner.image.isNotEmpty
                      ? Image.network(
                          banner.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _colorThumb(),
                        )
                      : _colorThumb(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            banner.title.isNotEmpty
                                ? banner.title
                                : 'Untitled banner',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: WaUi.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: live
                                ? Colors.black
                                : const Color(0xFFB0B0B5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            live ? 'Live' : 'Off',
                            style: WaUi.label.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (v) {
                            if (v == 'edit') onEdit();
                            if (v == 'toggle') onToggle();
                            if (v == 'delete') onDelete();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text('Show / Hide'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store,
                      style: WaUi.body.copyWith(
                        fontSize: 12.5,
                        color: BarqodyChrome.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (banner.buttonText.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    banner.buttonText,
                    style: WaUi.label.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              if (banner.buttonText.isNotEmpty) const SizedBox(width: 8),
              if (handle.isNotEmpty)
                Expanded(
                  child: Text(
                    handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WaUi.body.copyWith(
                      fontSize: 12,
                      color: BarqodyChrome.secondaryText,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: WaUi.label.copyWith(
                    fontSize: 11,
                    color: const Color(0xFFB0B0B5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorThumb() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _parseHex(banner.gradientStart, const Color(0xFF0F766E)),
            _parseHex(banner.gradientEnd, const Color(0xFFEA580C)),
          ],
        ),
      ),
    );
  }
}
