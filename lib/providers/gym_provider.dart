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

  List<Gym> get favoriteGyms => _gyms.where((g) => g.isFavorite).toList();

  List<Gym> get deletedGyms => _gyms.where((g) => g.isDeleted).toList();

  Future<void> loadGyms() async {
    try {
      _gyms = await ApiServices.fetchGyms();
      final favoriteIds = await StorageService.getFavorites(role);
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
      role,
    );
    notifyListeners();
  }

  void deleteGyms(Gym gym) {
    gym.isDeleted = true;
    notifyListeners();
  }

  void restoreGym(Gym gym) {
    gym.isDeleted = false;
    notifyListeners();
  }

  void add(Gym gym) {
    _gyms.add(gym);
    notifyListeners();
  }

  void setFilters(String? type, List<String> amenities) {
    selectedType = type;
    selectedAmenities = amenities;
    notifyListeners();
  }
  


}