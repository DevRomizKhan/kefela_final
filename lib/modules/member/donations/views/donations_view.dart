import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/donations_controller.dart';
import '../models/donation_model.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/common/empty_state.dart';

class DonationsView extends GetView<DonationsController> {
  const DonationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('My Donations'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            children: [
              // Info Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingM),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pay your assigned monthly donation here. You can pay the exact amount or any amount you wish.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceM),

              // Donations List
              Expanded(
                child: Obx(() {
                  if (controller.monthlyDonations.isEmpty) {
                    return const EmptyState(
                      message: 'No monthly donation assigned\nContact admin for assignment',
                      icon: Icons.attach_money,
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.monthlyDonations.length,
                    itemBuilder: (context, index) {
                      final donation = controller.monthlyDonations[index];
                      return _buildDonationCard(donation);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCard(MonthlyDonation donation) {
    return Obx(() {
      final currentPayment = controller.currentPayments[donation.id];

      return Card(
        margin: EdgeInsets.only(bottom: AppSizes.cardMargin),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.assignment, color: AppColors.primary, size: 24),
                  SizedBox(width: AppSizes.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Donation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Assigned: ৳${donation.monthlyAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Admin Notice
              if (donation.adminNotice != null) ...[
                SizedBox(height: AppSizes.spaceM),
                Container(
                  padding: EdgeInsets.all(AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.announcement, size: 14, color: Colors.blue),
                      SizedBox(width: AppSizes.spaceS),
                      Expanded(
                        child: Text(
                          'Admin: ${donation.adminNotice}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: AppSizes.spaceM),

              // Current Month Payment Status or Pay Button
              if (currentPayment != null)
                _buildPaymentStatus(currentPayment)
              else
                _buildPayButton(donation),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPaymentStatus(DonationPayment payment) {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: payment.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: payment.statusColor,
                size: 20,
              ),
              SizedBox(width: AppSizes.spaceS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paid: ৳${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      payment.statusMessage,
                      style: TextStyle(
                        color: payment.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Paid on: ${DateFormat('MMM dd, yyyy').format(payment.paidAt)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Admin Feedback
          if (payment.adminFeedback != null) ...[
            SizedBox(height: AppSizes.spaceS),
            Container(
              padding: EdgeInsets.all(AppSizes.paddingS),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusXS),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.feedback, size: 14, color: Colors.grey),
                  SizedBox(width: AppSizes.spaceS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Feedback:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          payment.adminFeedback!,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayButton(MonthlyDonation donation) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => controller.showPaymentDialog(donation),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: const Text('Pay Now'),
      ),
    );
  }
}
