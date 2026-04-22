import 'package:curs_proj/services/api_services.dart';
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'gym_list_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _LoginScreenState();
    
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final username = _loginController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiServices.login(username, password);
      if (!mounted) return;
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
      setState(() => _error = 'Неверный пароль или логин');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(AppStyles.paddingLarge),
              child: Form(
                key: _formKey,
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
                    TextFormField(
                      controller: _loginController,
                      decoration: InputDecoration(
                        labelText: 'Логин',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Введите логин';
                        if (v.length < 3) return 'Минимум 3 символа';
                        return null;
                      },
                    ),
                    SizedBox(height: AppStyles.paddingMedium),
                    TextFormField(
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
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите пароль';
                        return null;
                      },
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text('Войти', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    SizedBox(height: AppStyles.paddingSmall),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        );
                      },
                      child: Text('Нет аккаунта? Зарегистрироваться'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}