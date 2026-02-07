import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  final String role; // student or teacher

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 🔹 Student-only controllers
  final TextEditingController blkController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  String studentType = 'regular';

  static const primaryColor = Color(0xFFD72520);

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (widget.role == 'student') {
      if (blkController.text.trim().isEmpty ||
          yearController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please complete student information')),
        );
        return;
      }
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final Map<String, dynamic> userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'role': widget.role,
        'createdAt': Timestamp.now(),
      };

      if (widget.role == 'student') {
        userData.addAll({
          'blk': blkController.text.trim(),
          'year': yearController.text.trim(),
          'studentType': studentType,
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleText =
        '${widget.role[0].toUpperCase()}${widget.role.substring(1)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Register as $roleText',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Fill in the details to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 40),

            // Full Name
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Email
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Password
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            // 🔹 STUDENT-ONLY FIELDS
            if (widget.role == 'student') ...[
              const SizedBox(height: 20),

              TextField(
                controller: blkController,
                decoration: InputDecoration(
                  labelText: 'Block (BLK)',
                  prefixIcon: const Icon(Icons.group_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: yearController,
                decoration: InputDecoration(
                  labelText: 'Year Level',
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Type',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Regular',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: 'regular',
                          groupValue: studentType,
                          onChanged: (value) {
                            setState(() => studentType = value!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Irregular',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: 'irregular',
                          groupValue: studentType,
                          onChanged: (value) {
                            setState(() => studentType = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: registerUser,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
