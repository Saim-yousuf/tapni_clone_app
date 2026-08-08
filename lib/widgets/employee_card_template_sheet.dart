import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/card_template.dart';
import 'package:tapni_app/models/company_business_card.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/repository/attendance_repo.dart';
import 'package:tapni_app/utils/card_template_catalog.dart';
import 'package:tapni_app/widgets/attendance_ui.dart';
import 'package:tapni_app/widgets/employee_company_card_preview.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';
import 'package:tapni_app/widgets/sheet_scaffold.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class EmployeeCardTemplateSheet extends StatefulWidget {
  final CompanyBusinessCard card;
  final ValueChanged<CompanyBusinessCard>? onApplied;

  const EmployeeCardTemplateSheet({
    super.key,
    required this.card,
    this.onApplied,
  });

  static Future<void> show(
    BuildContext context, {
    required CompanyBusinessCard card,
    ValueChanged<CompanyBusinessCard>? onApplied,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: true,
      builder: (_) => EmployeeCardTemplateSheet(
        card: card,
        onApplied: onApplied,
      ),
    );
  }

  @override
  State<EmployeeCardTemplateSheet> createState() =>
      _EmployeeCardTemplateSheetState();
}

class _EmployeeCardTemplateSheetState extends State<EmployeeCardTemplateSheet> {
  late final PageController _pageController;
  late int _activePage;
  bool _isApplying = false;

  List<CardTemplate> get _templates => CardTemplateCatalog.all;

  @override
  void initState() {
    super.initState();
    _activePage = CardTemplateCatalog.indexById(widget.card.cardTemplateId);
    _pageController = PageController(
      initialPage: _activePage,
      viewportFraction: 0.82,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _employeeName(BuildContext context) =>
      widget.card.employeeName.isNotEmpty
          ? widget.card.employeeName
          : context.l10n.you;

  String _employeeInitial(BuildContext context) {
    final name = _employeeName(context);
    return name.isNotEmpty ? name[0].toUpperCase() : 'Y';
  }

  String get _profileUrl {
    if (widget.card.employeeProfileUrl.isNotEmpty) {
      return widget.card.employeeProfileUrl;
    }
    return widget.card.profileUrl;
  }

  Future<void> _applyTemplate() async {
    final selected = _templates[_activePage];
    final isPro = Provider.of<ProfileProvider>(context, listen: false).isProUser;

    if (selected.isPro && !isPro) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ProUpgradeSheet(),
      );
      return;
    }

    setState(() => _isApplying = true);
    final res = await AttendanceRepo().updateEmployeeCardTemplate(
      employeeRefId: widget.card.employeeRefId,
      cardTemplateId: selected.id,
    );
    if (!mounted) return;
    setState(() => _isApplying = false);

    final messenger = sheetMessenger(context);
    if (!res.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.message ?? context.l10n.couldNotSaveCardDesign),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updated = widget.card.copyWith(
      cardTemplateId: selected.id,
      employeeCardTemplateId: selected.id,
    );
    widget.onApplied?.call(updated);

    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.appliedDesign(selected.name)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SheetScaffold(
      body: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.black,
            width: AttendanceUi.borderWidth,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: 18),
            Text(context.l10n.customizeCardDesign, style: AttendanceUi.sectionTitle),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${widget.card.displayName} • Swipe to pick your employee card look',
                textAlign: TextAlign.center,
                style: AttendanceUi.bodyMuted,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 340,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _templates.length,
                onPageChanged: (page) => setState(() => _activePage = page),
                itemBuilder: (context, index) {
                  final template = _templates[index];
                  final scale = _activePage == index ? 1.0 : 0.9;
                  final opacity = _activePage == index ? 1.0 : 0.55;

                  return AnimatedScale(
                    scale: scale,
                    duration: const Duration(milliseconds: 220),
                    child: AnimatedOpacity(
                      opacity: opacity,
                      duration: const Duration(milliseconds: 220),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: EmployeeCompanyCardPreview(
                            template: template,
                            employeeName: _employeeName(context),
                            employeeId: widget.card.employeeDisplayId,
                            employeeInitial: _employeeInitial(context),
                            employeePhotoUrl:
                                widget.card.employeePhoto.isNotEmpty
                                    ? widget.card.employeePhoto
                                    : null,
                            profileUrl: _profileUrl,
                            width: 280,
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12),
            Text(
              _templates[_activePage].name,
              style: AttendanceUi.cardTitle.copyWith(fontSize: 18),
            ),
            if (_templates[_activePage].isPro)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(context.l10n.proTemplate, style: AttendanceUi.bodyMuted),
              ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _templates.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  height: 7,
                  width: _activePage == index ? 18 : 7,
                  decoration: BoxDecoration(
                    color: _activePage == index ? Colors.black : Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
              child: AttendanceUi.primaryButton(
                label: context.l10n.applyDesign,
                icon: Icons.palette_outlined,
                loading: _isApplying,
                onPressed: _applyTemplate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
