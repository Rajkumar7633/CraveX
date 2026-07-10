import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';

class RiderLoginScreen extends StatelessWidget {
  const RiderLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.delivery_dining, size: 64, color: AppTheme.primaryRed),
              const SizedBox(height: 16),
              const Text('Delivery Partner', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              const TextField(decoration: InputDecoration(labelText: 'Phone Number', prefixText: '+91 ')),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => context.go('/dashboard'), child: const Text('Send OTP')),
              Center(
                child: TextButton(onPressed: () => context.go('/onboarding'), child: const Text('New rider? Register')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
