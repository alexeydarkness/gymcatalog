import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';

class GymEditScreen extends StatefulWidget{ 
  final Gym? gym;

  const GymEditScreen({this.gym});

  @override
  State<GymEditScreen> createState() => _GymEditScreenState();

}

  class _GymEditScreenState extends State<GymEditScreen> {
    final _formKey = GlobalKey<FormState>();
    late String _name;
    late String _address;
    late String _imageUrl;
    late double _rating;
    late double _pricePerMonth;
    late String _type;
    late List<String> _amenities;

    final List<String> _types = ['бодибилдинг', 'кроссфит', 'йога', 'единоборства'];
    final List<String> _allAmenities = ['душ', 'сауна', 'парковка', 'тренер', 'Wi-Fi'];

    @override
  void initState() {
    super.initState();
    _name = widget.gym?.name ?? '';
    _address = widget.gym?.address ?? '';
    _imageUrl = widget.gym?.imageUrl ?? '';
    _rating = widget.gym?.rating ?? 0;
    _pricePerMonth = widget.gym?.pricePerMonth ?? 0;
    _type = widget.gym?.type ?? 'бодибилдинг';
    _amenities = List.from(widget.gym?.amenities ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gym == null ? 'Добавить зал' : 'Редактировать '),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppStyles.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Название зала'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите название';
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              SizedBox(height: AppStyles.paddingSmall),
              TextFormField(
                initialValue: _address,
                decoration: InputDecoration(labelText: 'Адрес'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите адрес';
                  return null;
                },
                onSaved: (value) => _address = value!,
              ),
              SizedBox(height: AppStyles.paddingSmall),
              TextFormField(
              initialValue: _imageUrl,
              decoration: InputDecoration(labelText: 'URL изображения'),
              onSaved: (value) => _imageUrl = value ?? '',
            ),
              SizedBox(height: AppStyles.paddingSmall),
              TextFormField(
              initialValue: _rating > 0 ? _rating.toString() : '',
              decoration: InputDecoration(labelText: 'Рейтинг (0-5)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final num = double.tryParse(value ?? '');
                if (num == null || num < 0 || num > 5) return 'Введите число от 0 до 5';
                return null;
              },
              onSaved: (value) => _rating = double.parse(value!),
            ),
              SizedBox(height: AppStyles.paddingSmall),
              TextFormField(
              initialValue: _pricePerMonth > 0 ? _pricePerMonth.toString() : '',
              decoration: InputDecoration(labelText: 'Цена за месяц'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (double.tryParse(value ?? '') == null) return 'Введите число';
                return null;
              },
              onSaved: (value) => _pricePerMonth = double.parse(value!),
            ),
              SizedBox(height: AppStyles.paddingMedium),
              Text('Тип зала', style: AppStyles.titleStyle),
              ..._types.map((type) {
                return RadioListTile<String>(
                  title: Text(type),
                  value: type, 
                  groupValue: _type, 
                  onChanged: (value) {
                    setState(() => _type = value!);
                  }
                );
              }),
              SizedBox(height: AppStyles.paddingMedium),
              Text('Удобства', style: AppStyles.titleStyle),
              ..._allAmenities.map((amenity) {
                return CheckboxListTile(
                  title: Text(amenity),
                  value: _amenities.contains(amenity), 
                  onChanged: (checked) {
                    setState(() {
                      if (checked!) {
                        _amenities.add(amenity);
                      } else {
                        _amenities.remove(amenity);
                      }
                    });
                  },
                );
              }),
              SizedBox(height: AppStyles.paddingLarge),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final gym = Gym(
                        id: widget.gym?.id ?? DateTime.now().millisecondsSinceEpoch,
                        name: _name,
                        address: _address,
                        imageUrl: _imageUrl,
                        rating: _rating,
                        pricePerMonth: _pricePerMonth,
                        type: _type,
                        amenities: _amenities,
                      );
                      Navigator.pop(context, gym);
                    }
                  }, 
                  child: Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}