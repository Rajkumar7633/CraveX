import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardPage(
      icon: Icons.delivery_dining,
      title: 'Fast Delivery',
      subtitle: 'Get your favourite food delivered in minutes',
    ),
    _OnboardPage(
      icon: Icons.restaurant_menu,
      title: 'Thousands of Restaurants',
      subtitle: 'Discover cuisines from the best restaurants near you',
    ),
    _OnboardPage(
      icon: Icons.location_on,
      title: 'Live Tracking',
      subtitle: 'Track your order in real-time on the map',
    ),
    _OnboardPage(
      icon: Icons.card_giftcard,
      title: 'Rewards & Offers',
      subtitle: 'Earn points, get discounts, refer friends',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: const WormEffect(dotColor: Colors.grey, activeDotColor: AppTheme.primaryRed),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  if (_page < _pages.length - 1) {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                  } else {
                    context.go('/login');
                  }
                },
                child: Text(_page < _pages.length - 1 ? 'Next' : 'Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardPage({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: AppTheme.primaryRed),
          const SizedBox(height: 32),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
