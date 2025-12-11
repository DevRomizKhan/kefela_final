import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.message,
    required this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.iconXL * 2, color: Colors.grey[400]),
          SizedBox(height: AppSizes.spaceL),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            SizedBox(height: AppSizes.spaceXL),
            action!,
          ],
        ],
      ),
    );
  }
}
