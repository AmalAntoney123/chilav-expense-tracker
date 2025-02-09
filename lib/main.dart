import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.green.shade400,
          surface: Colors.grey[900]!,
          background: Colors.black,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.green.shade400,
          surface: Colors.grey[900]!,
          background: Colors.black,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark, // Force dark theme
      home: const HomeScreen(),
    );
  }
}
