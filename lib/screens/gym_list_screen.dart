import 'package:curs_proj/screens/gym_detail_screen.dart';
import 'package:curs_proj/services/api_services.dart';
import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';
import 'filter_screen.dart';

class GymListScreen extends StatefulWidget {
  @override
  State<GymListScreen> createState() => _GymListScreenState();
}

class _GymListScreenState extends State<GymListScreen> {
  List<Gym> _gyms = [];
  String? _selectedType;
  List<String> _selectedAmenities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  Future<void> _loadGyms() async {
    try {
      final gyms = await ApiServices.fetchGyms();
      setState(() {
        _gyms = gyms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Gym> _filteredGyms() {
    return _gyms.where((gym) {
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
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Корзина'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Профиль'),
              onTap: () {
                Navigator.pop(context);
              },
            )                        
          ],
        ),
      ),
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
    final gyms = _filteredGyms();
    if (gyms.isEmpty) {
      return Center(child: Text('Список пуст', style: AppStyles.subtitleStyle));
    }
    return ListView.builder(
        itemCount: gyms.length,
        itemBuilder: (context, index) {
          final gym = gyms[index];
          return Card(
            margin: EdgeInsets.all(AppStyles.paddingSmall),
            child: ListTile(
              title: Text(gym.name, style: AppStyles.titleStyle),
              subtitle: Text(gym.address, style: AppStyles.subtitleStyle),
              trailing: Text('${gym.rating}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GymDetailScreen(gym: gym),
                  ),
                );
              },
            ),
          );
        }
    );
  }
}