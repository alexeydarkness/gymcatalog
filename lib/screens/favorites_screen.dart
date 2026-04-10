import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';
import 'gym_detail_screen.dart';

class FavoritesScreen extends StatelessWidget{
  final List<Gym> gyms;

  const FavoritesScreen({required this.gyms});

  List<Gym> get favorites => gyms.where((g) => g.isFavorite).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Избранное'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: favorites.isEmpty ? Center(child: Text('Нет избранных залов', style: AppStyles.subtitleStyle)) : ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final gym = favorites[index];
          return Card(
            margin: EdgeInsets.all(AppStyles.paddingSmall),
            child: ListTile(
              title: Text(gym.name, style: AppStyles.subtitleStyle),
              trailing: Text('${gym.rating}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GymDetailScreen(gym: gym),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}