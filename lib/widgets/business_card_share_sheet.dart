import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapni_app/models/card_template.dart';
import 'package:tapni_app/models/company_business_card.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/wallet_repo.dart';
import 'package:tapni_app/utils/business_card_export_helper.dart';
import 'package:tapni_app/utils/card_template_catalog.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/employee_company_card_preview.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';
import 'package:tapni_app/widgets/template_business_card_preview.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessCardShareSheet extends StatefulWidget {
  final String profileUrl;
  final String displayName;
  final String userInitial;
  final String? profilePhotoUrl;
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

  const BusinessCardShareSheet({
    super.key,
    required this.profileUrl,
    required this.displayName,
    required this.userInitial,
    required this.template,
    this.profilePhotoUrl,
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
  });

  static void show(
    BuildContext context, {
    required String profileUrl,
    required String displayName,
    required String userInitial,
    required CardTemplate template,
    String? profilePhotoUrl,
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
      ),
    );
  }

  static void showForCompanyCard(
    BuildContext context,
    CompanyBusinessCard card,
  ) {
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
    );
  }

  static void showMyCard(BuildContext context) {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;
    final template = profileProvider.currentTemplate;
    final profileUrl = '${Constants.appDomain}/${profile.username}';

    show(
      context,
      profileUrl: profileUrl,
      displayName: profile.businessName?.isNotEmpty == true
          ? profile.businessName!
          : profile.name,
      userInitial:
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
      template: template,
      profilePhotoUrl: profile.profilePhotoUrl,
      useMyCardWallet: true,
      subtitle: profile.designation.isNotEmpty
          ? profile.designation
          : (profile.company.isNotEmpty ? profile.company : null),
      bio: profile.bio,
    );
  }

  @override
  State<BusinessCardShareSheet> createState() => _BusinessCardShareSheetState();
}

class _BusinessCardShareSheetState extends State<BusinessCardShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _walletLoading = false;
  bool _pngLoading = false;
  bool _jpgLoading = false;

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

  Future<void> _downloadPng() async {
    final messenger = sheetMessenger(context);
    setState(() => _pngLoading = true);
    final ok = await BusinessCardExportHelper.savePng(
      _cardKey,
      fileName: widget.displayName,
    );
    if (!mounted) return;
    setState(() => _pngLoading = false);
    _snack(
      messenger,
      ok ? 'Card saved as PNG' : 'Failed to save PNG',
      color: ok ? Colors.green : Colors.red,
    );
  }

  Future<void> _downloadJpg() async {
    final messenger = sheetMessenger(context);
    setState(() => _jpgLoading = true);
    final ok = await BusinessCardExportHelper.saveJpg(
      _cardKey,
      fileName: widget.displayName,
    );
    if (!mounted) return;
    setState(() => _jpgLoading = false);
    _snack(
      messenger,
      ok ? 'Card saved as JPG' : 'Failed to save JPG',
      color: ok ? Colors.green : Colors.red,
    );
  }

  Future<void> _addToGoogleWallet() async {
    final messenger = sheetMessenger(context);
    setState(() => _walletLoading = true);

    final res = widget.useMyCardWallet || widget.businessUserId == null
        ? await WalletRepo().getMyGoogleWalletLink()
        : await WalletRepo().getCompanyGoogleWalletLink(widget.businessUserId!);

    if (!mounted) return;
    setState(() => _walletLoading = false);

    if (!res.success) {
      _snack(
        messenger,
        res.message ?? 'Could not open Google Wallet',
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
        _snack(messenger, 'Could not open Google Wallet', color: Colors.red);
      }
      return;
    }

    _snack(
      messenger,
      data['message'] as String? ??
          'Google Wallet setup pending. Profile link copied.',
    );
    await Clipboard.setData(ClipboardData(text: widget.profileUrl));
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SheetScaffold(
      body: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.black,
            width: AttendanceUi.borderWidth,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomPadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.isEmployeeCard ? 'Employee Card' : widget.displayName,
              textAlign: TextAlign.center,
              style: AttendanceUi.sectionTitle,
            ),
            const SizedBox(height: 6),
            Text(
              widget.isEmployeeCard
                  ? '${widget.companyName ?? ''} • ${widget.template.name} template'
                  : '${widget.template.name} template',
              textAlign: TextAlign.center,
              style: AttendanceUi.bodyMuted,
            ),
            const SizedBox(height: 20),
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: widget.isEmployeeCard
                  ? EmployeeCompanyCardPreview(
                      template: widget.template,
                      employeeName: widget.employeeName ?? 'Employee',
                      employeeId: widget.employeeId ?? '',
                      employeeInitial: widget.employeeInitial ?? 'E',
                      employeePhotoUrl: widget.employeePhotoUrl,
                      profileUrl: widget.profileUrl,
                    )
                  : TemplateBusinessCardPreview(
                      template: widget.template,
                      name: widget.displayName,
                      profileUrl: widget.profileUrl,
                      userInitial: widget.userInitial,
                      profilePhotoUrl: widget.profilePhotoUrl,
                      subtitle: widget.subtitle,
                      bio: widget.bio,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AttendanceUi.secondaryButton(
                    label: 'PNG',
                    icon: Icons.image_outlined,
                    loading: _pngLoading,
                    height: 56,
                    onPressed: _downloadPng,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AttendanceUi.secondaryButton(
                    label: 'JPG',
                    icon: Icons.photo_outlined,
                    loading: _jpgLoading,
                    height: 56,
                    onPressed: _downloadJpg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AttendanceUi.secondaryButton(
                    label: 'Share',
                    icon: Icons.share_rounded,
                    height: 56,
                    onPressed: () => Share.share(
                      widget.isEmployeeCard
                          ? 'Employee card - ${widget.employeeName}: ${widget.profileUrl}'
                          : 'Business card: ${widget.profileUrl}',
                      subject: widget.isEmployeeCard
                          ? 'Employee Card - ${widget.employeeName}'
                          : widget.displayName,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AttendanceUi.primaryButton(
              label: 'Add to Google Wallet',
              icon: Icons.account_balance_wallet_outlined,
              loading: _walletLoading,
              onPressed: _addToGoogleWallet,
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}
