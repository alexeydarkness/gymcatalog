import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';

class GymDetailScreen extends StatelessWidget{
  final Gym gym;
  
  const GymDetailScreen({required this.gym});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(gym.name),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (gym.imageUrl.isNotEmpty)
              Image.network(
                gym.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),

            SizedBox(height: AppStyles.paddingMedium),
            Text(gym.name, style: AppStyles.titleStyle),
            SizedBox(height: AppStyles.paddingSmall),
            Text(gym.address, style: AppStyles.subtitleStyle),
            SizedBox(height: AppStyles.paddingSmall),
            Text('Рейтинг: ${gym.rating} ⭐'),
            SizedBox(height: AppStyles.paddingSmall),
            Text('Цена: ${gym.pricePerMonth} ₽/мес', style: AppStyles.priceStyle),
            SizedBox(height: AppStyles.paddingSmall),
            Text('Тип: ${gym.type}'),
            SizedBox(height: AppStyles.paddingMedium),
            Text('Удобства:', style: AppStyles.titleStyle),
            SizedBox(height: AppStyles.paddingSmall),
            Wrap(
              spacing: 0,
              children: gym.amenities.map((a) => Chip(label: Text(a))).toList(),
              ),                                  
          ],
        ),
      )
    );
  }
}

