import 'package:flutter/material.dart';
import '../models/splash_content_model.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class ContentCard extends StatelessWidget {
  final SplashContent content;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContentCard({
    super.key,
    required this.content,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.cardMargin),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge and actions
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: content.type == 'quran'
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Text(
                    content.type == 'quran' ? 'Quran' : 'Hadith',
                    style: TextStyle(
                      color: content.type == 'quran'
                          ? AppColors.primary
                          : AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.primary),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            SizedBox(height: AppSizes.spaceM),

            // Arabic text
            Text(
              content.arabic,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.6,
              ),
            ),
            SizedBox(height: AppSizes.spaceM),

            // Bangla text
            Text(
              content.bangla,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSizes.spaceM),

            // Reference
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                content.reference,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
