import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user, required this.auth});

  final AppUser user;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Log'),
        actions: [
          IconButton(
            key: const Key('signOutButton'),
            tooltip: 'ออกจากระบบ',
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: Center(child: Text('สวัสดี ${user.email}')),
    );
  }
}