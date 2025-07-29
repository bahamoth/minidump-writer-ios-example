import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MinidumpWriterApp());
}

class MinidumpWriterApp extends StatelessWidget {
  const MinidumpWriterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinidumpWriter Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}