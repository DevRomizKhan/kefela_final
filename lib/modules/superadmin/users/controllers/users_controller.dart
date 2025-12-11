import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../repositories/users_repository.dart';
import '../../../../core/constants/app_strings.dart';

class UsersController extends GetxController {
  final UsersRepository _repository = UsersRepository();

  // Observables
  final users = <SystemUser>[].obs;
  final searchQuery = ''.obs;
  final selectedRole = 'All'.obs;

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final newRole = 'Member'.obs;

  final roles = ['All', 'Member', 'Admin', 'Superadmin'];
  final createRoles = ['Member', 'Admin'];

  List<SystemUser> get filteredUsers {
    var filtered = users.toList();

    // Filter by role
    if (selectedRole.value != 'All') {
      filtered = filtered.where((user) => user.role == selectedRole.value).toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void _loadUsers() {
    _repository.getAllUsers().listen(
      (usersList) {
        users.value = usersList;
      },
      onError: (error) {
        Get.snackbar(
          AppStrings.error,
          'Error loading users: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  void showCreateUserDialog() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    newRole.value = 'Member';

    Get.dialog(
      AlertDialog(
        title: const Text('Create New User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              Obx(() => DropdownButtonFormField<String>(
                    value: newRole.value,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: createRoles
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) => newRole.value = value!,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createUser,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createUser() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      Get.snackbar(
        AppStrings.error,
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      await _repository.createUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        role: newRole.value,
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
      );

      Get.back();

      Get.snackbar(
        AppStrings.success,
        'User created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error creating user: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> updateRole(SystemUser user, String newRole) async {
    try {
      await _repository.updateUserRole(user.uid, newRole);

      Get.snackbar(
        AppStrings.success,
        'User role updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error updating role: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteUser(SystemUser user) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteUser(user.uid);

        Get.snackbar(
          AppStrings.success,
          'User deleted successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          AppStrings.error,
          'Error deleting user: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}
