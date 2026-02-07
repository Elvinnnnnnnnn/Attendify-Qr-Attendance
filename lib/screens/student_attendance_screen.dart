import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'archived_attendance_screen.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  static const primaryColor = Color(0xFFD72520);

  Future<DocumentSnapshot> getSubject(String subjectId) {
    return FirebaseFirestore.instance
        .collection('subjects')
        .doc(subjectId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final student = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'Archived Attendance',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArchivedAttendanceScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('studentId', isEqualTo: student.uid)
            .where('isArchived', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs;

          if (records.isEmpty) {
            return const Center(
              child: Text(
                'No attendance records yet',
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

              final Timestamp? timeInTs =
                  data.containsKey('timeInAt') ? data['timeInAt'] : null;

              final Timestamp? timeOutTs =
                  data.containsKey('timeOutAt') ? data['timeOutAt'] : null;

              final Timestamp? scannedTs =
                  data.containsKey('scannedAt') ? data['scannedAt'] : null;

              return FutureBuilder<DocumentSnapshot>(
                future: getSubject(data['subjectId']),
                builder: (context, subjectSnapshot) {
                  if (subjectSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const _AttendanceSkeleton();
                  }

                  if (!subjectSnapshot.hasData ||
                      !subjectSnapshot.data!.exists ||
                      subjectSnapshot.data!.data() == null) {
                    return const _AttendanceSkeleton();
                  }

                  final subjectData =
                      subjectSnapshot.data!.data() as Map<String, dynamic>;

                  final subjectName = subjectData['subjectName'];

                  // ✅ ADDED: BLK & YEAR
                  final String? blk = subjectData['blk'];
                  final String? year = subjectData['year'];

                  String scheduleText = 'Schedule: Not set';

                  if (subjectData['scheduleAt'] != null) {
                    scheduleText =
                        'Schedule: ${_formatDate((subjectData['scheduleAt'] as Timestamp).toDate())}';
                  } else if (subjectData['classDate'] != null &&
                      subjectData['classTime'] != null) {
                    scheduleText =
                        'Schedule: ${_formatDateOnly((subjectData['classDate'] as Timestamp).toDate())} • ${subjectData['classTime']}';
                  }

                  return _AttendanceCard(
                    subjectName: subjectName,
                    blk: blk, // ✅ ADDED
                    year: year, // ✅ ADDED
                    scheduleText: scheduleText,
                    timeIn:
                        timeInTs?.toDate() ?? scannedTs?.toDate(),
                    timeOut: timeOutTs?.toDate(),
                    onArchive: () async {
                      await FirebaseFirestore.instance
                          .collection('attendance')
                          .doc(record.id)
                          .update({'isArchived': true});
                    },
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Attendance'),
                          content: const Text(
                            'Are you sure you want to delete this attendance record?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('attendance')
                            .doc(record.id)
                            .delete();
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.month}/${date.day}/${date.year} • $hour:$minute $period';
  }

  static String _formatDateOnly(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// 🔹 Attendance Card
class _AttendanceCard extends StatelessWidget {
  final String subjectName;
  final String? blk; // ✅ ADDED
  final String? year; // ✅ ADDED
  final String scheduleText;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _AttendanceCard({
    required this.subjectName,
    required this.blk,
    required this.year,
    required this.scheduleText,
    required this.timeIn,
    required this.timeOut,
    required this.onArchive,
    required this.onDelete,
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subjectName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.archive),
                onPressed: onArchive,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),

          // ✅ ADDED: BLK & YEAR DISPLAY
          if (blk != null && year != null) ...[
            const SizedBox(height: 4),
            Text(
              'BLK: $blk • Year: $year',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],

          const SizedBox(height: 6),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: StudentAttendanceScreen.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              scheduleText,
              style: const TextStyle(
                fontSize: 12,
                color: StudentAttendanceScreen.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.login, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                timeIn != null
                    ? 'Time In: ${StudentAttendanceScreen._formatDate(timeIn!)}'
                    : 'Time In: —',
                style:
                    const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.logout, size: 16, color: Colors.red),
              const SizedBox(width: 6),
              Text(
                timeOut != null
                    ? 'Time Out: ${StudentAttendanceScreen._formatDate(timeOut!)}'
                    : 'Time Out: —',
                style:
                    const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 🔹 Skeleton loader
class _AttendanceSkeleton extends StatelessWidget {
  const _AttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black12.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
