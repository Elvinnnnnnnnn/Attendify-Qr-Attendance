import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentScanScreen extends StatefulWidget {
  const StudentScanScreen({super.key});

  @override
  State<StudentScanScreen> createState() => _StudentScanScreenState();
}

class _StudentScanScreenState extends State<StudentScanScreen> {
  bool isProcessing = false;
  final MobileScannerController _scannerController =
      MobileScannerController();

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> handleScan(String rawQrData) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);
    await _scannerController.stop();

    try {
      final qrData = rawQrData.trim();
      debugPrint('📸 QR DATA: $qrData');

      final parts = qrData.split('|');
      if (parts.length != 3) {
        throw Exception('Invalid QR format');
      }

      final subjectId = parts[0].trim();
      final teacherId = parts[1].trim();

      // ✅ NORMALIZE MODE
      String mode = parts[2].trim().toUpperCase();
      if (mode == 'TIME_IN') mode = 'IN';
      if (mode == 'TIME_OUT') mode = 'OUT';

      final student = FirebaseAuth.instance.currentUser;
      if (student == null) throw Exception('Not logged in');

      final studentId = student.uid;
      final dateKey = _todayKey();

      final attendanceRef =
          FirebaseFirestore.instance.collection('attendance');

      final existing = await attendanceRef
          .where('subjectId', isEqualTo: subjectId)
          .where('studentId', isEqualTo: studentId)
          .where('dateKey', isEqualTo: dateKey)
          .limit(1)
          .get();

      // ================= TIME IN =================
      if (mode == 'IN') {
        if (existing.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already timed in today')),
          );
          return;
        }

        await attendanceRef.add({
          'subjectId': subjectId,
          'teacherId': teacherId,
          'studentId': studentId,
          'dateKey': dateKey,

          // 🔹 compatibility
          'scannedAt': Timestamp.now(),

          // 🔹 time in
          'timeInAt': Timestamp.now(),
          'isArchived': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Time In recorded')),
        );
      }

      // ================= TIME OUT =================
      else if (mode == 'OUT') {
        if (existing.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must Time In first')),
          );
          return;
        }

        final doc = existing.docs.first;
        final data = doc.data();

        if (data.containsKey('timeOutAt')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already timed out today')),
          );
          return;
        }

        await attendanceRef.doc(doc.id).update({
          'timeOutAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⏹ Time Out recorded')),
        );
      }

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ SCAN ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan failed')),
      );
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Attendance QR'),
        centerTitle: true,
      ),
      body: MobileScanner(
        controller: _scannerController,
        onDetect: (capture) {
          if (isProcessing) return;
          final value = capture.barcodes.first.rawValue;
          if (value != null) handleScan(value);
        },
      ),
    );
  }
}
