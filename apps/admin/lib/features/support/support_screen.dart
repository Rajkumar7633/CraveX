import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => SupportScreenState();
}

class SupportScreenState extends State<SupportScreen> {
  String _filter = 'open';

  @override
  Widget build(BuildContext context) {
    final tickets = MockData.supportTickets.where((t) => _filter == 'all' || t.status == _filter).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Moderation'),
        actions: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'open', label: Text('Open')),
              ButtonSegment(value: 'in_progress', label: Text('In Progress')),
              ButtonSegment(value: 'resolved', label: Text('Resolved')),
              ButtonSegment(value: 'all', label: Text('All')),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (_, i) {
                final t = tickets[i];
                return Card(
                  child: ListTile(
                    leading: _priorityIcon(t.priority),
                    title: Text(t.subject),
                    subtitle: Text('${t.customerName} • ${t.createdAt.day}/${t.createdAt.month}'),
                    trailing: Chip(label: Text(t.status.replaceAll('_', ' '))),
                    onTap: () => _showTicketDetail(t),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fraud Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...MockData.fraudAlerts.map((f) => Card(
                        color: Colors.red[50],
                        child: ListTile(
                          leading: const Icon(Icons.warning, color: Colors.red),
                          title: Text(f['title'] as String, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(f['detail'] as String, style: const TextStyle(fontSize: 11)),
                        ),
                      )),
                  const SizedBox(height: 16),
                  const Text('Review Moderation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ...MockData.flaggedReviews.map((r) => ListTile(
                        dense: true,
                        title: Text(r['review'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () {}),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityIcon(String priority) {
    final color = switch (priority) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      _ => Colors.grey,
    };
    return Icon(Icons.support_agent, color: color);
  }

  void _showTicketDetail(SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(ticket.subject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${ticket.customerName}'),
            Text('Priority: ${ticket.priority}'),
            Text('Status: ${ticket.status}'),
            const SizedBox(height: 16),
            const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Reply')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket updated'))); }, child: const Text('Update')),
        ],
      ),
    );
  }
}
