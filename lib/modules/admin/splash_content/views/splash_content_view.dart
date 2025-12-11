import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_content_controller.dart';
import '../widgets/content_card.dart';
import '../widgets/add_edit_dialog.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/common/empty_state.dart';

class SplashContentView extends GetView<SplashContentController> {
  const SplashContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Verses & Hadiths',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.contents.isEmpty) {
          return EmptyState(
            message: 'No content available.\nTap + to add new verse or hadith.',
            icon: Icons.menu_book,
            action: FloatingActionButton(
              onPressed: () => _showAddDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSizes.screenPadding),
          itemCount: controller.contents.length,
          itemBuilder: (context, index) {
            final content = controller.contents[index];
            return ContentCard(
              content: content,
              onEdit: () => _showEditDialog(context, content),
              onDelete: () => controller.deleteContent(content),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    controller.showAddDialog();
    showDialog(
      context: context,
      builder: (context) => const AddEditDialog(),
    );
  }

  void _showEditDialog(BuildContext context, content) {
    controller.showEditDialog(content);
    showDialog(
      context: context,
      builder: (context) => const AddEditDialog(),
    );
  }
}
