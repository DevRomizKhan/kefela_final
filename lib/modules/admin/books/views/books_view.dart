import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/books_controller.dart';
import '../../../../shared/widgets/common/empty_state.dart';
import '../../../../shared/widgets/common/loading_widget.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

class BooksView extends GetView<BooksController> {
  const BooksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: Obx(() {
              if (controller.filteredBooks.isEmpty) {
                return EmptyState(
                  message: 'কোন বই নেই',
                  icon: Icons.book_outlined,
                  action: ElevatedButton.icon(
                    onPressed: controller.importBooks,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('১৩২টি বই ইমপোর্ট করুন'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(AppSizes.screenPadding),
                itemCount: controller.filteredBooks.length,
                itemBuilder: (context, index) {
                  final book = controller.filteredBooks[index];
                  return _buildBookCard(book);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show add book dialog
        },
        icon: const Icon(Icons.add),
        label: Text(AppStrings.addBook),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.all(AppSizes.screenPadding),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            AppStrings.books,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.spaceM),
          TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: controller.searchType.value == 'name'
                  ? 'বইয়ের নাম দিয়ে খুঁজুন...'
                  : 'লেখকের নাম দিয়ে খুঁজুন...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
          ),
          SizedBox(height: AppSizes.spaceM),
          Row(
            children: [
              Expanded(
                child: _buildSearchTypeButton(
                  'বইয়ের নাম',
                  'name',
                  Icons.book,
                ),
              ),
              SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: _buildSearchTypeButton(
                  'লেখকের নাম',
                  'author',
                  Icons.person,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTypeButton(String label, String type, IconData icon) {
    return Obx(() {
      final isSelected = controller.searchType.value == type;
      return InkWell(
        onTap: () => controller.toggleSearchType(type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppSizes.paddingM),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: AppSizes.iconM,
              ),
              SizedBox(width: AppSizes.spaceS),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBookCard(book) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.cardMargin),
      child: ListTile(
        title: Text(book.bookName),
        subtitle: Text(book.author),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                // Edit
              },
              icon: const Icon(Icons.edit, color: Colors.blue),
            ),
            IconButton(
              onPressed: () => controller.deleteBook(book),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
