import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Restaurant> _results = [];
  final _history = ['Biryani', 'Pizza', 'Meghana Foods', 'Domino\'s'];

  void _search(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _results = MockData.restaurants
          .where((r) =>
              r.name.toLowerCase().contains(query.toLowerCase()) ||
              r.cuisines.any((c) => c.toLowerCase().contains(query.toLowerCase())))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search dishes, restaurants...', border: InputBorder.none),
          onChanged: _search,
        ),
        actions: [IconButton(icon: const Icon(Icons.mic), onPressed: () {})],
      ),
      body: _results.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Trending Searches', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _history
                      .map((h) => ActionChip(
                            label: Text(h),
                            onPressed: () {
                              _controller.text = h;
                              _search(h);
                            },
                          ))
                      .toList(),
                ),
              ],
            )
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) => RestaurantCard(
                restaurant: _results[i],
                onTap: () => context.push('/restaurant/${_results[i].id}'),
              ),
            ),
    );
  }
}
