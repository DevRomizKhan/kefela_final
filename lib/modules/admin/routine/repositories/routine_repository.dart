import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine_model.dart';
import '../../../../core/constants/firebase_constants.dart';

class RoutineRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Routine>> getAllRoutines() {
    return _firestore
        .collection(FirebaseConstants.routinesCollection)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Routine.fromFirestore(doc)).toList());
  }

  Future<void> addRoutine(Routine routine) async {
    await _firestore
        .collection(FirebaseConstants.routinesCollection)
        .add(routine.toFirestore());
  }

  Future<void> deleteRoutine(String id) async {
    await _firestore
        .collection(FirebaseConstants.routinesCollection)
        .doc(id)
        .delete();
  }
}
