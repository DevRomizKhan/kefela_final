import 'package:cloud_firestore/cloud_firestore.dart';

class Routine {
  final String id;
  final String className;
  final String instructor;
  final String room;
  final String day;
  final String startTime;
  final String endTime;
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.className,
    required this.instructor,
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  factory Routine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Routine(
      id: doc.id,
      className: data['className'] ?? '',
      instructor: data['instructor'] ?? '',
      room: data['room'] ?? '',
      day: data['day'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'className': className,
      'instructor': instructor,
      'room': room,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Routine copyWith({
    String? id,
    String? className,
    String? instructor,
    String? room,
    String? day,
    String? startTime,
    String? endTime,
    DateTime? createdAt,
  }) {
    return Routine(
      id: id ?? this.id,
      className: className ?? this.className,
      instructor: instructor ?? this.instructor,
      room: room ?? this.room,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
