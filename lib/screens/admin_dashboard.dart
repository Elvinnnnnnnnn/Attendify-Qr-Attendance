import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_reports_screen.dart';
import 'manage_users_screen.dart';
import 'package:attendify_qr/profile/profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const primaryColor = Color(0xFFD72520);

  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const Text(
              'Welcome 👋',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),

            const Text(
              'Manage system data and reports',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 30),

            // ADMIN INFO
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>;

                return Container(
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
                        'Admin Information',
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
                        icon: Icons.admin_panel_settings,
                        label: 'Role',
                        value: data['role'],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // DATE RANGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    startDate == null || endDate == null
                        ? 'Select Date Range'
                        : '${startDate!.month}/${startDate!.day} - ${endDate!.month}/${endDate!.day}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setState(() {
                        startDate = picked.start;
                        endDate = picked.end;
                      });
                    }
                  },
                  child: const Text('Select Range'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // STATS
            FutureBuilder(
              future: _getAdminStatsRange(startDate, endDate),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data as Map<String, int>;

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Enrolled',
                        value: stats['enrolled'].toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Present',
                        value: stats['present'].toString(),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Absent',
                        value: stats['absent'].toString(),
                        color: Colors.red,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            _DashboardCard(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'View and edit your account',
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

            // MANAGE USERS
            _DashboardCard(
              icon: Icons.group_outlined,
              title: 'Manage Users',
              subtitle: 'View, edit, and manage users',
              color: primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageUsersScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // REPORTS
            _DashboardCard(
              icon: Icons.bar_chart_outlined,
              title: 'Attendance Reports',
              subtitle: 'View attendance analytics',
              color: Colors.white,
              textColor: primaryColor,
              borderColor: primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // KEEP YOUR EXISTING FUNCTION (NO CHANGE)
  Future<Map<String, int>> _getAdminStatsRange(
      DateTime? start, DateTime? end) async {
    final firestore = FirebaseFirestore.instance;

    final studentsSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final enrolled = studentsSnapshot.docs.length;

    if (start == null || end == null) {
      return {
        'enrolled': enrolled,
        'present': 0,
        'absent': enrolled,
      };
    }

    final startOfRange = DateTime(start.year, start.month, start.day);
    final endOfRange =
        DateTime(end.year, end.month, end.day, 23, 59, 59);

    final attendanceSnapshot = await firestore
        .collection('attendance')
        .where('timeInAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
        .where('timeInAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfRange))
        .get();

    final presentStudentIds = attendanceSnapshot.docs
        .map((doc) => doc['studentId'])
        .toSet();

    final present = presentStudentIds.length;
    final absent = enrolled - present;

    return {
      'enrolled': enrolled,
      'present': present,
      'absent': absent,
    };
  }
}

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
          Icon(icon, size: 18, color: const Color(0xFFD72520)),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border:
              borderColor != null ? Border.all(color: borderColor!) : null,
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
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}