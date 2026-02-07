import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSubjectScreen extends StatefulWidget {
  final String subjectId;
  final String currentName;
  final String currentDescription;

  const EditSubjectScreen({
    super.key,
    required this.subjectId,
    required this.currentName,
    required this.currentDescription,
  });

  @override
  State<EditSubjectScreen> createState() => _EditSubjectScreenState();
}

class _EditSubjectScreenState extends State<EditSubjectScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController blkController;
  late TextEditingController yearController;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  static const primaryColor = Color(0xFFD72520);

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.currentName);
    descriptionController =
        TextEditingController(text: widget.currentDescription);
    blkController = TextEditingController();
    yearController = TextEditingController();

    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final doc = await FirebaseFirestore.instance
        .collection('subjects')
        .doc(widget.subjectId)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    blkController.text = data['blk'] ?? '';
    yearController.text = data['year'] ?? '';

    if (data['classDate'] != null) {
      selectedDate =
          (data['classDate'] as Timestamp).toDate();
    }

    if (data['classTime'] != null && selectedDate != null) {
      // time string is already formatted, just keep it
      // we only need TimeOfDay for picker
      final now = DateTime.now();
      selectedTime = TimeOfDay.fromDateTime(now);
    }

    setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> updateSubject() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final blk = blkController.text.trim();
    final year = yearController.text.trim();

    if (name.isEmpty ||
        description.isEmpty ||
        blk.isEmpty ||
        year.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final classDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    await FirebaseFirestore.instance
        .collection('subjects')
        .doc(widget.subjectId)
        .update({
      'subjectName': name,
      'description': description,
      'blk': blk,
      'year': year,
      'classDate': Timestamp.fromDate(classDateTime),
      'classTime': _formatTime(selectedTime!),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subject updated')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Subject'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              'Update Subject Details',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Subject Name',
                      prefixIcon:
                          const Icon(Icons.book_outlined),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon:
                          const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: blkController,
                    decoration: InputDecoration(
                      labelText: 'Block (BLK)',
                      prefixIcon:
                          const Icon(Icons.group_outlined),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: yearController,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      prefixIcon:
                          const Icon(Icons.school_outlined),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Class Date',
                        prefixIcon:
                            const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        selectedDate == null
                            ? 'Select date'
                            : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Class Time',
                        prefixIcon:
                            const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        selectedTime == null
                            ? 'Select time'
                            : _formatTime(selectedTime!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: updateSubject,
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, 56),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Update Subject',
                      style: TextStyle(fontSize: 16),
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
