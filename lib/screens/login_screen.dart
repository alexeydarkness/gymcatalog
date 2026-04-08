import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../services/storage_service.dart';
import 'gym_list_screen.dart';


class LoginScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _LoginScreenState();
    
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;


  final Map<String, Map<String, String>> _users = {
    'admin': {'password': 'admin123', 'role': 'admin'},
    'user': {'password': 'user123', 'role': 'user'},
  };

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();  
    super.dispose();
  }

  void _login() {
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (_users.containsKey(login) && _users[login]!['password'] == password) {
      final role = _users[login]!['role']!;
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (context) => GymListScreen(role: role),
        ),
      );
    } else {
      setState(() {
        _error = 'Неверный пароль или логин';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppStyles.paddingLarge),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppStyles.paddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppStyles.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fitness_center, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: AppStyles.paddingMedium),
                  Text('Каталог залов', style: AppStyles.titleStyle),
                  SizedBox(height: 4),
                  Text('Войдите в аккаунт', style: AppStyles.subtitleStyle),
                  SizedBox(height: AppStyles.paddingLarge),
                  TextField(
                    controller: _loginController,
                    decoration: InputDecoration(
                      labelText: 'Логин',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: AppStyles.paddingMedium),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.only(top: AppStyles.paddingSmall),
                      child: Text(_error!, style: TextStyle(color: AppStyles.errorColor)),
                    ),
                  SizedBox(height: AppStyles.paddingLarge),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Войти', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}