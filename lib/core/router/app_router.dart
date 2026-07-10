import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zomato_clone/presentation/pages/user/home_page.dart';
import 'package:zomato_clone/presentation/pages/user/login_page.dart';
import 'package:zomato_clone/presentation/pages/user/register_page.dart';
import 'package:zomato_clone/presentation/pages/user/splash_page.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String restaurantDetails = '/restaurant/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderTracking = '/order/:id';
  static const String profile = '/profile';
  static const String orders = '/orders';
  static const String favorites = '/favorites';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: restaurantDetails,
        name: 'restaurantDetails',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RestaurantDetailPage(restaurantId: id);
        },
      ),
      GoRoute(
        path: cart,
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: checkout,
        name: 'checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: orderTracking,
        name: 'orderTracking',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderTrackingPage(orderId: id);
        },
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: orders,
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: favorites,
        name: 'favorites',
        builder: (context, state) => const FavoritesPage(),
      ),
    ],
  );
}
