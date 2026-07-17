import 'package:flutter/material.dart';
import 'package:tapni_app/screens/phone_auth_screen.dart';

/// Legacy signup screen — phone OTP handles both login and signup.
class SignupScreen extends StatelessWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const PhoneAuthScreen();
  }
}
