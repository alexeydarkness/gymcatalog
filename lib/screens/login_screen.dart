import 'package:curs_proj/services/api_services.dart';
import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'gym_list_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
    return Scaffold(
      backgroundColor: AppStyles.darkBg,
      body: Stack(
        children: [
          // Градиентная шапка сверху, в духе hero-секций макета
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-0.6, -1),
                end: const Alignment(1, 1),
                colors: [
                  const Color(0xFF1A0505),
                  const Color(0xFF2A0808),
                  AppStyles.primaryColor.withValues(alpha: 0.27),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'GYM CATALOG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Найди свой зал',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Карточка формы
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: AppStyles.paddingLarge + 8,
                left: AppStyles.paddingLarge,
                right: AppStyles.paddingLarge,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    AppStyles.paddingLarge,
              ),
              decoration: const BoxDecoration(
                color: AppStyles.darkBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: AppStyles.darkBorder),
                ),
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
                            color: AppStyles.darkBorderHi,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppStyles.paddingLarge),
                      const Text(
                        'Вход',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppStyles.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Войдите, чтобы продолжить',
                        style: AppStyles.subtitleStyle,
                      ),
                      const SizedBox(height: AppStyles.paddingLarge),
                      TextFormField(
                        controller: _loginController,
                        style: const TextStyle(color: AppStyles.textPrimary),
                        decoration: const InputDecoration(
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
                      const SizedBox(height: AppStyles.paddingMedium),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppStyles.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Введите пароль' : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppStyles.paddingSmall),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppStyles.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppStyles.radiusMedium,
                            ),
                            border: Border.all(
                              color: AppStyles.errorColor.withValues(alpha: 0.27),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppStyles.errorColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppStyles.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppStyles.paddingLarge),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'ВОЙТИ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppStyles.paddingMedium),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: AppStyles.textTertiary),
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
