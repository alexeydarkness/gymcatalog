import 'dart:io';

import 'package:curs_proj/providers/gym_provider.dart';
import 'package:curs_proj/providers/theme_provider.dart';
import 'package:curs_proj/screens/gym_detail_screen.dart';
import 'package:curs_proj/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';
import 'compare_screen.dart';
import 'filter_screen.dart';
import 'gym_edit_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'trash_screen.dart';
import 'login_screen.dart';

class GymListScreen extends StatefulWidget {
  final String role;
  final String username;

  const GymListScreen({required this.role, required this.username});

  @override
  State<GymListScreen> createState() => _GymListScreenState();
}

class _GymListScreenState extends State<GymListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GymProvider>();
      provider.setRole(widget.role);
      provider.setUsername(widget.username);
      provider.loadGyms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GymProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Каталог залов'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort),
            tooltip: 'Сортировка',
            onSelected: (o) => provider.setSortOption(o),
            itemBuilder: (context) => [
              PopupMenuItem(value: SortOption.none, child: Text('Без сортировки')),
              PopupMenuItem(value: SortOption.ratingDesc, child: Text('По рейтингу ↓')),
              PopupMenuItem(value: SortOption.priceAsc, child: Text('По цене ↑')),
              PopupMenuItem(value: SortOption.priceDesc, child: Text('По цене ↓')),
              PopupMenuItem(value: SortOption.nameAsc, child: Text('По названию А–Я')),
            ],
          ),
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FilterScreen(
                    selectedType: provider.selectedType,
                    selectedAmenities: provider.selectedAmenities,
                    priceRange: provider.priceRange,
                    minPrice: provider.minPrice,
                    maxPrice: provider.maxPrice,
                  ),
                ),
              );
              if (result != null) {
                provider.setFilters(
                  result['type'],
                  List<String>.from(result['amenities']),
                  priceRange: result['priceRange'],
                );
              }
            },
            icon: Icon(Icons.tune),
          ),
        ],
      ),
      drawer: _buildDrawer(provider),
      floatingActionButton: widget.role == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final newGym = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GymEditScreen()),
                );
                if (newGym != null) {
                  try {
                    await provider.createGym(newGym);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка при создании: $e')),
                    );
                  }
                }
              },
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add),
              label: Text('Добавить'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppStyles.paddingMedium,
              AppStyles.paddingSmall,
              AppStyles.paddingMedium,
              AppStyles.paddingSmall,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по названию или адресу',
                prefixIcon: Icon(Icons.search),
                suffixIcon: provider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () => provider.setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: (v) => provider.setSearchQuery(v),
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(GymProvider provider) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: AppStyles.primaryColor));
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppStyles.errorColor),
            SizedBox(height: 8),
            Text('Ошибка: ${provider.error}'),
            SizedBox(height: 12),
            ElevatedButton(onPressed: () => provider.loadGyms(), child: Text('Повторить')),
          ],
        ),
      );
    }
    final gyms = provider.displayedGyms;

    return RefreshIndicator(
      color: AppStyles.primaryColor,
      onRefresh: () => provider.loadGyms(),
      child: gyms.isEmpty
          ? ListView(
              children: [
                SizedBox(height: 150),
                Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Center(child: Text('Ничего не найдено', style: AppStyles.subtitleStyle)),
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.only(bottom: 100),
              itemCount: gyms.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == gyms.length) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppStyles.paddingMedium),
                      child: OutlinedButton.icon(
                        onPressed: () => provider.loadMore(),
                        icon: Icon(Icons.expand_more),
                        label: Text('Загрузить ещё'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppStyles.primaryColor,
                          side: BorderSide(color: AppStyles.primaryColor),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  );
                }
                return TweenAnimationBuilder<double>(
                  key: ValueKey(gyms[index].id),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: child,
                      ),
                    );
                  },
                  child: _buildGymCard(provider, gyms[index]),
                );
              },
            ),
    );
  }

  Widget _buildGymCard(GymProvider provider, Gym gym) {
    final inCompare = provider.isInCompare(gym.id);

    final card = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppStyles.paddingMedium,
        vertical: AppStyles.paddingSmall,
      ),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GymDetailScreen(gym: gym, role: widget.role),
              ),
            );
            if (result != null && result is Gym) {
              try {
                await provider.updateGym(result);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка обновления: $e')),
                );
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'gym-image-${gym.id}',
                    child: gym.imageUrl.isNotEmpty
                        ? Image.network(
                            gym.imageUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          )
                        : _imageFallback(),
                  ),
                  // градиент снизу для читаемости плашек
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.55),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // плашка с типом зала
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                      ),
                      child: Text(
                        gym.type.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  // кнопки в правом верхнем углу
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _circleIcon(
                          icon: inCompare ? Icons.check : Icons.compare_arrows,
                          color: inCompare ? AppStyles.primaryColor : Colors.white,
                          bg: inCompare ? Colors.white : Colors.black.withOpacity(0.45),
                          onTap: () {
                            if (!inCompare && !provider.canAddMoreToCompare) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Максимум ${GymProvider.maxCompare} зала для сравнения'),
                                ),
                              );
                              return;
                            }
                            provider.toggleCompare(gym.id);
                          },
                        ),
                        SizedBox(width: 6),
                        _circleIcon(
                          icon: gym.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: gym.isFavorite ? AppStyles.primaryColor : Colors.white,
                          bg: gym.isFavorite ? Colors.white : Colors.black.withOpacity(0.45),
                          onTap: () => provider.toggleFavorite(gym),
                        ),
                      ],
                    ),
                  ),
                  // рейтинг поверх картинки
                  if (gym.rating > 0)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 15),
                            SizedBox(width: 4),
                            Text(
                              gym.rating.toStringAsFixed(1),
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(AppStyles.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gym.name,
                      style: AppStyles.titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            gym.address,
                            style: AppStyles.subtitleStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppStyles.paddingSmall),
                    Row(
                      children: [
                        if (gym.rating == 0)
                          Text('Нет оценок', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Spacer(),
                        Text('${gym.pricePerMonth.toInt()} ₽', style: AppStyles.priceStyle),
                        Text(' /мес', style: AppStyles.subtitleStyle),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.role == 'admin') {
      return Dismissible(
        key: Key(gym.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppStyles.paddingMedium,
            vertical: AppStyles.paddingSmall,
          ),
          decoration: BoxDecoration(
            color: AppStyles.errorColor,
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 24),
          child: Icon(Icons.delete, color: Colors.white, size: 28),
        ),
        confirmDismiss: (_) async {
          try {
            await provider.deleteGym(gym.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${gym.name} удалён')),
            );
            return true;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка удаления: $e')),
            );
            return false;
          }
        },
        child: card,
      );
    }
    return card;
  }

  Widget _imageFallback() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(gradient: AppStyles.primaryGradient),
      child: Icon(Icons.fitness_center, size: 60, color: Colors.white.withOpacity(0.5)),
    );
  }

  Widget _circleIcon({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      shape: CircleBorder(),
      child: InkWell(
        customBorder: CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: TweenAnimationBuilder<double>(
            // ключ к иконке — при смене перезапускаем анимацию
            key: ValueKey(icon.codePoint),
            tween: Tween(begin: 0.5, end: 1.0),
            duration: Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Icon(icon, color: color, size: 20),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(GymProvider provider) {
    final themeProvider = context.watch<ThemeProvider>();
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppStyles.paddingLarge),
              decoration: BoxDecoration(gradient: AppStyles.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      widget.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                      size: 36,
                      color: AppStyles.primaryColor,
                    ),
                  ),
                  SizedBox(height: AppStyles.paddingMedium),
                  Text(
                    provider.username.isNotEmpty ? provider.username : '—',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    widget.role == 'admin' ? 'Администратор' : 'Пользователь',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            _drawerItem(
              icon: Icons.fitness_center,
              label: 'Каталог',
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(
              icon: Icons.favorite_outline,
              label: 'Избранное',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FavoritesScreen(gyms: provider.gyms),
                  ),
                );
              },
            ),
            _drawerItem(
              icon: Icons.compare_arrows,
              label: 'Сравнение',
              badge: provider.compareCount > 0 ? '${provider.compareCount}' : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => CompareScreen()));
              },
            ),
            if (widget.role == 'admin')
              _drawerItem(
                icon: Icons.delete_outline,
                label: 'Корзина',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TrashScreen()),
                  ).then((_) => provider.loadGyms());
                },
              ),
            _drawerItem(
              icon: Icons.person_outline,
              label: 'Профиль',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(role: widget.role, gyms: provider.gyms),
                  ),
                );
              },
            ),
            Divider(),
            SwitchListTile(
              secondary: Icon(themeProvider.isDark ? Icons.dark_mode : Icons.light_mode),
              title: Text('Тёмная тема'),
              value: themeProvider.isDark,
              activeColor: AppStyles.primaryColor,
              onChanged: (_) => themeProvider.toggle(),
            ),
            Spacer(),
            Divider(height: 1),
            _drawerItem(
              icon: Icons.logout,
              label: 'Выйти',
              color: AppStyles.errorColor,
              onTap: () {
                ApiServices.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (_) => false,
                );
              },
            ),
            _drawerItem(
              icon: Icons.exit_to_app,
              label: 'Закрыть приложение',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Выход'),
                    content: Text('Закрыть приложение?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('Нет')),
                      TextButton(onPressed: () => exit(0), child: Text('Да')),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
    String? badge,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      trailing: badge != null
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppStyles.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}