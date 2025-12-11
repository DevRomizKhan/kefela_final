import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';

class MeetingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Meeting>> getMeetings() {
    return _firestore
        .collection('meetings')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Meeting.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> createMeeting(Map<String, dynamic> meetingData) async {
    await _firestore.collection('meetings').add({
      ...meetingData,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateMeeting(String id, Map<String, dynamic> meetingData) async {
    await _firestore.collection('meetings').doc(id).update({
      ...meetingData,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteMeeting(String id) async {
    await _firestore.collection('meetings').doc(id).delete();
  }
}
