import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/splash_content_model.dart';
import '../../../../core/constants/firebase_constants.dart';

class SplashContentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<SplashContent>> getAllContent() {
    return _firestore
        .collection(FirebaseConstants.splashContentCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SplashContent.fromFirestore(doc)).toList());
  }

  Future<SplashContent?> getRandomContent() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.splashContentCollection)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final random = Random();
      final randomIndex = random.nextInt(snapshot.docs.length);

      return SplashContent.fromFirestore(snapshot.docs[randomIndex]);
    } catch (e) {
      return null;
    }
  }

  Future<void> addContent(SplashContent content) async {
    await _firestore
        .collection(FirebaseConstants.splashContentCollection)
        .add(content.toFirestore());
  }

  Future<void> updateContent(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore
        .collection(FirebaseConstants.splashContentCollection)
        .doc(id)
        .update(data);
  }

  Future<void> deleteContent(String id) async {
    await _firestore
        .collection(FirebaseConstants.splashContentCollection)
        .doc(id)
        .delete();
  }

  Future<int> getTotalContent() async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.splashContentCollection)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
