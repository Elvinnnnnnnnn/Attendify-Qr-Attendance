import 'package:flutter/material.dart';
import 'student_login_screen.dart';
import 'teacher_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Role'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/east_LOGO-removebg-preview-removebg-preview.png',
              height: 120,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 30),

            // App Title
            const Text(
              'ATTENDIFY',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD72520),
                letterSpacing: 2,
              ),
            ),

            // Subtitle
            const Text(
              'QR-Driven Classroom Attendance System',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 80),

            // Continue as
            const Text(
              'Continue as',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 32),

            // Student Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentLoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: const Color(0xFFD72520),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Student',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Teacher Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherLoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD72520),
                side: const BorderSide(color: Color(0xFFD72520)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Teacher',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}