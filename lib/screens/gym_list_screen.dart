import 'package:curs_proj/screens/gym_detail_screen.dart';
import 'package:curs_proj/services/api_services.dart';
import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';
import 'filter_screen.dart';
import 'gym_edit_screen.dart';
import 'favorites_screen.dart';
import '../services/storage_service.dart';
import 'profile_screen.dart';
import 'trash_screen.dart';

class GymListScreen extends StatefulWidget {

  final String role;

  const GymListScreen({required this.role});

  @override
  State<GymListScreen> createState() => _GymListScreenState();
}

class _GymListScreenState extends State<GymListScreen> {
  List<Gym> _gyms = [];
  String? _selectedType;
  List<String> _selectedAmenities = [];
  List<Gym> _displayedGyms = [];
  int _currentPage = 0;
  final int _pageSize = 5;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGyms();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        _loadMore();
      }
    });
  }

  void _loadMore() {
      if (!_hasMore) return;
      final filtered = _filteredGyms();
      final start = _displayedGyms.length;
      if (start >= filtered.length) {
        setState(() => _hasMore = false);
        return;
      }
      final end = (start + _pageSize).clamp(0, filtered.length);
      setState(() {
        _displayedGyms = filtered.sublist(0, end);
        _hasMore = end < filtered.length;
    });
  }

  void _refreshDisplayed() {
    final filtered = _filteredGyms();
    final currentLength = _displayedGyms.length.clamp(0, filtered.length);
    setState(() {
      _displayedGyms = filtered.sublist(0, currentLength);
      _hasMore = currentLength < filtered.length;
    });
  }

  void _resetPagination() {
    _displayedGyms.clear();
    _currentPage = 0;
    _hasMore = true;
    _loadMore();
  }

  Future<void> _loadGyms() async {
    try {
      final gyms = await ApiServices.fetchGyms();
      final favoriteIds = await StorageService.getFavorites(widget.role);
      final deletedIds = await StorageService.getDeleted();
      setState(() {
        _gyms = gyms;
        for (var gym in _gyms) {
          if (favoriteIds.contains(gym.id)) gym.isFavorite = true;
          if (deletedIds.contains(gym.id)) gym.isDeleted = true;
        }
        _isLoading = false;
      });
      _resetPagination();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Gym> _filteredGyms() {
    return _gyms.where((gym) {
      if (gym.isDeleted) return false;
      if(_selectedType != null && gym.type != _selectedType) {
        return false;
      }
      for (var amenity in _selectedAmenities) {
        if (!gym.amenities.contains(amenity)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                    selectedType: _selectedType,
                    selectedAmenities: _selectedAmenities,
                  ),
                ),
              );
              if (result != null) {
                setState(() {
                  _selectedType = result['type'];
                  _selectedAmenities = List<String>.from(result['amenities']);
                });
                _resetPagination();
              }
            }, 
            icon: Icon(Icons.filter_list),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text('Меню', style: TextStyle(color: Colors.white, fontSize: 24),),
              decoration: BoxDecoration(color: AppStyles.primaryColor),
            ),
            ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text('Каталог'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Избранное'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => FavoritesScreen(
                      favorites: _gyms.where((g) => g.isFavorite).toList(),
                    ),
                  ),
                );
              },
            ),
            if (widget.role == 'admin')
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Корзина'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrashScreen(
                      deletedGyms: _gyms.where((g) => g.isDeleted).toList(),
                    ),
                  ),
                );
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
                      favoritesCount: _gyms.where((g) => g.isFavorite).length,
                    ),
                  ),
                );
              },
            )                        
          ],
        ),
      ),
      floatingActionButton: widget.role == 'admin' 
        ? FloatingActionButton(
          onPressed: () async {
            final newGym = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GymEditScreen()),
            );
            if (newGym != null) {
              setState(() {
                _gyms.add(newGym);
              });
            }
          },
        backgroundColor: AppStyles.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        )
      : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if(_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Ошибка $_error'));
    }
    if (_displayedGyms.isEmpty && !_hasMore) {
      return Center(child: Text('Список пуст', style: AppStyles.subtitleStyle));
    }
    return ListView.builder(
      controller: _scrollController,
        itemCount: _displayedGyms.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
        if (index == _displayedGyms.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppStyles.paddingMedium),
              child: ElevatedButton(
                onPressed: _loadMore,
                child: Text('Загрузить ещё'),
              ),
            ),
          );
        }
          final gym = _displayedGyms[index];
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
                    onPressed: () {
                      gym.isFavorite = !gym.isFavorite;
                      StorageService.saveFavorites(
                        _gyms.where((g) => g.isFavorite).map((g) => g.id).toList(),
                        widget.role,
                      );
                      _refreshDisplayed();
                    },
                    icon: Icon(
                      gym.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: gym.isFavorite ? Colors.red : null,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GymDetailScreen(gym: gym),
                      ),
                    );
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
              onDismissed: (direction) {
                setState(() {
                  gym.isDeleted = true;
                });
                StorageService.saveDeleted(
                  _gyms.where((g) => g.isDeleted).map((g) => g.id).toList(),
                );
                _refreshDisplayed();
              },
              child: card,
          );
        }
        return card;
      },
    );
  }
}