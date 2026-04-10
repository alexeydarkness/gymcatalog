import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';
import 'gym_edit_screen.dart';

class GymDetailScreen extends StatelessWidget{
  final Gym gym;
  final String role;
  
  const GymDetailScreen({required this.gym, this.role = 'user'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(gym.name),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (role == 'admin')
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                final edited = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GymEditScreen(gym: gym)),
                );
                if (edited != null) {
                  Navigator.pop(context, edited);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (gym.imageUrl.isNotEmpty)
              Image.network(
                gym.imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: Icon(Icons.fitness_center, size: 60, color: Colors.grey),
                  );
                },
              ),
            Padding(
              padding: EdgeInsets.all(AppStyles.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gym.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: AppStyles.paddingSmall),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(child: Text(gym.address, style: AppStyles.subtitleStyle)),
                    ],
                  ),
                  SizedBox(height: AppStyles.paddingMedium),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppStyles.paddingMedium),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 28),
                              SizedBox(height: 4),
                              Text('${gym.rating}', style: AppStyles.titleStyle),
                              Text('Рейтинг', style: AppStyles.subtitleStyle),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.attach_money, color: Colors.green, size: 28),
                              SizedBox(height: 4),
                              Text('${gym.pricePerMonth.toInt()}', style: AppStyles.titleStyle),
                              Text('₽/мес', style: AppStyles.subtitleStyle),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.category, color: AppStyles.primaryColor, size: 28),
                              SizedBox(height: 4),
                              Text(gym.type, style: AppStyles.titleStyle),
                              Text('Тип', style: AppStyles.subtitleStyle),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppStyles.paddingMedium),
                  Text('Удобства', style: AppStyles.titleStyle),
                  SizedBox(height: AppStyles.paddingSmall),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: gym.amenities.map((a) {
                      return Chip(
                        avatar: Icon(_getAmenityIcon(a), size: 18),
                        label: Text(a),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
        switch (amenity) {
          case 'душ': return Icons.shower;
          case 'сауна': return Icons.hot_tub;
          case 'парковка': return Icons.local_parking;
          case 'тренер': return Icons.person;
          case 'Wi-Fi': return Icons.wifi;
          case 'бассейн': return Icons.pool;
          case 'ринг': return Icons.sports_mma;
          case 'чай': return Icons.local_cafe;
          default: return Icons.check_circle;
        }
  }
}

