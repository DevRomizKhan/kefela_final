// import 'package:flutter/material.dart';
// import 'package:kafela/services/update_service.dart';
//
// class EditProfile extends StatefulWidget {
//   final Function()? onProfileUpdated; // Callback to notify parent
//   const EditProfile({Key? key, this.onProfileUpdated}) : super(key: key);
//
//   @override
//   State<EditProfile> createState() => _EditProfileState();
// }
//
// class _EditProfileState extends State<EditProfile> {
//   final UpdateService _updateService = UpdateService();
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   bool _needsReauth = false;
//   Map<String, dynamic> _userProfile = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserProfile();
//   }
//
//   Future<void> _loadUserProfile() async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//       final profile = await _updateService.getUserProfile();
//       setState(() {
//         _userProfile = profile;
//         _nameController.text = profile['displayName'] ?? '';
//         _emailController.text = profile['email'] ?? '';
//       });
//     } catch (e) {
//       _showErrorDialog('Failed to load profile: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _updateProfile() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       final String newName = _nameController.text.trim();
//       final String newEmail = _emailController.text.trim();
//       bool nameUpdated = false;
//       bool emailUpdated = false;
//
//       if (newName != _userProfile['displayName']) {
//         await _updateService.updateUserProfile(displayName: newName);
//         nameUpdated = true;
//       }
//
//       if (newEmail != _userProfile['email']) {
//         if (_needsReauth) {
//           final String password = _passwordController.text.trim();
//           await _updateService.reauthenticateUser(password);
//         }
//         await _updateService.updateUserEmail(newEmail);
//         emailUpdated = true;
//         _showSuccessDialog(
//           'Verification Email Sent',
//           'A verification email has been sent to $newEmail. '
//               'Please verify your new email address to complete the update.',
//         );
//       } else if (nameUpdated) {
//         _showSuccessDialog(
//             'Profile Updated', 'Your profile has been updated successfully!');
//       }
//
//       if (widget.onProfileUpdated != null) {
//         widget.onProfileUpdated!();
//       }
//
//       await _loadUserProfile();
//       setState(() {
//         _needsReauth = false;
//         _passwordController.clear();
//       });
//     } catch (e) {
//       if (e.toString().contains('re-authenticate')) {
//         setState(() {
//           _needsReauth = true;
//         });
//         _showErrorDialog(
//             'Security verification required. Please enter your password to continue.');
//       } else {
//         _showErrorDialog('Failed to update profile: $e');
//       }
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _showSuccessDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.white,
//         title: Text(title, style: const TextStyle(color: Colors.black)),
//         content: Text(message, style: const TextStyle(color: Colors.black54)),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               if (!message.contains('verification email')) {
//                 Navigator.pop(context);
//               }
//             },
//             child: const Text('OK', style: TextStyle(color: Colors.green)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.white,
//         title: const Text('Error', style: TextStyle(color: Colors.black)),
//         content: Text(message, style: const TextStyle(color: Colors.black54)),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK', style: TextStyle(color: Colors.green)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title:
//             const Text('Update Profile', style: TextStyle(color: Colors.black)),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.close, color: Colors.black),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//       body: _isLoading && _userProfile.isEmpty
//           ? const Center(child: CircularProgressIndicator(color: Colors.green))
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       // Current User Info
//                       Card(
//                         color: Colors.white,
//                         elevation: 2,
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: SizedBox(
//                             height: 110,
//                             width: double.infinity,
//                             child: Center(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     'Current Profile',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 10),
//                                   Text(
//                                       'Name: ${_userProfile['displayName'] ?? 'Not set'}',
//                                       style: const TextStyle(
//                                           color: Colors.black54)),
//                                   Text(
//                                       'Email: ${_userProfile['email'] ?? 'Not set'}',
//                                       style: const TextStyle(
//                                           color: Colors.black54)),
//                                   const SizedBox(height: 10),
//                                   Text(
//                                     'Email Verified: ${_userProfile['emailVerified'] == true ? 'Yes' : 'No'}',
//                                     style: TextStyle(
//                                       color:
//                                           _userProfile['emailVerified'] == true
//                                               ? Colors.green
//                                               : Colors.orange,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       // Name Field
//                       TextFormField(
//                         controller: _nameController,
//                         decoration: const InputDecoration(
//                           labelText: 'Display Name',
//                           labelStyle: TextStyle(color: Colors.black54),
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.person, color: Colors.green),
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.green),
//                           ),
//                         ),
//                         style: const TextStyle(color: Colors.black),
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return 'Please enter your name';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       // Email Field
//                       TextFormField(
//                         controller: _emailController,
//                         decoration: const InputDecoration(
//                           labelText: 'Email Address',
//                           labelStyle: TextStyle(color: Colors.black54),
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.email, color: Colors.green),
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.green),
//                           ),
//                         ),
//                         keyboardType: TextInputType.emailAddress,
//                         style: const TextStyle(color: Colors.black),
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return 'Please enter your email';
//                           }
//                           if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                               .hasMatch(value)) {
//                             return 'Please enter a valid email';
//                           }
//                           return null;
//                         },
//                       ),
//                       // Re-authentication Field (shown when needed)
//                       if (_needsReauth) ...[
//                         const SizedBox(height: 16),
//                         TextFormField(
//                           controller: _passwordController,
//                           decoration: const InputDecoration(
//                             labelText: 'Current Password',
//                             labelStyle: TextStyle(color: Colors.black54),
//                             border: OutlineInputBorder(),
//                             prefixIcon: Icon(Icons.lock, color: Colors.green),
//                             focusedBorder: OutlineInputBorder(
//                               borderSide: BorderSide(color: Colors.green),
//                             ),
//                           ),
//                           obscureText: true,
//                           style: const TextStyle(color: Colors.black),
//                           validator: (value) {
//                             if (_needsReauth &&
//                                 (value == null || value.isEmpty)) {
//                               return 'Please enter your password';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 8),
//                         const Text(
//                           'Security verification required to update email',
//                           style: TextStyle(
//                             color: Colors.orange,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                       const SizedBox(height: 24),
//                       // Update Button
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton(
//                           onPressed: _isLoading ? null : _updateProfile,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                             foregroundColor: Colors.white,
//                           ),
//                           child: _isLoading
//                               ? const SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     valueColor:
//                                         AlwaysStoppedAnimation(Colors.white),
//                                   ),
//                                 )
//                               : const Text(
//                                   'Update Profile',
//                                   style: TextStyle(fontSize: 16),
//                                 ),
//                         ),
//                       ),
//                       // Info Text
//                       const SizedBox(height: 16),
//                       Card(
//                         color: Colors.white,
//                         elevation: 2,
//                         child: const Padding(
//                           padding: EdgeInsets.all(12.0),
//                           child: Text(
//                             'Note: Changing your email will require verification. '
//                             'A verification email will be sent to your new email address. '
//                             'Please logout and login again to see changes.',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }


import 'package:flutter/material.dart';
import 'package:kafela/services/update_service.dart';

class EditProfile extends StatefulWidget {
  final Function()? onProfileUpdated; // Callback to notify parent
  const EditProfile({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final UpdateService _updateService = UpdateService();
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic> _userProfile = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final profile = await _updateService.getUserProfile();
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      _showErrorDialog('Failed to load profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String currentPassword = _currentPasswordController.text.trim();
      final String newPassword = _newPasswordController.text.trim();

      // Re-authenticate user first
      await _updateService.reauthenticateUser(currentPassword);

      // Update password
      await _updateService.updateUserPassword(newPassword);

      _showSuccessDialog(
        'Password Updated',
        'Your password has been updated successfully!',
      );

      // Clear form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }

    } catch (e) {
      if (e.toString().contains('re-authenticate') ||
          e.toString().contains('invalid-credential') ||
          e.toString().contains('wrong-password')) {
        _showErrorDialog(
          'Incorrect current password. Please enter your correct current password.',
        );
      } else {
        _showErrorDialog('Failed to update password: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(color: Colors.black)),
        content: Text(message, style: const TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close the edit profile screen
            },
            child: const Text('OK', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Error', style: TextStyle(color: Colors.black)),
        content: Text(message, style: const TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading && _userProfile.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Current Password Field
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: Colors.green),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                  obscureText: true,
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // New Password Field
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.green),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                  obscureText: true,
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.trim().length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm New Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset, color: Colors.green),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                  obscureText: true,
                  style: const TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : const Text(
                      'Update Password',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                // Info Text
                const SizedBox(height: 16),
                const Card(
                  color: Colors.white,
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Requirements:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• At least 6 characters long\n'
                              '• Enter your current password for security verification\n'
                              '• Make sure new passwords match',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
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
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
