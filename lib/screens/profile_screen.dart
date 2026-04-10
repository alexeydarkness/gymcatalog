import 'package:curs_proj/services/api_services.dart';
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'login_screen.dart';
import '../models/gym.dart';

class ProfileScreen extends StatelessWidget {
  final String role;
  final List<Gym> gyms;

  int get favoritesCount => gyms.where((g) => g.isFavorite).length;

  const ProfileScreen({
    required this.role,
    required this.gyms,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          children: [
            Icon(Icons.account_circle, size: 100, color: AppStyles.primaryColor),
            SizedBox(height: AppStyles.paddingMedium),
            Text(
              role == 'admin' ? 'Администратор' : 'Пользователь',
              style: AppStyles.titleStyle,
            ),
            SizedBox(height: AppStyles.paddingSmall),
            Text(
              role == 'admin' ? 'admin' : 'user',
              style: AppStyles.subtitleStyle,
            ),
            SizedBox(height: AppStyles.paddingLarge),
            Card(
              child: ListTile(
                leading: Icon(Icons.favorite, color: Colors.red),
                title: Text('Избранных залов'),
                trailing: Text('$favoritesCount', style: AppStyles.titleStyle),
              ),
            ),
            SizedBox(height: AppStyles.paddingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ApiServices.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                }, 
                icon: Icon(Icons.logout),
                label: Text('Выйти'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.errorColor,
                  foregroundColor: Colors.white,
                ),
              ),
            )                        
          ],
        ),
      ),
    );
  }
}