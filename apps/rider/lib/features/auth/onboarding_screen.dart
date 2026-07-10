import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';

class RiderOnboardingScreen extends StatefulWidget {
  const RiderOnboardingScreen({super.key});

  @override
  State<RiderOnboardingScreen> createState() => _RiderOnboardingScreenState();
}

class _RiderOnboardingScreenState extends State<RiderOnboardingScreen> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rider Registration')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step < 4) setState(() => _step++);
          else context.go('/dashboard');
        },
        onStepCancel: () { if (_step > 0) setState(() => _step--); },
        steps: [
          Step(title: const Text('Personal Details'), content: const Column(children: [
            TextField(decoration: InputDecoration(labelText: 'Full Name')),
            TextField(decoration: InputDecoration(labelText: 'Phone')),
          ]), isActive: _step >= 0),
          Step(title: const Text('Documents'), content: Column(children: [
            _upload('Driving License'), _upload('Vehicle RC'), _upload('Aadhaar/PAN'),
          ]), isActive: _step >= 1),
          Step(title: const Text('Vehicle'), content: DropdownButtonFormField(
            items: ['Bike', 'Scooter', 'Bicycle', 'On Foot'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (_) {},
            decoration: const InputDecoration(labelText: 'Vehicle Type'),
          ), isActive: _step >= 2),
          Step(title: const Text('Bank Details'), content: const Column(children: [
            TextField(decoration: InputDecoration(labelText: 'Account Number')),
            TextField(decoration: InputDecoration(labelText: 'IFSC')),
          ]), isActive: _step >= 3),
          Step(title: const Text('Verification'), content: const Column(children: [
            Icon(Icons.hourglass_top, size: 48, color: AppTheme.primaryRed),
            Text('Background verification in progress'),
            Text('Usually takes 24-48 hours', style: TextStyle(color: Colors.grey)),
          ]), isActive: _step >= 4),
        ],
      ),
    );
  }

  Widget _upload(String label) => ListTile(
    leading: const Icon(Icons.upload),
    title: Text(label),
    trailing: TextButton(onPressed: () {}, child: const Text('Upload')),
  );
}
