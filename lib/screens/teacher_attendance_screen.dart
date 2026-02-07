import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherAttendanceScreen extends StatelessWidget {
  final String subjectId;

  TeacherAttendanceScreen({super.key, required this.subjectId});

  static const primaryColor = Color(0xFFD72520);

  // 🔹 Cache to avoid reloading student data repeatedly
  final Map<String, Map<String, dynamic>> studentCache = {};

  // 🔹 Fetch student data with caching
  Future<Map<String, dynamic>> getStudent(String studentId) async {
    if (studentCache.containsKey(studentId)) {
      return studentCache[studentId]!;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .get();

    final data = doc.data()!;
    studentCache[studentId] = data;
    return data;
  }

  // 🔹 12-hour formatter
  String formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance List'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('subjectId', isEqualTo: subjectId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs;

          if (records.isEmpty) {
            return const Center(
              child: Text(
                'No attendance recorded',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final data = record.data() as Map<String, dynamic>;

              final studentId = data['studentId'];

              final Timestamp? timeInTs =
                  data.containsKey('timeInAt') ? data['timeInAt'] : null;
              final Timestamp? timeOutTs =
                  data.containsKey('timeOutAt') ? data['timeOutAt'] : null;

              return FutureBuilder<Map<String, dynamic>>(
                future: getStudent(studentId),
                builder: (context, studentSnapshot) {
                  if (!studentSnapshot.hasData) {
                    return const _AttendanceSkeleton();
                  }

                  final student = studentSnapshot.data!;

                  return _TeacherAttendanceCard(
                    name: student['name'],
                    photoUrl: student['photoUrl'],
                    blk: student['blk'],
                    year: student['year'],
                    studentType: student['studentType'],
                    date: timeInTs != null
                        ? formatDate(timeInTs.toDate())
                        : '—',
                    timeIn: timeInTs != null
                        ? formatTime(timeInTs.toDate())
                        : null,
                    timeOut: timeOutTs != null
                        ? formatTime(timeOutTs.toDate())
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// 🔹 Teacher Attendance Card
class _TeacherAttendanceCard extends StatelessWidget {
  final String name;
  final String date;
  final String? photoUrl;

  final String? blk;
  final String? year;
  final String? studentType;

  final String? timeIn;
  final String? timeOut;

  const _TeacherAttendanceCard({
    required this.name,
    required this.date,
    this.photoUrl,
    this.blk,
    this.year,
    this.studentType,
    this.timeIn,
    this.timeOut,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor:
                TeacherAttendanceScreen.primaryColor.withOpacity(0.1),
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? const Icon(
                    Icons.person_outline,
                    color: TeacherAttendanceScreen.primaryColor,
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (blk != null && year != null && studentType != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$blk • $year • $studentType',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 8),

                // 🔹 Time In / Time Out row
                Row(
                  children: [
                    const Icon(Icons.login, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      timeIn ?? '—',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.logout, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      timeOut ?? '—',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status icon
          Icon(
            timeOut != null ? Icons.check_circle : Icons.schedule,
            color: timeOut != null ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
}

/// 🔹 Loading Skeleton
class _AttendanceSkeleton extends StatelessWidget {
  const _AttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black12.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
