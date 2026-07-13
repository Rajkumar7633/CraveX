import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@zomato-clone.com');
  final _passwordCtrl = TextEditingController(text: 'admin123');
  final _otpCtrl = TextEditingController();
  bool _show2fa = false;
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
    if (!_show2fa) {
      setState(() => _show2fa = true);
    } else {
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, size: 40, color: AppTheme.primaryRed),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Super Admin Portal',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!_show2fa) ...[
                    AppTextField(
                      controller: _emailCtrl,
                      hintText: 'Email',
                      prefixIcon: Icons.email_rounded,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordCtrl,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_rounded,
                      obscureText: true,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.security_rounded, color: AppTheme.primaryRed),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Enter 2FA code sent to your authenticator app',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1C)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _otpCtrl,
                      hintText: '2FA Code',
                      prefixIcon: Icons.verified_user_rounded,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 4),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: _loading ? 'Verifying...' : _show2fa ? 'Verify & Login' : 'Continue',
                    onPressed: _loading ? null : _login,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
