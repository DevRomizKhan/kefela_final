import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({
    super.key,
    required String selectedMemberId,
    required String selectedMemberName,
  });

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Map<String, dynamic>? _selectedUserReport;
  String _selectedReportType = 'overview';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _useDateFilter = false;

  // Cache for member creation dates
  final Map<String, DateTime> _memberCreatedAtCache = {};

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Member')
          .get();

      _members = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final createdAt = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();

        _memberCreatedAtCache[doc.id] = createdAt;

        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Unknown Member',
          'email': data['email'] ?? 'No email',
          'joinDate': data['createdAt'],
          'createdAt': createdAt,
        };
      }));
    } catch (e) {
      _showError('Failed to fetch members: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserReport(String uid, String userName) async {
    setState(() => _isLoading = true);
    try {
      final memberCreatedAt = _memberCreatedAtCache[uid] ?? DateTime.now();

      // Determine date range
      DateTime effectiveStartDate = memberCreatedAt;
      DateTime effectiveEndDate = DateTime.now();

      if (_useDateFilter && _startDate != null && _endDate != null) {
        effectiveStartDate = _startDate!.isAfter(memberCreatedAt)
            ? _startDate!
            : memberCreatedAt;
        effectiveEndDate = _endDate!;
      }

      final results = await Future.wait([
        _fetchMeetingAttendance(uid, effectiveStartDate, effectiveEndDate),
        _fetchPrayerAttendance(uid, effectiveStartDate, effectiveEndDate),
        _fetchTaskPerformance(uid, effectiveStartDate, effectiveEndDate),
      ]);

      final meetingData = results[0] as Map<String, dynamic>;
      final prayerData = results[1] as Map<String, dynamic>;
      final taskData = results[2] as Map<String, dynamic>;

      setState(() {
        _selectedUserReport = {
          'uid': uid,
          'userName': userName,
          'meetingReport': meetingData['report'],
          'totalMeetings': meetingData['totalMeetings'],
          'attendedMeetings': meetingData['attendedMeetings'],
          'attendanceRate': meetingData['attendanceRate'].toDouble(),
          'prayerStats': prayerData,
          'taskStats': taskData,
          'reportType': _selectedReportType,
          'dateRange': _useDateFilter && _startDate != null && _endDate != null
              ? '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
              : 'All Time (Since ${DateFormat('MMM dd, yyyy').format(memberCreatedAt)})',
          'effectiveStartDate': effectiveStartDate,
          'effectiveEndDate': effectiveEndDate,
        };
      });
    } catch (e) {
      _showError('Failed to fetch report: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _fetchMeetingAttendance(
      String uid, DateTime startDate, DateTime endDate) async {
    final meetingsSnapshot = await _firestore
        .collection('meetings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .get();

    final report = <String, dynamic>{};
    int totalMeetings = meetingsSnapshot.docs.length;
    int attendedMeetings = 0;

    final futures = meetingsSnapshot.docs.map((meetingDoc) async {
      final meetingId = meetingDoc.id;
      final meetingData = meetingDoc.data();
      try {
        final attendanceDoc = await _firestore
            .collection('meetings')
            .doc(meetingId)
            .collection('attendance')
            .doc(uid)
            .get();

        if (attendanceDoc.exists) {
          final data = attendanceDoc.data() as Map<String, dynamic>;
          final attendancePercentage = data['attendancePercentage'] ?? '0%';
          final startAttended = data['startAttended'] == true;
          final endAttended = data['endAttended'] == true;

          report[meetingId] = {
            'title': meetingData['title'] ?? 'No Title',
            'date': meetingData['date'],
            'startTime': meetingData['startTime'] ?? 'N/A',
            'endTime': meetingData['endTime'] ?? 'N/A',
            'attendancePercentage': attendancePercentage,
            'startAttended': startAttended,
            'endAttended': endAttended,
            'timestamp': data['timestamp'],
          };

          if (attendancePercentage != '0%') {
            attendedMeetings++;
          }
        } else {
          final meetingDate = (meetingData['date'] as Timestamp).toDate();
          report[meetingId] = {
            'title': meetingData['title'] ?? 'No Title',
            'date': meetingData['date'],
            'startTime': meetingData['startTime'] ?? 'N/A',
            'endTime': meetingData['endTime'] ?? 'N/A',
            'attendancePercentage': '0%',
            'startAttended': false,
            'endAttended': false,
            'timestamp': null,
          };
        }
      } catch (e) {
        print('Error fetching attendance for meeting $meetingId: $e');
        final meetingData = meetingDoc.data();
        report[meetingId] = {
          'title': meetingData['title'] ?? 'No Title',
          'date': meetingData['date'],
          'startTime': meetingData['startTime'] ?? 'N/A',
          'endTime': meetingData['endTime'] ?? 'N/A',
          'attendancePercentage': '0%',
          'startAttended': false,
          'endAttended': false,
          'timestamp': null,
        };
      }
    }).toList();

    await Future.wait(futures);

    final attendanceRate = totalMeetings > 0
        ? (attendedMeetings / totalMeetings) * 100
        : 0.0;

    return {
      'report': report,
      'totalMeetings': totalMeetings,
      'attendedMeetings': attendedMeetings,
      'attendanceRate': attendanceRate,
    };
  }

  Future<Map<String, dynamic>> _fetchPrayerAttendance(
      String uid, DateTime startDate, DateTime endDate) async {
    try {
      final prayerSnapshot = await _firestore
          .collection('prayer_attendance')
          .doc(uid)
          .collection('records')
          .where('date',
          isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startDate))
          .where('date',
          isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endDate))
          .get();
      int totalPrayers = 0;
      int completedPrayers = 0;
      final dailyStats = <Map<String, dynamic>>[];
      for (var doc in prayerSnapshot.docs) {
        final data = doc.data();
        int dayPrayers = 0;
        if (data['fajr'] == true) dayPrayers++;
        if (data['dhuhr'] == true) dayPrayers++;
        if (data['asr'] == true) dayPrayers++;
        if (data['maghrib'] == true) dayPrayers++;
        if (data['isha'] == true) dayPrayers++;
        totalPrayers += 5;
        completedPrayers += dayPrayers;
        dailyStats.add({
          'date': data['date'],
          'completed': dayPrayers,
          'total': 5,
          'percentage': (dayPrayers / 5) * 100,
        });
      }
      final prayerRate =
      totalPrayers > 0 ? (completedPrayers / totalPrayers) * 100 : 0.0;
      return {
        'totalPrayers': totalPrayers,
        'completedPrayers': completedPrayers,
        'prayerRate': prayerRate,
        'dailyStats': dailyStats,
      };
    } catch (e) {
      return {
        'totalPrayers': 0,
        'completedPrayers': 0,
        'prayerRate': 0.0,
        'dailyStats': [],
      };
    }
  }

  Future<Map<String, dynamic>> _fetchTaskPerformance(
      String uid, DateTime startDate, DateTime endDate) async {
    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: uid)
          .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      int totalTasks = tasksSnapshot.docs.length;
      int completedTasks = tasksSnapshot.docs
          .where((doc) => doc['status'] == 'completed')
          .length;
      int overdueTasks = tasksSnapshot.docs.where((doc) {
        final dueDate = (doc['dueDate'] as Timestamp).toDate();
        return dueDate.isBefore(DateTime.now()) && doc['status'] != 'completed';
      }).length;
      final completionRate =
      totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
      double avgCompletionTime = 0.0;
      int tasksWithCompletion = 0;
      for (var task in tasksSnapshot.docs) {
        if (task['status'] == 'completed' &&
            task['createdAt'] != null &&
            task['updatedAt'] != null) {
          final created = (task['createdAt'] as Timestamp).toDate();
          final completed = (task['updatedAt'] as Timestamp).toDate();
          final difference = completed.difference(created).inHours.toDouble();
          avgCompletionTime += difference;
          tasksWithCompletion++;
        }
      }
      if (tasksWithCompletion > 0) {
        avgCompletionTime = avgCompletionTime / tasksWithCompletion;
      }
      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'overdueTasks': overdueTasks,
        'completionRate': completionRate,
        'avgCompletionTime': avgCompletionTime,
        'tasks': tasksSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'],
            'status': data['status'],
            'dueDate': data['dueDate'],
            'feedback': data['feedback'] ?? '',
          };
        }).toList(),
      };
    } catch (e) {
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'overdueTasks': 0,
        'completionRate': 0.0,
        'avgCompletionTime': 0.0,
        'tasks': [],
      };
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDateRangePicker() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Select Date Range',
              style: TextStyle(color: Colors.black),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Filter Toggle - FIXED VERSION
                SwitchListTile(
                  title: const Text('Use Date Filter',
                      style: TextStyle(color: Colors.black)),
                  value: _useDateFilter,
                  onChanged: (value) {
                    setDialogState(() {
                      _useDateFilter = value;
                    });
                  },
                  activeColor: Colors.green,
                ),
                if (_useDateFilter) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Start Date',
                        style: TextStyle(color: Colors.black)),
                    subtitle: Text(
                      _startDate != null
                          ? DateFormat('MMM dd, yyyy').format(_startDate!)
                          : 'Select start date',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.green),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          _startDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('End Date',
                        style: TextStyle(color: Colors.black)),
                    subtitle: Text(
                      _endDate != null
                          ? DateFormat('MMM dd, yyyy').format(_endDate!)
                          : 'Select end date',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.green),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          _endDate = picked;
                        });
                      }
                    },
                  ),
                  if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Warning: Start date is after end date',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Update the main state after dialog closes
                  setState(() {
                    // State is already updated via setDialogState
                  });

                  // Refresh report if one is selected
                  if (_selectedUserReport != null) {
                    _fetchUserReport(_selectedUserReport!['uid'], _selectedUserReport!['userName']);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  // FIXED PDF DOWNLOAD METHOD
  Future<void> _downloadReportAsPDF() async {
    if (_selectedUserReport == null) return;

    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();

      final meetingReport = _selectedUserReport!;
      final userName = meetingReport['userName'];
      final dateRange = meetingReport['dateRange'];

      // Title Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Member Performance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Member Name: $userName',
                    style: pw.TextStyle(fontSize: 16)),
                pw.Text('Report Period: $dateRange',
                    style: pw.TextStyle(fontSize: 16)),
                pw.Text('Generated on: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 30),
                pw.Text('This report contains:', style: pw.TextStyle(fontSize: 14)),
                pw.Bullet(text: 'Meeting Attendance Summary'),
                pw.Bullet(text: 'Prayer Attendance Details'),
                pw.Bullet(text: 'Task Performance Analysis'),
              ],
            );
          },
        ),
      );

      // Meeting Attendance Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 1,
                  child: pw.Text('Meeting Attendance Report'),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Meetings: ${meetingReport['totalMeetings']}'),
                    pw.Text('Attended: ${meetingReport['attendedMeetings']}'),
                    pw.Text('Rate: ${meetingReport['attendanceRate'].toStringAsFixed(1)}%'),
                  ],
                ),
                pw.SizedBox(height: 20),
                ..._buildMeetingPDFContent(meetingReport),
              ],
            );
          },
        ),
      );

      // Prayer Attendance Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final prayerStats = meetingReport['prayerStats'];
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 1,
                  child: pw.Text('Prayer Attendance Report'),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Prayers: ${prayerStats['totalPrayers']}'),
                    pw.Text('Completed: ${prayerStats['completedPrayers']}'),
                    pw.Text('Rate: ${prayerStats['prayerRate'].toStringAsFixed(1)}%'),
                  ],
                ),
                pw.SizedBox(height: 20),
                ..._buildPrayerPDFContent(prayerStats),
              ],
            );
          },
        ),
      );

      // Task Performance Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final taskStats = meetingReport['taskStats'];
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 1,
                  child: pw.Text('Task Performance Report'),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Tasks: ${taskStats['totalTasks']}'),
                    pw.Text('Completed: ${taskStats['completedTasks']}'),
                    pw.Text('Overdue: ${taskStats['overdueTasks']}'),
                  ],
                ),
                pw.SizedBox(height: 20),
                ..._buildTaskPDFContent(taskStats),
              ],
            );
          },
        ),
      );

      // METHOD 1: Try using Printing.sharePdf (most reliable)
      try {
        final pdfBytes = await pdf.save();
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'member_report_${userName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        _showSuccess('PDF report generated and shared successfully!');
        return;
      } catch (e) {
        print('Printing.sharePdf failed: $e');
      }

      // METHOD 2: Try direct file system access with better error handling
      try {
        // Get temporary directory with null safety
        final Directory? tempDir = await getTemporaryDirectory();
        if (tempDir == null) {
          throw Exception('Could not access temporary directory');
        }

        final file = File("${tempDir.path}/member_report_${userName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf");
        await file.writeAsBytes(await pdf.save());

        // Try to open the file using multiple methods
        bool fileOpened = false;

        // Method 2A: Try using url_launcher
        try {
          final uri = Uri.file(file.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            fileOpened = true;
          }
        } catch (e) {
          print('url_launcher failed: $e');
        }

        // Method 2B: Try using share_plus as fallback
        if (!fileOpened) {
          try {
            await Share.shareXFiles([XFile(file.path)], text: 'Member Performance Report');
            fileOpened = true;
          } catch (e) {
            print('share_plus failed: $e');
          }
        }

        if (fileOpened) {
          _showSuccess('PDF report downloaded successfully!');
        } else {
          _showSuccess('PDF saved to: ${file.path}');
        }
      } catch (e) {
        // METHOD 3: Final fallback - just save the PDF and show path
        print('PDF generation error: $e');
        _showError('PDF generated but could not open. Error: ${e.toString()}');
      }

    } catch (e) {
      _showError('Failed to generate PDF: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<pw.Widget> _buildMeetingPDFContent(Map<String, dynamic> report) {
    final meetingsReport = report['meetingReport'] as Map<String, dynamic>;
    if (meetingsReport.isEmpty) {
      return [pw.Text('No meeting records found.')];
    }

    return [
      pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Meeting Title',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Date',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Attendance',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Status',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          ...meetingsReport.entries.map((entry) {
            final data = entry.value as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final status = data['startAttended'] && data['endAttended']
                ? 'Full'
                : data['startAttended'] || data['endAttended']
                ? 'Partial'
                : 'Absent';

            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(data['title']),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(DateFormat('MMM dd, yyyy').format(date)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(data['attendancePercentage']),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(status),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildPrayerPDFContent(Map<String, dynamic> prayerStats) {
    final dailyStats = prayerStats['dailyStats'] as List<Map<String, dynamic>>;
    if (dailyStats.isEmpty) {
      return [pw.Text('No prayer records found.')];
    }

    return [
      pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Date',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Completed',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Total',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Percentage',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          ...dailyStats.map((day) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(day['date']),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(day['completed'].toString()),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(day['total'].toString()),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${day['percentage'].toStringAsFixed(1)}%'),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildTaskPDFContent(Map<String, dynamic> taskStats) {
    final tasks = taskStats['tasks'] as List<Map<String, dynamic>>;
    if (tasks.isEmpty) {
      return [pw.Text('No task records found.')];
    }

    return [
      pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Task Title',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Due Date',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Status',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Feedback',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          ...tasks.map((task) {
            final dueDate = (task['dueDate'] as Timestamp).toDate();
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(task['title']),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(DateFormat('MMM dd, yyyy').format(dueDate)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(task['status']),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(task['feedback'] ?? ''),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.analytics,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Member Reports',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedUserReport != null)
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.green),
                            onPressed: _downloadReportAsPDF,
                            tooltip: 'Download PDF Report',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Report Type Selection
                    DropdownButtonFormField<String>(
                      value: _selectedReportType,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Report Type',
                        labelStyle: const TextStyle(color: Colors.black54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'overview',
                          child: Text('Overview Report',
                              style: TextStyle(color: Colors.black)),
                        ),
                        DropdownMenuItem(
                          value: 'attendance',
                          child: Text('Attendance Report',
                              style: TextStyle(color: Colors.black)),
                        ),
                        DropdownMenuItem(
                          value: 'prayer',
                          child: Text('Prayer Report',
                              style: TextStyle(color: Colors.black)),
                        ),
                        DropdownMenuItem(
                          value: 'tasks',
                          child: Text('Tasks Report',
                              style: TextStyle(color: Colors.black)),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedReportType = value!),
                    ),
                    const SizedBox(height: 12),
                    // Date Range Selection
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range,
                                color: Colors.green, size: 16),
                            label: Text(
                              _useDateFilter && _startDate != null && _endDate != null
                                  ? '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                                  : 'All Time (No Filter)',
                              style: const TextStyle(color: Colors.black),
                            ),
                            onPressed: _showDateRangePicker,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Search members by name or email...',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon:
                        const Icon(Icons.search, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style: const TextStyle(color: Colors.black),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ],
                ),
              ),
            ),
            // Members List or Report
            Expanded(
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator(color: Colors.green))
                  : _selectedUserReport != null
                  ? _buildUserReport()
                  : _buildMembersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    final filteredMembers = _searchQuery.isEmpty
        ? _members
        : _members
        .where((member) =>
    member['name']
        .toLowerCase()
        .contains(_searchQuery.toLowerCase()) ||
        member['email']
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
    if (filteredMembers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No members found',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        final joinDate = member['createdAt'] is Timestamp
            ? (member['createdAt'] as Timestamp).toDate()
            : member['createdAt'] is DateTime
            ? member['createdAt']
            : DateTime.now();

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.2),
              child: Text(
                member['name'][0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            title: Text(
              member['name'],
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['email'],
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  'Joined: ${DateFormat('MMM dd, yyyy').format(joinDate)}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.analytics, color: Colors.green, size: 20),
            ),
            onTap: () => _fetchUserReport(member['uid'], member['name']),
          ),
        );
      },
    );
  }

  Widget _buildUserReport() {
    final report = _selectedUserReport!;
    final userName = report['userName'];
    final dateRange = report['dateRange'];

    return Column(
      children: [
        // Download Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download Complete Report as PDF'),
            onPressed: _downloadReportAsPDF,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report Header
                _buildReportHeader(userName, dateRange, report),
                const SizedBox(height: 20),
                // Show different reports based on selected type
                if (_selectedReportType == 'overview') _buildOverviewReport(report),
                if (_selectedReportType == 'attendance')
                  _buildAttendanceReport(report),
                if (_selectedReportType == 'prayer') _buildPrayerReport(report),
                if (_selectedReportType == 'tasks') _buildTasksReport(report),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportHeader(
      String userName, String dateRange, Map<String, dynamic> report) {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.2),
                  radius: 30,
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date Range: $dateRange',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(() => _selectedUserReport = null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quick Stats Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickStat(
                    'Meetings',
                    '${report['attendedMeetings']}/${report['totalMeetings']}',
                    Icons.meeting_room,
                    _getPerformanceColor(report['attendanceRate']),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickStat(
                    'Prayers',
                    '${report['prayerStats']['completedPrayers']}/${report['prayerStats']['totalPrayers']}',
                    Icons.mosque,
                    _getPerformanceColor(report['prayerStats']['prayerRate']),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickStat(
                    'Tasks',
                    '${report['taskStats']['completedTasks']}/${report['taskStats']['totalTasks']}',
                    Icons.assignment_turned_in,
                    _getPerformanceColor(report['taskStats']['completionRate']),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewReport(Map<String, dynamic> report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _buildPerformanceCard(
              'Meeting Attendance',
              '${report['attendanceRate'].toStringAsFixed(1)}%',
              Icons.meeting_room,
              _getPerformanceColor(report['attendanceRate']),
              '${report['attendedMeetings']} of ${report['totalMeetings']} meetings',
            ),
            _buildPerformanceCard(
              'Prayer Consistency',
              '${report['prayerStats']['prayerRate'].toStringAsFixed(1)}%',
              Icons.mosque,
              _getPerformanceColor(report['prayerStats']['prayerRate']),
              '${report['prayerStats']['completedPrayers']} of ${report['prayerStats']['totalPrayers']} prayers',
            ),
            _buildPerformanceCard(
              'Task Completion',
              '${report['taskStats']['completionRate'].toStringAsFixed(1)}%',
              Icons.assignment_turned_in,
              _getPerformanceColor(report['taskStats']['completionRate']),
              '${report['taskStats']['completedTasks']} of ${report['taskStats']['totalTasks']} tasks',
            ),
            _buildPerformanceCard(
              'Average Completion',
              '${report['taskStats']['avgCompletionTime'].toStringAsFixed(1)}h',
              Icons.timer,
              Colors.blue,
              'Average task completion time',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceReport(Map<String, dynamic> report) {
    final meetingsReport = report['meetingReport'] as Map<String, dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meeting Attendance Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (meetingsReport.isEmpty)
          _buildEmptyState(
              'No meeting records found for this period', Icons.meeting_room)
        else
          ...meetingsReport.entries.map((entry) {
            final data = entry.value as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getPercentageColorFromString(
                                data['attendancePercentage']),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              data['attendancePercentage'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildAttendanceChip('Start', data['startAttended']),
                        const SizedBox(width: 8),
                        _buildAttendanceChip('End', data['endAttended']),
                        const Spacer(),
                        Chip(
                          label: Text(
                            data['startAttended'] && data['endAttended']
                                ? 'Full'
                                : data['startAttended'] || data['endAttended']
                                ? 'Partial'
                                : 'Absent',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                          backgroundColor:
                          data['startAttended'] && data['endAttended']
                              ? Colors.green
                              : data['startAttended'] || data['endAttended']
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildPrayerReport(Map<String, dynamic> report) {
    final prayerStats = report['prayerStats'];
    final dailyStats = prayerStats['dailyStats'] as List<Map<String, dynamic>>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prayer Attendance Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Prayer Performance',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${prayerStats['completedPrayers']} of ${prayerStats['totalPrayers']} prayers completed',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        '${prayerStats['prayerRate'].toStringAsFixed(1)}% consistency rate',
                        style: TextStyle(
                          color:
                          _getPerformanceColor(prayerStats['prayerRate']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(prayerStats['prayerRate'])
                        .withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mosque,
                    color: _getPerformanceColor(prayerStats['prayerRate']),
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Daily Prayer Completion',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        if (dailyStats.isEmpty)
          _buildEmptyState(
              'No prayer records found for this period', Icons.mosque)
        else
          ...dailyStats.map((day) {
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  _getPerformanceColor(day['percentage']).withOpacity(0.2),
                  child: Text(
                    '${day['completed']}',
                    style: TextStyle(
                      color: _getPerformanceColor(day['percentage']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  day['date'],
                  style: const TextStyle(color: Colors.black),
                ),
                subtitle: Text(
                  '${day['completed']}/5 prayers (${day['percentage'].toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: _getPerformanceColor(day['percentage']),
                  ),
                ),
                trailing: Chip(
                  label: Text(
                    '${day['percentage'].toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getPerformanceColor(day['percentage']),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTasksReport(Map<String, dynamic> report) {
    final taskStats = report['taskStats'];
    final tasks = taskStats['tasks'] as List<Map<String, dynamic>>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Performance Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTaskStat(
                    'Total', '${taskStats['totalTasks']}', Icons.assignment),
                _buildTaskStat('Completed', '${taskStats['completedTasks']}',
                    Icons.check_circle),
                _buildTaskStat(
                    'Overdue', '${taskStats['overdueTasks']}', Icons.warning),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Task Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          _buildEmptyState('No tasks found for this period', Icons.assignment)
        else
          ...tasks.map((task) {
            final dueDate = (task['dueDate'] as Timestamp).toDate();
            final isOverdue = dueDate.isBefore(DateTime.now()) &&
                task['status'] != 'completed';
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  task['status'] == 'completed'
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: task['status'] == 'completed'
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text(
                  task['title'],
                  style: TextStyle(
                    color: Colors.black,
                    decoration: task['status'] == 'completed'
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.grey,
                      ),
                    ),
                    if (task['feedback'] != null && task['feedback'].isNotEmpty)
                      Text(
                        'Feedback: ${task['feedback']}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Chip(
                  label: Text(
                    task['status'] == 'completed' ? 'Done' : 'Pending',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: task['status'] == 'completed'
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTaskStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChip(String label, bool attended) {
    return Chip(
      label: Text(
        '$label: ${attended ? 'Present' : 'Absent'}',
        style: TextStyle(
          fontSize: 10,
          color: attended ? Colors.white : Colors.black,
        ),
      ),
      backgroundColor: attended ? Colors.green : Colors.grey[300],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getPercentageColorFromString(String percentage) {
    switch (percentage) {
      case '100%':
        return Colors.green;
      case '50%':
        return Colors.orange;
      case '0%':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}