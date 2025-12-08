// lib/models/splash_content_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashContent {
  final String id;
  final String arabic;
  final String bangla;
  final String reference;
  final String type; // 'quran' or 'hadith'
  final DateTime createdAt;
  final DateTime updatedAt;

  SplashContent({
    required this.id,
    required this.arabic,
    required this.bangla,
    required this.reference,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create SplashContent from Firestore document
  factory SplashContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SplashContent(
      id: doc.id,
      arabic: data['arabic'] ?? '',
      bangla: data['bangla'] ?? '',
      reference: data['reference'] ?? '',
      type: data['type'] ?? 'quran',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert SplashContent to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'arabic': arabic,
      'bangla': bangla,
      'reference': reference,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  SplashContent copyWith({
    String? id,
    String? arabic,
    String? bangla,
    String? reference,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SplashContent(
      id: id ?? this.id,
      arabic: arabic ?? this.arabic,
      bangla: bangla ?? this.bangla,
      reference: reference ?? this.reference,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
