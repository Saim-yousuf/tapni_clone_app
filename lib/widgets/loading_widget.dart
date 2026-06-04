import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tapni_app/utils/theme.dart';

class CustomDialog {
  static showDailog({
    required Widget child,
    bool barrierDismissible = true,
    required BuildContext context,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: "Dismiss",
      barrierColor: Colors.transparent, // transparent for blur visibility
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => BlurredDialog(child: child),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static loadingDialog(context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => WillPopScope(
        onWillPop: () async => true,
        child: const ProgressDialog(),
      ),
    );
  }
}

class ProgressDialog extends StatelessWidget {
  final double height;
  final double width;
  const ProgressDialog({this.height = 50, this.width = 50, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: height,
        width: width,
        child: CircularProgressIndicator(
          color: AppTheme.primaryBlack,
          strokeWidth: 2.5,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

class BlurredDialog extends StatelessWidget {
  final Widget child;

  const BlurredDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withOpacity(0.4), // adjust for darkness
          ),
        ),
        Center(child: child),
      ],
    );
  }
}
