import 'package:core/core.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favorites = MockData.restaurants.take(2).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _favorites.isEmpty
          ? const Center(child: Text('No favorites yet'))
          : ListView.builder(
              itemCount: _favorites.length,
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text(_favorites[i].name),
                subtitle: Text(_favorites[i].cuisines.join(', ')),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => setState(() => _favorites.removeAt(i)),
                ),
              ),
            ),
    );
  }
}
