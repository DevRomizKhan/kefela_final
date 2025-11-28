
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> roleFilters = ['All', 'SuperAdmin', 'Admin', 'Member'];
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      // Update in Firestore
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('User role updated to $newRole', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to update role: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      // Check if user is trying to delete themselves
      final currentUser = _auth.currentUser;
      if (currentUser?.uid == userId) {
        _showSnackBar('You cannot delete your own account', Colors.red);
        return;
      }

      // Get user data before deletion
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        _showSnackBar('User not found', Colors.red);
        return;
      }

      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();

      _showSnackBar('User deleted successfully!', Colors.green);

    } catch (e) {
      _showSnackBar('Failed to delete user: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'SuperAdmin':
        return Colors.purple;
      case 'Admin':
        return Colors.green;
      case 'Member':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'SuperAdmin':
        return Icons.admin_panel_settings;
      case 'Admin':
        return Icons.manage_accounts;
      case 'Member':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'User Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search and Filter Card
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Search users by name or email...',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWideScreen = constraints.maxWidth > 600;
                          return isWideScreen
                              ? _buildWideFilterRow()
                              : _buildNarrowFilterColumn();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Users List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading users: ${snapshot.error}',
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            Text(
                              'Add your first user to get started',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final users = snapshot.data!.docs.where((doc) {
                      final userData = doc.data() as Map<String, dynamic>;
                      final role = userData['role'] as String? ?? 'Member';
                      final name = userData['name'] as String? ?? '';
                      final email = userData['email'] as String? ?? '';

                      // Role filter
                      if (_selectedRoleFilter != 'All' && role != _selectedRoleFilter) {
                        return false;
                      }

                      // Search filter
                      if (_searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase();
                        return name.toLowerCase().contains(query) ||
                            email.toLowerCase().contains(query);
                      }

                      return true;
                    }).toList();

                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No users match your search',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            Text(
                              'Try changing your search or filters',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final user = userDoc.data() as Map<String, dynamic>;
                        final userId = userDoc.id;
                        final userName = user['name'] ?? 'Unknown User';
                        final userEmail = user['email'] ?? 'No email';
                        final userRole = user['role'] ?? 'Member';
                        final currentUser = _auth.currentUser;
                        final isCurrentUser = currentUser?.uid == userId;

                        return Card(
                          elevation: 1,
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getRoleColor(userRole),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _getRoleColor(userRole),
                                    child: Icon(
                                      _getRoleIcon(userRole),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  if (isCurrentUser)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                if (isCurrentUser)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: const Text(
                                      'You',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userEmail,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(userRole).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getRoleColor(userRole).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    userRole,
                                    style: TextStyle(
                                      color: _getRoleColor(userRole),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 400;
                                return isWide
                                    ? _buildWideTrailing(userId, userRole, isCurrentUser)
                                    : _buildNarrowTrailing(userId, userRole, isCurrentUser);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddUserScreen(),
            ),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Users'),
      ),
    );
  }

  Widget _buildWideFilterRow() {
    return Row(
      children: [
        const Text(
          'Filter by role:',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRoleFilter,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black),
              items: roleFilters.map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(role),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRoleFilter = newValue;
                  });
                }
              },
            ),
          ),
        ),
        // -
      ],
    );
  }

  Widget _buildNarrowFilterColumn() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Filter by role:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRoleFilter,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: roleFilters.map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(role),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRoleFilter = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWideTrailing(String userId, String userRole, bool isCurrentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Role Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: userRole,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black, fontSize: 12),
              items: <String>['Member', 'Admin', 'SuperAdmin']
                  .where((role) => !isCurrentUser) // Can't change own role
                  .map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: isCurrentUser
                  ? null
                  : (String? newRole) {
                if (newRole != null) {
                  _updateUserRole(userId, newRole);
                }
              },
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, size: 20, color: Colors.green),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Delete Button
        if (!isCurrentUser)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _showDeleteConfirmationDialog(userId, userRole),
          ),
      ],
    );
  }

  Widget _buildNarrowTrailing(String userId, String userRole, bool isCurrentUser) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black),
      color: Colors.white,
      itemBuilder: (context) => [
        if (!isCurrentUser)
          const PopupMenuItem<String>(
            value: 'change_role',
            child: Row(
              children: [
                Icon(Icons.swap_horiz, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text('Change Role', style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
        if (!isCurrentUser)
          const PopupMenuDivider(),
        if (!isCurrentUser)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('Delete User', style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'change_role') {
          _showRoleChangeDialog(context, userId, userRole);
        } else if (value == 'delete') {
          _showDeleteConfirmationDialog(userId, userRole);
        }
      },
    );
  }

  void _showRoleChangeDialog(BuildContext context, String userId, String currentRole) {
    String newRole = currentRole;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Change User Role',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select new role for this user:',
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: newRole,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black),
                    items: <String>['Member', 'Admin', 'SuperAdmin'].map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(role),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        newRole = value;
                        Navigator.of(context).pop();
                        _updateUserRole(userId, newRole);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String userId, String userRole) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete User',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this $userRole?',
                style: const TextStyle(color: Colors.black, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'This user will be permanently deleted from both Firestore and Authentication.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This action cannot be undone!',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser(userId);
              },
              child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'Member';
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _addAnother = false;

  final List<Map<String, String>> _addedUsers = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', Colors.red);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters long', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String userId = userCredential.user!.uid;

      // Create user document in Firestore
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Add to added users list
      _addedUsers.add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
      });

      _showSnackBar('User added successfully!', Colors.green);

      if (_addAnother) {
        // Clear form for next user
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _selectedRole = 'Member';
        _isPasswordVisible = false;
      } else {
        // Navigate back to user management
        if (mounted) {
          Navigator.pop(context);
        }
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to create user: ';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email is already registered';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        default:
          errorMessage = e.message ?? 'Unknown error occurred';
      }
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      _showSnackBar('Failed to add user: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _selectedRole = 'Member';
      _isPasswordVisible = false;
      _addAnother = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Add New User',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_addedUsers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.checklist, color: Colors.green),
              onPressed: () {
                _showAddedUsersSummary();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Added Users Summary (if any)
              if (_addedUsers.isNotEmpty) ...[
                Card(
                  elevation: 2,
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_addedUsers.length} user${_addedUsers.length > 1 ? 's' : ''} added',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _showAddedUsersSummary,
                          child: const Text(
                            'View All',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Add User Form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        elevation: 2,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.green, width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.person, color: Colors.green),
                                ),
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.green, width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.email, color: Colors.green),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  border: const OutlineInputBorder(),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.green, width: 2),
                                  ),
                                  prefixIcon: const Icon(Icons.lock, color: Colors.green),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_isPasswordVisible,
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text(
                                    'Role:',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.green),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedRole,
                                          isExpanded: true,
                                          dropdownColor: Colors.white,
                                          style: const TextStyle(color: Colors.black),
                                          items: ['Member', 'Admin', 'SuperAdmin'].map((String role) {
                                            return DropdownMenuItem<String>(
                                              value: role,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(
                                                  role,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              setState(() {
                                                _selectedRole = newValue;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Password must be at least 6 characters long',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _clearForm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey,
                                side: const BorderSide(color: Colors.grey),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Clear Form'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _addUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text('Add User'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Add Another Option
                      Card(
                        color: Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _addAnother,
                                onChanged: (value) {
                                  setState(() {
                                    _addAnother = value ?? false;
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Add another user after this one',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddedUsersSummary() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Added Users',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _addedUsers.isEmpty
                ? const Text('No users added yet')
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < _addedUsers.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getRoleColor(_addedUsers[i]['role']!),
                          radius: 16,
                          child: Icon(
                            _getRoleIcon(_addedUsers[i]['role']!),
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _addedUsers[i]['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _addedUsers[i]['email']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(_addedUsers[i]['role']!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _addedUsers[i]['role']!,
                            style: TextStyle(
                              color: _getRoleColor(_addedUsers[i]['role']!),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'SuperAdmin':
        return Colors.purple;
      case 'Admin':
        return Colors.green;
      case 'Member':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'SuperAdmin':
        return Icons.admin_panel_settings;
      case 'Admin':
        return Icons.manage_accounts;
      case 'Member':
        return Icons.person;
      default:
        return Icons.person;
    }
  }
}