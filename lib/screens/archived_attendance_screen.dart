import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArchivedAttendanceScreen extends StatelessWidget {
  const ArchivedAttendanceScreen({super.key});

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
        title: const Text('Archived Attendance'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('studentId', isEqualTo: student.uid)
            .where('isArchived', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs;

          if (records.isEmpty) {
            return const Center(child: Text('No archived attendance'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final subjectId = record['subjectId'];
              final scannedAt =
                  (record['scannedAt'] as Timestamp).toDate();

              return FutureBuilder<DocumentSnapshot>(
                future: getSubject(subjectId),
                builder: (context, subjectSnapshot) {
                  String subjectName = 'Subject deleted';

                  if (subjectSnapshot.hasData &&
                      subjectSnapshot.data!.exists &&
                      subjectSnapshot.data!.data() != null) {
                    final data =
                        subjectSnapshot.data!.data() as Map<String, dynamic>;
                    subjectName = data['subjectName'];
                  }

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
                    child: Row(
                      children: [
                        const Icon(Icons.book_outlined,
                            color: primaryColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                subjectName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(scannedAt),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.unarchive),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('attendance')
                                .doc(record.id)
                                .update({'isArchived': false});
                          },
                        ),
                      ],
                    ),
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

    return '${date.month}/${date.day}/${date.year} • '
        '$hour:$minute $period';
  }
}
