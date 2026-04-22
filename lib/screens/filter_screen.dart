import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class FilterScreen extends StatefulWidget {
  final String? selectedType;
  final List<String> selectedAmenities;
  final RangeValues? priceRange;
  final double minPrice;
  final double maxPrice;

  const FilterScreen({
    this.selectedType,
    required this.selectedAmenities,
    this.priceRange,
    required this.minPrice,
    required this.maxPrice,
  });

  @override
  State<StatefulWidget> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String? _selectedType;
  List<String> _selectedAmenities = [];
  late RangeValues _priceRange;

  final List<String> _types = ['бодибилдинг', 'кроссфит', 'йога', 'единоборства'];
  final List<String> _amenities = ['душ', 'сауна', 'парковка', 'тренер', 'Wi-Fi'];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedAmenities = List.from(widget.selectedAmenities);
    _priceRange = widget.priceRange ??
        RangeValues(widget.minPrice, widget.maxPrice);
  }

  @override
  Widget build(BuildContext context) {
    // защита от случая, когда min == max (ещё не загрузились залы)
    final safeMin = widget.minPrice;
    final safeMax = widget.maxPrice > widget.minPrice
        ? widget.maxPrice
        : widget.minPrice + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Фильтры'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedAmenities.clear();
                _priceRange = RangeValues(safeMin, safeMax);
              });
            },
            child: Text('Сбросить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppStyles.paddingMedium),
        children: [
          Text('Тип зала', style: AppStyles.titleStyle),
          ..._types.map((type) {
            return RadioListTile<String>(
              title: Text(type),
              value: type,
              groupValue: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value),
            );
          }),
          SizedBox(height: AppStyles.paddingMedium),
          Text('Цена, ₽/мес', style: AppStyles.titleStyle),
          RangeSlider(
            values: _priceRange,
            min: safeMin,
            max: safeMax,
            divisions: 20,
            labels: RangeLabels(
              _priceRange.start.toInt().toString(),
              _priceRange.end.toInt().toString(),
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppStyles.paddingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_priceRange.start.toInt()} ₽'),
                Text('${_priceRange.end.toInt()} ₽'),
              ],
            ),
          ),
          SizedBox(height: AppStyles.paddingMedium),
          Text('Удобства', style: AppStyles.titleStyle),
          ..._amenities.map((amenity) {
            return CheckboxListTile(
              title: Text(amenity),
              value: _selectedAmenities.contains(amenity),
              onChanged: (checked) {
                setState(() {
                  if (checked!) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
            );
          }),
          SizedBox(height: AppStyles.paddingLarge),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'type': _selectedType,
                'amenities': _selectedAmenities,
                'priceRange': _priceRange,
              });
            },
            child: Text('Применить'),
          ),
        ],
      ),
    );
  }
}