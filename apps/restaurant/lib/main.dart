import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/menu/menu_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/reviews/reviews_screen.dart';
import 'features/promotions/promotions_screen.dart';
import 'features/settings/settings_screen.dart';

void main() {
  runApp(const RestaurantApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const RestaurantLoginScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const RestaurantOnboardingScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
    GoRoute(path: '/menu', builder: (_, __) => const MenuScreen()),
    GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
    GoRoute(path: '/reviews', builder: (_, __) => const ReviewsScreen()),
    GoRoute(path: '/promotions', builder: (_, __) => const PromotionsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const RestaurantSettingsScreen()),
  ],
);

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Restaurant Partner',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
