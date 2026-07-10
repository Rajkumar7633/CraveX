import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.primaryRed.withValues(alpha: 0.05),
            child: const ListTile(
              leading: Icon(Icons.smart_toy, color: AppTheme.primaryRed),
              title: Text('AI Support Chatbot'),
              subtitle: Text('Ask about order status, refunds, FAQs'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Frequently Asked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...['How do I track my order?', 'How to get a refund?', 'How to apply coupon?', 'How to cancel order?'].map((q) => ExpansionTile(title: Text(q, style: const TextStyle(fontSize: 14)), children: const [Padding(padding: EdgeInsets.all(16), child: Text('Our support team will help you with this. You can also raise a ticket below.'))])),
          const SizedBox(height: 16),
          const Text('Raise a Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField(
            decoration: const InputDecoration(labelText: 'Issue Type'),
            items: const [
              DropdownMenuItem(value: 'order', child: Text('Order issue')),
              DropdownMenuItem(value: 'payment', child: Text('Payment issue')),
              DropdownMenuItem(value: 'delivery', child: Text('Delivery issue')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 8),
          TextField(controller: _messageCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Describe your issue')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket raised — TKT-004'))), child: const Text('Submit Ticket')),
        ],
      ),
    );
  }
}
