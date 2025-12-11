import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final String feedback;
  final String assignedBy;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.feedback,
    required this.assignedBy,
    required this.createdAt,
  });

  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      feedback: data['feedback'] ?? '',
      assignedBy: data['assignedBy'] ?? 'Admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && status != 'completed';
  bool get isCompleted => status == 'completed';
}
