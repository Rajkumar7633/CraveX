import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';

class DeliveryScreen extends StatefulWidget {
  final String orderId;
  const DeliveryScreen({super.key, required this.orderId});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  int _step = 0;
  final _steps = [
    'Navigate to Restaurant',
    'Arrived at Restaurant',
    'Pickup OTP Verification',
    'Navigate to Customer',
    'Arrived at Customer',
    'Delivery Complete',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delivery #${widget.orderId.substring(widget.orderId.length - 6)}')),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / _steps.length, color: AppTheme.primaryRed),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation, size: 48),
                      Text('Turn-by-turn navigation'),
                      Text('Google Maps integration', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )),
                ),
                const SizedBox(height: 24),
                ..._steps.asMap().entries.map((e) {
                  final done = e.key < _step;
                  final active = e.key == _step;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: done ? Colors.green : active ? AppTheme.primaryRed : Colors.grey[300],
                      child: done ? const Icon(Icons.check, color: Colors.white, size: 18) : Text('${e.key + 1}'),
                    ),
                    title: Text(e.value, style: TextStyle(fontWeight: active ? FontWeight.bold : null)),
                  );
                }),
                if (_step == 2) ...[
                  const TextField(decoration: InputDecoration(labelText: 'Enter Pickup OTP', hintText: '1234')),
                ],
                if (_step == 5) ...[
                  const TextField(decoration: InputDecoration(labelText: 'Delivery OTP from Customer')),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Photo proof of delivery'),
                    trailing: ElevatedButton(onPressed: () {}, child: const Text('Capture')),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_step < _steps.length - 1)
                  ElevatedButton(
                    onPressed: () => setState(() => _step++),
                    child: Text(_stepButtonLabel()),
                  )
                else
                  ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Complete Delivery'),
                  ),
                if (_step > 0 && _step < _steps.length - 1)
                  TextButton(onPressed: () {}, child: const Text('Report Issue')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stepButtonLabel() {
    switch (_step) {
      case 0: return 'Start Navigation to Restaurant';
      case 1: return 'Confirm Arrival at Restaurant';
      case 2: return 'Confirm Pickup';
      case 3: return 'Start Navigation to Customer';
      case 4: return 'Confirm Arrival at Customer';
      default: return 'Next';
    }
  }
}
