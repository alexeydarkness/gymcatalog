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
import '../services/storage_service.dart';
import 'profile_screen.dart';
import 'trash_screen.dart';
import 'package:flutter/services.dart';
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
  void dispose() {
    super.dispose();
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
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilterScreen(
                    selectedType: provider.selectedType,
                    selectedAmenities: provider.selectedAmenities,
                  ),
                ),
              );
              if (result != null) {
                provider.setFilters(
                  result['type'], 
                  List<String>.from(result['amenities'])
                );
              }
            }, 
            icon: Icon(Icons.filter_list),
          )
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
      body: _buildBody(provider),
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
    if (gyms.isEmpty) {
      return Center(child: Text('Список пуст', style: AppStyles.subtitleStyle));
    }
    return ListView.builder(
      itemCount: gyms.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == gyms.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppStyles.paddingMedium),
              child: ElevatedButton(onPressed: () => provider.loadMore(), child: Text("Загрузить еще")),
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
                        Text('${gym.rating} ⭐', style: TextStyle(fontSize: 14)),
                        Spacer(),
                        Text('${gym.pricePerMonth.toInt()} ₽/мес', style: AppStyles.priceStyle),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  onPressed: () => provider.toggleFavorite(gym),
                  icon: Icon(
                    gym.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: gym.isFavorite ? Colors.red : null,
                  ),
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