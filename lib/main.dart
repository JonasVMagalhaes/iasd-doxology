import 'package:flutter/material.dart';
import 'presentation/pages/home_page.dart';

void main() {
  runApp(const ChurchVideoPlayerApp());
}

class ChurchVideoPlayerApp extends StatelessWidget {
  const ChurchVideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Church Video Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}