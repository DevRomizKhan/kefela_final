import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/books_controller.dart';
import '../../../admin/books/models/book_model.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/common/empty_state.dart';

class BooksView extends GetView<BooksController> {
  const BooksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Books Library'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(AppSizes.paddingM),
            child: TextField(
              onChanged: controller.updateSearch,
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),

          // Books List
          Expanded(
            child: Obx(() {
              final filteredBooks = controller.filteredBooks;

              if (controller.books.isEmpty) {
                return const EmptyState(
                  message: 'No books available',
                  icon: Icons.book,
                );
              }

              if (filteredBooks.isEmpty) {
                return const EmptyState(
                  message: 'No books match your search',
                  icon: Icons.search_off,
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  final book = filteredBooks[index];
                  return _buildBookCard(book);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    final isAvailable = book.stock > 0;

    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.cardMargin),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAvailable
              ? AppColors.primary.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          child: Icon(
            Icons.book,
            color: isAvailable ? AppColors.primary : Colors.grey,
          ),
        ),
        title: Text(
          book.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSizes.spaceXS),
            Text(
              'By ${book.author}',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
            Text(
              book.subject,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            SizedBox(height: AppSizes.spaceXS),
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                SizedBox(width: AppSizes.spaceXS),
                Text(
                  isAvailable ? 'Available (${book.stock})' : 'Out of stock',
                  style: TextStyle(
                    fontSize: 12,
                    color: isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.info_outline, color: AppColors.primary),
          onPressed: () => controller.showBookDetails(book),
        ),
        onTap: () => controller.showBookDetails(book),
      ),
    );
  }
}
