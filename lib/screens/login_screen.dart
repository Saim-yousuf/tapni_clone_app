import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/linked_devices/qr_login_screen.dart';
import 'package:tapni_app/screens/signup_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/custom_button.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, this.addAccount = false}) : super(key: key);

  final bool addAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // if (_formKey.currentState!.validate()) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      authProvider.setLoading(true);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        context,
        addAccount: widget.addAccount,
      );

      if (success && mounted) {
        final subProvider = Provider.of<SubscriptionProvider>(
          context,
          listen: false,
        );
        await subProvider.checkSubscriptionStatus();
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        await profileProvider.fetchProfile();
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => MainShell()));
      }
    } catch (e) {
    } finally {
      authProvider.setLoading(false);
    }
    //
    // }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                // Heading
                Text(
                  context.l10n.welcomeBack,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    // letterSpacing: -1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  context.l10n.logInToManageYourDigitalCardAndNetwork,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppTheme.textGreyDark
                        : AppTheme.textGreyLight,
                  ),
                ),
                SizedBox(height: 48),

                // Email
                Text(
                  context.l10n.emailAddress,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: context.l10n.nameCompanyCom,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.pleaseEnterYourEmail;
                    }
                    if (!value.contains('@')) {
                      return context.l10n.pleaseEnterAValidEmailAddress;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),

                // Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.password,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.commingSoon),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(context.l10n.forgot,
                        style: TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    hintText: context.l10n.enterYourPassword,
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.pleaseEnterYourPassword;
                    }
                    if (value.length < 4) {
                      return context.l10n.passwordMustBeAtLeast4Characters;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),

                // Login Button
                CustomButton(
                  text: context.l10n.logIn,
                  onTap: _handleLogin,
                  // isGold: true,
                  isLoading: authProvider.isLoading,
                ),
                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WaUi.primaryText,
                      side: BorderSide(color: WaUi.divider, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QrLoginScreen(
                            addAccount: widget.addAccount,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.qr_code_2, color: WaUi.accent),
                    label: Text(
                      context.l10n.logInWithQRCode,
                      style: WaUi.bodyMedium,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        context.l10n.orCONTINUEWITH,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.textGreyDark
                              : AppTheme.textGreyLight,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Premium Sign in with Google Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFE5E5EA),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      // authProvider
                      //     .login(
                      //       _emailController.text,
                      //       _passwordController.text,
                      //       context,
                      //     )
                      //     .then((success) async {
                      //       if (success && mounted) {
                      //         final subProvider =
                      //             Provider.of<SubscriptionProvider>(
                      //               context,
                      //               listen: false,
                      //             );
                      //         await subProvider.checkSubscriptionStatus();
                      //         final profileProvider =
                      //             Provider.of<ProfileProvider>(
                      //               context,
                      //               listen: false,
                      //             );
                      //         await profileProvider.fetchProfile();
                      //         if (!mounted) return;
                      //         Navigator.of(context).pushReplacement(
                      //           MaterialPageRoute(
                      //             builder: (_) => MainShell(),
                      //           ),
                      //         );

                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text(
                      //       context.l10n.loggedInWithGoogleDemoAccountSaimY,
                      //     ),
                      //     behavior: SnackBarBehavior.floating,
                      //   ),
                      // );
                      //       }
                      //     });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.underDevelopmentLoginViaEmailPasswordInstead2,
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          margin: EdgeInsets.only(right: 12),
                          child: CustomPaint(
                            painter: GoogleIconPainter(isDark: isDark),
                          ),
                        ),
                        Text(context.l10n.signInWithGoogle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40),

                // Register Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.dontHaveAnAccount2,
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textGreyDark
                            : AppTheme.textGreyLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SignupScreen(),
                          ),
                        );
                      },
                      child: Text(context.l10n.signUp,
                        style: TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Beautiful Google G logo Custom Painter
class GoogleIconPainter extends CustomPainter {
  final bool isDark;
  GoogleIconPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r - 2);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.45
      ..strokeCap = StrokeCap.square;

    // Red sector (top-left)
    canvas.drawArc(
      rect,
      3.14 + 0.35,
      1.57,
      false,
      strokePaint..color = const Color(0xFFEA4335),
    );
    // Yellow sector (bottom-left)
    canvas.drawArc(
      rect,
      3.14 - 1.22,
      1.57,
      false,
      strokePaint..color = const Color(0xFFFBBC05),
    );
    // Green sector (bottom-right)
    canvas.drawArc(
      rect,
      0.35,
      1.57,
      false,
      strokePaint..color = const Color(0xFF34A853),
    );
    // Blue sector (top-right)
    canvas.drawArc(
      rect,
      -1.22,
      1.57,
      false,
      strokePaint..color = const Color(0xFF4285F4),
    );

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.225, r - 1, r * 0.45),
      barPaint,
    );

    // Subtle mask to make it look like a G cutout
    final cutoutPaint = Paint()
      ..color = isDark ? const Color(0xFF1C1C1E) : Colors.white
      ..style = PaintingStyle.fill;
    // G inner cutout spacing
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
