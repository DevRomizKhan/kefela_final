import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/group_model.dart';
import '../repositories/groups_repository.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/dialogs/confirmation_dialog.dart';

class GroupsController extends GetxController {
  final GroupsRepository _repository = GroupsRepository();

  // Observables
  final groups = <Group>[].obs;
  final members = <Member>[].obs;
  final selectedMembers = <String>[].obs;
  final isLoading = false.obs;

  // Form controllers
  final groupNameController = TextEditingController();

  // For edit mode
  Group? editingGroup;

  @override
  void onInit() {
    super.onInit();
    _loadGroups();
    _loadMembers();
  }

  @override
  void onClose() {
    groupNameController.dispose();
    super.onClose();
  }

  void _loadGroups() {
    _repository.getAllGroups().listen(
      (groupsList) {
        groups.value = groupsList;
      },
      onError: (error) {
        Get.snackbar(
          AppStrings.error,
          'Error loading groups: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  Future<void> _loadMembers() async {
    try {
      final membersList = await _repository.getMembers();
      members.value = membersList;
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error loading members: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void showCreateDialog() {
    editingGroup = null;
    groupNameController.clear();
    selectedMembers.clear();
  }

  void showEditDialog(Group group) {
    editingGroup = group;
    groupNameController.text = group.name;
    selectedMembers.value = List.from(group.members);
  }

  void toggleMemberSelection(String memberId) {
    if (selectedMembers.contains(memberId)) {
      selectedMembers.remove(memberId);
    } else {
      selectedMembers.add(memberId);
    }
  }

  Future<void> saveGroup() async {
    if (groupNameController.text.isEmpty) {
      Get.snackbar(
        AppStrings.error,
        'Group name is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedMembers.isEmpty) {
      Get.snackbar(
        AppStrings.error,
        'Please select at least one member',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      final selectedMemberNames = members
          .where((member) => selectedMembers.contains(member.uid))
          .map((member) => member.name)
          .toList();

      if (editingGroup != null) {
        // Update existing
        await _repository.updateGroup(editingGroup!.id, {
          'name': groupNameController.text,
          'members': selectedMembers,
          'memberNames': selectedMemberNames,
        });

        Get.back();
        Get.snackbar(
          AppStrings.success,
          'Group updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Create new
        final group = Group(
          id: '',
          name: groupNameController.text,
          members: selectedMembers.toList(),
          memberNames: selectedMemberNames,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _repository.createGroup(group);

        Get.back();
        Get.snackbar(
          AppStrings.success,
          'Group created successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteGroup(Group group) async {
    final confirmed = await ConfirmationDialog.show(
      Get.context!,
      title: 'Delete Group',
      message: 'Are you sure you want to delete this group?',
      icon: Icons.delete,
      confirmColor: Colors.red,
      confirmText: AppStrings.delete,
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteGroup(group.id);

      Get.snackbar(
        AppStrings.success,
        'Group deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        AppStrings.error,
        'Error deleting group: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void navigateToGroupChat(String groupId, String groupName) {
    // Navigate to group chat
    Get.toNamed('/admin/groups/$groupId/chat', arguments: {
      'groupId': groupId,
      'groupName': groupName,
    });
  }
}
