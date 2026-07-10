import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';

class RestaurantLoginScreen extends StatelessWidget {
  const RestaurantLoginScreen({super.key});

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
              const Icon(Icons.restaurant, size: 64, color: AppTheme.primaryRed),
              const SizedBox(height: 16),
              const Text('Restaurant Partner', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Manage your restaurant on Zomato Clone'),
              const SizedBox(height: 32),
              const TextField(decoration: InputDecoration(labelText: 'Phone / Email', prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)), obscureText: true),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => context.go('/dashboard'), child: const Text('Login')),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/onboarding'),
                  child: const Text('New restaurant? Register here'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
