import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../admin/groups/models/group_model.dart';
import '../../../admin/groups/repositories/groups_repository.dart';

class GroupsController extends GetxController {
  // REUSE admin repository!
  final GroupsRepository _repository = GroupsRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observables
  final groups = <Group>[].obs;
  final myGroups = <Group>[].obs;

  // Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Filter groups that current user is member of
  List<Group> get userGroups {
    return groups.where((group) => group.members.contains(currentUserId)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _loadGroups();
  }

  void _loadGroups() {
    _repository.getAllGroups().listen(
      (groupsList) {
        groups.value = groupsList;
      },
      onError: (error) {
        Get.snackbar(
          'Error',
          'Error loading groups: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  void navigateToGroupChat(String groupId, String groupName) {
    // Navigate to group chat
    Get.toNamed('/member/groups/$groupId/chat', arguments: {
      'groupId': groupId,
      'groupName': groupName,
    });
  }

  void showGroupDetails(Group group) {
    Get.dialog(
      AlertDialog(
        title: Text(group.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Members (${group.members.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...group.memberNames.map((name) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(name),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              navigateToGroupChat(group.id, group.name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Chat'),
          ),
        ],
      ),
    );
  }
}
