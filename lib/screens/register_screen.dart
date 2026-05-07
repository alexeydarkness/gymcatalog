import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../services/api_services.dart';
import 'gym_list_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiServices.register(
        _loginController.text.trim(),
        _passwordController.text.trim(),
        _role,
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
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(gradient: AppStyles.primaryGradient),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
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
                          child: Icon(Icons.person_add_alt_1, size: 48, color: Colors.white),
                        ),
                        SizedBox(height: AppStyles.paddingMedium),
                        Text(
                          'РЕГИСТРАЦИЯ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                      Text('Создать аккаунт', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Заполните поля ниже', style: AppStyles.subtitleStyle),
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
                          if (t.length > 20) return 'Максимум 20 символов';
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(t)) {
                            return 'Только латиница, цифры и _';
                          }
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Введите пароль';
                          if (v.length < 6) return 'Минимум 6 символов';
                          return null;
                        },
                      ),
                      SizedBox(height: AppStyles.paddingMedium),
                      // выбор роли — сегментный контрол
                      Text('Роль', style: AppStyles.subtitleStyle),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _roleChip('user', 'Пользователь', Icons.person)),
                          SizedBox(width: 8),
                          Expanded(child: _roleChip('admin', 'Администратор', Icons.admin_panel_settings)),
                        ],
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
                              Expanded(child: Text(_error!, style: TextStyle(color: AppStyles.errorColor))),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: AppStyles.paddingLarge),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _register,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('СОЗДАТЬ АККАУНТ', style: TextStyle(fontSize: 15, letterSpacing: 1)),
                        ),
                      ),
                      SizedBox(height: AppStyles.paddingMedium),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: AppStyles.subtitleStyle.color),
                            children: [
                              TextSpan(text: 'Уже есть аккаунт? '),
                              TextSpan(
                                text: 'Войти',
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

  Widget _roleChip(String value, String label, IconData icon) {
    final selected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppStyles.primaryColor : Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall + 4),
          border: Border.all(
            color: selected ? AppStyles.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : null, size: 22),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}