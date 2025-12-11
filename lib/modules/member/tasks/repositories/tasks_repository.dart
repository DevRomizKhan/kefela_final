import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TasksRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  Stream<List<Task>> getUserTasks() {
    if (userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> toggleTaskStatus(String taskId, String currentStatus) async {
    final newStatus = currentStatus == 'completed' ? 'pending' : 'completed';
    await _firestore.collection('tasks').doc(taskId).update({
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> submitFeedback(String taskId, String feedback) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'feedback': feedback,
      'feedbackAt': Timestamp.now(),
    });
  }
}
