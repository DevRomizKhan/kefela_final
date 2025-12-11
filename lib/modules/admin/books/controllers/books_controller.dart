import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../models/book_model.dart';
import '../repositories/books_repository.dart';
import '../../../../core/utils/bengali_utils.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';

class BooksController extends GetxController {
  final BooksRepository _repository = BooksRepository();

  // Observables
  final books = <Book>[].obs;
  final filteredBooks = <Book>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final searchType = 'name'.obs; // 'name' or 'author'

  // Controllers
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadBooks();
    _setupSearch();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Load books
  void _loadBooks() {
    _repository.getAllBooks().listen(
      (booksList) {
        books.value = booksList;
        _filterBooks();
      },
      onError: (error) {
        Get.snackbar(
          AppStrings.error,
          'বই লোড করতে সমস্যা হয়েছে: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  // Setup search
  void _setupSearch() {
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      _filterBooks();
    });
  }

  // Filter books
  void _filterBooks() {
    if (searchQuery.value.isEmpty) {
      filteredBooks.value = books;
      return;
    }

    if (searchType.value == 'name') {
      filteredBooks.value = books
          .where((book) => book.bookName
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()))
          .toList();
    } else {
      filteredBooks.value = books
          .where((book) => book.author
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()))
          .toList();
    }
  }

  // Toggle search type
  void toggleSearchType(String type) {
    searchType.value = type;
    _filterBooks();
  }

  // Add book
  Future<void> addBook(Book book) async {
    try {
      isLoading.value = true;
      await _repository.addBook(book);
      Get.back();
      Get.snackbar(
        AppStrings.success,
        'বই যোগ করা হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'বই যোগ করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update book
  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      await _repository.updateBook(id, data);
      Get.back();
      Get.snackbar(
        AppStrings.success,
        'বই আপডেট করা হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'আপডেট করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update stock
  Future<void> updateStock(String id, int quantity) async {
    try {
      await _repository.updateStockQuantity(id, quantity);
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'স্টক আপডেট করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Delete book
  Future<void> deleteBook(Book book) async {
    final confirmed = await ConfirmationDialog.show(
      Get.context!,
      title: AppStrings.confirm,
      message: 'আপনি কি "${book.bookName}" মুছে ফেলতে চান?',
      icon: Icons.warning,
      confirmColor: Colors.red,
      confirmText: AppStrings.delete,
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteBook(book.id);
      Get.snackbar(
        AppStrings.success,
        'বই মুছে ফেলা হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'মুছে ফেলতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Import books from JSON
  Future<void> importBooks() async {
    final confirmed = await ConfirmationDialog.show(
      Get.context!,
      title: 'বই ইমপোর্ট করুন',
      message: 'আপনি কি ১৩২টি বই ইমপোর্ট করতে চান?',
      icon: Icons.upload_file,
      confirmText: 'হ্যাঁ, ইমপোর্ট করুন',
    );

    if (confirmed != true) return;

    try {
      isLoading.value = true;
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('বই ইমপোর্ট হচ্ছে...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final jsonString = await rootBundle.loadString('assets/books.json');
      final booksData = json.decode(jsonString) as Map<String, dynamic>;

      int successCount = 0;
      for (var entry in booksData.entries) {
        final data = entry.value as Map<String, dynamic>;
        final book = Book(
          id: '',
          bookName: data['bookName'] ?? '',
          author: data['author'] ?? '',
          stockQuantity: BengaliUtils.parseBengaliNumber(data['quantity'] ?? '0'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _repository.addBook(book);
        successCount++;
      }

      Get.back(); // Close loading
      Get.snackbar(
        AppStrings.success,
        '✅ $successCount টি বই ইমপোর্ট করা হয়েছে',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close loading
      Get.snackbar(
        AppStrings.error,
        'ইমপোর্ট করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
