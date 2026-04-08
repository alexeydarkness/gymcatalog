import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';
import '../services/api_services.dart';
class TrashScreen extends StatefulWidget{
  // final List<Gym> deletedGyms;

  // const TrashScreen({required this.deletedGyms});

  const TrashScreen();

  @override
  State<StatefulWidget> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<Gym> _deletedGyms = [];
  bool _isLoading = true;

    @override
  void initState() {
    super.initState();
    _loadDeleted();
  }

  Future<void> _loadDeleted() async {
    try {
      final gyms = await ApiServices.fetchDeletedGyms();
      setState(() {
        _deletedGyms = gyms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print(e);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Корзина'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _deletedGyms.isEmpty ? Center(child: Text('Корзина пуста', style: AppStyles.subtitleStyle)) : ListView.builder(
        itemCount: _deletedGyms.length,
        itemBuilder: (context, index) {
          final gym = _deletedGyms[index];
          return Card(
            margin: EdgeInsets.all(AppStyles.paddingSmall),
            child: ListTile(
              title: Text(gym.name, style: AppStyles.titleStyle),
              trailing: IconButton(
                icon: Icon(Icons.restore, color: Colors.green),
                onPressed: () async {
                  try {
                    await ApiServices.restoreGym(gym.id);
                    setState(() {
                      _deletedGyms.removeAt(index);
                  });
                  } catch (e) {
                    print(e);
                  }
                },
              ),
            ),
          );
        }
      ),
    );
  }
}