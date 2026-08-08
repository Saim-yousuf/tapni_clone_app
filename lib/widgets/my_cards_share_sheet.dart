import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/models/user_custom_card.dart';
import 'package:tapni_app/models/company_business_card.dart';
import 'package:tapni_app/models/business_card_design.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/wallet_repo.dart';
import 'package:tapni_app/screens/business_card/business_card_design_editor_screen.dart';
import 'package:tapni_app/utils/print_export_sizes.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/card_download_size_sheet.dart';
import 'package:tapni_app/widgets/custom_card_editor_sheet.dart';
import 'package:tapni_app/widgets/qr_card_stack_carousel.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 14)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color == WaUi.accent ? WaUi.primaryText : color,
      ),
    );
  }

  Future<void> _openDownloadSheet() async {
    final card = _currentCard(Provider.of<ProfileProvider>(context, listen: false));
    if (card == null) return;
    await CardDownloadSizeSheet.show(
      context,
      cardCaptureKey: _cardKey,
      profileUrl: card.profileUrl,
      fileName: card.name,
      cardAspectRatio: BusinessCardDesign.defaultAspectRatio,
      initialKind: PrintExportKind.fullCard,
    );
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
      _snack(res.message ?? context.l10n.couldNotOpenGoogleWallet, color: Colors.red);
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
        _snack(context.l10n.couldNotOpenGoogleWallet, color: Colors.red);
      }
      return;
    }

    _snack(data['message'] as String? ?? context.l10n.googleWalletSetupPending);
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
    if (existing?.design != null && existing!.design!.hasLayers) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BusinessCardDesignEditorScreen(
            design: existing.design!.copy(),
            cardId: existing.id,
          ),
        ),
      );
      return;
    }
    CustomCardEditorSheet.show(context, existing: existing);
  }

  Future<void> _deleteCurrentCard() async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final cards = provider.allCardDisplays;
    final card = _currentCard(provider);
    if (card == null || card.isPrimary) return;
    if (cards.length <= 1) {
      _snack('Last card cannot be deleted', color: Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteCard, style: WaUi.title),
        content: Text(
          ctx.l10n.thisCardAndItsQRCodeWillBeRemoved,
          style: WaUi.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await provider.deleteCustomCard(card.id);
    if (!mounted) return;
    _snack(
      ok ? 'Card deleted' : 'Could not delete card',
      color: ok ? WaUi.accent : Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    final cards = provider.allCardDisplays;
    final card = _currentCard(provider);
    final activeIndex = cards.indexWhere((c) => c.id == provider.activeCardId);
    final stackIndex = activeIndex >= 0 ? activeIndex : _currentIndex;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) {
        return Container(
          width: double.infinity,
          decoration: WaUi.sheetDecoration,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomPadding),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WaUi.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.shareCard, style: WaUi.headline),
                          const SizedBox(height: 2),
                          Text(
                            card != null
                                ? '${card.template.name} · Swipe for more cards'
                                : context.l10n.createACardToShareYourProfile,
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
              const SizedBox(height: 8),
              QrCardStackCarousel(
                key: ValueKey(cards.length),
                cards: cards,
                initialIndex: stackIndex.clamp(
                  0,
                  cards.isEmpty ? 0 : cards.length - 1,
                ),
                cardKey: _cardKey,
                onPageChanged: (i) => _onPageChanged(i, provider),
                onAddCard: () => _openEditor(),
                onEditCard: card != null && !card.isPrimary
                    ? () {
                        final custom = provider.customCardById(card.id);
                        if (custom != null) _openEditor(existing: custom);
                      }
                    : null,
                onDeleteCard:
                    card != null && !card.isPrimary && cards.length > 1
                        ? _deleteCurrentCard
                        : null,
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: WaUi.scaffold,
                  borderRadius: BorderRadius.circular(WaUi.radiusLg),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _ExportAction(
                        label: context.l10n.download,
                        icon: Icons.download_rounded,
                        onTap: _openDownloadSheet,
                      ),
                    ),
                    _ExportDivider(),
                    Expanded(
                      child: _ExportAction(
                        label: context.l10n.share,
                        icon: Icons.ios_share_rounded,
                        onTap: _shareCard,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: WaUi.buttonDark,
                borderRadius: BorderRadius.circular(WaUi.radiusLg),
                child: InkWell(
                  onTap: _walletLoading ? null : _addToGoogleWallet,
                  borderRadius: BorderRadius.circular(WaUi.radiusLg),
                  child: SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_walletLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 10),
                        Text(
                          context.l10n.addToGoogleWallet,
                          style: WaUi.button.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExportDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: WaUi.divider,
    );
  }
}

class _ExportAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  const _ExportAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(WaUi.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: WaUi.surface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: WaUi.secondaryText,
                          ),
                        )
                      : Icon(icon, size: 20, color: WaUi.primaryText),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: WaUi.label.copyWith(
                color: WaUi.primaryText,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
