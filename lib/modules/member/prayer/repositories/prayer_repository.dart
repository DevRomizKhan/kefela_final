import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrayerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  Future<Map<String, bool>> getTodayAttendance(String date) async {
    if (userId.isEmpty) return {};

    final doc = await _firestore
        .collection('prayer_attendance')
        .doc(userId)
        .collection('records')
        .doc(date)
        .get();

    if (!doc.exists) return {};

    final data = doc.data()!;
    return {
      'fajr': data['fajr'] ?? false,
      'dhuhr': data['dhuhr'] ?? false,
      'asr': data['asr'] ?? false,
      'maghrib': data['maghrib'] ?? false,
      'isha': data['isha'] ?? false,
    };
  }

  Future<void> togglePrayer(String date, String prayerName, bool isMarked) async {
    if (userId.isEmpty) return;

    await _firestore
        .collection('prayer_attendance')
        .doc(userId)
        .collection('records')
        .doc(date)
        .set({
      prayerName.toLowerCase(): isMarked,
      'date': date,
      'timestamp': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> markAll(String date, List<String> prayerNames) async {
    if (userId.isEmpty) return;

    final Map<String, dynamic> data = {
      'date': date,
      'timestamp': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    for (var name in prayerNames) {
      data[name.toLowerCase()] = true;
    }

    await _firestore
        .collection('prayer_attendance')
        .doc(userId)
        .collection('records')
        .doc(date)
        .set(data);
  }

  Future<void> clearAll(String date) async {
    if (userId.isEmpty) return;

    await _firestore
        .collection('prayer_attendance')
        .doc(userId)
        .collection('records')
        .doc(date)
        .delete();
  }
}
