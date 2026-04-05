import 'package:flutter/material.dart';
import '../models/gym.dart';
import '../styles/app_styles.dart';

class TrashScreen extends StatefulWidget{
  final List<Gym> deletedGyms;

  const TrashScreen({required this.deletedGyms});

  @override
  State<StatefulWidget> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Корзина'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: widget.deletedGyms.isEmpty ? Center(child: Text('Корзина пуста', style: AppStyles.subtitleStyle)) : ListView.builder(
        itemCount: widget.deletedGyms.length,
        itemBuilder: (context, index) {
          final gym = widget.deletedGyms[index];
          return Card(
            margin: EdgeInsets.all(AppStyles.paddingSmall),
            child: ListTile(
              title: Text(gym.name, style: AppStyles.titleStyle),
              trailing: IconButton(
                icon: Icon(Icons.restore, color: Colors.green),
                onPressed: () {
                  setState(() {
                    gym.isDeleted = false;
                    widget.deletedGyms.removeAt(index);
                  });
                },
              ),
            ),
          );
        }
      ),
    );
  }
}