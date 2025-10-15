import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'email_auth_screen.dart';
import 'phone_auth_screen.dart';

class AuthScreen {
  static void showAuthBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AuthBottomSheet(),
    );
  }
}

class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({super.key});

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
  setState(() => _isLoading = true);
  
  try {
    await _authService.signInWithGoogle();
    // Browser will open, user will be redirected back after auth
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  void _handleEmailAuth() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmailAuthScreen()),
    );
  }

  void _handlePhoneAuth() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(15),
              ),
              const SizedBox(height: 16),

              // Welcome Text
              Text(
                'Welcome',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to save your preferences',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Google Sign In Button
              _buildAuthButton(
                onTap: _isLoading ? null : _handleGoogleSignIn,
                icon: Icons.g_mobiledata,
                label: 'Sign in with Google',
                backgroundColor: isDarkMode ? Colors.white : Colors.grey[800]!,
                textColor: isDarkMode ? Colors.black : Colors.white,
              ),
              const SizedBox(height: 12),

              // Phone Sign In Button
              _buildAuthButton(
                onTap: _isLoading ? null : _handlePhoneAuth,
                icon: Icons.phone,
                label: 'Sign in with Phone',
                backgroundColor: const Color(0xFF34C759),
                textColor: Colors.white,
              ),
              const SizedBox(height: 12),

              // Email Sign In Button
              _buildAuthButton(
                onTap: _isLoading ? null : _handleEmailAuth,
                icon: Icons.email,
                label: 'Sign in with Email',
                backgroundColor: const Color(0xFFEF4444),
                textColor: Colors.white,
              ),
              const SizedBox(height: 24),

              // Terms & Privacy
              Text(
                'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const CircularProgressIndicator(
                  color: Color(0xFF2196F3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required VoidCallback? onTap,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}