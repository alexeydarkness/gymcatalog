import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../services/api_services.dart';
import '../services/storage_service.dart';

class GymProvider extends ChangeNotifier {
  List<Gym> _gyms = [];
  bool isLoading = true;
  String? error;
  String? selectedType;
  List<String> selectedAmenities = [];
  String role = 'user';
  String username = '';
  int _displayedCount = 10;
  final int _pageSize = 10;

  List<Gym>get gyms => _gyms;

  List<Gym> get filteredGyms {
    return _gyms.where((gym) {
      if (gym.isDeleted) return false;
      if (selectedType != null && gym.type != selectedType) return false;
      for (var amenity in selectedAmenities) {
        if (!gym.amenities.contains(amenity)) return false;
      }
      return true;  
    }).toList();
  }




  List<Gym>get displayedGyms {
    final filtered = filteredGyms;
    return filtered.take(_displayedCount).toList();
  }

  bool get hasMore => _displayedCount < filteredGyms.length;

  void loadMore() {
    _displayedCount += _pageSize;
    notifyListeners();
  }

  void resetPagination() {
    _displayedCount = _pageSize;
    notifyListeners();
  }

  List<Gym> get favoriteGyms => _gyms.where((g) => g.isFavorite).toList();

  List<Gym> get deletedGyms => _gyms.where((g) => g.isDeleted).toList();

  Future<void> loadGyms() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _gyms = await ApiServices.fetchGyms();
      final favoriteIds = await StorageService.getFavorites(username);
      for (var gym in _gyms) {
        if (favoriteIds.contains(gym.id)) gym.isFavorite = true;
      }
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleFavorite(Gym gym) {
    gym.isFavorite = !gym.isFavorite;
    StorageService.saveFavorites(
      _gyms.where((g) => g.isFavorite).map((g) => g.id).toList(),
      username,
    );
    notifyListeners();
  }

  Future<void> createGym(Gym gym) async {
    await ApiServices.createGym(gym);
    await loadGyms();
  }
  Future<void> updateGym(Gym gym) async {
    await ApiServices.updateGym(gym.id, gym);
    await loadGyms();
  }
  Future<void> deleteGym(int id) async {
    await ApiServices.deleteGym(id);
    final gym = _gyms.firstWhere((g) => g.id == id);
    gym.isDeleted = true;
    await loadGyms();
  }

  Future<void> loadDeletedGyms() async {
    isLoading = true;
    notifyListeners();
    try {
      final deleted = await ApiServices.fetchDeletedGyms();
      _gyms.removeWhere((g) => g.isDeleted);
      _gyms.addAll(deleted);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }    

  void setFilters(String? type, List<String> amenities) {
    selectedType = type;
    selectedAmenities = amenities;
    notifyListeners();
  }

  void setRole(String newRole) {
    role = newRole;
    notifyListeners();
  }
  
  void setUsername(String name) {
    username = name;
  }

}