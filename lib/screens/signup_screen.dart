import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/subscription_provider.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/custom_button.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        authProvider.setLoading(true);
        final success = await authProvider.register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          context,
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
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainShell()),
            (route) => false,
          );
        }
      } catch (e) {
      } finally {
        authProvider.setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                // Heading
                Text(
                  context.l10n.createAccount,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  context.l10n.startNetworkingSmarterWithBarqody,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppTheme.textGreyDark
                        : AppTheme.textGreyLight,
                  ),
                ),
                SizedBox(height: 36),

                // Name
                Text(
                  context.l10n.fullName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: context.l10n.johnDoe,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.pleaseEnterYourName;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

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
                SizedBox(height: 20),

                // Password
                Text(
                  context.l10n.password,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignup(),
                  decoration: InputDecoration(
                    hintText: context.l10n.atLeast6Characters,
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
                      return context.l10n.pleaseEnterAPassword;
                    }
                    if (value.length < 6) {
                      return context.l10n.passwordMustBeAtLeast6Characters;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),

                // Sign Up Button
                CustomButton(
                  text: context.l10n.createAccount,
                  onTap: _handleSignup,
                  // isGold: true,
                  isLoading: authProvider.isLoading,
                ),
                SizedBox(height: 32),

                // Terms Notice
                Center(
                  child: Text(
                    context.l10n.bySigningUpYouAgreeToOurTermsAndConditions,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.textGreyDark
                          : AppTheme.textGreyLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),

                // Login Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.alreadyHaveAnAccount2,
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textGreyDark
                            : AppTheme.textGreyLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(context.l10n.logIn,
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
