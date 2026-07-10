import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _darkMode = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold))),
          SwitchListTile(title: const Text('Order updates'), value: _orderUpdates, onChanged: (v) => setState(() => _orderUpdates = v)),
          SwitchListTile(title: const Text('Promotions & offers'), value: _promotions, onChanged: (v) => setState(() => _promotions = v)),
          const Divider(),
          const ListTile(title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold))),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: _darkMode,
            onChanged: (v) async {
              setState(() => _darkMode = v);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('dark_mode', v);
            },
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(),
          ),
          const Divider(),
          const ListTile(title: Text('Accessibility', style: TextStyle(fontWeight: FontWeight.bold))),
          SwitchListTile(title: const Text('Large text'), value: false, onChanged: (_) {}),
          SwitchListTile(title: const Text('Screen reader support'), value: false, onChanged: (_) {}),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: ['English', 'Hindi', 'Kannada', 'Tamil', 'Telugu'].map((l) => ListTile(
              title: Text(l),
              trailing: _language == l ? const Icon(Icons.check, color: AppTheme.primaryRed) : null,
              onTap: () { setState(() => _language = l); Navigator.pop(context); },
            )).toList(),
      ),
    );
  }
}
