import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../admin/books/models/book_model.dart';
import '../../../admin/books/repositories/books_repository.dart';

class BooksController extends GetxController {
  // REUSE admin repository - no need to create new one!
  final BooksRepository _repository = BooksRepository();

  // Observables
  final books = <Book>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  // Filtered books based on search
  List<Book> get filteredBooks {
    if (searchQuery.value.isEmpty) return books;
    
    return books.where((book) {
      final query = searchQuery.value.toLowerCase();
      return book.name.toLowerCase().contains(query) ||
             book.author.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _loadBooks();
  }

  void _loadBooks() {
    _repository.getAllBooks().listen(
      (booksList) {
        books.value = booksList;
      },
      onError: (error) {
        Get.snackbar(
          'Error',
          'Error loading books: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void showBookDetails(Book book) {
    Get.dialog(
      AlertDialog(
        title: Text(book.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Author', book.author),
              _buildDetailRow('Subject', book.subject),
              _buildDetailRow('Stock', '${book.stock}'),
              if (book.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    book.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
