import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_subject_screen.dart';
import 'generate_qr_screen.dart';
import 'teacher_attendance_screen.dart';
import 'archived_subjects_screen.dart';

class TeacherSubjectsScreen extends StatefulWidget {
  const TeacherSubjectsScreen({super.key});

  static const primaryColor = Color(0xFFD72520);

  @override
  State<TeacherSubjectsScreen> createState() =>
      _TeacherSubjectsScreenState();
}

class _TeacherSubjectsScreenState extends State<TeacherSubjectsScreen> {
  final Set<String> _deletingIds = {};

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subjects'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArchivedSubjectsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .where('teacherId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snapshot.data!.docs.where((doc) {
            if (_deletingIds.contains(doc.id)) return false;
            final data = doc.data() as Map<String, dynamic>;
            return data['isArchived'] != true;
          }).toList();

          if (subjects.isEmpty) {
            return const Center(
              child: Text('No subjects yet',
                  style: TextStyle(color: Colors.black54)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final data = subject.data() as Map<String, dynamic>;

              return _SubjectCard(
                subjectId: subject.id,
                subjectName: data['subjectName'],
                description: data['description'],
                blk: data['blk'],
                year: data['year'],
                classDate: data['classDate'],
                classTime: data['classTime'],
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditSubjectScreen(
                        subjectId: subject.id,
                        currentName: data['subjectName'],
                        currentDescription: data['description'],
                      ),
                    ),
                  );
                },
                onGenerateQR: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GenerateQrScreen(subjectId: subject.id),
                    ),
                  );
                },
                onViewAttendance: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherAttendanceScreen(
                        subjectId: subject.id,
                      ),
                    ),
                  );
                },
                onArchive: () async {
                  await FirebaseFirestore.instance
                      .collection('subjects')
                      .doc(subject.id)
                      .update({'isArchived': true});
                },
                onDelete: () async {
                  setState(() => _deletingIds.add(subject.id));
                  await FirebaseFirestore.instance
                      .collection('subjects')
                      .doc(subject.id)
                      .delete();
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// 🔹 SUBJECT CARD
class _SubjectCard extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  final String description;
  final String? blk;
  final String? year;
  final Timestamp? classDate;
  final String? classTime;
  final VoidCallback onEdit;
  final VoidCallback onGenerateQR;
  final VoidCallback onViewAttendance;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subjectId,
    required this.subjectName,
    required this.description,
    this.blk,
    this.year,
    this.classDate,
    this.classTime,
    required this.onEdit,
    required this.onGenerateQR,
    required this.onViewAttendance,
    required this.onArchive,
    required this.onDelete,
  });

  String _formatDate(Timestamp timestamp) {
    final d = timestamp.toDate();
    return '${d.month}/${d.day}/${d.year}';
  }

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
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.archive),
                onPressed: onArchive,
              ),
            ],
          ),

          Text(description,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),

          const SizedBox(height: 6),

          if (blk != null && year != null)
            Text(
              'BLK: $blk • Year: $year',
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500),
            ),

          if (classDate != null && classTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 6),
                Text(_formatDate(classDate!),
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14),
                const SizedBox(width: 6),
                Text(classTime!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              _ActionButton(
                  icon: Icons.qr_code,
                  label: 'QR',
                  onTap: onGenerateQR),
              const SizedBox(width: 12),
              _ActionButton(
                  icon: Icons.list_alt,
                  label: 'Attendance',
                  onTap: onViewAttendance),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit),
                color: TeacherSubjectsScreen.primaryColor,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 🔹 ACTION BUTTON
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              TeacherSubjectsScreen.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: TeacherSubjectsScreen.primaryColor),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        TeacherSubjectsScreen.primaryColor)),
          ],
        ),
      ),
    );
  }
}
