import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/delivery/delivery_screen.dart';
import 'features/earnings/earnings_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/support/support_screen.dart';

void main() {
  runApp(const RiderApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const RiderLoginScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const RiderOnboardingScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const RiderDashboardScreen()),
    GoRoute(path: '/delivery/:orderId', builder: (_, s) => DeliveryScreen(orderId: s.pathParameters['orderId']!)),
    GoRoute(path: '/earnings', builder: (_, __) => const EarningsScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const RiderProfileScreen()),
    GoRoute(path: '/support', builder: (_, __) => const RiderSupportScreen()),
  ],
);

class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rider App',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
