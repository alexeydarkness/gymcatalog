import 'package:curs_proj/providers/gym_provider.dart';
import 'package:curs_proj/screens/login_screen.dart';
import 'package:curs_proj/styles/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {

WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => GymProvider(),
      child: MyApp(),
    ),
  );
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
        elevatedButtonTheme: AppStyles.elevatedButtonTheme,
        cardTheme: AppStyles.cardTheme,
      ),
      home: LoginScreen(),
    );
  }
}