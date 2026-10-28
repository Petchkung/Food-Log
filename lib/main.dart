import 'package:flutter/material.dart';

import 'app/theme.dart';

void main() {
  runApp(const FoodLogApp());
}

class FoodLogApp extends StatelessWidget {
  const FoodLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Log',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Center(child: Text('Food Log')),
      ),
    );
  }
}