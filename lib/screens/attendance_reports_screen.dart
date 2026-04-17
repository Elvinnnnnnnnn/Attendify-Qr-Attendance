import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendanceReportsScreen extends StatefulWidget {
  const AttendanceReportsScreen({super.key});

  @override
  State<AttendanceReportsScreen> createState() => _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {

  DateTime? startDate;
  DateTime? endDate;

  DateTime weekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday % 7),
  );

  int totalStudents = 0;

  String searchQuery = '';
  
  String? selectedSubjectId;
  List<QueryDocumentSnapshot> subjects = [];

  Future<void> _loadSubjects() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('subjects')
        .get();

    setState(() {
      subjects = snapshot.docs;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  String _getSubjectName() {
    if (selectedSubjectId == null) return "All Subjects";

    final subject = subjects.firstWhere(
      (s) => s.id == selectedSubjectId,
      orElse: () => subjects.first,
    );

    return subject['subjectName'] ?? 'Unknown';
  }

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

    var query = firestore
        .collection('attendance')
        .where('timeInAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
        .where('timeInAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfRange));

    if (selectedSubjectId != null) {
      query = query.where('subjectId', isEqualTo: selectedSubjectId);
    }

    final attendanceSnapshot = await query.get();

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

  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    final stats = await _getAdminStatsRange(startDate, endDate);
    final present = await _getPresentStudents(startDate, endDate);
    final absent = await _getAbsentStudents(startDate, endDate);

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [

          // HEADER
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#D72520'),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ATTENDIFY REPORT',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      startDate == null || endDate == null
                          ? 'No Date'
                          : '${startDate!.month}/${startDate!.day} - ${endDate!.month}/${endDate!.day}',
                      style: const pw.TextStyle(color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Subject: ${_getSubjectName()}',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // STATS CARDS
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _pdfStatCard('Enrolled', stats['enrolled'], PdfColors.blue),
              _pdfStatCard('Present', stats['present'], PdfColors.green),
              _pdfStatCard('Absent', stats['absent'], PdfColors.red),
            ],
          ),

          pw.SizedBox(height: 20),

          // PRESENT TABLE
          pw.Text(
            'Present Students',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green100),
                children: [
                  _pdfCell('Name', bold: true),
                ],
              ),
              ...present.map((s) => pw.TableRow(
                children: [
                  _pdfCell(s['name'] ?? 'No Name'),
                ],
              )),
            ],
          ),

          pw.SizedBox(height: 20),

          // ABSENT TABLE
          pw.Text(
            'Absent Students',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.red100),
                children: [
                  _pdfCell('Name', bold: true),
                ],
              ),
              ...absent.map((s) => pw.TableRow(
                children: [
                  _pdfCell(s['name'] ?? 'No Name'),
                ],
              )),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.Widget _pdfStatCard(String title, int? value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '${value ?? 0}',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(title),
        ],
      ),
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

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

            const SizedBox(height: 20),

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

            // WEEK HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      weekStart = weekStart.subtract(const Duration(days: 7));
                    });
                  },
                ),
                Column(
                  children: [
                    const Text(
                      'Weekly Attendance',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${weekStart.month}/${weekStart.day} - ${weekStart.add(const Duration(days: 6)).month}/${weekStart.add(const Duration(days: 6)).day}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      weekStart = weekStart.add(const Duration(days: 7));
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // GRAPH (MODERN)
            FutureBuilder(
              future: _getWeeklyData(weekStart),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data as List<int>;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  height: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance Graph',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: BarChart(
                          BarChartData(
                            minY: 0,
                            maxY: (data.isEmpty ? 5 : data.reduce((a, b) => a > b ? a : b) + 5).toDouble(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 5,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5,
                                  reservedSize: 28,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) {
                                    final date = weekStart.add(Duration(days: value.toInt()));

                                    return Column(
                                      children: [
                                        Text(
                                          ['S','M','T','W','T','F','S'][date.weekday % 7],
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        Text(
                                          '${date.day}',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(data.length, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: data[index].toDouble(),
                                    width: 18,
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFD72520),
                                        Color(0xFFFF6B6B),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            FutureBuilder(
              future: _getWeeklyData(weekStart),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final data = snapshot.data as List<int>;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: const [
                          Expanded(
                            child: Text(
                              'Day',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Present',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Absent',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      const Divider(),

                      const SizedBox(height: 16),

                      ...List.generate(data.length, (index) {
                        final date = weekStart.add(Duration(days: index));

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][date.weekday % 7]} ${date.day}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),

                              // PRESENT
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    data[index].toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              // ABSENT
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (totalStudents - data[index]).toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search student...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String?>(
              value: selectedSubjectId,
              hint: const Text('Select Subject'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Subjects'),
                ),
                ...subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject.id,
                    child: Text(subject['subjectName'] ?? 'No Name'),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedSubjectId = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            FutureBuilder(
              future: _getPresentStudents(startDate, endDate),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final students = snapshot.data as List<Map<String, dynamic>>;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Present Students',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (students.isEmpty)
                        const Text('No present students'),

                      ...students
                        .where((student) =>
                            (student['name'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(searchQuery))
                        .map((student) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  student['name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            FutureBuilder(
              future: _getAbsentStudents(startDate, endDate),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final students = snapshot.data as List<Map<String, dynamic>>;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Absent Students',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (students.isEmpty)
                        const Text('No absent students'),

                      ...students
                        .where((student) =>
                            (student['name'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(searchQuery))
                        .map((student) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Colors.red),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  student['name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _exportPDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export PDF'),
            ),
          ],
        ),
      ),
    );
  }

  // SAME FUNCTIONS (NO CHANGE)

  Future<List<int>> _getWeeklyData(DateTime startOfWeek) async {
    final firestore = FirebaseFirestore.instance;
    List<int> weeklyData = [];

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));

      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      var query = firestore
          .collection('attendance')
          .where('timeInAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timeInAt',
              isLessThanOrEqualTo: Timestamp.fromDate(end));

      if (selectedSubjectId != null) {
        query = query.where('subjectId', isEqualTo: selectedSubjectId);
      }

      final snapshot = await query.get();

      final count = snapshot.docs.map((doc) => doc['studentId']).toSet().length;
      weeklyData.add(count);
    }

    final studentsSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    totalStudents = studentsSnapshot.docs.length;

    return weeklyData;
  }

  Future<List<Map<String, dynamic>>> _getPresentStudents(DateTime? start, DateTime? end) async {
    final firestore = FirebaseFirestore.instance;

    if (start == null || end == null) return [];

    final startOfRange = DateTime(start.year, start.month, start.day);
    final endOfRange = DateTime(end.year, end.month, end.day, 23, 59, 59);

    var query = firestore
        .collection('attendance')
        .where('timeInAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
        .where('timeInAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfRange));

    if (selectedSubjectId != null) {
      query = query.where('subjectId', isEqualTo: selectedSubjectId);
    }

    final attendanceSnapshot = await query.get();

    final presentIds = attendanceSnapshot.docs.map((doc) => doc['studentId']).toSet();

    final studentsSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    return studentsSnapshot.docs
        .where((doc) => presentIds.contains(doc.id))
        .map((doc) => doc.data())
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getAbsentStudents(DateTime? start, DateTime? end) async {
    final firestore = FirebaseFirestore.instance;

    if (start == null || end == null) return [];

    final startOfRange = DateTime(start.year, start.month, start.day);
    final endOfRange = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final studentsSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

      var query = firestore
        .collection('attendance')
        .where('timeInAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
        .where('timeInAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfRange));

    if (selectedSubjectId != null) {
      query = query.where('subjectId', isEqualTo: selectedSubjectId);
    }

    final attendanceSnapshot = await query.get();
    final presentIds = attendanceSnapshot.docs.map((doc) => doc['studentId']).toSet();

    return studentsSnapshot.docs
        .where((doc) => !presentIds.contains(doc.id))
        .map((doc) => doc.data())
        .toList();
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
          Text(title),
        ],
      ),
    );
  }
}