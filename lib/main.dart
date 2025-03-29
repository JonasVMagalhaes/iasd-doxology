import 'package:flutter/material.dart';
import 'presentation/pages/welcome_page.dart';

void main() {
  runApp(const ChurchVideoPlayerApp());
}

class ChurchVideoPlayerApp extends StatelessWidget {
  const ChurchVideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IASD Video Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Lora',
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}