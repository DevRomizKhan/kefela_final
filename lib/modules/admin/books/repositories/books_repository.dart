import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../../../../core/constants/firebase_constants.dart';

class BooksRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all books as a stream
  Stream<List<Book>> getAllBooks() {
    return _firestore
        .collection(FirebaseConstants.booksCollection)
        .orderBy('bookName')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList());
  }

  // Add a new book
  Future<void> addBook(Book book) async {
    await _firestore
        .collection(FirebaseConstants.booksCollection)
        .add(book.toFirestore());
  }

  // Update book details
  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore
        .collection(FirebaseConstants.booksCollection)
        .doc(id)
        .update(data);
  }

  // Update stock quantity
  Future<void> updateStockQuantity(String id, int quantity) async {
    await _firestore
        .collection(FirebaseConstants.booksCollection)
        .doc(id)
        .update({
      'stockQuantity': quantity,
      'updatedAt': Timestamp.now(),
    });
  }

  // Delete a book
  Future<void> deleteBook(String id) async {
    await _firestore
        .collection(FirebaseConstants.booksCollection)
        .doc(id)
        .delete();
  }

  // Get a single book by ID
  Future<Book?> getBookById(String id) async {
    final doc = await _firestore
        .collection(FirebaseConstants.booksCollection)
        .doc(id)
        .get();
    if (doc.exists) {
      return Book.fromFirestore(doc);
    }
    return null;
  }

  // Get total books count
  Future<int> getTotalBooks() async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.booksCollection)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
