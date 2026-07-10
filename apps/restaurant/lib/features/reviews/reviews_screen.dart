import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:theme/app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _replyCtrl = TextEditingController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews & Ratings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('4.4', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RatingBarIndicator(rating: 4.4, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber), itemCount: 5, itemSize: 16),
                      Text('12,500 ratings', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...MockData.reviews.map((r) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 16, child: Text((r['user'] as String)[0])),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r['user'] as String, style: const TextStyle(fontWeight: FontWeight.bold)), Text(r['date'] as String, style: TextStyle(fontSize: 11, color: Colors.grey[600]))])),
                          RatingBarIndicator(rating: r['rating'] as double, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber), itemCount: 5, itemSize: 14),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(r['comment'] as String),
                      if ((r['photos'] as int) > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('📷 ${r['photos']} photos', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => _showReplyDialog(r['user'] as String), child: const Text('Reply')),
                          TextButton(onPressed: () {}, child: const Text('Flag')),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showReplyDialog(String user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reply to $user'),
        content: TextField(controller: _replyCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Write your reply...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply posted'))); }, child: const Text('Post')),
        ],
      ),
    );
  }
}
