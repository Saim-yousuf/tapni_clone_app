import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/models/card_template.dart';
import 'package:tapni_app/models/company_business_card.dart';
import 'package:tapni_app/models/business_card_design.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/widgets/my_cards_share_sheet.dart';
import 'package:tapni_app/repository/wallet_repo.dart';
import 'package:tapni_app/utils/card_template_catalog.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/print_export_sizes.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:tapni_app/widgets/card_download_size_sheet.dart';
import 'package:tapni_app/widgets/employee_card_template_sheet.dart';
import 'package:tapni_app/widgets/employee_company_card_preview.dart';
import 'package:tapni_app/widgets/template_business_card_preview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class BusinessCardShareSheet extends StatefulWidget {
  final String profileUrl;
  final String displayName;
  final String userInitial;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final String? businessUserId;
  final bool useMyCardWallet;
  final CardTemplate template;
  final String? subtitle;
  final String? bio;
  final bool isEmployeeCard;
  final String? employeeName;
  final String? employeeInitial;
  final String? employeePhotoUrl;
  final String? employeeId;
  final String? companyName;
  final String? employeeRefId;
  final CompanyBusinessCard? companyCard;
  final ValueChanged<CompanyBusinessCard>? onTemplateChanged;

  const BusinessCardShareSheet({
    super.key,
    required this.profileUrl,
    required this.displayName,
    required this.userInitial,
    required this.template,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    this.businessUserId,
    this.useMyCardWallet = false,
    this.subtitle,
    this.bio,
    this.isEmployeeCard = false,
    this.employeeName,
    this.employeeInitial,
    this.employeePhotoUrl,
    this.employeeId,
    this.companyName,
    this.employeeRefId,
    this.companyCard,
    this.onTemplateChanged,
  });

  static void show(
    BuildContext context, {
    required String profileUrl,
    required String displayName,
    required String userInitial,
    required CardTemplate template,
    String? profilePhotoUrl,
    String? coverPhotoUrl,
    String? businessUserId,
    bool useMyCardWallet = false,
    String? subtitle,
    String? bio,
    bool isEmployeeCard = false,
    String? employeeName,
    String? employeeInitial,
    String? employeePhotoUrl,
    String? employeeId,
    String? companyName,
    String? employeeRefId,
    CompanyBusinessCard? companyCard,
    ValueChanged<CompanyBusinessCard>? onTemplateChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: true,
      builder: (_) => BusinessCardShareSheet(
        profileUrl: profileUrl,
        displayName: displayName,
        userInitial: userInitial,
        template: template,
        profilePhotoUrl: profilePhotoUrl,
        coverPhotoUrl: coverPhotoUrl,
        businessUserId: businessUserId,
        useMyCardWallet: useMyCardWallet,
        subtitle: subtitle,
        bio: bio,
        isEmployeeCard: isEmployeeCard,
        employeeName: employeeName,
        employeeInitial: employeeInitial,
        employeePhotoUrl: employeePhotoUrl,
        employeeId: employeeId,
        companyName: companyName,
        employeeRefId: employeeRefId,
        companyCard: companyCard,
        onTemplateChanged: onTemplateChanged,
      ),
    );
  }

  static void showForCompanyCard(
    BuildContext context,
    CompanyBusinessCard card, {
    ValueChanged<CompanyBusinessCard>? onTemplateChanged,
  }) {
    final template = CardTemplateCatalog.byId(card.cardTemplateId);
    final employeeName = card.employeeName.isNotEmpty
        ? card.employeeName
        : 'Employee';
    final employeeProfileUrl = card.employeeProfileUrl.isNotEmpty
        ? card.employeeProfileUrl
        : (card.employeeUsername.isNotEmpty
            ? '${Constants.appDomain}/${card.employeeUsername}'
            : card.profileUrl);

    show(
      context,
      profileUrl: employeeProfileUrl,
      displayName: employeeName,
      userInitial:
          employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'E',
      template: template,
      profilePhotoUrl:
          card.employeePhoto.isNotEmpty ? card.employeePhoto : null,
      useMyCardWallet: true,
      subtitle: card.displayName,
      isEmployeeCard: true,
      employeeName: employeeName,
      employeeInitial:
          employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'E',
      employeePhotoUrl:
          card.employeePhoto.isNotEmpty ? card.employeePhoto : null,
      employeeId: card.employeeDisplayId,
      companyName: card.displayName,
      employeeRefId: card.employeeRefId,
      companyCard: card,
      onTemplateChanged: onTemplateChanged,
    );
  }

  static void showMyCard(BuildContext context) {
    MyCardsShareSheet.show(context);
  }

  @override
  State<BusinessCardShareSheet> createState() => _BusinessCardShareSheetState();
}

class _BusinessCardShareSheetState extends State<BusinessCardShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _googleWalletLoading = false;
  bool _appleWalletLoading = false;
  late CardTemplate _template;

  @override
  void initState() {
    super.initState();
    _template = widget.template;
  }

  Future<void> _openCustomizeDesign() async {
    final card = widget.companyCard;
    if (card == null) return;

    await EmployeeCardTemplateSheet.show(
      context,
      card: card.copyWith(cardTemplateId: _template.id),
      onApplied: (updated) {
        setState(() {
          _template = CardTemplateCatalog.byId(updated.cardTemplateId);
        });
        widget.onTemplateChanged?.call(updated);
      },
    );
  }

  void _snack(
    ScaffoldMessengerState messenger,
    String message, {
    Color color = Colors.green,
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  Future<void> _openDownloadSheet() async {
    await CardDownloadSizeSheet.show(
      context,
      cardCaptureKey: _cardKey,
      profileUrl: widget.profileUrl,
      fileName: widget.displayName,
      cardAspectRatio: BusinessCardDesign.defaultAspectRatio,
      initialKind: PrintExportKind.fullCard,
    );
  }

  Future<void> _addToAppleWallet() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _appleWalletLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _appleWalletLoading = false);

    _snack(
      messenger,
      context.l10n.appleWalletSetupPendingProfileLinkCopied,
    );
    await Clipboard.setData(ClipboardData(text: widget.profileUrl));
  }

  Future<void> _addToGoogleWallet() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _googleWalletLoading = true);

    final res = widget.useMyCardWallet || widget.businessUserId == null
        ? await WalletRepo().getMyGoogleWalletLink()
        : await WalletRepo().getCompanyGoogleWalletLink(widget.businessUserId!);

    if (!mounted) return;
    setState(() => _googleWalletLoading = false);

    if (!res.success) {
      _snack(
        messenger,
        res.message ?? context.l10n.couldNotOpenGoogleWallet,
        color: Colors.red,
      );
      return;
    }

    final data = unwrapWalletPayload(res.data);
    final saveUrl = data['saveUrl'] as String?;
    final configured = data['configured'] as bool? ?? false;

    if (configured && saveUrl != null && saveUrl.isNotEmpty) {
      final uri = Uri.parse(saveUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _snack(messenger, context.l10n.couldNotOpenGoogleWallet, color: Colors.red);
      }
      return;
    }

    _snack(
      messenger,
      data['message'] as String? ??
          context.l10n.googleWalletSetupPendingProfileLinkCopied,
    );
    await Clipboard.setData(ClipboardData(text: widget.profileUrl));
  }

  void _shareCard() {
    Share.share(
      widget.isEmployeeCard
          ? 'Employee card - ${widget.employeeName}: ${widget.profileUrl}'
          : 'Business card: ${widget.profileUrl}',
      subject: widget.isEmployeeCard
          ? 'Employee Card - ${widget.employeeName}'
          : widget.displayName,
    );
  }

  bool get _walletBusy => _googleWalletLoading || _appleWalletLoading;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final title = widget.isEmployeeCard
        ? context.l10n.employeeCard
        : widget.displayName;
    final subtitle = widget.isEmployeeCard
        ? widget.companyName ?? _template.name
        : '${_template.name} template';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: BarqodyChrome.scaffold,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(BarqodyChrome.sheetRadius),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              BarqodyChrome.sidePad,
              10,
              BarqodyChrome.sidePad,
              24 + bottomPadding,
            ),
            children: [
              const Center(child: SheetDragHandle()),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WaUi.toolsTitleOf(
                        size: 18,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CircleCloseButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    color: BarqodyChrome.secondaryText,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: widget.isEmployeeCard
                      ? EmployeeCompanyCardPreview(
                          template: _template,
                          employeeName: widget.employeeName ?? 'Employee',
                          employeeId: widget.employeeId ?? '',
                          employeeInitial: widget.employeeInitial ?? 'E',
                          employeePhotoUrl: widget.employeePhotoUrl,
                          profileUrl: widget.profileUrl,
                        )
                      : TemplateBusinessCardPreview(
                          template: _template,
                          name: widget.displayName,
                          profileUrl: widget.profileUrl,
                          userInitial: widget.userInitial,
                          profilePhotoUrl: widget.profilePhotoUrl,
                          coverPhotoUrl: widget.coverPhotoUrl,
                          subtitle: widget.subtitle,
                          bio: widget.bio,
                          verified: !widget.isEmployeeCard &&
                              Provider.of<ProfileProvider>(context).isProUser,
                        ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isEmployeeCard && widget.companyCard != null)
                    CircleAssetButton(
                      asset: 'assets/images/png/settings-sliders.png',
                      iconSize: 18,
                      onTap: _openCustomizeDesign,
                    ),
                  if (widget.isEmployeeCard && widget.companyCard != null)
                    const SizedBox(width: 12),
                  CircleAssetButton(
                    asset: 'assets/images/png/download-icon.png',
                    iconSize: 18,
                    onTap: _openDownloadSheet,
                  ),
                  const SizedBox(width: 12),
                  CircleAssetButton(
                    asset: 'assets/images/png/arrow-up-icon.png',
                    iconSize: 16,
                    onTap: _shareCard,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isEmployeeCard && widget.companyCard != null) ...[
                    Text(
                      context.l10n.customizeDesign,
                      style: _actionCaptionStyle,
                    ),
                    const SizedBox(width: 36),
                  ],
                  Text(context.l10n.download, style: _actionCaptionStyle),
                  const SizedBox(width: 52),
                  Text(context.l10n.share, style: _actionCaptionStyle),
                ],
              ),
              const SizedBox(height: 24),
              _WalletPillButton(
                title: 'Add to',
                subtitle: 'Apple Wallet',
                iconAsset: 'assets/images/png/apple-wallet-icon-1.png',
                loading: _appleWalletLoading,
                onPressed: _walletBusy ? null : _addToAppleWallet,
              ),
              const SizedBox(height: 10),
              _WalletPillButton(
                title: 'Add to',
                subtitle: 'Google Wallet',
                iconAsset: 'assets/images/png/google_wallet_icon.png',
                loading: _googleWalletLoading,
                onPressed: _walletBusy ? null : _addToGoogleWallet,
              ),
            ],
          ),
        );
      },
    );
  }

  TextStyle get _actionCaptionStyle => WaUi.body.copyWith(
        fontSize: 11,
        color: BarqodyChrome.secondaryText,
      );
}

class _WalletPillButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconAsset;
  final VoidCallback? onPressed;
  final bool loading;

  const _WalletPillButton({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.black,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          customBorder: const StadiumBorder(),
          child: Opacity(
            opacity: disabled && !loading ? 0.5 : 1,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          iconAsset,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Image.asset(
                            'assets/images/png/google-wallet-icon.png',
                            width: 28,
                            height: 28,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                height: 1.1,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
