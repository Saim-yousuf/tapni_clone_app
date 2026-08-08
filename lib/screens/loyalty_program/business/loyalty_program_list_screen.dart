import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_program_details_screen.dart';
import 'package:tapni_app/screens/loyalty_program/business/loyalty_template_gallery_screen.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/reward_card_stack_carousel.dart';

class LoyaltyProgramListScreen extends StatefulWidget {
  LoyaltyProgramListScreen({super.key});

  @override
  State<LoyaltyProgramListScreen> createState() =>
      _LoyaltyProgramListScreenState();
}

class _LoyaltyProgramListScreenState extends State<LoyaltyProgramListScreen> {
  List<RewardProgram> _programs = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await RewardRepo().getPrograms();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        final list = res.data is List
            ? res.data as List
            : (res.data['data'] as List? ?? []);
        _programs = list
            .map((e) => RewardProgram.fromJson(e as Map<String, dynamic>))
            .toList();
        _currentIndex = _currentIndex.clamp(
          0,
          _programs.isEmpty ? 0 : _programs.length - 1,
        );
      }
    });
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoyaltyTemplateGalleryScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _openDetails(RewardProgram program) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LoyaltyProgramDetailsScreen(programId: program.id),
      ),
    );
    if (changed == true) _load();
  }

  List<RewardCardStackItem> get _items =>
      _programs.map(RewardCardStackItem.fromProgram).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      appBar: AppBar(
        backgroundColor: WaUi.toolsScaffold,
        surfaceTintColor: WaUi.toolsScaffold,
        elevation: 0,
        title: Text(
          context.l10n.rewardPrograms,
          style: WaUi.headline,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openCreate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _programs.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          context.l10n.swipeToBrowseCards,
                          style: WaUi.caption,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RewardCardStackCarousel(
                        key: ValueKey(_programs.length),
                        items: _items,
                        initialIndex: _currentIndex.clamp(
                          0,
                          _programs.length - 1,
                        ),
                        onPageChanged: (i) =>
                            setState(() => _currentIndex = i),
                        onCardTap: (i) => _openDetails(_programs[i]),
                        onAddCard: _openCreate,
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FilledButton.icon(
                          onPressed: () =>
                              _openDetails(_programs[_currentIndex.clamp(
                            0,
                            _programs.length - 1,
                          )]),
                          style: FilledButton.styleFrom(
                            backgroundColor: WaUi.buttonDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.info_outline),
                          label: Text(context.l10n.programDetails),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: !_isLoading && _programs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.newReward),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_giftcard_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(context.l10n.noRewardProgramsYet,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(context.l10n.createYourFirstRewardCardForCustomers,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.createReward),
          ),
        ],
      ),
    );
  }
}
