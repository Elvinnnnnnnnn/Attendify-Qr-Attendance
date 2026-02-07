import 'package:flutter/material.dart';
import 'screens/role_selection_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AttendifyApp());
}

class AttendifyApp extends StatelessWidget {
  const AttendifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendify',
      debugShowCheckedModeBanner: false,
      home: const RoleSelectionScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendify'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Welcome to Attendify',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
