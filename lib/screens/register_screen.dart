import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../services/api_services.dart';
import 'gym_list_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RegisterScreenState();

}

class _RegisterScreenState extends State<RegisterScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'user';
  String? _error;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_isLoading) return;

    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();
    

    if (login.isEmpty || password.isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }

    try {
      final result = await ApiServices.register(login, password, _role);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GymListScreen(
            role: result['role'],
            username: result['username'],
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
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
                    child: Icon(Icons.person_add, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: AppStyles.paddingMedium),
                  Text('Регистрация', style: AppStyles.titleStyle),
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
                  SizedBox(height: AppStyles.paddingLarge),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),                      
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ), 
                  SizedBox(height: AppStyles.paddingMedium),
                  DropdownButtonFormField<String>(
                    value: _role, 
                    decoration: InputDecoration(
                      labelText: 'Роль',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 'user', child: Text('Пользователь')),
                      DropdownMenuItem(value: 'admin', child: Text('Администратор'))
                    ],
                    onChanged: (value) => setState(() => _role = value!),
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
                      onPressed: _register,
                      child: _isLoading 
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Зарегистрироваться', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: AppStyles.paddingSmall),
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: Text('Уже есть аккаунт? Войти')
                  ),                              
                ],
              ),
            ),
          ),
        )
      ),
    );
  }
}
