import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatbytes_task_manager/common/constants.dart';
import 'package:whatbytes_task_manager/providers/auth_provider.dart';

class GoogleLoginButton extends ConsumerStatefulWidget {
  const GoogleLoginButton({super.key});

  @override
  ConsumerState<GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends ConsumerState<GoogleLoginButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      label: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : const Text(
              'Continue with Google',
              style: TextStyle(
                letterSpacing: 1,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
      icon: _isLoading
          ? const SizedBox.shrink()
          : Image.asset(Constants.googlePath, width: 40),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(244, 244, 244, 1),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        disabledBackgroundColor: Colors.grey.shade300,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle(context);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
