import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class FilterScreen  extends StatefulWidget{
  final String? selectedType;
  final List<String> selectedAmenities;

  const FilterScreen({
    this.selectedType,
    required this.selectedAmenities,
  });

  @override
  State<StatefulWidget> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String? _selectedType;
  List<String> _selectedAmenities = [];

  final List<String> _types = ['бодибилдинг', 'кроссфит', 'йога', 'единоборства'];
  final List<String> _amenities = ['душ', 'сауна', 'парковка', 'тренер', 'Wi-Fi'];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedAmenities = List.from(widget.selectedAmenities);
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            );
          }),
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
              }
            );
          }),
          SizedBox(height: AppStyles.paddingLarge),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'type': _selectedType,
                'amenities': _selectedAmenities,
              });
            }, 
            child: Text('Применить')
          ),
        ],
      ),
    );
  }
}