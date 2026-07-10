import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/cart/checkout_screen.dart';
import '../features/home/home_screen.dart';
import '../features/orders/order_history_screen.dart';
import '../features/orders/order_tracking_screen.dart';
import '../features/profile/addresses_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/favorites_screen.dart';
import '../features/profile/gold_membership_screen.dart';
import '../features/profile/help_support_screen.dart';
import '../features/profile/notifications_screen.dart';
import '../features/profile/payment_methods_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/profile/wallet_screen.dart';
import '../features/restaurant/menu_item_detail_screen.dart';
import '../features/restaurant/restaurant_detail_screen.dart';
import '../features/search/search_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    GoRoute(
      path: '/restaurant/:id',
      builder: (_, state) => RestaurantDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/restaurant/:id/item/:itemId',
      builder: (_, state) => MenuItemDetailScreen(
        restaurantId: state.pathParameters['id']!,
        itemId: state.pathParameters['itemId']!,
      ),
    ),
    GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
    GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
    GoRoute(
      path: '/order/:id',
      builder: (_, state) => OrderTrackingScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
    GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
    GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/help', builder: (_, __) => const HelpSupportScreen()),
    GoRoute(path: '/gold', builder: (_, __) => const GoldMembershipScreen()),
    GoRoute(path: '/payment-methods', builder: (_, __) => const PaymentMethodsScreen()),
  ],
);
