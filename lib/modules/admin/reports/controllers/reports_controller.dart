import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  final members = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedMember = Rx<Map<String, dynamic>?>(null);
  final reportData = Rx<Map<String, dynamic>?>(null);

  List<Map<String, dynamic>> get filteredMembers {
    if (searchQuery.value.isEmpty) return members;
    
    return members.where((member) {
      final name = member['name'].toString().toLowerCase();
      final email = member['email'].toString().toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      isLoading.value = true;

      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Member')
          .get();

      members.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Unknown Member',
          'email': data['email'] ?? 'No email',
          'createdAt': data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        };
      }).toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load members: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectMember(Map<String, dynamic> member) async {
    selectedMember.value = member;
    await loadMemberReport(member['uid'], member['name']);
  }

  Future<void> loadMemberReport(String uid, String userName) async {
    try {
      isLoading.value = true;

      final results = await Future.wait([
        _fetchTaskStats(uid),
        _fetchGroupsCount(uid),
        _fetchPrayerStats(uid),
        _fetchDonationStats(uid),
      ]);

      reportData.value = {
        'uid': uid,
        'userName': userName,
        'taskStats': results[0],
        'groupsCount': results[1],
        'prayerStats': results[2],
        'donationStats': results[3],
        'generatedAt': DateTime.now(),
      };
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load report: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _fetchTaskStats(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: uid)
          .get();

      final totalTasks = snapshot.docs.length;
      final completedTasks = snapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;
      final pendingTasks = totalTasks - completedTasks;

      return {
        'total': totalTasks,
        'completed': completedTasks,
        'pending': pendingTasks,
        'completionRate': totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0,
      };
    } catch (e) {
      return {'total': 0, 'completed': 0, 'pending': 0, 'completionRate': 0.0};
    }
  }

  Future<int> _fetchGroupsCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: uid)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> _fetchPrayerStats(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('prayer_attendance')
          .doc(uid)
          .collection('records')
          .get();

      int totalPrayers = 0;
      int completedPrayers = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['fajr'] == true) completedPrayers++;
        if (data['dhuhr'] == true) completedPrayers++;
        if (data['asr'] == true) completedPrayers++;
        if (data['maghrib'] == true) completedPrayers++;
        if (data['isha'] == true) completedPrayers++;
        totalPrayers += 5;
      }

      return {
        'totalPrayers': totalPrayers,
        'completedPrayers': completedPrayers,
        'prayerRate': totalPrayers > 0 ? (completedPrayers / totalPrayers) * 100 : 0.0,
        'daysTracked': snapshot.docs.length,
      };
    } catch (e) {
      return {
        'totalPrayers': 0,
        'completedPrayers': 0,
        'prayerRate': 0.0,
        'daysTracked': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _fetchDonationStats(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('monthlyDonationPayments')
          .where('memberId', isEqualTo: uid)
          .get();

      double totalAmount = 0;
      int verifiedCount = 0;
      int pendingCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        totalAmount += amount;

        final status = data['status']?.toString().toLowerCase() ?? 'pending';
        if (status == 'verified') {
          verifiedCount++;
        } else if (status == 'pending') {
          pendingCount++;
        }
      }

      return {
        'totalAmount': totalAmount,
        'totalDonations': snapshot.docs.length,
        'verifiedCount': verifiedCount,
        'pendingCount': pendingCount,
      };
    } catch (e) {
      return {
        'totalAmount': 0.0,
        'totalDonations': 0,
        'verifiedCount': 0,
        'pendingCount': 0,
      };
    }
  }

  Future<void> downloadReportAsPDF() async {
    if (reportData.value == null) return;

    try {
      isLoading.value = true;

      final pdf = pw.Document();
      final report = reportData.value!;
      final userName = report['userName'];
      final generatedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final taskStats = report['taskStats'] as Map<String, dynamic>;
            final prayerStats = report['prayerStats'] as Map<String, dynamic>;
            final donationStats = report['donationStats'] as Map<String, dynamic>;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'Member Performance Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Member Info
                pw.Text('Member Name: $userName',
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text('Generated on: $generatedDate',
                    style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),

                // Task Statistics
                pw.Text(
                  'Task Performance',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Total Tasks: ${taskStats['total']}'),
                pw.Text('Completed: ${taskStats['completed']}'),
                pw.Text('Pending: ${taskStats['pending']}'),
                pw.Text(
                    'Completion Rate: ${taskStats['completionRate'].toStringAsFixed(1)}%'),
                pw.SizedBox(height: 20),

                // Prayer Statistics
                pw.Text(
                  'Prayer Attendance',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Days Tracked: ${prayerStats['daysTracked']}'),
                pw.Text('Total Prayers: ${prayerStats['totalPrayers']}'),
                pw.Text('Completed: ${prayerStats['completedPrayers']}'),
                pw.Text(
                    'Prayer Rate: ${prayerStats['prayerRate'].toStringAsFixed(1)}%'),
                pw.SizedBox(height: 20),

                // Donation Statistics
                pw.Text(
                  'Donation Summary',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                    'Total Donations: ${donationStats['totalDonations']}'),
                pw.Text(
                    'Total Amount: ৳${donationStats['totalAmount'].toStringAsFixed(2)}'),
                pw.Text('Verified: ${donationStats['verifiedCount']}'),
                pw.Text('Pending: ${donationStats['pendingCount']}'),
                pw.SizedBox(height: 20),

                // Groups
                pw.Text(
                  'Group Membership',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Total Groups: ${report['groupsCount']}'),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      Get.snackbar(
        'Success',
        'Report generated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
