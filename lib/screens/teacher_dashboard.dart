import 'package:flutter/material.dart';
import 'add_subject_screen.dart';
import 'teacher_subjects_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendify_qr/profile/profile_screen.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  static const primaryColor = Color(0xFFD72520);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [

            // Welcome
            const Text(
              'Welcome 👋',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),

            const Text(
              'Manage your classes and attendance',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 TEACHER INFO CARD (ADDED)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  );
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teacher Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Name',
                        value: data['name'],
                      ),
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: data['email'],
                      ),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Role',
                        value: data['role'],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 🔹 PROFILE CARD
            _DashboardCard(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'View your account details',
              color: Colors.white,
              textColor: primaryColor,
              borderColor: primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Add Subject
            _DashboardCard(
              icon: Icons.add_circle_outline,
              title: 'Add Subject',
              subtitle: 'Create a new class or subject',
              color: primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddSubjectScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // View Subjects
            _DashboardCard(
              icon: Icons.menu_book_outlined,
              title: 'View My Subjects',
              subtitle: 'See and manage your subjects',
              color: Colors.white,
              textColor: primaryColor,
              borderColor: primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const TeacherSubjectsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Small info row (same style as student dashboard)
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TeacherDashboard.primaryColor),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Reusable Dashboard Card (UNCHANGED)
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.textColor = Colors.white,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border:
              borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: textColor),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: textColor.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }
}
