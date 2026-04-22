import 'package:curs_proj/services/api_services.dart';
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'gym_list_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiServices.login(
        _loginController.text.trim(),
        _passwordController.text.trim(),
      );
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
      setState(() => _error = 'Неверный логин или пароль');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // градиентная шапка сверху
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              gradient: AppStyles.primaryGradient,
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: Icon(Icons.fitness_center, size: 56, color: Colors.white),
                    ),
                    SizedBox(height: AppStyles.paddingMedium),
                    Text(
                      'GYM CATALOG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Найди свой зал',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // карточка формы поверх
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: AppStyles.paddingLarge + 8,
                left: AppStyles.paddingLarge,
                right: AppStyles.paddingLarge,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppStyles.paddingLarge,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: AppStyles.paddingLarge),
                      Text('Вход', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Войдите, чтобы продолжить', style: AppStyles.subtitleStyle),
                      SizedBox(height: AppStyles.paddingLarge),
                      TextFormField(
                        controller: _loginController,
                        decoration: InputDecoration(
                          labelText: 'Логин',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Введите логин';
                          if (t.length < 3) return 'Минимум 3 символа';
                          return null;
                        },
                      ),
                      SizedBox(height: AppStyles.paddingMedium),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Введите пароль' : null,
                      ),
                      if (_error != null) ...[
                        SizedBox(height: AppStyles.paddingSmall),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppStyles.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppStyles.errorColor, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!, style: TextStyle(color: AppStyles.errorColor)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: AppStyles.paddingLarge),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('ВОЙТИ', style: TextStyle(fontSize: 16, letterSpacing: 1)),
                        ),
                      ),
                      SizedBox(height: AppStyles.paddingMedium),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterScreen()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: AppStyles.subtitleStyle.color),
                            children: [
                              TextSpan(text: 'Нет аккаунта? '),
                              TextSpan(
                                text: 'Зарегистрироваться',
                                style: TextStyle(
                                  color: AppStyles.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}