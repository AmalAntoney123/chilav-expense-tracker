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
          primary: const Color.fromARGB(255, 64, 136, 67),
          secondary: Colors.green.shade400,
          tertiary: const Color.fromARGB(255, 223, 62, 62),
          surface: Colors.grey[900]!,
          background: Colors.black,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: const Color.fromARGB(255, 76, 175, 120),
          secondary: const Color.fromARGB(255, 102, 187, 154),
          tertiary: const Color.fromARGB(255, 203, 75, 75),
          onSurface: const Color.fromARGB(255, 194, 193, 193)!,
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
