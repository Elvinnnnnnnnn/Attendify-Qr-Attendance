import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const primaryColor = Color(0xFFD72520);

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// 🔹 Edit Full Name
  Future<void> _editName(
    BuildContext context,
    String currentName,
    String userId,
  ) async {
    final controller = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Full Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'name': newName});

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Edit Student Info (BLK / Year / Student Type)
  Future<void> _editStudentInfo(
    BuildContext context,
    String userId,
    String blk,
    String year,
    String type,
  ) async {
    final blkController = TextEditingController(text: blk);
    final yearController = TextEditingController(text: year);
    String studentType = type;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Student Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: blkController,
                decoration: const InputDecoration(
                  labelText: 'Block',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(
                  labelText: 'Year Level',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Type',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  RadioListTile<String>(
                    title:
                        const Text('Regular', style: TextStyle(fontSize: 12)),
                    value: 'regular',
                    groupValue: studentType,
                    onChanged: (value) {
                      studentType = value!;
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Irregular',
                        style: TextStyle(fontSize: 12)),
                    value: 'irregular',
                    groupValue: studentType,
                    onChanged: (value) {
                      studentType = value!;
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({
                  'blk': blkController.text.trim(),
                  'year': yearController.text.trim(),
                  'studentType': studentType,
                });

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Change Password
  Future<void> _changePassword(BuildContext context, String email) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final currentPassword =
                    currentPasswordController.text.trim();
                final newPassword =
                    newPasswordController.text.trim();

                if (currentPassword.isEmpty || newPassword.isEmpty) return;

                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final credential = EmailAuthProvider.credential(
                    email: email,
                    password: currentPassword,
                  );

                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPassword);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password updated successfully')),
                  );
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(e.message ?? 'Password change failed')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Change Profile Photo
  Future<void> _changeProfilePhoto(BuildContext context, String userId) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (picked == null) return;

    final file = File(picked.path);

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('$userId.jpg');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'photoUrl': url});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final role = data['role'];
          final name = data['name'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _changeProfilePhoto(context, user.uid),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: primaryColor,
                    backgroundImage: data['photoUrl'] != null
                        ? NetworkImage(data['photoUrl'])
                        : null,
                    child: data['photoUrl'] == null
                        ? Text(
                            _getInitials(name),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Tap photo to change profile picture',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),

                const SizedBox(height: 12),

                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  data['email'],
                  style:
                      const TextStyle(fontSize: 14, color: Colors.black54),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toString().toUpperCase(),
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                _InfoCard(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  value: name,
                ),
                _InfoCard(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: data['email'],
                ),
                _InfoCard(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: role,
                ),

                if (role == 'student') ...[
                  _InfoCard(
                    icon: Icons.group_outlined,
                    label: 'Block',
                    value: data['blk'],
                  ),
                  _InfoCard(
                    icon: Icons.school_outlined,
                    label: 'Year Level',
                    value: data['year'],
                  ),
                  _InfoCard(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Student Type',
                    value: data['studentType'],
                  ),
                ],

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () =>
                      _editName(context, name, user.uid),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Edit Full Name'),
                ),

                if (role == 'student') ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _editStudentInfo(
                      context,
                      user.uid,
                      data['blk'],
                      data['year'],
                      data['studentType'],
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: primaryColor),
                      foregroundColor: primaryColor,
                    ),
                    child: const Text('Edit Student Info'),
                  ),
                ],

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: () =>
                      _changePassword(context, data['email']),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: primaryColor),
                    foregroundColor: primaryColor,
                  ),
                  child: const Text('Change Password'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: ProfileScreen.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
