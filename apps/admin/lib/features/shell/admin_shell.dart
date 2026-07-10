import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    _NavItem('/dashboard', Icons.dashboard, 'Dashboard'),
    _NavItem('/restaurants', Icons.store, 'Restaurants'),
    _NavItem('/riders', Icons.delivery_dining, 'Riders'),
    _NavItem('/customers', Icons.people, 'Customers'),
    _NavItem('/orders', Icons.receipt_long, 'Orders'),
    _NavItem('/content', Icons.campaign, 'Content'),
    _NavItem('/finance', Icons.account_balance, 'Finance'),
    _NavItem('/analytics', Icons.analytics, 'Analytics'),
    _NavItem('/support', Icons.support_agent, 'Support'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    _selectedIndex = _destinations.indexWhere((d) => location.startsWith(d.path));
    if (_selectedIndex < 0) _selectedIndex = 0;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => context.go(_destinations[i].path),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: AppTheme.primaryRed),
            selectedLabelTextStyle: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Logout',
                    onPressed: () => context.go('/login'),
                  ),
                ),
              ),
            ),
            destinations: _destinations
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final String label;

  const _NavItem(this.path, this.icon, this.label);
}
