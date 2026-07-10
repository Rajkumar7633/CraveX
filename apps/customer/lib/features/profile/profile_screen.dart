import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.demoUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: AppTheme.primaryRed.withValues(alpha: 0.05),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryRed,
                  child: Text(user.name[0], style: const TextStyle(color: Colors.white, fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(user.phone ?? user.email ?? ''),
                      if (user.isGoldMember)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(4)),
                          child: const Text('GOLD MEMBER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/profile/edit')),
              ],
            ),
          ),
          _tile(Icons.location_on, 'Manage Addresses', () => context.push('/addresses')),
          _tile(Icons.favorite, 'Favorites', () => context.push('/favorites')),
          _tile(Icons.account_balance_wallet, 'Wallet & Credits', () => context.push('/wallet'), subtitle: '₹${user.walletBalance.toInt()}'),
          _tile(Icons.receipt_long, 'Order History', () => context.push('/orders')),
          _tile(Icons.payment, 'Payment Methods', () => context.push('/payment-methods')),
          _tile(Icons.card_giftcard, 'Refer & Earn', () {}, subtitle: 'Code: ${user.referralCode}'),
          _tile(Icons.workspace_premium, 'Gold Membership', () => context.push('/gold')),
          _tile(Icons.notifications, 'Notifications', () => context.push('/notifications')),
          _tile(Icons.help, 'Help & Support', () => context.push('/help')),
          _tile(Icons.settings, 'Settings', () => context.push('/settings')),
          _tile(Icons.dark_mode, 'Dark Mode', () => context.push('/settings')),
          _tile(Icons.language, 'Language', () => context.push('/settings')),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.primaryRed),
            title: const Text('Logout', style: TextStyle(color: AppTheme.primaryRed)),
            onTap: () => context.go('/login'),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red[300]),
            title: Text('Delete Account', style: TextStyle(color: Colors.red[300])),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
