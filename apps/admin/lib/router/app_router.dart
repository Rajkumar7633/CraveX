import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/content/content_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/finance/finance_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/restaurants/restaurants_screen.dart';
import '../features/riders/riders_screen.dart';
import '../features/shell/admin_shell.dart';
import '../features/support/support_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final adminRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const AdminLoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (_, __, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const AdminDashboardScreen()),
        GoRoute(path: '/restaurants', builder: (_, __) => const RestaurantsScreen()),
        GoRoute(path: '/riders', builder: (_, __) => const RidersScreen()),
        GoRoute(path: '/customers', builder: (_, __) => const CustomersScreen()),
        GoRoute(path: '/orders', builder: (_, __) => const AdminOrdersScreen()),
        GoRoute(path: '/content', builder: (_, __) => const ContentScreen()),
        GoRoute(path: '/finance', builder: (_, __) => const FinanceScreen()),
        GoRoute(path: '/analytics', builder: (_, __) => const AdminAnalyticsScreen()),
        GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
      ],
    ),
  ],
);
