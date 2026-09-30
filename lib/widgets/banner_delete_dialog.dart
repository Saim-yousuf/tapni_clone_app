import 'package:flutter/material.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

Future<bool> showBannerDeleteDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => const _BannerDeleteDialog(),
  );
  return result == true;
}

class _BannerDeleteDialog extends StatelessWidget {
  const _BannerDeleteDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BarqodyChrome.modalRadius),
        clipBehavior: Clip.antiAlias,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: CircleCloseButton(
                  onTap: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(height: 4),
              Image.asset(
                'assets/images/png/delete-img.png',
                width: 72,
                height: 72,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.delete_outline_rounded,
                  size: 64,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Are you sure you want to Delete?',
                textAlign: TextAlign.center,
                style: WaUi.toolsTitleOf(
                  size: 18,
                  weight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 24),
              PillButton(
                label: 'Cancel',
                filled: false,
                onPressed: () => Navigator.pop(context, false),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: 'Delete',
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
