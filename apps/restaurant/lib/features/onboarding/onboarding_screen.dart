import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';

class RestaurantOnboardingScreen extends StatefulWidget {
  const RestaurantOnboardingScreen({super.key});

  @override
  State<RestaurantOnboardingScreen> createState() => _RestaurantOnboardingScreenState();
}

class _RestaurantOnboardingScreenState extends State<RestaurantOnboardingScreen> {
  int _step = 0;
  final _steps = [
    'Business Details',
    'Documents',
    'Bank Details',
    'Restaurant Photos',
    'Menu Setup',
    'Operating Hours',
    'Agreement',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Onboarding')),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / _steps.length, color: AppTheme.primaryRed),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _steps.asMap().entries.map((e) {
                final done = e.key <= _step;
                return Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: done ? AppTheme.primaryRed : Colors.grey[300],
                        child: Text('${e.key + 1}', style: TextStyle(fontSize: 10, color: done ? Colors.white : Colors.black)),
                      ),
                      const SizedBox(height: 4),
                      Text(e.value, style: TextStyle(fontSize: 8, color: done ? AppTheme.primaryRed : Colors.grey), textAlign: TextAlign.center),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(child: _buildStepContent()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_step > 0)
                  OutlinedButton(onPressed: () => setState(() => _step--), child: const Text('Back')),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_step < _steps.length - 1) {
                      setState(() => _step++);
                    } else {
                      context.go('/dashboard');
                    }
                  },
                  child: Text(_step < _steps.length - 1 ? 'Next' : 'Submit for Review'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _form([
          const TextField(decoration: InputDecoration(labelText: 'Restaurant Name')),
          const TextField(decoration: InputDecoration(labelText: 'Cuisine Type')),
          const TextField(decoration: InputDecoration(labelText: 'Address')),
          const TextField(decoration: InputDecoration(labelText: 'GST Number')),
        ]);
      case 1:
        return _form([
          _uploadTile('FSSAI License'),
          _uploadTile('PAN Card'),
          _uploadTile('Cancelled Cheque'),
        ]);
      case 2:
        return _form([
          const TextField(decoration: InputDecoration(labelText: 'Account Holder Name')),
          const TextField(decoration: InputDecoration(labelText: 'Account Number')),
          const TextField(decoration: InputDecoration(labelText: 'IFSC Code')),
        ]);
      case 3:
        return _form([_uploadTile('Exterior Photo'), _uploadTile('Interior Photo'), _uploadTile('Kitchen Photo')]);
      case 4:
        return _form([
          const Text('Menu categories and items can be added after approval'),
          ElevatedButton(onPressed: () {}, child: const Text('Upload Menu CSV')),
          OutlinedButton(onPressed: () {}, child: const Text('Add Items Manually')),
        ]);
      case 5:
        return _form([
          SwitchListTile(title: const Text('Monday'), subtitle: const Text('11 AM - 11 PM'), value: true, onChanged: (_) {}),
          SwitchListTile(title: const Text('Tuesday'), subtitle: const Text('11 AM - 11 PM'), value: true, onChanged: (_) {}),
          SwitchListTile(title: const Text('Sunday'), subtitle: const Text('Closed'), value: false, onChanged: (_) {}),
        ]);
      default:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.description, size: 64, color: AppTheme.primaryRed),
              const SizedBox(height: 16),
              const Text('Terms & Conditions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(child: SingleChildScrollView(child: Text('By signing up, you agree to our partner terms...' * 5))),
              CheckboxListTile(title: const Text('I agree to the terms'), value: true, onChanged: (_) {}),
            ],
          ),
        );
    }
  }

  Widget _form(List<Widget> children) {
    return ListView(padding: const EdgeInsets.all(24), children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList());
  }

  Widget _uploadTile(String label) => ListTile(
        leading: const Icon(Icons.upload_file),
        title: Text(label),
        trailing: ElevatedButton(onPressed: () {}, child: const Text('Upload')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey[300]!)),
      );
}
