import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GenerateQrScreen extends StatefulWidget {
  final String subjectId;

  const GenerateQrScreen({super.key, required this.subjectId});

  static const primaryColor = Color(0xFFD72520);

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  String mode = 'TIME_IN';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final String qrData = '${widget.subjectId}|${user.uid}|$mode';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance QR'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Scan to Mark Attendance',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: GenerateQrScreen.primaryColor,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              mode == 'TIME_IN'
                  ? 'TIME IN QR (Class Start)'
                  : 'TIME OUT QR (Class End)',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(24),
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
              child: QrImageView(
                data: qrData,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => mode = 'TIME_IN');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mode == 'TIME_IN'
                          ? GenerateQrScreen.primaryColor
                          : Colors.grey.shade300,
                      foregroundColor:
                          mode == 'TIME_IN' ? Colors.white : Colors.black,
                    ),
                    child: const Text('TIME IN'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => mode = 'TIME_OUT');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mode == 'TIME_OUT'
                          ? Colors.black
                          : Colors.grey.shade300,
                      foregroundColor:
                          mode == 'TIME_OUT' ? Colors.white : Colors.black,
                    ),
                    child: const Text('TIME OUT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
