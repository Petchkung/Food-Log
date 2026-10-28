import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/food_repository.dart';
import 'data/local_database.dart';
import 'firebase_options.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final local = await LocalDatabase.open();
  final repository = FoodRepository(local: local, cloud: FirestoreSyncService());

  runApp(FoodLogApp(auth: FirebaseAuthService(), repository: repository));
}