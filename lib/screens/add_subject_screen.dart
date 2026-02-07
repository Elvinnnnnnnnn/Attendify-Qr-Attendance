import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final TextEditingController subjectNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController blkController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  static const primaryColor = Color(0xFFD72520);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> addSubject() async {
    if (subjectNameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        blkController.text.isEmpty ||
        yearController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;

    final classDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    await FirebaseFirestore.instance.collection('subjects').add({
      'subjectName': subjectNameController.text.trim(),
      'description': descriptionController.text.trim(),
      'blk': blkController.text.trim(),
      'year': yearController.text.trim(),
      'teacherId': user.uid,
      'createdAt': Timestamp.now(),
      'classDate': Timestamp.fromDate(classDateTime),
      'classTime': _formatTime(selectedTime!),
      'isArchived': false,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subject created')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Subject'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Create New Subject',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            _input(subjectNameController, 'Subject Name', Icons.book),
            const SizedBox(height: 20),
            _input(descriptionController, 'Description', Icons.description),
            const SizedBox(height: 20),
            _input(blkController, 'Block (BLK)', Icons.group),
            const SizedBox(height: 20),
            _input(yearController, 'Year', Icons.school),
            const SizedBox(height: 20),
            _picker('Class Date', Icons.calendar_today, _pickDate,
                selectedDate == null
                    ? 'Select date'
                    : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'),
            const SizedBox(height: 20),
            _picker('Class Time', Icons.access_time, _pickTime,
                selectedTime == null
                    ? 'Select time'
                    : _formatTime(selectedTime!)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: addSubject,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: primaryColor,
              ),
              child: const Text('Create Subject'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
      TextEditingController c, String label, IconData icon) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _picker(
      String label, IconData icon, VoidCallback onTap, String value) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(value),
      ),
    );
  }
}
