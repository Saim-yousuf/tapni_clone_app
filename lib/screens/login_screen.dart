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

                // Premium Sign in with Google Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFE5E5EA),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      authProvider.login('saim@gmail.com', 'password123').then((success) {
                        if (success && mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const MainShell()),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Logged in with Google (Demo account: Saim Y)'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(right: 12),
                          child: CustomPaint(
                            painter: GoogleIconPainter(isDark: isDark),
                          ),
                        ),
                        const Text(
                          'Sign in with Google',
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
    canvas.drawArc(rect, 3.14 + 0.35, 1.57, false, strokePaint..color = const Color(0xFFEA4335));
    // Yellow sector (bottom-left)
    canvas.drawArc(rect, 3.14 - 1.22, 1.57, false, strokePaint..color = const Color(0xFFFBBC05));
    // Green sector (bottom-right)
    canvas.drawArc(rect, 0.35, 1.57, false, strokePaint..color = const Color(0xFF34A853));
    // Blue sector (top-right)
    canvas.drawArc(rect, -1.22, 1.57, false, strokePaint..color = const Color(0xFF4285F4));

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.225, r - 1, r * 0.45), barPaint);

    // Subtle mask to make it look like a G cutout
    final cutoutPaint = Paint()
      ..color = isDark ? const Color(0xFF1C1C1E) : Colors.white
      ..style = PaintingStyle.fill;
    // G inner cutout spacing
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
