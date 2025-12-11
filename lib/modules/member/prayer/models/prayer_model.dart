import 'package:cloud_firestore/cloud_firestore.dart';

class Prayer {
  final String name;
  final String time;
  bool isMarked;

  Prayer({
    required this.name,
    required this.time,
    this.isMarked = false,
  });
}

class PrayerAttendance {
  final String date;
  final Map<String, bool> prayers;
  final DateTime timestamp;

  PrayerAttendance({
    required this.date,
    required this.prayers,
    required this.timestamp,
  });

  factory PrayerAttendance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrayerAttendance(
      date: data['date'] ?? '',
      prayers: Map<String, bool>.from(data),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      ...prayers,
      'timestamp': Timestamp.fromDate(timestamp),
      'updatedAt': Timestamp.now(),
    };
  }
}
