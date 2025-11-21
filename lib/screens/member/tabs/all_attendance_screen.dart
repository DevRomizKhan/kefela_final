import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AllAttendanceScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AllAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Records",style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: _firestore.collection("meetings").orderBy("date").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final meetings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              final Map<String, dynamic> meetingData = meeting.data() as Map<String, dynamic>;

              // Safely handle date
              String dateStr = "Unknown Date";
              if (meetingData['date'] != null) {
                if (meetingData['date'] is Timestamp) {
                  dateStr = DateFormat("dd MMM yyyy").format((meetingData['date'] as Timestamp).toDate());
                } else if (meetingData['date'] is String) {
                  // If date is stored as string, try to parse it
                  try {
                    DateTime parsedDate = DateTime.parse(meetingData['date'] as String);
                    dateStr = DateFormat("dd MMM yyyy").format(parsedDate);
                  } catch (e) {
                    dateStr = meetingData['date'] as String;
                  }
                }
              }

              // Safely handle start time
              String startTime = "N/A";
              if (meetingData['startTime'] != null) {
                if (meetingData['startTime'] is Timestamp) {
                  startTime = DateFormat("HH:mm").format((meetingData['startTime'] as Timestamp).toDate());
                } else if (meetingData['startTime'] is String) {
                  startTime = meetingData['startTime'] as String;
                }
              }

              // Safely handle end time
              String endTime = "N/A";
              if (meetingData['endTime'] != null) {
                if (meetingData['endTime'] is Timestamp) {
                  endTime = DateFormat("HH:mm").format((meetingData['endTime'] as Timestamp).toDate());
                } else if (meetingData['endTime'] is String) {
                  endTime = meetingData['endTime'] as String;
                }
              }

              return FutureBuilder(
                future: meeting.reference
                    .collection('attendance')
                    .doc(user.uid)
                    .get(),
                builder: (context, attendanceSnap) {
                  if (!attendanceSnap.hasData) {
                    return const Card(
                      child: ListTile(
                        title: Text("Loading..."),
                      ),
                    );
                  }

                  final attendanceData = attendanceSnap.data!.data();
                  bool hasAttendance = attendanceSnap.hasData && attendanceSnap.data!.exists;

                  // Determine attendance status
                  String attendanceStatus = "Absent";
                  Color statusColor = Colors.black;
                  IconData statusIcon = Icons.cancel;

                  if (hasAttendance && attendanceData != null) {
                    bool startAttended = attendanceData['startAttended'] ?? false;
                    bool endAttended = attendanceData['endAttended'] ?? false;

                    if (startAttended && endAttended) {
                      attendanceStatus = "Full";
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else if (startAttended || endAttended) {
                      attendanceStatus = "Partial";
                      statusColor = Colors.orangeAccent;
                      statusIcon = Icons.watch_later;
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        meetingData['title'] ?? 'No Title',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateStr),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text("Start: $startTime"),
                              const SizedBox(width: 12),
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text("End: $endTime"),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusIcon, color: statusColor),
                          const SizedBox(height: 2),
                          Text(
                            attendanceStatus,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showAttendanceDetails(
                            context,
                            meetingData,
                            attendanceData,
                            dateStr,
                            startTime,
                            endTime
                        );
                      },
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

  void _showAttendanceDetails(
      BuildContext context,
      Map<String, dynamic> meetingData,
      Map<String, dynamic>? attendanceData,
      String dateStr,
      String startTime,
      String endTime
      ) {

    String startStatus = "Not Attended";
    String endStatus = "Not Attended";

    if (attendanceData != null) {
      startStatus = (attendanceData['startAttended'] ?? false) ? "Attended" : "Not Attended";
      endStatus = (attendanceData['endAttended'] ?? false) ? "Attended" : "Not Attended";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meetingData['title'] ?? 'No Title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: $dateStr"),
            const SizedBox(height: 8),
            Text("Time: $startTime - $endTime"),
            const SizedBox(height: 16),
            const Text("Attendance Details:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("• Start Time: $startStatus"),
            Text("• End Time: $endStatus"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}