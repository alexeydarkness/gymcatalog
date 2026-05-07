import 'package:curs_proj/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gym_provider.dart';
import '../styles/app_styles.dart';
import 'compare_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import '../models/gym.dart';

class ProfileScreen extends StatelessWidget {
  final String role;
  final List<Gym> gyms;

  const ProfileScreen({
    super.key,
    required this.role,
    required this.gyms,
  });

  int get favoritesCount => gyms.where((g) => g.isFavorite).length;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    final provider = context.watch<GymProvider>();
    final username = provider.username.isNotEmpty
        ? provider.username
        : (isAdmin ? 'admin' : 'user');
    final initial = username[0].toUpperCase();
    final compareCount = provider.compareCount;

    return Scaffold(
      backgroundColor: AppStyles.darkBg,
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: AppStyles.darkBg,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === Шапка профиля ===
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.5, -1),
                  end: const Alignment(1, 1),
                  colors: [
                    const Color(0xFF1A0505),
                    const Color(0xFF2A0808),
                    AppStyles.primaryColor.withValues(alpha: 0.2),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppStyles.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppStyles.primaryColor.withValues(alpha: 0.4),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppStyles.primaryColor.withValues(alpha: 0.13),
                          blurRadius: 0,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isAdmin ? 'Администратор' : 'Пользователь',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppStyles.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppStyles.textTertiary,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                        border: Border.all(
                          color: AppStyles.primaryColor.withValues(alpha: 0.27),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 14,
                            color: AppStyles.primaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Администратор',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppStyles.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // === Контент ===
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Статистика
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '$favoritesCount',
                          label: 'Избранных',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '$compareCount',
                          label: 'Сравнений',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '${gyms.length}',
                          label: 'Залов',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Меню
                  _MenuItem(
                    icon: Icons.favorite_outline,
                    iconColor: AppStyles.primaryColor,
                    label: 'Избранные залы',
                    badge: '$favoritesCount',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FavoritesScreen(gyms: gyms),
                      ),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.compare_arrows,
                    label: 'Сравнение залов',
                    badge: '$compareCount',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CompareScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Корзина',
                    badge: '0',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Корзина пока пуста')),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Кнопка выхода
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ApiServices.logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                          (_) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Выйти'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.darkSurface,
                        foregroundColor: AppStyles.errorColor,
                        side: BorderSide(
                          color: AppStyles.errorColor.withValues(alpha: 0.27),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppStyles.darkSurface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppStyles.darkBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppStyles.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppStyles.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    this.iconColor,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppStyles.darkSurface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(color: AppStyles.darkBorder),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? AppStyles.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppStyles.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
