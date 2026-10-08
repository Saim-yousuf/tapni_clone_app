import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/models/business_card_design.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/user_custom_card.dart';
import 'package:tapni_app/utils/card_template_catalog.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/print_export_sizes.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/card_download_size_sheet.dart';
import 'package:tapni_app/widgets/qr_card_stack_carousel.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';

/// Read-only sheet showing another user's digital business cards.
class UserCardsSheet extends StatefulWidget {
  const UserCardsSheet({super.key, required this.profile});

  final UserProfile profile;

  static Future<void> show(
    BuildContext context, {
    required UserProfile profile,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => UserCardsSheet(profile: profile),
    );
  }

  @override
  State<UserCardsSheet> createState() => _UserCardsSheetState();
}

class _UserCardsSheetState extends State<UserCardsSheet> {
  final GlobalKey _cardKey = GlobalKey();
  late final List<CardDisplayData> _cards;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _cards = cardDisplaysForProfile(widget.profile);
  }

  CardDisplayData? get _current {
    if (_cards.isEmpty) return null;
    return _cards[_currentIndex.clamp(0, _cards.length - 1)];
  }

  Future<void> _shareCard() async {
    final card = _current;
    if (card == null) return;
    await Share.share(
      'Business card: ${card.profileUrl}',
      subject: card.name,
    );
  }

  Future<void> _openDownloadSheet() async {
    final card = _current;
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height * 0.92;
    final card = _current;

    // Fixed-height sheet (no nested DraggableScrollableSheet) — avoids freezes
    // when opened over the profile's own draggable sheet.
    return Padding(
      padding: EdgeInsets.only(top: media.padding.top + 4),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(BarqodyChrome.sheetRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const SheetDragHandle(),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          CircleBackButton(
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              context.l10n.digitalBusinessCard,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WaUi.toolsTitleOf(
                                size: 18,
                                weight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      child: QrCardStackCarousel(
                        key: ValueKey(_cards.length),
                        cards: _cards,
                        initialIndex: _currentIndex.clamp(
                          0,
                          _cards.isEmpty ? 0 : _cards.length - 1,
                        ),
                        cardKey: _cardKey,
                        onPageChanged: (i) =>
                            setState(() => _currentIndex = i),
                        onShare: card != null ? _shareCard : null,
                        onDownload: card != null ? _openDownloadSheet : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<CardDisplayData> cardDisplaysForProfile(UserProfile profile) {
  final username = profile.username?.trim() ?? '';
  final allLinkIds = profile.socialLinks
      .where((l) => l.isActive)
      .map((l) => l.id)
      .toList();
  final displayName = profile.businessName?.trim().isNotEmpty == true
      ? profile.businessName!.trim()
      : profile.name;
  final subtitle = profile.designation.isNotEmpty
      ? profile.designation
      : (profile.company.isNotEmpty ? profile.company : null);

  final cards = <CardDisplayData>[
    CardDisplayData(
      id: UserCustomCard.primaryId,
      title: 'Main Card',
      name: displayName,
      subtitle: subtitle,
      bio: profile.bio.isNotEmpty ? profile.bio : null,
      template: CardTemplateCatalog.byId(profile.cardTemplateId),
      profilePhotoUrl: profile.profilePhotoUrl,
      coverPhotoUrl: null,
      enabledLinkIds: allLinkIds,
      profileUrl: username.isNotEmpty
          ? '${Constants.appDomain}/$username'
          : Constants.appDomain,
      isPrimary: true,
      printDesign: profile.cardPrintDesign,
      isVerified: profile.isPro,
    ),
  ];

  for (final card in profile.customCards) {
    final enabledIds =
        card.enabledLinkIds.isEmpty ? allLinkIds : card.enabledLinkIds;
    cards.add(
      CardDisplayData(
        id: card.id,
        title: card.title,
        name: card.displayName.isNotEmpty ? card.displayName : displayName,
        subtitle: card.subtitle,
        bio: card.bio,
        template: card.effectiveTemplate(),
        profilePhotoUrl: card.profilePhotoUrl ?? profile.profilePhotoUrl,
        coverPhotoUrl: card.coverPhotoUrl,
        enabledLinkIds: enabledIds,
        profileUrl: card.profileUrl(username),
        isPrimary: false,
        printDesign: card.design,
        isVerified: profile.isPro,
      ),
    );
  }

  return cards;
}
