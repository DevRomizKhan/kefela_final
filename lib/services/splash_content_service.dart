// lib/services/splash_content_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/splash_content_model.dart';

class SplashContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all splash content as a stream
  Stream<List<SplashContent>> getAllContent() {
    return _firestore
        .collection('splash_content')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SplashContent.fromFirestore(doc)).toList());
  }

  // Get a random splash content item
  Future<SplashContent?> getRandomContent() async {
    try {
      final snapshot = await _firestore.collection('splash_content').get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }

      // Get random index
      final random = Random();
      final randomIndex = random.nextInt(snapshot.docs.length);
      
      return SplashContent.fromFirestore(snapshot.docs[randomIndex]);
    } catch (e) {
      print('Error fetching random content: $e');
      return null;
    }
  }

  // Add new splash content (admin only)
  Future<void> addContent(SplashContent content) async {
    await _firestore.collection('splash_content').add(content.toFirestore());
  }

  // Update splash content (admin only)
  Future<void> updateContent(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore.collection('splash_content').doc(id).update(data);
  }

  // Delete splash content (admin only)
  Future<void> deleteContent(String id) async {
    await _firestore.collection('splash_content').doc(id).delete();
  }

  // Get a single content by ID
  Future<SplashContent?> getContentById(String id) async {
    final doc = await _firestore.collection('splash_content').doc(id).get();
    if (doc.exists) {
      return SplashContent.fromFirestore(doc);
    }
    return null;
  }

  // Get total content count
  Future<int> getTotalContent() async {
    final snapshot = await _firestore.collection('splash_content').count().get();
    return snapshot.count ?? 0;
  }

  // Import content from JSON data
  Future<void> importFromJson(List<Map<String, dynamic>> jsonData) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    for (var item in jsonData) {
      final docRef = _firestore.collection('splash_content').doc();
      final content = SplashContent(
        id: docRef.id,
        arabic: item['arabic'] ?? '',
        bangla: item['bangla'] ?? '',
        reference: item['reference'] ?? '',
        type: item['type'] ?? 'quran',
        createdAt: now,
        updatedAt: now,
      );
      batch.set(docRef, content.toFirestore());
    }
    await batch.commit();
  }
}
