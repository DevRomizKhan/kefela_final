// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
// class MemberTasksTab extends StatefulWidget {
//   const MemberTasksTab({super.key});
//
//   @override
//   State<MemberTasksTab> createState() => _MemberTasksTabState();
// }
//
// class _MemberTasksTabState extends State<MemberTasksTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final TextEditingController _feedbackController = TextEditingController();
//   List<Map<String, dynamic>> _tasks = [];
//   bool _isLoading = true;
//   String _selectedFilter = 'all';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchTasks();
//   }
//
//   Future<void> _fetchTasks() async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         final snapshot = await _firestore
//             .collection('tasks')
//             .where('assignedTo', isEqualTo: user.uid)
//             .orderBy('dueDate')
//             .get();
//         setState(() {
//           _tasks = snapshot.docs.map((doc) {
//             final data = doc.data();
//             return {
//               'id': doc.id,
//               'title': data['title'] ?? 'No Title',
//               'description': data['description'] ?? 'No description',
//               'dueDate': data['dueDate'],
//               'status': data['status'] ?? 'pending',
//               'feedback': data['feedback'] ?? '',
//               'assignedBy': data['assignedBy'] ?? 'Admin',
//               'createdAt': data['createdAt'],
//             };
//           }).toList();
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching tasks: $e');
//       setState(() => _isLoading = false);
//     }
//   }
//
//   List<Map<String, dynamic>> get _filteredTasks {
//     switch (_selectedFilter) {
//       case 'pending':
//         return _tasks.where((task) => task['status'] == 'pending').toList();
//       case 'completed':
//         return _tasks.where((task) => task['status'] == 'completed').toList();
//       case 'overdue':
//         return _tasks.where((task) {
//           final dueDate = (task['dueDate'] as Timestamp).toDate();
//           return dueDate.isBefore(DateTime.now()) && task['status'] != 'completed';
//         }).toList();
//       default:
//         return _tasks;
//     }
//   }
//
//   Gradient _getTaskGradient(Map<String, dynamic> task) {
//     final dueDate = (task['dueDate'] as Timestamp).toDate();
//     final isOverdue = dueDate.isBefore(DateTime.now()) && task['status'] != 'completed';
//
//     if (_selectedFilter == 'all') {
//       if (task['status'] == 'completed') {
//         // Strong Greenish gradient for completed tasks
//         return LinearGradient(
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//           colors: [
//             Colors.green.shade100,
//             Colors.green.shade50,
//             Colors.white,
//           ],
//         );
//       } else {
//         // Strong Reddish gradient for uncompleted tasks
//         return LinearGradient(
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//           colors: [
//             Colors.red.shade100,
//             Colors.red.shade50,
//             Colors.white,
//           ],
//         );
//       }
//     } else if (_selectedFilter == 'pending') {
//       // Strong Yellowish gradient for pending tasks
//       return LinearGradient(
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//         colors: [
//           Colors.orange.shade100,
//           Colors.orange.shade50,
//           Colors.white,
//         ],
//       );
//     } else if (_selectedFilter == 'completed') {
//       // Strong Greenish gradient for completed tasks
//       return LinearGradient(
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//         colors: [
//           Colors.green.shade100,
//           Colors.green.shade50,
//           Colors.white,
//         ],
//       );
//     } else if (_selectedFilter == 'overdue') {
//       // Strong Reddish gradient for overdue tasks
//       return LinearGradient(
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//         colors: [
//           Colors.red.shade100,
//           Colors.red.shade50,
//           Colors.white,
//         ],
//       );
//     }
//
//     return LinearGradient(
//       colors: [Colors.white, Colors.white],
//     );
//   }
//
//   Color _getFeedbackIconColor(Map<String, dynamic> task) {
//     final dueDate = (task['dueDate'] as Timestamp).toDate();
//     final isOverdue = dueDate.isBefore(DateTime.now()) && task['status'] != 'completed';
//
//     if (_selectedFilter == 'all') {
//       if (task['status'] == 'completed') {
//         return Colors.green.shade700; // Dark green for completed
//       } else {
//         return Colors.red.shade700; // Dark red for uncompleted
//       }
//     } else if (_selectedFilter == 'pending') {
//       return Colors.orange.shade700; // Dark orange for pending
//     } else if (_selectedFilter == 'completed') {
//       return Colors.green.shade700; // Dark green for completed
//     } else if (_selectedFilter == 'overdue') {
//       return Colors.red.shade700; // Dark red for overdue
//     }
//
//     return Colors.green; // Default color
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header
//             Card(
//               color: Colors.white,
//               margin: const EdgeInsets.all(16),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.2),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.assignment,
//                         color: Colors.green,
//                         size: 24,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     const Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'My Tasks',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             'View and manage your assigned tasks',
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             // Filter Chips
//             SizedBox(
//               height: 50,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 children: [
//                   _buildFilterChip('All Tasks', 'all'),
//                   _buildFilterChip('Pending', 'pending'),
//                   _buildFilterChip('Completed', 'completed'),
//                   _buildFilterChip('Overdue', 'overdue'),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             // Tasks List
//             Expanded(
//               child: _isLoading
//                   ? const Center(child: CircularProgressIndicator(color: Colors.green))
//                   : _filteredTasks.isEmpty
//                   ? const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.assignment, size: 64, color: Colors.grey),
//                     SizedBox(height: 16),
//                     Text(
//                       'No tasks found',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Admin will assign tasks to you',
//                       style: TextStyle(color: Colors.black, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               )
//                   : ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: _filteredTasks.length,
//                 itemBuilder: (context, index) {
//                   final task = _filteredTasks[index];
//                   final dueDate = (task['dueDate'] as Timestamp).toDate();
//                   final isOverdue = dueDate.isBefore(DateTime.now()) && task['status'] != 'completed';
//                   final gradient = _getTaskGradient(task);
//                   final feedbackIconColor = _getFeedbackIconColor(task);
//
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     decoration: BoxDecoration(
//                       gradient: gradient,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.3),
//                           blurRadius: 6,
//                           offset: Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     child: Card(
//                       color: Colors.transparent,
//                       elevation: 0,
//                       margin: EdgeInsets.zero,
//                       child: ListTile(
//                         leading: IconButton(
//                           icon: Icon(
//                             task['status'] == 'completed'
//                                 ? Icons.check_circle
//                                 : Icons.radio_button_unchecked,
//                             color: task['status'] == 'completed'
//                                 ? Colors.green
//                                 : Colors.orange,
//                             size: 28,
//                           ),
//                           onPressed: () => _toggleTaskStatus(task['id'], task['status']),
//                         ),
//                         title: Text(
//                           task['title'],
//                           style: TextStyle(
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               task['description'],
//                               style: const TextStyle(color: Colors.black),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
//                               style: TextStyle(
//                                 color: isOverdue ? Colors.red : Colors.black,
//                                 fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
//                               ),
//                             ),
//                             if (task['feedback'] != null && task['feedback'].isNotEmpty)
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     'Your Feedback: ${task['feedback']}',
//                                     style: const TextStyle(
//                                       color: Colors.green,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                           ],
//                         ),
//                         trailing: IconButton(
//                           icon: Icon(Icons.feedback, color: feedbackIconColor),
//                           onPressed: () => _showFeedbackDialog(task['id'], task['title']),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFilterChip(String label, String value) {
//     final isSelected = _selectedFilter == value;
//     return Container(
//       margin: const EdgeInsets.only(right: 8),
//       child: FilterChip(
//         label: Text(
//           label,
//           style: TextStyle(
//             color: isSelected ? Colors.white : Colors.black,
//           ),
//         ),
//         selected: isSelected,
//         onSelected: (selected) {
//           setState(() {
//             _selectedFilter = value;
//           });
//         },
//         backgroundColor: Colors.grey[200],
//         selectedColor: Colors.green,
//         checkmarkColor: Colors.white,
//       ),
//     );
//   }
//
//   Future<void> _toggleTaskStatus(String taskId, String currentStatus) async {
//     try {
//       final newStatus = currentStatus == 'completed' ? 'pending' : 'completed';
//       await _firestore.collection('tasks').doc(taskId).update({
//         'status': newStatus,
//         'updatedAt': Timestamp.now(),
//       });
//       setState(() {
//         final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
//         if (taskIndex != -1) {
//           _tasks[taskIndex]['status'] = newStatus;
//         }
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             newStatus == 'completed'
//                 ? 'Task marked as completed!'
//                 : 'Task marked as pending',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error updating task: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   void _showFeedbackDialog(String taskId, String taskTitle) {
//     _feedbackController.clear();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.white,
//         title: Text(
//           'Provide Feedback for: $taskTitle',
//           style: const TextStyle(color: Colors.black),
//         ),
//         content: TextField(
//           controller: _feedbackController,
//           maxLines: 4,
//           decoration: const InputDecoration(
//             hintText: 'Enter your feedback or comments...',
//             hintStyle: TextStyle(color: Colors.grey),
//             border: OutlineInputBorder(),
//             focusedBorder: OutlineInputBorder(
//               borderSide: BorderSide(color: Colors.green),
//             ),
//           ),
//           style: const TextStyle(color: Colors.black),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             onPressed: () => _submitFeedback(taskId),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             child: const Text('Submit Feedback', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _submitFeedback(String taskId) async {
//     if (_feedbackController.text.trim().isEmpty) return;
//     try {
//       await _firestore.collection('tasks').doc(taskId).update({
//         'feedback': _feedbackController.text.trim(),
//         'feedbackAt': Timestamp.now(),
//       });
//       setState(() {
//         final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
//         if (taskIndex != -1) {
//           _tasks[taskIndex]['feedback'] = _feedbackController.text.trim();
//         }
//       });
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Feedback submitted successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error submitting feedback: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MemberTasksTab extends StatefulWidget {
  const MemberTasksTab({super.key});

  @override
  State<MemberTasksTab> createState() => _MemberTasksTabState();
}

class _MemberTasksTabState extends State<MemberTasksTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _feedbackController = TextEditingController();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('tasks')
            .where('assignedTo', isEqualTo: user.uid)
            .orderBy('dueDate')
            .get();
        setState(() {
          _tasks = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'No Title',
              'description': data['description'] ?? 'No description',
              'dueDate': data['dueDate'],
              'status': data['status'] ?? 'pending',
              'feedback': data['feedback'] ?? '',
              'assignedBy': data['assignedBy'] ?? 'Admin',
              'createdAt': data['createdAt'],
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTasks {
    switch (_selectedFilter) {
      case 'pending':
        return _tasks.where((task) => task['status'] == 'pending').toList();
      case 'completed':
        return _tasks.where((task) => task['status'] == 'completed').toList();
      case 'overdue':
        return _tasks.where((task) {
          final dueDate = (task['dueDate'] as Timestamp).toDate();
          return dueDate.isBefore(DateTime.now()) && task['status'] != 'completed';
        }).toList();
      default:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed to white
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Card(
              color: Colors.white, // Changed to white
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Tasks',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Changed to black
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'View and manage your assigned tasks',
                            style: TextStyle(
                              color: Colors.black, // Changed to black
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Filter Chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('All Tasks', 'all'),
                  _buildFilterChip('Pending', 'pending'),
                  _buildFilterChip('Completed', 'completed'),
                  _buildFilterChip('Overdue', 'overdue'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tasks List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _filteredTasks.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No tasks found',
                      style: TextStyle(color: Colors.black), // Changed to black
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Admin will assign tasks to you',
                      style: TextStyle(color: Colors.black, fontSize: 12), // Changed to black
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  final dueDate = (task['dueDate'] as Timestamp).toDate();
                  final isOverdue = dueDate.isBefore(DateTime.now()) && task['status'] != 'completed';
                  return Card(
                    color: Colors.white, // Changed to white
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: IconButton(
                        icon: Icon(
                          task['status'] == 'completed'
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: task['status'] == 'completed'
                              ? Colors.green
                              : Colors.orange,
                          size: 28,
                        ),
                        onPressed: () => _toggleTaskStatus(task['id'], task['status']),
                      ),
                      title: Text(
                        task['title'],
                        style: TextStyle(
                          color: Colors.black, // Changed to black
                          fontWeight: FontWeight.bold,
                          decoration: task['status'] == 'completed'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['description'],
                            style: const TextStyle(color: Colors.black), // Changed to black
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                            style: TextStyle(
                              color: isOverdue ? Colors.red : Colors.black, // Changed to black
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (task['feedback'] != null && task['feedback'].isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Your Feedback: ${task['feedback']}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.feedback, color: Colors.green),
                        onPressed: () => _showFeedbackDialog(task['id'], task['title']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black, // Changed to black
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Colors.grey[200], // Changed to light grey for contrast
        selectedColor: Colors.green,
        checkmarkColor: Colors.white,
      ),
    );
  }

  Future<void> _toggleTaskStatus(String taskId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'completed' ? 'pending' : 'completed';
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
      setState(() {
        final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
        if (taskIndex != -1) {
          _tasks[taskIndex]['status'] = newStatus;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'completed'
                ? 'Task marked as completed!'
                : 'Task marked as pending',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFeedbackDialog(String taskId, String taskTitle) {
    _feedbackController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Changed to white
        title: Text(
          'Provide Feedback for: $taskTitle',
          style: const TextStyle(color: Colors.black), // Changed to black
        ),
        content: TextField(
          controller: _feedbackController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter your feedback or comments...',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green),
            ),
          ),
          style: const TextStyle(color: Colors.black), // Changed to black
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _submitFeedback(taskId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Submit Feedback', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback(String taskId) async {
    if (_feedbackController.text.trim().isEmpty) return;
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'feedback': _feedbackController.text.trim(),
        'feedbackAt': Timestamp.now(),
      });
      setState(() {
        final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
        if (taskIndex != -1) {
          _tasks[taskIndex]['feedback'] = _feedbackController.text.trim();
        }
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}