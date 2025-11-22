// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
// class MemberActivityTab extends StatefulWidget {
//   const MemberActivityTab({super.key});
//
//   @override
//   State<MemberActivityTab> createState() => _MemberActivityTabState();
// }
//
// class _MemberActivityTabState extends State<MemberActivityTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   List<Map<String, dynamic>> _activities = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchActivities();
//   }
//
//   Future<void> _fetchActivities() async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         final activities = <Map<String, dynamic>>[];
//         // Fetch task activities
//         final tasksSnapshot = await _firestore
//             .collection('tasks')
//             .where('assignedTo', isEqualTo: user.uid)
//             .orderBy('updatedAt', descending: true)
//             .limit(10)
//             .get();
//         for (var task in tasksSnapshot.docs) {
//           final data = task.data();
//           final status = data['status'] ?? 'pending';
//           final color = _getTaskColor(status);
//           final icon = _getTaskIcon(status);
//           activities.add({
//             'type': 'task',
//             'title': 'Task: ${data['title']}',
//             'description': 'Status: ${_capitalize(status)}',
//             'timestamp': data['updatedAt'] ?? data['createdAt'],
//             'icon': icon,
//             'color': color,
//             'status': status,
//           });
//         }
//         // Fetch prayer attendance activities
//         final prayerSnapshot = await _firestore
//             .collection('prayer_attendance')
//             .doc(user.uid)
//             .collection('records')
//             .orderBy('updatedAt', descending: true)
//             .limit(10)
//             .get();
//         for (var prayer in prayerSnapshot.docs) {
//           final data = prayer.data();
//           final prayers = data.entries.where((entry) =>
//           entry.key != 'updatedAt' && entry.key != 'createdAt' &&
//               entry.key != 'date' && entry.key != 'timestamp');
//           for (var prayerEntry in prayers) {
//             if (prayerEntry.value == true) {
//               activities.add({
//                 'type': 'prayer',
//                 'title': 'Prayer: ${_capitalize(prayerEntry.key)}',
//                 'description': 'Marked as prayed',
//                 'timestamp': data['updatedAt'],
//                 'icon': Icons.mosque,
//                 'color': Colors.green,
//                 'status': 'completed',
//               });
//             }
//           }
//         }
//         // Sort all activities by timestamp
//         activities.sort((a, b) =>
//             (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
//         setState(() {
//           _activities = activities.take(20).toList();
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching activities: $e');
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Color _getTaskColor(String status) {
//     switch (status) {
//       case 'completed':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'overdue':
//         return Colors.red;
//       default:
//         return Colors.blue;
//     }
//   }
//
//   IconData _getTaskIcon(String status) {
//     switch (status) {
//       case 'completed':
//         return Icons.check_circle;
//       case 'pending':
//         return Icons.pending_actions;
//       case 'overdue':
//         return Icons.warning;
//       default:
//         return Icons.assignment;
//     }
//   }
//
//   Gradient _getActivityGradient(Color color) {
//     // Use MaterialColor shades for predefined colors, or create custom light versions
//     if (color == Colors.green) {
//       return LinearGradient(
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//         colors: [
//           Colors.green.shade100,
//           Colors.green.shade50,
//           Colors.white,
//         ],
//       );
//     } else if (color == Colors.orange) {
//       return LinearGradient(
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//         colors: [
//           Colors.orange.shade100,
//           Colors.orange.shade50,
//           Colors.white,
//         ],
//       );
//     } else if (color == Colors.red) {
//       return LinearGradient(
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//         colors: [
//           Colors.red.shade100,
//           Colors.red.shade50,
//           Colors.white,
//         ],
//       );
//     } else if (color == Colors.blue) {
//       return LinearGradient(
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//         colors: [
//           Colors.blue.shade100,
//           Colors.blue.shade50,
//           Colors.white,
//         ],
//       );
//     } else {
//       // For custom colors, create light versions manually
//       return LinearGradient(
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//         colors: [
//           color.withOpacity(0.2),
//           color.withOpacity(0.1),
//           Colors.white,
//         ],
//       );
//     }
//   }
//
//   String _capitalize(String text) {
//     if (text.isEmpty) return text;
//     return text[0].toUpperCase() + text.substring(1);
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
//               elevation: 4,
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
//                         Icons.analytics,
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
//                             'My Activity',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                           Text(
//                             'Recent activities and progress',
//                             style: TextStyle(
//                               color: Colors.black54,
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
//             const SizedBox(height: 16),
//             // Activities List
//             Expanded(
//               child: _isLoading
//                   ? const Center(child: CircularProgressIndicator(color: Colors.green))
//                   : _activities.isEmpty
//                   ? const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.history, size: 64, color: Colors.grey),
//                     SizedBox(height: 16),
//                     Text(
//                       'No activities found',
//                       style: TextStyle(color: Colors.black54),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Your activities will appear here',
//                       style: TextStyle(color: Colors.black54, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               )
//                   : ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: _activities.length,
//                 itemBuilder: (context, index) {
//                   final activity = _activities[index];
//                   final timestamp = (activity['timestamp'] as Timestamp).toDate();
//                   final gradient = _getActivityGradient(activity['color'] as Color);
//
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 8),
//                     decoration: BoxDecoration(
//                       gradient: gradient,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.3),
//                           blurRadius: 6,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     child: Card(
//                       color: Colors.transparent,
//                       elevation: 0,
//                       margin: EdgeInsets.zero,
//                       child: ListTile(
//                         leading: Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: (activity['color'] as Color).withOpacity(0.2),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             activity['icon'],
//                             color: activity['color'],
//                             size: 20,
//                           ),
//                         ),
//                         title: Text(
//                           activity['title'],
//                           style: const TextStyle(
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               activity['description'],
//                               style: TextStyle(
//                                 color: (activity['color'] as Color).withOpacity(0.8),
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               _formatTimestamp(timestamp),
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
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
//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);
//     if (difference.inMinutes < 1) {
//       return 'Just now';
//     } else if (difference.inHours < 1) {
//       return '${difference.inMinutes}m ago';
//     } else if (difference.inDays < 1) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inDays < 7) {
//       return '${difference.inDays}d ago';
//     } else {
//       return DateFormat('MMM dd, yyyy').format(timestamp);
//     }
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MemberActivityTab extends StatefulWidget {
  const MemberActivityTab({super.key});

  @override
  State<MemberActivityTab> createState() => _MemberActivityTabState();
}

class _MemberActivityTabState extends State<MemberActivityTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final activities = <Map<String, dynamic>>[];
        // Fetch task activities
        final tasksSnapshot = await _firestore
            .collection('tasks')
            .where('assignedTo', isEqualTo: user.uid)
            .orderBy('updatedAt', descending: true)
            .limit(10)
            .get();
        for (var task in tasksSnapshot.docs) {
          final data = task.data();
          activities.add({
            'type': 'task',
            'title': 'Task: ${data['title']}',
            'description': 'Status: ${data['status']}',
            'timestamp': data['updatedAt'] ?? data['createdAt'],
            'icon': Icons.assignment,
            'color': Colors.orange,
          });
        }
        // Fetch prayer attendance activities
        final prayerSnapshot = await _firestore
            .collection('prayer_attendance')
            .doc(user.uid)
            .collection('records')
            .orderBy('updatedAt', descending: true)
            .limit(10)
            .get();
        for (var prayer in prayerSnapshot.docs) {
          final data = prayer.data();
          final prayers = data.entries.where((entry) =>
          entry.key != 'updatedAt' && entry.key != 'createdAt');
          for (var prayerEntry in prayers) {
            if (prayerEntry.value == true) {
              activities.add({
                'type': 'prayer',
                'title': 'Prayer: ${_capitalize(prayerEntry.key)}',
                'description': 'Marked as prayed',
                'timestamp': data['updatedAt'],
                'icon': Icons.mosque,
                'color': Colors.green,
              });
            }
          }
        }
        // Sort all activities by timestamp
        activities.sort((a, b) =>
            (b['timestamp'] as
            Timestamp).compareTo(a['timestamp'] as Timestamp));
        setState( () {
          _activities = activities.take(20).toList();
          _isLoading = false;
        } );
      }
    } catch (e) {
      print('Error fetching activities: $e');
      setState(() => _isLoading = false);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Card(
              color: Colors.white,
              elevation: 4,
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
                        Icons.analytics,
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
                            'My Activity',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Recent activities and progress',
                            style: TextStyle(
                              color: Colors.black54,
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
            const SizedBox(height: 16),
            // Activities List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _activities.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No activities found',
                      style: TextStyle(color: Colors.black54),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your activities will appear here',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final activity = _activities[index];
                  final timestamp = (activity['timestamp'] as Timestamp).toDate();
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (activity['color'] as Color).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          activity['icon'],
                          color: activity['color'],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        activity['title'],
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['description'],
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(timestamp),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  Widget _buildActivityStat(String period, String count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          period,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }
}
