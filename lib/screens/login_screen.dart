import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/auth_provider.dart';
import 'package:tapni_app/screens/signup_screen.dart';
import 'package:tapni_app/screens/main_shell.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
    _emailController.text = 'saim@gmail.com';
    _passwordController.text = 'password123';
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Heading
                Text(
                  'Welcome Back',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to manage your digital card and network.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                  ),
                ),
                const SizedBox(height: 48),

                // Email
                Text(
                  'Email Address',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'name@company.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Demo account: use any email & password to login.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot?',
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
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                      return 'Please enter your password';
                    }
                    if (value.length < 4) {
                      return 'Password must be at least 4 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Login Button
                CustomButton(
                  text: 'Log In',
                  onTap: _handleLogin,
                  // isGold: true,
                  isLoading: authProvider.isLoading,
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
                  ],
                ),
                const SizedBox(height: 24),

                // Google Button (UI only)
                CustomButton(
                  text: 'Sign in with Google',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google Login is UI only for this demo.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  isSecondary: true,
                  icon: Icons.g_mobiledata_rounded,
                ),
                const SizedBox(height: 40),

                // Register Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
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
