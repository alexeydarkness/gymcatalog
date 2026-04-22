import 'package:curs_proj/providers/gym_provider.dart';
import 'package:curs_proj/providers/theme_provider.dart';
import 'package:curs_proj/screens/login_screen.dart';
import 'package:curs_proj/styles/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GymProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Каталог залов',
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      themeMode: themeProvider.mode,
      home: LoginScreen(),
    );
  }
}