import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/donation_model.dart';
import '../repositories/donations_repository.dart';
import '../../../../core/constants/app_strings.dart';

class DonationsController extends GetxController {
  final DonationsRepository _repository = DonationsRepository();

  // Observables
  final monthlyDonations = <MonthlyDonation>[].obs;
  final currentPayments = <String, DonationPayment?>{}.obs; // donationId -> payment
  final isLoading = false.obs;

  // Payment form controllers
  final amountController = TextEditingController();
  final transactionIdController = TextEditingController();
  final selectedPaymentMethod = 'bKash'.obs;
  final selectedMonth = ''.obs;
  final selectedYear = ''.obs;

  final paymentMethods = ['bKash', 'Nagad', 'Rocket', 'Upai', 'Others'];
  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  String get currentMonth => DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    _initializeDefaults();
    _loadDonations();
  }

  @override
  void onClose() {
    amountController.dispose();
    transactionIdController.dispose();
    super.onClose();
  }

  void _initializeDefaults() {
    final now = DateTime.now();
    selectedMonth.value = months[now.month - 1];
    selectedYear.value = now.year.toString();
  }

  void _loadDonations() {
    _repository.getMonthlyDonations().listen(
      (donations) {
        monthlyDonations.value = donations;
        // Load current month payment for each donation
        for (var donation in donations) {
          _loadCurrentPayment(donation.id);
        }
      },
      onError: (error) {
        Get.snackbar(
          AppStrings.error,
          'Error loading donations: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  Future<void> _loadCurrentPayment(String donationId) async {
    try {
      final payment = await _repository.getCurrentMonthPayment(
        donationId,
        currentMonth,
      );
      currentPayments[donationId] = payment;
    } catch (e) {
      // Silent fail - no payment exists yet
    }
  }

  void showPaymentDialog(MonthlyDonation donation) {
    amountController.text = donation.monthlyAmount.toStringAsFixed(2);
    transactionIdController.clear();
    _initializeDefaults();

    Get.dialog(
      AlertDialog(
        title: const Text('Pay Monthly Donation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assigned Amount Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Assigned Monthly Amount',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '৳${donation.monthlyAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (donation.adminNotice != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Admin: ${donation.adminNotice}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Month & Year Selection
              Row(
                children: [
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                          value: selectedMonth.value,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            border: OutlineInputBorder(),
                          ),
                          items: months
                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (value) => selectedMonth.value = value!,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                          value: selectedYear.value,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(),
                          ),
                          items: _getYears()
                              .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                              .toList(),
                          onChanged: (value) => selectedYear.value = value!,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (BDT)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount',
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method
              Obx(() => DropdownButtonFormField<String>(
                    value: selectedPaymentMethod.value,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                    ),
                    items: paymentMethods
                        .map((method) =>
                            DropdownMenuItem(value: method, child: Text(method)))
                        .toList(),
                    onChanged: (value) => selectedPaymentMethod.value = value!,
                  )),
              const SizedBox(height: 16),

              // Transaction ID
              TextField(
                controller: transactionIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID',
                  border: OutlineInputBorder(),
                  hintText: 'Enter transaction ID',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitPayment(donation),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Submit Payment'),
          ),
        ],
      ),
    );
  }

  List<String> _getYears() {
    final currentYear = DateTime.now().year;
    return List.generate(3, (i) => (currentYear - i).toString());
  }

  int _getMonthNumber(String monthName) {
    return months.indexOf(monthName) + 1;
  }

  Future<void> _submitPayment(MonthlyDonation donation) async {
    // Validation
    if (amountController.text.trim().isEmpty ||
        transactionIdController.text.trim().isEmpty) {
      Get.snackbar(
        AppStrings.error,
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        AppStrings.error,
        'Please enter a valid amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final monthKey =
          '${selectedYear.value}-${_getMonthNumber(selectedMonth.value).toString().padLeft(2, '0')}';
      final monthName = '${selectedMonth.value} ${selectedYear.value}';

      // Check if already paid for selected month
      final existingPayment = await _repository.getCurrentMonthPayment(
        donation.id,
        monthKey,
      );

      if (existingPayment != null) {
        Get.back();
        Get.snackbar(
          'Already Paid',
          'You have already paid for $monthName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Submit payment
      await _repository.submitPayment(
        monthlyDonationId: donation.id,
        memberName: donation.memberName,
        memberEmail: donation.memberEmail,
        amount: amount,
        assignedAmount: donation.monthlyAmount,
        transactionId: transactionIdController.text.trim(),
        paymentMethod: selectedPaymentMethod.value,
        month: monthKey,
        monthName: monthName,
      );

      Get.back();

      Get.snackbar(
        AppStrings.success,
        'Payment submitted successfully! Waiting for verification.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh current payment
      _loadCurrentPayment(donation.id);
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error submitting payment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
