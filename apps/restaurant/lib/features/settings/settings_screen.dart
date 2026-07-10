import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  bool _orderSound = true;
  bool _pushNotif = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Restaurant Profile', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.store), title: const Text('Meghana Foods'), subtitle: const Text('Edit restaurant details'), onTap: () {}),
          ListTile(leading: const Icon(Icons.schedule), title: const Text('Operating Hours'), subtitle: const Text('Mon-Sun: 11 AM - 11 PM'), onTap: () {}),
          const Divider(),
          const ListTile(title: Text('Staff Management', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.person), title: const Text('Manager — Rajesh'), subtitle: const Text('Full access'), trailing: const Icon(Icons.chevron_right)),
          ListTile(leading: const Icon(Icons.person), title: const Text('Chef — Kumar'), subtitle: const Text('Orders & Menu'), trailing: const Icon(Icons.chevron_right)),
          ListTile(leading: const Icon(Icons.add), title: const Text('Add Staff Member'), onTap: () {}),
          const Divider(),
          const ListTile(title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold))),
          SwitchListTile(title: const Text('Order sound alert'), value: _orderSound, onChanged: (v) => setState(() => _orderSound = v)),
          SwitchListTile(title: const Text('Push notifications'), value: _pushNotif, onChanged: (v) => setState(() => _pushNotif = v)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Help & Support'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.primaryRed),
            title: const Text('Logout', style: TextStyle(color: AppTheme.primaryRed)),
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
