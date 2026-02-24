import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotVerifiedScreen extends StatelessWidget {
  const NotVerifiedScreen({super.key});

  static const primaryColor = Color(0xFFD72520);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Not Verified'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread,
                size: 80, color: primaryColor),
            const SizedBox(height: 20),
            const Text(
              'Your email is not verified yet.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'We sent a verification link to ${user.email}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await user.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification email sent again'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Resend Email'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}