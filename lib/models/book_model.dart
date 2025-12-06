// lib/models/book_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String bookName;
  final String author;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.bookName,
    required this.author,
    required this.stockQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create Book from Firestore document
  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      bookName: data['bookName'] ?? '',
      author: data['author'] ?? '',
      stockQuantity: data['stockQuantity'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Book to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bookName': bookName,
      'author': author,
      'stockQuantity': stockQuantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  Book copyWith({
    String? id,
    String? bookName,
    String? author,
    int? stockQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      bookName: bookName ?? this.bookName,
      author: author ?? this.author,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
