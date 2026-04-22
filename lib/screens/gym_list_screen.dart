import 'dart:io';

import 'package:curs_proj/providers/gym_provider.dart';
import 'package:curs_proj/screens/gym_detail_screen.dart';
import 'package:curs_proj/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';
import 'filter_screen.dart';
import 'gym_edit_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'trash_screen.dart';
import 'compare_screen.dart';
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
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort),
            tooltip: 'Сортировка',
            onSelected: (option) => provider.setSortOption(option),
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
                  builder: (context) => FilterScreen(
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
            icon: Icon(Icons.filter_list),
          ),
        ],
      ),
      drawer: _buildDrawer(provider),
      floatingActionButton: widget.role == 'admin'
          ? FloatingActionButton(
              onPressed: () async {
                final newGym = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GymEditScreen()),
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
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppStyles.paddingMedium),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => provider.setSearchQuery(value),
            ),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(GymProvider provider) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Ошибка ${provider.error}'));
    }
    final gyms = provider.displayedGyms;

    return RefreshIndicator(
      onRefresh: () => provider.loadGyms(),
      child: gyms.isEmpty
          ? ListView(
              children: [
                SizedBox(height: 200),
                Center(child: Text('Список пуст', style: AppStyles.subtitleStyle)),
              ],
            )
          : ListView.builder(
              itemCount: gyms.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == gyms.length) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppStyles.paddingMedium),
                      child: ElevatedButton(
                        onPressed: () => provider.loadMore(),
                        child: Text("Загрузить еще"),
                      ),
                    ),
                  );
                }
                final gym = gyms[index];
                final card = Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(
                    horizontal: AppStyles.paddingMedium,
                    vertical: AppStyles.paddingSmall,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (gym.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            gym.imageUrl,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: Icon(Icons.fitness_center, size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ListTile(
                        title: Text(gym.name, style: AppStyles.titleStyle),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(child: Text(gym.address, style: AppStyles.subtitleStyle)),
                              ],
                            ),
                            SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            SizedBox(width: 2),
                            Text(
                              gym.rating > 0 ? gym.rating.toStringAsFixed(1) : 'Нет оценок',
                              style: TextStyle(
                                fontSize: 14,
                                color: gym.rating > 0 ? Colors.black87 : Colors.grey,
                              ),
                            ),
                            Spacer(),
                            Text('${gym.pricePerMonth.toInt()} ₽/мес', style: AppStyles.priceStyle),
                          ],
                        ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: provider.isInCompare(gym.id)
                                  ? 'Убрать из сравнения'
                                  : 'В сравнение',
                              onPressed: () {
                                final inCompare = provider.isInCompare(gym.id);
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
                              icon: Icon(
                                provider.isInCompare(gym.id)
                                    ? Icons.check_box
                                    : Icons.compare_arrows,
                                color: provider.isInCompare(gym.id) ? AppStyles.primaryColor : null,
                              ),
                            ),
                            IconButton(
                              onPressed: () => provider.toggleFavorite(gym),
                              icon: Icon(
                                gym.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: gym.isFavorite ? Colors.red : null,
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GymDetailScreen(gym: gym, role: widget.role),
                            ),
                          );
                          if (result != null && result is Gym) {
                            try {
                              await provider.updateGym(result);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка обновления: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
                if (widget.role == 'admin') {
                  return Dismissible(
                    key: Key(gym.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: AppStyles.errorColor,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      try {
                        await provider.deleteGym(gym.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${gym.name} удален')),
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
              },
            ),
    );
  }

  Widget _buildDrawer(GymProvider provider) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppStyles.primaryColor),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                widget.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                size: 40,
                color: AppStyles.primaryColor,
              ),
            ),
            accountName: Text(
              widget.role == 'admin' ? 'Администратор' : 'Пользователь',
              style: TextStyle(fontSize: 18),
            ),
            accountEmail: Text(widget.role == 'admin' ? 'admin' : 'user'),
          ),
          ListTile(
            leading: Icon(Icons.fitness_center),
            title: Text('Каталог'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.favorite, color: Colors.red),
            title: Text('Избранное'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(
                    gyms: provider.gyms,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.compare_arrows, color: AppStyles.primaryColor),
            title: Text('Сравнение'),
            trailing: provider.compareCount > 0
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: AppStyles.primaryColor,
                    child: Text(
                      '${provider.compareCount}',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CompareScreen()),
              );
            },
          ),          
          if (widget.role == 'admin')
            ListTile(
              leading: Icon(Icons.delete, color: Colors.grey),
              title: Text('Корзина'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrashScreen(),
                  ),
                ).then((_) => provider.loadGyms());
              },
            ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Профиль'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    role: widget.role,
                    gyms: provider.gyms,
                  ),
                ),
              );
            },
          ),
          Spacer(),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: AppStyles.errorColor),
            title: Text('Выйти', style: TextStyle(color: AppStyles.errorColor)),
            onTap: () {
              ApiServices.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Закрыть приложение'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Выход'),
                  content: Text('Закрыть приложение?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Нет'),
                    ),
                    TextButton(
                      onPressed: () => exit(0),
                      child: Text('Да'),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: AppStyles.paddingMedium),
        ],
      ),
    );
  }
}