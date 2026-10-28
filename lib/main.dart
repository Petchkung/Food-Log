import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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