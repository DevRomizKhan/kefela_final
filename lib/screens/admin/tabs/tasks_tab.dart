// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
//
// class TasksTab extends StatefulWidget {
//   const TasksTab({super.key});
//
//   @override
//   State<TasksTab> createState() => _TasksTabState();
// }
//
// class _TasksTabState extends State<TasksTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   DateTime _dueDate = DateTime.now();
//   String _selectedMember = '';
//   List<Map<String, dynamic>> _members = [];
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchMembers();
//   }
//
//   Future<void> _fetchMembers() async {
//     try {
//       final snapshot = await _firestore
//           .collection('users')
//           .where('role', isEqualTo: 'Member')
//           .limit(100)
//           .get();
//       setState(() {
//         _members = snapshot.docs.map((doc) {
//           final data = doc.data();
//           return {
//             'uid': doc.id,
//             'name': data['name'] ?? 'Unknown Member',
//             'email': data['email'] ?? 'No email',
//           };
//         }).toList();
//         if (_members.isNotEmpty) {
//           _selectedMember = _members.first['uid'];
//         }
//       });
//     } catch (e) {
//       print('Error fetching members: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               // Header
//               Card(
//                 color: Colors.white,
//                 elevation: 4,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.assignment,
//                           color: Colors.green, size: 28),
//                       const SizedBox(width: 12),
//                       const Text(
//                         'Task Management',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         icon: const Icon(Icons.add, color: Colors.green),
//                         onPressed: _showAddTaskDialog,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               // Tasks List
//               Expanded(
//                 child: StreamBuilder<QuerySnapshot>(
//                   stream: _firestore
//                       .collection('tasks')
//                       .orderBy('dueDate')
//                       .snapshots(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(
//                           child:
//                               CircularProgressIndicator(color: Colors.green));
//                     }
//                     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                       return const Center(
//                         child: Text(
//                           'No tasks found',
//                           style: TextStyle(color: Colors.black54),
//                         ),
//                       );
//                     }
//                     final tasks = snapshot.data!.docs;
//                     return ListView.builder(
//                       itemCount: tasks.length,
//                       itemBuilder: (context, index) {
//                         final task =
//                             tasks[index].data() as Map<String, dynamic>;
//                         final taskId = tasks[index].id;
//                         final dueDate = (task['dueDate'] as Timestamp).toDate();
//                         final isOverdue = dueDate.isBefore(DateTime.now()) &&
//                             task['status'] != 'completed';
//                         return Card(
//                           color: Colors.white,
//                           margin: const EdgeInsets.only(bottom: 8),
//                           elevation: 2,
//                           child: ListTile(
//                             leading: Icon(
//                               task['status'] == 'completed'
//                                   ? Icons.check_circle
//                                   : Icons.radio_button_unchecked,
//                               color: task['status'] == 'completed'
//                                   ? Colors.green
//                                   : Colors.orange,
//                             ),
//                             title: Text(
//                               task['title'] ?? 'No Title',
//                               style: TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                                 decoration: task['status'] == 'completed'
//                                     ? TextDecoration.lineThrough
//                                     : null,
//                               ),
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   task['description'] ?? 'No description',
//                                   style: const TextStyle(color: Colors.black54),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 const SizedBox(height: 4),
//
//                                 // Due date
//                                 Text(
//                                   'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
//                                   style: TextStyle(
//                                     color: isOverdue ? Colors.red : Colors.black54,
//                                     fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
//                                   ),
//                                 ),
//
//                                 // Assigned member
//                                 Text(
//                                   'Assigned to: ${task['assignedToName'] ?? 'Unknown'}',
//                                   style: const TextStyle(color: Colors.black54, fontSize: 12),
//                                 ),
//
//                                 const SizedBox(height: 8),
//
//                                 // FEEDBACK SECTION
//                                 Container(
//                                   padding: const EdgeInsets.all(10),
//                                   decoration: BoxDecoration(
//                                     color: task['feedback'] != null
//                                         ? Colors.green.withOpacity(0.1)
//                                         : Colors.orange.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Member Feedback:',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: task['feedback'] != null ? Colors.green : Colors.orange,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 6),
//
//                                       // If feedback exists
//                                       if (task['feedback'] != null) ...[
//                                         Text(
//                                           task['feedback'],
//                                           style: const TextStyle(color: Colors.black87),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           'Submitted on: ${task['feedbackAt'] != null ? DateFormat('MMM dd, yyyy  hh:mm a').format((task['feedbackAt'] as Timestamp).toDate()) : "Unknown"}',
//                                           style: const TextStyle(color: Colors.black54, fontSize: 11),
//                                         ),
//                                       ],
//
//                                       // If feedback does NOT exist
//                                       if (task['feedback'] == null)
//                                         const Text(
//                                           'No feedback submitted yet',
//                                           style: TextStyle(color: Colors.black54),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 if (task['status'] != 'completed')
//                                   IconButton(
//                                     icon: const Icon(Icons.check,
//                                         color: Colors.green),
//                                     onPressed: () =>
//                                         _updateTaskStatus(taskId, 'completed'),
//                                   ),
//                                 IconButton(
//                                   icon: const Icon(Icons.delete,
//                                       color: Colors.red),
//                                   onPressed: () => _deleteTask(taskId),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showAddTaskDialog() {
//     String searchQuery = '';
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) {
//           final filteredMembers = searchQuery.isEmpty
//               ? _members
//               : _members
//                   .where((member) => (member['name'] ?? '')
//                       .toLowerCase()
//                       .contains(searchQuery.toLowerCase()))
//                   .toList();
//           return AlertDialog(
//             backgroundColor: Colors.white,
//             title: const Text(
//               'Assign New Task',
//               style: TextStyle(color: Colors.black),
//             ),
//             content: SizedBox(
//               width: double.maxFinite,
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Task Title
//                     TextField(
//                       controller: _titleController,
//                       decoration: const InputDecoration(
//                         labelText: 'Task Title',
//                         labelStyle: TextStyle(color: Colors.black54),
//                         border: OutlineInputBorder(),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: Colors.green),
//                         ),
//                       ),
//                       style: const TextStyle(color: Colors.black),
//                     ),
//                     const SizedBox(height: 12),
//                     // Description
//                     TextField(
//                       controller: _descriptionController,
//                       maxLines: 3,
//                       decoration: const InputDecoration(
//                         labelText: 'Description',
//                         labelStyle: TextStyle(color: Colors.black54),
//                         border: OutlineInputBorder(),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: Colors.green),
//                         ),
//                       ),
//                       style: const TextStyle(color: Colors.black),
//                     ),
//                     const SizedBox(height: 12),
//                     // Search for Members
//                     TextField(
//                       onChanged: (value) {
//                         setDialogState(() {
//                           searchQuery = value;
//                         });
//                       },
//                       decoration: const InputDecoration(
//                         labelText: 'Search Members...',
//                         labelStyle: TextStyle(color: Colors.black54),
//                         prefixIcon: Icon(Icons.search, color: Colors.green),
//                         border: OutlineInputBorder(),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: Colors.green),
//                         ),
//                       ),
//                       style: const TextStyle(color: Colors.black),
//                     ),
//                     const SizedBox(height: 12),
//                     // Selected Member Display
//                     if (_selectedMember.isNotEmpty)
//                       Card(
//                         color: Colors.green.withOpacity(0.1),
//                         child: ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: Colors.green,
//                             child: Text(
//                               _members
//                                   .firstWhere((m) =>
//                                       m['uid'] == _selectedMember)['name'][0]
//                                   .toUpperCase(),
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ),
//                           title: Text(
//                             _members.firstWhere(
//                                 (m) => m['uid'] == _selectedMember)['name'],
//                             style: const TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: const Text(
//                             'Selected for task assignment',
//                             style: TextStyle(color: Colors.black54),
//                           ),
//                           trailing: IconButton(
//                             icon: const Icon(Icons.clear, color: Colors.red),
//                             onPressed: () {
//                               setDialogState(() {
//                                 _selectedMember = '';
//                               });
//                             },
//                           ),
//                         ),
//                       ),
//                     // Members List
//                     if (searchQuery.isNotEmpty || _selectedMember.isEmpty)
//                       Container(
//                         constraints: const BoxConstraints(maxHeight: 200),
//                         child: filteredMembers.isEmpty
//                             ? const Padding(
//                                 padding: EdgeInsets.all(16.0),
//                                 child: Text(
//                                   'No members found',
//                                   style: TextStyle(color: Colors.black54),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               )
//                             : ListView.builder(
//                                 shrinkWrap: true,
//                                 physics: const AlwaysScrollableScrollPhysics(),
//                                 itemCount: filteredMembers.length,
//                                 itemBuilder: (context, index) {
//                                   final member = filteredMembers[index];
//                                   final isSelected =
//                                       member['uid'] == _selectedMember;
//                                   return Card(
//                                     color: isSelected
//                                         ? Colors.green.withOpacity(0.2)
//                                         : Colors.white,
//                                     margin: const EdgeInsets.only(bottom: 8),
//                                     elevation: isSelected ? 2 : 1,
//                                     child: ListTile(
//                                       leading: CircleAvatar(
//                                         backgroundColor: isSelected
//                                             ? Colors.green
//                                             : Colors.grey[300],
//                                         child: Text(
//                                           (member['name'] ?? '')[0]
//                                               .toUpperCase(),
//                                           style: const TextStyle(
//                                               color: Colors.white),
//                                         ),
//                                       ),
//                                       title: Text(
//                                         member['name'] ?? 'Unknown',
//                                         style: TextStyle(
//                                           color: Colors.black,
//                                           fontWeight: isSelected
//                                               ? FontWeight.bold
//                                               : FontWeight.normal,
//                                         ),
//                                       ),
//                                       subtitle: Text(
//                                         member['email'] ?? 'No email',
//                                         style: const TextStyle(
//                                             color: Colors.black54,
//                                             fontSize: 12),
//                                       ),
//                                       trailing: isSelected
//                                           ? const Icon(Icons.check_circle,
//                                               color: Colors.green)
//                                           : null,
//                                       onTap: () {
//                                         setDialogState(() {
//                                           _selectedMember =
//                                               member['uid'] as String;
//                                         });
//                                       },
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),
//                     const SizedBox(height: 12),
//                     // Due Date
//                     Card(
//                       color: Colors.white,
//                       elevation: 1,
//                       child: ListTile(
//                         leading: const Icon(Icons.calendar_today,
//                             color: Colors.green),
//                         title: const Text('Due Date',
//                             style: TextStyle(color: Colors.black54)),
//                         subtitle: Text(
//                           DateFormat('MMM dd, yyyy').format(_dueDate),
//                           style: const TextStyle(color: Colors.black),
//                         ),
//                         trailing: const Icon(Icons.arrow_drop_down,
//                             color: Colors.green),
//                         onTap: () async {
//                           final date = await showDatePicker(
//                             context: context,
//                             initialDate: _dueDate,
//                             firstDate: DateTime.now(),
//                             lastDate: DateTime(2100),
//                           );
//                           if (date != null) {
//                             setDialogState(() {
//                               _dueDate = date;
//                             });
//                           }
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   _selectedMember = '';
//                   Navigator.pop(context);
//                 },
//                 child: const Text('Cancel',
//                     style: TextStyle(color: Colors.black54)),
//               ),
//               ElevatedButton(
//                 onPressed: _selectedMember.isNotEmpty &&
//                         _titleController.text.isNotEmpty
//                     ? _addTask
//                     : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                   disabledBackgroundColor: Colors.grey,
//                 ),
//                 child: const Text('Assign Task'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Future<void> _addTask() async {
//     if (_titleController.text.isEmpty || _selectedMember.isEmpty) return;
//     setState(() => _isLoading = true);
//     try {
//       final member = _members.firstWhere((m) => m['uid'] == _selectedMember);
//       await _firestore.collection('tasks').add({
//         'title': _titleController.text,
//         'description': _descriptionController.text,
//         'assignedTo': _selectedMember,
//         'assignedToName': member['name'],
//         'dueDate': Timestamp.fromDate(_dueDate),
//         'status': 'pending',
//         'createdAt': Timestamp.now(),
//         'updatedAt': Timestamp.now(),
//       });
//       _titleController.clear();
//       _descriptionController.clear();
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Task assigned successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error assigning task: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _updateTaskStatus(String taskId, String status) async {
//     try {
//       await _firestore.collection('tasks').doc(taskId).update({
//         'status': status,
//         'updatedAt': Timestamp.now(),
//       });
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
//   Future<void> _deleteTask(String taskId) async {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.white,
//         title: const Text('Delete Task', style: TextStyle(color: Colors.black)),
//         content: const Text('Are you sure you want to delete this task?',
//             style: TextStyle(color: Colors.black54)),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child:
//                 const Text('Cancel', style: TextStyle(color: Colors.black54)),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               try {
//                 await _firestore.collection('tasks').doc(taskId).delete();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Task deleted successfully!'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Error deleting task: $e'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red, foregroundColor: Colors.white),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Member')
          .limit(100)
          .get();
      setState(() {
        _members = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'uid': doc.id,
            'name': data['name'] ?? 'Unknown Member',
            'email': data['email'] ?? 'No email',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching members: $e');
    }
  }

  void _navigateToAddTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTaskPage(
          members: _members,
          onTaskSaved: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task assigned successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToEditTask(Map<String, dynamic> task, String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTaskPage(
          members: _members,
          task: task,
          taskId: taskId,
          onTaskSaved: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Card(
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment,
                          color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Task Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: _navigateToAddTask,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Tasks List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('tasks')
                      .orderBy('dueDate')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                          CircularProgressIndicator(color: Colors.green));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: TextStyle(color: Colors.black54),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to create a task',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    final tasks = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task =
                        tasks[index].data() as Map<String, dynamic>;
                        final taskId = tasks[index].id;
                        final dueDate = (task['dueDate'] as Timestamp).toDate();
                        final isOverdue = dueDate.isBefore(DateTime.now()) &&
                            task['status'] != 'completed';

                        // Handle multiple assigned members
                        final assignedMembers = task['assignedMembers'] != null
                            ? List<Map<String, dynamic>>.from(task['assignedMembers'])
                            : [];
                        final assignedMemberNames = assignedMembers.isNotEmpty
                            ? assignedMembers.map((m) => m['name']).toList()
                            : [task['assignedToName'] ?? 'Unknown'];

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          child: ListTile(
                            leading: Icon(
                              task['status'] == 'completed'
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: task['status'] == 'completed'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            title: Text(
                              task['title'] ?? 'No Title',
                              style: TextStyle(
                                color: Colors.black,
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
                                  task['description'] ?? 'No description',
                                  style: const TextStyle(color: Colors.black54),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // Due date
                                Text(
                                  'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                                  style: TextStyle(
                                    color: isOverdue ? Colors.red : Colors.black54,
                                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),

                                // Assigned members
                                Text(
                                  'Assigned to: ${assignedMemberNames.join(', ')}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),

                                const SizedBox(height: 8),

                                // FEEDBACK SECTION
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: task['feedback'] != null
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Member Feedback:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: task['feedback'] != null ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // If feedback exists
                                      if (task['feedback'] != null) ...[
                                        Text(
                                          task['feedback'],
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Submitted on: ${task['feedbackAt'] != null ? DateFormat('MMM dd, yyyy  hh:mm a').format((task['feedbackAt'] as Timestamp).toDate()) : "Unknown"}',
                                          style: const TextStyle(color: Colors.black54, fontSize: 11),
                                        ),
                                      ],

                                      // If feedback does NOT exist
                                      if (task['feedback'] == null)
                                        const Text(
                                          'No feedback submitted yet',
                                          style: TextStyle(color: Colors.black54),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit button
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _navigateToEditTask(task, taskId),
                                ),
                                if (task['status'] != 'completed')
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _updateTaskStatus(taskId, 'completed'),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTask(taskId),
                                ),
                              ],
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
    );
  }

  Future<void> _updateTaskStatus(String taskId, String status) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTask(String taskId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Task', style: TextStyle(color: Colors.black)),
        content: const Text('Are you sure you want to delete this task?',
            style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('tasks').doc(taskId).delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting task: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddEditTaskPage extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final Map<String, dynamic>? task;
  final String? taskId;
  final VoidCallback onTaskSaved;

  const AddEditTaskPage({
    super.key,
    required this.members,
    this.task,
    this.taskId,
    required this.onTaskSaved,
  });

  @override
  State<AddEditTaskPage> createState() => _AddEditTaskPageState();
}

class _AddEditTaskPageState extends State<AddEditTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  List<Map<String, dynamic>> _selectedMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If editing existing task, populate the fields
    if (widget.task != null) {
      _titleController.text = widget.task!['title'] ?? '';
      _descriptionController.text = widget.task!['description'] ?? '';
      _dueDate = (widget.task!['dueDate'] as Timestamp).toDate();

      // Handle both single and multiple assigned members
      if (widget.task!['assignedMembers'] != null) {
        _selectedMembers = List<Map<String, dynamic>>.from(widget.task!['assignedMembers']);
      } else if (widget.task!['assignedTo'] != null) {
        // Convert single assignment to multiple assignment format
        final member = widget.members.firstWhere(
              (m) => m['uid'] == widget.task!['assignedTo'],
          orElse: () => {
            'uid': widget.task!['assignedTo'],
            'name': widget.task!['assignedToName'] ?? 'Unknown',
            'email': 'Unknown'
          },
        );
        _selectedMembers = [member];
      }
    }
  }

  void _toggleMemberSelection(Map<String, dynamic> member) {
    setState(() {
      if (_selectedMembers.any((m) => m['uid'] == member['uid'])) {
        _selectedMembers.removeWhere((m) => m['uid'] == member['uid']);
      } else {
        _selectedMembers.add(member);
      }
    });
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty || _selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final taskData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'assignedMembers': _selectedMembers.map((member) => {
          'uid': member['uid'],
          'name': member['name'],
          'email': member['email'],
        }).toList(),
        'assignedTo': _selectedMembers.first['uid'], // Keep for backward compatibility
        'assignedToName': _selectedMembers.first['name'], // Keep for backward compatibility
        'dueDate': Timestamp.fromDate(_dueDate),
        'updatedAt': Timestamp.now(),
      };

      if (widget.taskId == null) {
        // Create new task
        taskData['status'] = 'pending';
        taskData['createdAt'] = Timestamp.now();
        await FirebaseFirestore.instance.collection('tasks').add(taskData);
      } else {
        // Update existing task
        await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId!).update(taskData);
      }

      widget.onTaskSaved();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = widget.members.where((member) {
      final searchTerm = _searchController.text.toLowerCase();
      return member['name'].toLowerCase().contains(searchTerm) ||
          member['email'].toLowerCase().contains(searchTerm);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.taskId == null ? 'Assign New Task' : 'Edit Task',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const CircularProgressIndicator(color: Colors.green)
                : const Icon(Icons.save, color: Colors.green),
            onPressed: _isLoading ? null : _saveTask,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Task Title
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),

              // Due Date
              Card(
                color: Colors.white,
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.green),
                  title: const Text('Due Date *', style: TextStyle(color: Colors.black54)),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(_dueDate),
                    style: const TextStyle(color: Colors.black),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down, color: Colors.green),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        _dueDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Selected Members Section
              if (_selectedMembers.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selected Members:',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedMembers.map((member) {
                    return Chip(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      label: Text(
                        member['name'],
                        style: const TextStyle(color: Colors.green),
                      ),
                      deleteIcon: const Icon(Icons.clear, size: 16, color: Colors.green),
                      onDeleted: () => _toggleMemberSelection(member),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Search Members
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Search Members...',
                  labelStyle: TextStyle(color: Colors.black54),
                  prefixIcon: Icon(Icons.search, color: Colors.green),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),

              // Members List
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: filteredMembers.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No members found',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    final isSelected = _selectedMembers.any((m) => m['uid'] == member['uid']);

                    return Card(
                      color: isSelected
                          ? Colors.green.withOpacity(0.2)
                          : Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: isSelected ? 2 : 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Colors.green
                              : Colors.grey[300],
                          child: Text(
                            (member['name'] ?? '')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          member['name'] ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          member['email'] ?? 'No email',
                          style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                        onTap: () => _toggleMemberSelection(member),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey,
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
                      : Text(
                    widget.taskId == null ? 'Assign Task' : 'Update Task',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
