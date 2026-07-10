import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '9876543210');
  bool _useEmail = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('Welcome!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Login to continue ordering', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 32),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Phone'),
                    selected: !_useEmail,
                    onSelected: (_) => setState(() => _useEmail = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Email'),
                    selected: _useEmail,
                    onSelected: (_) => setState(() => _useEmail = true),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!_useEmail) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/otp'),
                  child: const Text('Send OTP'),
                ),
              ] else ...[
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Login'),
                ),
              ],
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR')),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              _socialButton(Icons.g_mobiledata, 'Continue with Google', () => context.go('/home')),
              const SizedBox(height: 12),
              _socialButton(Icons.apple, 'Continue with Apple', () => context.go('/home')),
              const SizedBox(height: 12),
              _socialButton(Icons.facebook, 'Continue with Facebook', () => context.go('/home')),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Continue as Guest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, String label, VoidCallback onTap) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      );
}
