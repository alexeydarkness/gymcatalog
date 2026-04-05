import 'package:curs_proj/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'screens/gym_list_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Каталог залов',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: LoginScreen(),
    );
  }
}