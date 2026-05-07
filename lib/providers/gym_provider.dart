import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../services/api_services.dart';
import '../services/storage_service.dart';

enum SortOption { none, ratingDesc, priceAsc, priceDesc, nameAsc }

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
  final Set<int> _compareIds = {};
  static const int maxCompare = 3;

  Set<int> get compareIds => _compareIds;
  int get compareCount => _compareIds.length;
  bool isInCompare(int gymId) => _compareIds.contains(gymId);
  bool get canAddMoreToCompare => _compareIds.length < maxCompare;

  // НОВОЕ: поиск + ценовой диапазон + сортировка
  String _searchQuery = '';
  RangeValues? _priceRange;
  SortOption _sortOption = SortOption.none;

  String get searchQuery => _searchQuery;
  RangeValues? get priceRange => _priceRange;
  SortOption get sortOption => _sortOption;

  List<Gym> get gyms => _gyms;

  // Границы цен по всему каталогу — для слайдера в фильтрах
  double get minPrice {
    if (_gyms.isEmpty) return 0;
    return _gyms.map((g) => g.pricePerMonth).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (_gyms.isEmpty) return 10000;
    return _gyms.map((g) => g.pricePerMonth).reduce((a, b) => a > b ? a : b);
  }

  List<Gym> get filteredGyms {
    var list = _gyms.where((gym) {
      // Удалённые залы (в корзине) НЕ скрываются — их видят все,
      // но в UI они помечаются как "Не работает".
      if (selectedType != null && gym.type != selectedType) return false;
      for (var amenity in selectedAmenities) {
        if (!gym.amenities.contains(amenity)) return false;
      }
      // поиск по названию и адресу (регистр не важен)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final inName = gym.name.toLowerCase().contains(q);
        final inAddress = gym.address.toLowerCase().contains(q);
        if (!inName && !inAddress) return false;
      }
      // ценовой диапазон
      if (_priceRange != null) {
        if (gym.pricePerMonth < _priceRange!.start) return false;
        if (gym.pricePerMonth > _priceRange!.end) return false;
      }
      return true;
    }).toList();

    // сортировка
    switch (_sortOption) {
      case SortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.priceAsc:
        list.sort((a, b) => a.pricePerMonth.compareTo(b.pricePerMonth));
        break;
      case SortOption.priceDesc:
        list.sort((a, b) => b.pricePerMonth.compareTo(a.pricePerMonth));
        break;
      case SortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.none:
        break;
    }
    return list;
  }

  List<Gym> get displayedGyms {
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
      final results = await Future.wait([
        ApiServices.fetchGyms(),
        ApiServices.fetchDeletedGyms().catchError((_) => <Gym>[]),
      ]);
      final active = results[0];
      final deleted = results[1];
      for (final g in deleted) {
        g.isDeleted = true;
      }

      _gyms = [...active, ...deleted];

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

  void setFilters(String? type, List<String> amenities, {RangeValues? priceRange}) {
    selectedType = type;
    selectedAmenities = amenities;
    _priceRange = priceRange;
    resetPagination();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    resetPagination();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    resetPagination();
  }

  void setRole(String newRole) {
    role = newRole;
    notifyListeners();
  }

  void setUsername(String name) {
    username = name;
  }

  List<Gym> get compareGyms =>
      _gyms.where((g) => _compareIds.contains(g.id) && !g.isDeleted).toList();

  void toggleCompare(int gymId) {
    if (_compareIds.contains(gymId)) {
      _compareIds.remove(gymId);
    } else {
      if (_compareIds.length >= maxCompare) return;
      _compareIds.add(gymId);
    }
    notifyListeners();
  }

  void clearCompare() {
    _compareIds.clear();
    notifyListeners();
  }
}