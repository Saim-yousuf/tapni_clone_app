import 'package:flutter/material.dart';
import 'package:tapni_app/utils/theme.dart';

void showSnackBar(context, String message) {
  final snackBar = SnackBar(
    backgroundColor: AppTheme.primaryBlack,
    duration: const Duration(milliseconds: 700),
    content: Text(
      message,
      style: TextStyle(
        color: AppTheme.secondaryWhite,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

class ShowAlert {
  // static success({
  //   required String message,
  //   required BuildContext context,
  // }) {
  //   final snackBar = SnackBar(
  //     backgroundColor: Palette.green,
  //     duration: const Duration(milliseconds: 700),
  //     content: Text(
  //       message,
  //       style: const TextStyle(
  //         color: Palette.white,
  //         fontWeight: boldfontweight,
  //       ),
  //     ),
  //   );
  //   ScaffoldMessenger.of(context).showSnackBar(snackBar);
  // }
  static error({required String message, required BuildContext context}) {
    late OverlayEntry overlayEntry;

    // Create animation controller safely
    final overlayState = Overlay.of(context);
    final tickerProvider = Navigator.of(context);

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: tickerProvider,
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutBack,
    );

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 20.0,
        right: 20.0,
        top: 80,
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(animation),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.0),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlack,
                      AppTheme.primaryBlack.withOpacity(0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlack.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    animationController.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      await animationController.reverse();
      overlayEntry.remove();
      animationController.dispose();
    });
  }

  // static error({
  //   required String message,
  //   required BuildContext context,
  // }) {

  //   OverlayEntry overlayEntry = OverlayEntry(
  //     builder: (context) => Positioned(
  //       left: 20.0,
  //       right: 20.0,
  //       top: 80,
  //       child: Material(
  //         color: Palette.red,
  //         borderRadius: BorderRadius.circular(12.0),
  //         child: Container(
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(12.0),
  //             gradient: LinearGradient(colors: [
  //               Palette.white.withOpacity(0.1),
  //               Palette.red.withOpacity(0.2),
  //               Palette.white.withOpacity(0.1),
  //             ]),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.2),
  //                 blurRadius: 4.0,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: Padding(
  //                   padding: const EdgeInsets.symmetric(
  //                       horizontal: 20, vertical: 10),
  //                   child: Row(
  //                     children: [
  //                       const Icon(
  //                         Icons.error_outline,
  //                         color: Palette.white,
  //                         size: 30,
  //                       ),
  //                       const SizedBox(width: 12),
  //                       Expanded(
  //                         child: Text(
  //                           message,
  //                           style: const TextStyle(
  //                             color: Palette.white,
  //                             fontSize: 14.0,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                           softWrap: true,
  //                         ),
  //                       ),
  //                       const SizedBox(width: 12),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   Overlay.of(context).insert(overlayEntry);

  //   Future.delayed(const Duration(seconds: 2), () {
  //     overlayEntry.remove();
  //   });
  // }

  // static success({
  //   required String message,
  //   required BuildContext context,
  // }) {
  //   OverlayEntry overlayEntry = OverlayEntry(
  //     builder: (context) => Positioned(
  //       left: 20.0,
  //       right: 20.0,
  //       top: 80,
  //       child: Material(
  //         color: Palette.appColor,
  //         borderRadius: BorderRadius.circular(12.0),
  //         child: Container(
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(12.0),
  //             gradient: LinearGradient(colors: [
  //               Palette.appColor.withOpacity(0.2),
  //               Palette.blue.withOpacity(0.2),
  //               Palette.white.withOpacity(0.2),
  //             ]),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.2),
  //                 blurRadius: 4.0,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: Padding(
  //                   padding: const EdgeInsets.symmetric(
  //                       horizontal: 20, vertical: 10),
  //                   child: Row(
  //                     children: [
  //                       Image.asset(
  //                         AssetsPath.png.checkIcon,
  //                         color: Palette.white,
  //                         height: 40,
  //                         fit: BoxFit.fill,
  //                       ),
  //                       const SizedBox(width: 12),
  //                       Expanded(
  //                         child: Text(
  //                           message,
  //                           style: const TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 16.0,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                           softWrap: true,
  //                         ),
  //                       ),
  //                       const SizedBox(width: 12),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.all(20.0),
  //                 child: Image.asset(
  //                   AssetsPath.png.logo,
  //                   height: 40,
  //                   fit: BoxFit.fill,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   Overlay.of(context).insert(overlayEntry);

  //   Future.delayed(const Duration(seconds: 2), () {
  //     overlayEntry.remove();
  //   });
  // }

  static success({required String message, required BuildContext context}) {
    late OverlayEntry overlayEntry;
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: Navigator.of(context),
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutBack,
    );

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 20.0,
        right: 20.0,
        top: 80,
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(animation),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.0),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlack.withOpacity(0.5),
                      AppTheme.primaryBlack.withOpacity(0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlack.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Image.asset(
                            //   AssetsPath.png.checkIcon,
                            //   color: Colors.white,
                            //   height: 28,
                            //   width: 28,
                            // ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.only(right: 16.0),
                    //   child: Image.asset(
                    //     AssetsPath.png.logo,
                    //     height: 32,
                    //     fit: BoxFit.fill,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    animationController.forward();

    // Hold for 2 seconds, then reverse animation
    Future.delayed(const Duration(seconds: 2), () async {
      await animationController.reverse();
      overlayEntry.remove();
      animationController.dispose();
    });
  }
}
// showTopAlertInfo({
//   required String text,
//   required BuildContext context,
// }) {
//   showTopSnackBar(
//     Overlay.of(context),
//     CustomSnackBar.info(
//       message: text,
//     ),
//     displayDuration: const Duration(milliseconds: 700),
//   );
// }

// showTopAlertSuccess({
//   required String text,
//   required BuildContext context,
// }) {
//   showTopSnackBar(
//     Overlay.of(context),
//     CustomSnackBar.success(
//       message: text,
//       backgroundColor: Theme.of(context).colorScheme.secondary,
//     ),
//     displayDuration: const Duration(milliseconds: 700),
//   );
// }

// showTopAlertError({
//   required String text,
//   required BuildContext context,
// }) {
//   showTopSnackBar(
//     Overlay.of(context),
//     CustomSnackBar.error(
//       message: text,
//     ),
//     displayDuration: const Duration(milliseconds: 700),
//   );
// }
