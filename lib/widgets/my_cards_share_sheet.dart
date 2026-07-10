import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/models/user_custom_card.dart';
import 'package:tapni_app/models/company_business_card.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/wallet_repo.dart';
import 'package:tapni_app/utils/business_card_export_helper.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/custom_card_editor_sheet.dart';
import 'package:tapni_app/widgets/qr_card_stack_carousel.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class MyCardsShareSheet extends StatefulWidget {
  const MyCardsShareSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: true,
      builder: (_) => const MyCardsShareSheet(),
    );
  }

  @override
  State<MyCardsShareSheet> createState() => _MyCardsShareSheetState();
}

class _MyCardsShareSheetState extends State<MyCardsShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  int _currentIndex = 0;
  bool _walletLoading = false;
  bool _pngLoading = false;
  bool _jpgLoading = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final cards = provider.allCardDisplays;
    final activeId = provider.activeCardId;
    _currentIndex = cards.indexWhere((c) => c.id == activeId);
    if (_currentIndex < 0) _currentIndex = 0;
  }

  CardDisplayData? _currentCard(ProfileProvider provider) {
    final cards = provider.allCardDisplays;
    if (cards.isEmpty) return null;
    final index = _currentIndex.clamp(0, cards.length - 1);
    return cards[index];
  }

  void _snack(String message, {Color color = WaUi.accent}) {
    sheetMessenger(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color == WaUi.accent ? WaUi.primaryText : color,
      ),
    );
  }

  Future<void> _downloadPng() async {
    final card = _currentCard(Provider.of<ProfileProvider>(context, listen: false));
    if (card == null) return;
    setState(() => _pngLoading = true);
    final ok = await BusinessCardExportHelper.savePng(_cardKey, fileName: card.name);
    if (!mounted) return;
    setState(() => _pngLoading = false);
    _snack(ok ? 'Card saved as PNG' : 'Failed to save PNG', color: Colors.red);
  }

  Future<void> _downloadJpg() async {
    final card = _currentCard(Provider.of<ProfileProvider>(context, listen: false));
    if (card == null) return;
    setState(() => _jpgLoading = true);
    final ok = await BusinessCardExportHelper.saveJpg(_cardKey, fileName: card.name);
    if (!mounted) return;
    setState(() => _jpgLoading = false);
    _snack(ok ? 'Card saved as JPG' : 'Failed to save JPG', color: Colors.red);
  }

  Future<void> _shareCard() async {
    final card = _currentCard(Provider.of<ProfileProvider>(context, listen: false));
    if (card == null) return;
    await Share.share(
      'Business card: ${card.profileUrl}',
      subject: card.name,
    );
  }

  Future<void> _addToGoogleWallet() async {
    setState(() => _walletLoading = true);
    final res = await WalletRepo().getMyGoogleWalletLink();
    if (!mounted) return;
    setState(() => _walletLoading = false);

    if (!res.success) {
      _snack(res.message ?? 'Could not open Google Wallet', color: Colors.red);
      return;
    }

    final data = unwrapWalletPayload(res.data);
    final saveUrl = data['saveUrl'] as String?;
    final configured = data['configured'] as bool? ?? false;
    final card = _currentCard(Provider.of<ProfileProvider>(context, listen: false));

    if (configured && saveUrl != null && saveUrl.isNotEmpty) {
      final uri = Uri.parse(saveUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _snack('Could not open Google Wallet', color: Colors.red);
      }
      return;
    }

    _snack(data['message'] as String? ?? 'Google Wallet setup pending.');
    if (card != null) {
      await Clipboard.setData(ClipboardData(text: card.profileUrl));
    }
  }

  void _onPageChanged(int index, ProfileProvider provider) async {
    setState(() => _currentIndex = index);
    final cards = provider.allCardDisplays;
    if (index >= 0 && index < cards.length) {
      await provider.setActiveCard(cards[index].id);
    }
  }

  void _openEditor({UserCustomCard? existing}) {
    CustomCardEditorSheet.show(context, existing: existing);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    final cards = provider.allCardDisplays;
    final card = _currentCard(provider);
    final activeIndex = cards.indexWhere((c) => c.id == provider.activeCardId);
    final stackIndex = activeIndex >= 0 ? activeIndex : _currentIndex;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.94;

    return SheetScaffold(
      body: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: WaUi.sheetDecoration,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: WaUi.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Share card', style: WaUi.headline),
                        const SizedBox(height: 2),
                        Text(
                          card != null
                              ? '${card.template.name} · Swipe for more cards'
                              : 'Create a card to share your profile',
                          style: WaUi.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: WaUi.secondaryText),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomPadding),
                child: Column(
                  children: [
                    QrCardStackCarousel(
                      key: ValueKey(cards.length),
                      cards: cards,
                      initialIndex: stackIndex.clamp(0, cards.isEmpty ? 0 : cards.length - 1),
                      cardKey: _cardKey,
                      onPageChanged: (i) => _onPageChanged(i, provider),
                      onAddCard: () => _openEditor(),
                      onEditCard: card != null && !card.isPrimary
                          ? () {
                              final custom = provider.customCardById(card.id);
                              if (custom != null) _openEditor(existing: custom);
                            }
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionChip(
                            label: 'PNG',
                            icon: Icons.image_outlined,
                            loading: _pngLoading,
                            onTap: _downloadPng,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionChip(
                            label: 'JPG',
                            icon: Icons.photo_outlined,
                            loading: _jpgLoading,
                            onTap: _downloadJpg,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionChip(
                            label: 'Share',
                            icon: Icons.ios_share,
                            onTap: _shareCard,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _walletLoading ? null : _addToGoogleWallet,
                        style: FilledButton.styleFrom(
                          backgroundColor: WaUi.primaryText,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(WaUi.radiusMd),
                          ),
                        ),
                        icon: _walletLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.account_balance_wallet_outlined, size: 20),
                        label: Text('Add to Google Wallet', style: WaUi.button.copyWith(color: Colors.white)),
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

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WaUi.scaffold,
      borderRadius: BorderRadius.circular(WaUi.radiusMd),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(WaUi.radiusMd),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: WaUi.primaryText),
                    const SizedBox(height: 2),
                    Text(label, style: WaUi.label.copyWith(color: WaUi.primaryText)),
                  ],
                ),
        ),
      ),
    );
  }
}
