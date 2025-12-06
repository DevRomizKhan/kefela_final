// lib/services/books_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class BooksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all books as a stream
  Stream<List<Book>> getAllBooks() {
    return _firestore
        .collection('books')
        .orderBy('bookName')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList());
  }

  // Search books by name
  Stream<List<Book>> searchBooksByName(String query) {
    if (query.isEmpty) {
      return getAllBooks();
    }
    
    return _firestore
        .collection('books')
        .orderBy('bookName')
        .snapshots()
        .map((snapshot) {
      final books = snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
      return books.where((book) => 
        book.bookName.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  // Search books by writer/author
  Stream<List<Book>> searchBooksByWriter(String query) {
    if (query.isEmpty) {
      return getAllBooks();
    }
    
    return _firestore
        .collection('books')
        .orderBy('author')
        .snapshots()
        .map((snapshot) {
      final books = snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
      return books.where((book) => 
        book.author.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  // Add a new book (admin only)
  Future<void> addBook(Book book) async {
    await _firestore.collection('books').add(book.toFirestore());
  }

  // Update book details (admin only)
  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore.collection('books').doc(id).update(data);
  }

  // Update stock quantity (admin only)
  Future<void> updateStockQuantity(String id, int quantity) async {
    await _firestore.collection('books').doc(id).update({
      'stockQuantity': quantity,
      'updatedAt': Timestamp.now(),
    });
  }

  // Delete a book (admin only)
  Future<void> deleteBook(String id) async {
    await _firestore.collection('books').doc(id).delete();
  }

  // Get a single book by ID
  Future<Book?> getBookById(String id) async {
    final doc = await _firestore.collection('books').doc(id).get();
    if (doc.exists) {
      return Book.fromFirestore(doc);
    }
    return null;
  }

  // Get total books count
  Future<int> getTotalBooks() async {
    final snapshot = await _firestore.collection('books').count().get();
    return snapshot.count ?? 0;
  }
}
