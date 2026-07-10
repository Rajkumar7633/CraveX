import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark all read')),
        ],
      ),
      body: ListView.builder(
        itemCount: MockData.notifications.length,
        itemBuilder: (_, i) {
          final n = MockData.notifications[i];
          final read = n['read'] as bool;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: read ? Colors.grey[200] : AppTheme.primaryRed.withValues(alpha: 0.1),
              child: Icon(Icons.notifications, color: read ? Colors.grey : AppTheme.primaryRed),
            ),
            title: Text(n['title'] as String, style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n['body'] as String), Text(n['time'] as String, style: TextStyle(fontSize: 11, color: Colors.grey[600]))]),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}
