import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArchivedSubjectsScreen extends StatelessWidget {
  const ArchivedSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Subjects'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .where('teacherId', isEqualTo: user.uid)
            .where('isArchived', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snapshot.data!.docs;

          if (subjects.isEmpty) {
            return const Center(child: Text('No archived subjects'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];

              return Card(
                child: ListTile(
                  title: Text(subject['subjectName']),
                  subtitle: Text(subject['description']),
                  trailing: IconButton(
                    icon: const Icon(Icons.unarchive),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('subjects')
                          .doc(subject.id)
                          .update({'isArchived': false});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
