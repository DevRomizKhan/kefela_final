// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:intl/intl.dart';
//
// import 'package:kafela/screens/member/tabs/prayer_attendance_tab.dart';
// import 'package:kafela/screens/member/tabs/tasks_tab.dart';
//
// import 'class_routine_tab.dart';
// import 'groups_tab.dart';
//
// class MemberDashboardTab extends StatefulWidget {
//   const MemberDashboardTab({super.key});
//
//   @override
//   State<MemberDashboardTab> createState() => _MemberDashboardTabState();
// }
//
// class _MemberDashboardTabState extends State<MemberDashboardTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   Map<String, dynamic>? _memberData;
//
//   int _completedTasks = 0;
//   int _pendingTasks = 0;
//   int _totalGroups = 0;
//   double _attendanceRate = 0.0;
//
//   bool _isLoading = true;
//
//   List<Map<String, dynamic>> _todayRoutines = [];
//   List<Map<String, dynamic>> _todayTasks = [];
//
//   final List<StreamSubscription> _subscriptions = [];
//
//   // Subscription reference for meetings so we can re-create it when member data changes.
//   StreamSubscription<QuerySnapshot>? _meetingsSubscription;
//
//   String _currentWeekday = '';
//
//   // Simple in-memory caches to speed repeated work
//   final Map<String, int> _attendanceCache =
//       {}; // meetingId -> attendancePoints for current user
//   DateTime? _memberCreatedAtCache;
//   String? _cachedUserIdForAttendance;
//
//   // Optionally cache routines & tasks results to avoid frequent UI rebuilds from identical data
//   List<Map<String, dynamic>> _routinesCache = [];
//   List<Map<String, dynamic>> _tasksCache = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Enable local persistence (Firestore caching) - do this early.
//     // Note: settings should be set before heavy reads; it's okay here for typical use.
//     _firestore.settings = const Settings(persistenceEnabled: true);
//
//     _currentWeekday = DateFormat('EEEE').format(DateTime.now());
//     _setupRealtimeListeners();
//   }
//
//   @override
//   void dispose() {
//     // Cancel all subscriptions when widget is disposed
//     for (var subscription in _subscriptions) {
//       subscription.cancel();
//     }
//     _meetingsSubscription?.cancel();
//     super.dispose();
//   }
//
//   void _setupRealtimeListeners() {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     final today = DateTime.now();
//     final startOfDay = DateTime(today.year, today.month, today.day);
//     final endOfDay = startOfDay.add(const Duration(hours: 24));
//
//     // Listen to member data
//     final userSub = _firestore
//         .collection('users')
//         .doc(user.uid)
//         .snapshots()
//         .listen((snapshot) {
//       if (snapshot.exists) {
//         final data = snapshot.data() as Map<String, dynamic>;
//
//         // Update member data and cached createdAt
//         setState(() {
//           _memberData = data;
//         });
//
//         // Cache createdAt if available
//         if (data['createdAt'] is Timestamp) {
//           final createdTs = (data['createdAt'] as Timestamp).toDate();
//           _memberCreatedAtCache = createdTs;
//         } else {
//           _memberCreatedAtCache = null;
//         }
//
//         // (Re)subscribe to meetings filtered by createdAt (we cancelled and recreate below)
//         _subscribeMeetingsForUser(user.uid);
//       }
//     });
//     _subscriptions.add(userSub);
//
//     // Listen to all tasks for stats (assigned to user)
//     final tasksSub = _firestore
//         .collection('tasks')
//         .where('assignedTo', isEqualTo: user.uid)
//         .snapshots()
//         .listen((snapshot) {
//       _calculateTaskStats(snapshot.docs);
//
//       // also cache today's tasks separately (we also have a dedicated query)
//       final todayTaskDocs = snapshot.docs.where((doc) {
//         final due = doc.data()['dueDate'];
//         if (due is Timestamp) {
//           final dt = due.toDate();
//           return dt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
//               dt.isBefore(endOfDay.add(const Duration(seconds: 1)));
//         }
//         return false;
//       }).toList();
//
//       final newTodayTasks = todayTaskDocs.map((doc) {
//         final data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
//
//       // small-cache check to avoid unnecessary setState
//       if (!_listEqualsById(_tasksCache, newTodayTasks)) {
//         _tasksCache = newTodayTasks;
//         setState(() {
//           _todayTasks = newTodayTasks;
//         });
//       }
//     });
//     _subscriptions.add(tasksSub);
//
//     // Listen to groups count
//     final groupsSub = _firestore
//         .collection('groups')
//         .where('members', arrayContains: user.uid)
//         .snapshots()
//         .listen((snapshot) {
//       setState(() {
//         _totalGroups = snapshot.docs.length;
//       });
//     });
//     _subscriptions.add(groupsSub);
//
//     // Listen to today's routines (by weekday)
//     final routinesSub = _firestore
//         .collection('routines')
//         .where('day', isEqualTo: _currentWeekday)
//         .snapshots()
//         .listen((snapshot) {
//       final newRoutines = snapshot.docs.map((doc) {
//         final data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
//
//       // small-cache check to avoid unnecessary setState
//       if (!_listEqualsById(_routinesCache, newRoutines)) {
//         _routinesCache = newRoutines;
//         setState(() {
//           _todayRoutines = newRoutines;
//         });
//       }
//     });
//     _subscriptions.add(routinesSub);
//
//     // Today's tasks (dedicated query for accurate dueDate filter)
//     final todayTasksSub = _firestore
//         .collection('tasks')
//         .where('assignedTo', isEqualTo: user.uid)
//         .where('dueDate',
//             isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
//         .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay))
//         .snapshots()
//         .listen((snapshot) {
//       final newTodayTasks = snapshot.docs.map((doc) {
//         final data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
//
//       if (!_listEqualsById(_tasksCache, newTodayTasks)) {
//         _tasksCache = newTodayTasks;
//         setState(() {
//           _todayTasks = newTodayTasks;
//         });
//       }
//     });
//     _subscriptions.add(todayTasksSub);
//
//     // Set loading to false after a short delay
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     });
//   }
//
//   // Cancels any previous meeting subscription and creates a new one filtered by member createdAt
//   void _subscribeMeetingsForUser(String userId) {
//     // If same user and same createdAt used previously, no need to recreate
//     if (_cachedUserIdForAttendance == userId && _meetingsSubscription != null) {
//       return;
//     }
//
//     // Cancel existing meeting subscription if any
//     _meetingsSubscription?.cancel();
//     _meetingsSubscription = null;
//     _attendanceCache.clear();
//     _cachedUserIdForAttendance = userId;
//
//     Query meetingsQuery = _firestore
//         .collection('meetings')
//         .orderBy('date', descending: true)
//         .limit(20);
//
//     // If we have member createdAt timestamp, only consider meetings on or after that date
//     if (_memberCreatedAtCache != null) {
//       meetingsQuery = meetingsQuery.where(
//         'date',
//         isGreaterThanOrEqualTo: Timestamp.fromDate(_memberCreatedAtCache!),
//       );
//     }
//
//     _meetingsSubscription =
//         meetingsQuery.snapshots().listen((meetingsSnapshot) async {
//       // when meetings change, recalculate attendance
//       final docs = meetingsSnapshot.docs;
//       await _calculateAttendanceRate(docs, userId);
//     }, onError: (e) {
//       // handle potential errors quietly
//       // print('Meetings subscription error: $e');
//     });
//   }
//
//   void _calculateTaskStats(List<QueryDocumentSnapshot> taskDocs) {
//     int total = taskDocs.length;
//     int completed = taskDocs
//         .where((doc) =>
//             (doc.data() as Map<String, dynamic>)['status'] == 'completed')
//         .length;
//     int pending = total - completed;
//
//     if (mounted) {
//       setState(() {
//         _completedTasks = completed;
//         _pendingTasks = pending;
//       });
//     }
//   }
//
//   // This function calculates attendance for the current user for the given meeting docs.
//   // It uses an in-memory cache (_attendanceCache) keyed by meetingId, so repeated recalculations are faster.
//   Future<void> _calculateAttendanceRate(
//       List<QueryDocumentSnapshot> meetings, String userId) async {
//     // total potential attendance points = meetings.length * 2
//     final int totalMeetings = meetings.length;
//     final int totalAttendancePossible = totalMeetings * 2;
//
//     int accumulatedAttendance = 0;
//
//     // We'll fetch attendance doc for each meeting reference; use Future.wait to do them concurrently.
//     // Use cache for meeting-level attendance to avoid re-fetching unchanged meetings.
//     final futures = <Future<void>>[];
//
//     for (var meetingDoc in meetings) {
//       final meetingId = meetingDoc.id;
//
//       // If we have cached attendance for this meeting, reuse it.
//       if (_attendanceCache.containsKey(meetingId)) {
//         accumulatedAttendance += _attendanceCache[meetingId]!;
//       } else {
//         // fetch the attendance doc for this user within the meeting subcollection
//         final f = meetingDoc.reference
//             .collection('attendance')
//             .doc(userId)
//             .get()
//             .then((attendanceDoc) {
//           int points = 0;
//           if (attendanceDoc.exists) {
//             final data = attendanceDoc.data() as Map<String, dynamic>;
//             // user specified fields: startAttended : true/false, endAttended : true/false
//             if (data['startAttended'] == true) points += 1;
//             if (data['endAttended'] == true) points += 1;
//           }
//           // store in cache
//           _attendanceCache[meetingId] = points;
//           accumulatedAttendance += points;
//         }).catchError((_) {
//           // on error treat as zero attendance for that meeting
//           _attendanceCache[meetingId] = 0;
//         });
//
//         futures.add(f);
//       }
//     }
//
//     // Wait for all fetches to finish
//     if (futures.isNotEmpty) {
//       await Future.wait(futures);
//     }
//
//     // After all cached + fetched values accounted for, compute final accumulatedAttendance.
//     // Note: If some values were cached, they already incremented accumulatedAttendance above.
//     // But because the above loop only added cached ones and added futures to modify accumulatedAttendance,
//     // we need to sum the cache to ensure correct value.
//     // Simpler: recompute sum from cache for meetings list to avoid concurrency/order issues.
//     int sumFromCache = 0;
//     for (var meetingDoc in meetings) {
//       final meetingId = meetingDoc.id;
//       sumFromCache += (_attendanceCache[meetingId] ?? 0);
//     }
//     accumulatedAttendance = sumFromCache;
//
//     double rate = 0.0;
//     if (totalAttendancePossible > 0) {
//       rate = (accumulatedAttendance / totalAttendancePossible) * 100.0;
//     }
//
//     if (mounted) {
//       setState(() {
//         _attendanceRate = rate;
//       });
//     }
//   }
//
//   void _refreshData() {
//     setState(() => _isLoading = true);
//
//     // Update weekday in case date changed
//     final newWeekday = DateFormat('EEEE').format(DateTime.now());
//     if (newWeekday != _currentWeekday) {
//       setState(() => _currentWeekday = newWeekday);
//     }
//
//     // Clear caches that are time-sensitive
//     _attendanceCache.clear();
//     _routinesCache = [];
//     _tasksCache = [];
//
//     Future.delayed(const Duration(milliseconds: 1000), () {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     });
//   }
//
//   bool _listEqualsById(
//       List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
//     if (identical(a, b)) return true;
//     if (a.length != b.length) return false;
//     for (int i = 0; i < a.length; i++) {
//       if (a[i]['id'] != b[i]['id']) return false;
//     }
//     return true;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();
//     final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(now);
//     final formattedTime = DateFormat('hh:mm a').format(now);
//
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SafeArea(
//         child: RefreshIndicator(
//           onRefresh: () async => _refreshData(),
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child:
//                 Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               _buildHeader(formattedDate, formattedTime),
//               const SizedBox(height: 20),
//               _buildTodaySummary(),
//               const SizedBox(height: 20),
//               _buildQuickActions(),
//             ]),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader(String date, String time) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const Text(
//               "Member Dashboard",
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.green,
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildDateTimeSection(date, time),
//             if (_memberData != null) ...[
//               const SizedBox(height: 12),
//               Text(
//                 "Welcome, ${_memberData!['name'] ?? 'Member'}!",
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.green,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDateTimeSection(String date, String time) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.green.withOpacity(0.3)),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           Column(
//             children: [
//               const Icon(Icons.calendar_today, color: Colors.green, size: 24),
//               const SizedBox(height: 8),
//               Text(
//                 date.split(',')[0],
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//               Text(
//                 date.split(',')[1].trim(),
//                 style: const TextStyle(
//                   color: Colors.black54,
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             width: 1,
//             height: 50,
//             color: Colors.green.withOpacity(0.3),
//           ),
//           Column(
//             children: [
//               const Icon(Icons.access_time, color: Colors.green, size: 24),
//               const SizedBox(height: 8),
//               Text(
//                 time,
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//               const Text(
//                 'Current Time',
//                 style: TextStyle(
//                   color: Colors.black54,
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuickActions() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//
//         child: Column(
//           children: [
//
//             /// Title text
//             const Text(
//               "Quick Actions",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             /// -------- FIRST ROW --------
//             Row(
//               children: [
//
//                 /// --- Mark Prayer (SVG ICON) ---
//                 Expanded(
//                   child: _buildActionButton(
//                     "Mark Prayer",
//
//                     /// SVG icon widget
//                     SvgPicture.asset(
//                       "assets/icons/mosque-svgrepo-com.svg",
//                       height: 28,
//                       width: 28,
//                       color: Colors.green,   // apply color
//                     ),
//
//                     /// Navigation
//                         () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const PrayerAttendanceTab()),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(width: 12),
//
//                 /// --- View Tasks (Normal Flutter Icon) ---
//                 Expanded(
//                   child: _buildActionButton(
//                     "View Tasks",
//                     const Icon(Icons.assignment, color: Colors.green, size: 28),
//
//                         () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const MemberTasksTab()),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             /// -------- SECOND ROW --------
//             Row(
//               children: [
//
//                 /// --- My Groups (Flutter Icon) ---
//                 Expanded(
//                   child: _buildActionButton(
//                     "My Groups",
//                     const Icon(Icons.group, color: Colors.green, size: 28),
//
//                         () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const MemberGroupsTab()),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(width: 12),
//
//                 /// --- Routine (Flutter Icon) ---
//                 Expanded(
//                   child: _buildActionButton(
//                     "Routine",
//                     const Icon(Icons.schedule, color: Colors.green, size: 28),
//
//                         () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const ClassRoutineTab()),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   /// Builds a reusable action button.
//   ///
//   /// [title] = text under the icon
//   /// [iconWidget] = can be SvgPicture OR Icon()
//   /// [onTap] = function to execute on click
//   Widget _buildActionButton(String title, Widget iconWidget, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
//
//         decoration: BoxDecoration(
//           color: Colors.green.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(12),
//         ),
//
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             /// Icon area (can be SVG or Flutter icon)
//             iconWidget,
//
//             const SizedBox(height: 8),
//
//             /// Text under icon
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.green,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // TODAY'S SUMMARY SECTION
//   Widget _buildTodaySummary() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Center(
//               child: Text(
//                 "Today's Activities",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             // Today's Routine
//             const Text(
//               "📘 Class Routine",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 8),
//
//             _todayRoutines.isEmpty
//                 ? const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 12.0),
//                     child: Text(
//                       "No class today",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   )
//                 : Column(
//                     children: _todayRoutines.map((routine) {
//                       // Show instructor avatar if available (field: instructorAvatar)
//                       final instructorName =
//                           (routine['instructor'] ?? '').toString();
//                       final instructorAvatar =
//                           routine['instructorAvatar'] as String?;
//                       final room = routine['room'] ?? '';
//                       final start = routine['startTime'] ?? '';
//                       final end = routine['endTime'] ?? '';
//
//                       return ListTile(
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 4),
//                         leading: _buildInstructorAvatar(
//                             instructorAvatar, instructorName),
//                         title: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 "${routine['className']}",
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               instructorName,
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "$start - $end",
//                               style: const TextStyle(fontSize: 12),
//                             ),
//                             const SizedBox(height: 4),
//                             Row(
//                               children: [
//                                 const Icon(Icons.location_on,
//                                     size: 12, color: Colors.grey),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   room.toString(),
//                                   style: const TextStyle(
//                                       fontSize: 12, color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         trailing: const SizedBox.shrink(),
//                       );
//                     }).toList(),
//                   ),
//
//             const SizedBox(height: 16),
//             const Divider(height: 1),
//             const SizedBox(height: 16),
//
//             const Text(
//               "📝 Today's Tasks",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 8),
//
//             _todayTasks.isEmpty
//                 ? const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 12.0),
//                     child: Text(
//                       "No tasks due today",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   )
//                 : Column(
//                     children: _todayTasks.map((task) {
//                       return ListTile(
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 4),
//                         leading: Icon(
//                           task['status'] == 'completed'
//                               ? Icons.check_circle
//                               : Icons.radio_button_unchecked,
//                           color: task['status'] == 'completed'
//                               ? Colors.green
//                               : Colors.black.withOpacity(0.5),
//                           size: 24,
//                         ),
//                         title: Text(
//                           task['title'] ?? '',
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                         subtitle: Text(
//                           task['description'] ?? '',
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                         trailing: Chip(
//                           label: Text(
//                             (task['status'] ?? 'pending')
//                                 .toString()
//                                 .toUpperCase(),
//                             style: const TextStyle(fontSize: 10),
//                           ),
//                           materialTapTargetSize:
//                               MaterialTapTargetSize.shrinkWrap,
//                         ),
//                       );
//                     }).toList(),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInstructorAvatar(String? avatarUrl, String instructorName) {
//     final initials = _getInitials(instructorName);
//
//     if (avatarUrl != null &&
//         avatarUrl.isNotEmpty &&
//         Uri.tryParse(avatarUrl)?.hasAbsolutePath == true) {
//       return CircleAvatar(
//         radius: 22,
//         backgroundImage: NetworkImage(avatarUrl),
//       );
//     } else {
//       return CircleAvatar(
//         radius: 22,
//         backgroundColor: Colors.green.withOpacity(0.2),
//         child: Text(
//           initials,
//           style:
//               const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
//         ),
//       );
//     }
//   }
//
//   String _getInitials(String name) {
//     if (name.trim().isEmpty) return 'IN';
//     final parts = name.trim().split(' ');
//     if (parts.length == 1) {
//       return parts[0].substring(0, 1).toUpperCase();
//     } else {
//       return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
//           .toUpperCase();
//     }
//   }
// }





import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:kafela/screens/member/tabs/prayer_attendance_tab.dart';
import 'package:kafela/screens/member/tabs/tasks_tab.dart';

import 'class_routine_tab.dart';
import 'groups_tab.dart';

class MemberDashboardTab extends StatefulWidget {
  const MemberDashboardTab({super.key});

  @override
  State<MemberDashboardTab> createState() => _MemberDashboardTabState();
}

class _MemberDashboardTabState extends State<MemberDashboardTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _memberData;

  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _totalGroups = 0;
  double _attendanceRate = 0.0;

  bool _isLoading = true;

  List<Map<String, dynamic>> _todayRoutines = [];
  List<Map<String, dynamic>> _todayTasks = [];

  final List<StreamSubscription> _subscriptions = [];

  // Subscription reference for meetings so we can re-create it when member data changes.
  StreamSubscription<QuerySnapshot>? _meetingsSubscription;

  String _currentWeekday = '';
  String _currentTime = '';
  Timer? _timeTimer;

  // Simple in-memory caches to speed repeated work
  final Map<String, int> _attendanceCache =
  {}; // meetingId -> attendancePoints for current user
  DateTime? _memberCreatedAtCache;
  String? _cachedUserIdForAttendance;

  // Optionally cache routines & tasks results to avoid frequent UI rebuilds from identical data
  List<Map<String, dynamic>> _routinesCache = [];
  List<Map<String, dynamic>> _tasksCache = [];

  @override
  void initState() {
    super.initState();

    // Enable local persistence (Firestore caching) - do this early.
    // Note: settings should be set before heavy reads; it's okay here for typical use.
    _firestore.settings = const Settings(persistenceEnabled: true);

    _currentWeekday = DateFormat('EEEE').format(DateTime.now());
    _updateCurrentTime();
    _startTimeTimer();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    // Cancel all subscriptions when widget is disposed
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _meetingsSubscription?.cancel();
    _timeTimer?.cancel();
    super.dispose();
  }

  void _startTimeTimer() {
    // Update time immediately
    _updateCurrentTime();

    // Update time every second
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    final newTime = DateFormat('hh:mm:ss a').format(now);

    if (mounted) {
      setState(() {
        _currentTime = newTime;
      });
    }
  }

  void _setupRealtimeListeners() {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(hours: 24));

    // Listen to member data
    final userSub = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        // Update member data and cached createdAt
        setState(() {
          _memberData = data;
        });

        // Cache createdAt if available
        if (data['createdAt'] is Timestamp) {
          final createdTs = (data['createdAt'] as Timestamp).toDate();
          _memberCreatedAtCache = createdTs;
        } else {
          _memberCreatedAtCache = null;
        }

        // (Re)subscribe to meetings filtered by createdAt (we cancelled and recreate below)
        _subscribeMeetingsForUser(user.uid);
      }
    });
    _subscriptions.add(userSub);

    // Listen to all tasks for stats (assigned to user)
    final tasksSub = _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      _calculateTaskStats(snapshot.docs);

      // also cache today's tasks separately (we also have a dedicated query)
      final todayTaskDocs = snapshot.docs.where((doc) {
        final due = doc.data()['dueDate'];
        if (due is Timestamp) {
          final dt = due.toDate();
          return dt.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              dt.isBefore(endOfDay.add(const Duration(seconds: 1)));
        }
        return false;
      }).toList();

      final newTodayTasks = todayTaskDocs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // small-cache check to avoid unnecessary setState
      if (!_listEqualsById(_tasksCache, newTodayTasks)) {
        _tasksCache = newTodayTasks;
        setState(() {
          _todayTasks = newTodayTasks;
        });
      }
    });
    _subscriptions.add(tasksSub);

    // Listen to groups count
    final groupsSub = _firestore
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _totalGroups = snapshot.docs.length;
      });
    });
    _subscriptions.add(groupsSub);

    // Listen to today's routines (by weekday)
    final routinesSub = _firestore
        .collection('routines')
        .where('day', isEqualTo: _currentWeekday)
        .snapshots()
        .listen((snapshot) {
      final newRoutines = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // small-cache check to avoid unnecessary setState
      if (!_listEqualsById(_routinesCache, newRoutines)) {
        _routinesCache = newRoutines;
        setState(() {
          _todayRoutines = newRoutines;
        });
      }
    });
    _subscriptions.add(routinesSub);

    // Today's tasks (dedicated query for accurate dueDate filter)
    final todayTasksSub = _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: user.uid)
        .where('dueDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .listen((snapshot) {
      final newTodayTasks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (!_listEqualsById(_tasksCache, newTodayTasks)) {
        _tasksCache = newTodayTasks;
        setState(() {
          _todayTasks = newTodayTasks;
        });
      }
    });
    _subscriptions.add(todayTasksSub);

    // Set loading to false after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  // Cancels any previous meeting subscription and creates a new one filtered by member createdAt
  void _subscribeMeetingsForUser(String userId) {
    // If same user and same createdAt used previously, no need to recreate
    if (_cachedUserIdForAttendance == userId && _meetingsSubscription != null) {
      return;
    }

    // Cancel existing meeting subscription if any
    _meetingsSubscription?.cancel();
    _meetingsSubscription = null;
    _attendanceCache.clear();
    _cachedUserIdForAttendance = userId;

    Query meetingsQuery = _firestore
        .collection('meetings')
        .orderBy('date', descending: true)
        .limit(20);

    // If we have member createdAt timestamp, only consider meetings on or after that date
    if (_memberCreatedAtCache != null) {
      meetingsQuery = meetingsQuery.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_memberCreatedAtCache!),
      );
    }

    _meetingsSubscription =
        meetingsQuery.snapshots().listen((meetingsSnapshot) async {
          // when meetings change, recalculate attendance
          final docs = meetingsSnapshot.docs;
          await _calculateAttendanceRate(docs, userId);
        }, onError: (e) {
          // handle potential errors quietly
          // print('Meetings subscription error: $e');
        });
  }

  void _calculateTaskStats(List<QueryDocumentSnapshot> taskDocs) {
    int total = taskDocs.length;
    int completed = taskDocs
        .where((doc) =>
    (doc.data() as Map<String, dynamic>)['status'] == 'completed')
        .length;
    int pending = total - completed;

    if (mounted) {
      setState(() {
        _completedTasks = completed;
        _pendingTasks = pending;
      });
    }
  }

  // This function calculates attendance for the current user for the given meeting docs.
  // It uses an in-memory cache (_attendanceCache) keyed by meetingId, so repeated recalculations are faster.
  Future<void> _calculateAttendanceRate(
      List<QueryDocumentSnapshot> meetings, String userId) async {
    // total potential attendance points = meetings.length * 2
    final int totalMeetings = meetings.length;
    final int totalAttendancePossible = totalMeetings * 2;

    int accumulatedAttendance = 0;

    // We'll fetch attendance doc for each meeting reference; use Future.wait to do them concurrently.
    // Use cache for meeting-level attendance to avoid re-fetching unchanged meetings.
    final futures = <Future<void>>[];

    for (var meetingDoc in meetings) {
      final meetingId = meetingDoc.id;

      // If we have cached attendance for this meeting, reuse it.
      if (_attendanceCache.containsKey(meetingId)) {
        accumulatedAttendance += _attendanceCache[meetingId]!;
      } else {
        // fetch the attendance doc for this user within the meeting subcollection
        final f = meetingDoc.reference
            .collection('attendance')
            .doc(userId)
            .get()
            .then((attendanceDoc) {
          int points = 0;
          if (attendanceDoc.exists) {
            final data = attendanceDoc.data() as Map<String, dynamic>;
            // user specified fields: startAttended : true/false, endAttended : true/false
            if (data['startAttended'] == true) points += 1;
            if (data['endAttended'] == true) points += 1;
          }
          // store in cache
          _attendanceCache[meetingId] = points;
          accumulatedAttendance += points;
        }).catchError((_) {
          // on error treat as zero attendance for that meeting
          _attendanceCache[meetingId] = 0;
        });

        futures.add(f);
      }
    }

    // Wait for all fetches to finish
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    // After all cached + fetched values accounted for, compute final accumulatedAttendance.
    // Note: If some values were cached, they already incremented accumulatedAttendance above.
    // But because the above loop only added cached ones and added futures to modify accumulatedAttendance,
    // we need to sum the cache to ensure correct value.
    // Simpler: recompute sum from cache for meetings list to avoid concurrency/order issues.
    int sumFromCache = 0;
    for (var meetingDoc in meetings) {
      final meetingId = meetingDoc.id;
      sumFromCache += (_attendanceCache[meetingId] ?? 0);
    }
    accumulatedAttendance = sumFromCache;

    double rate = 0.0;
    if (totalAttendancePossible > 0) {
      rate = (accumulatedAttendance / totalAttendancePossible) * 100.0;
    }

    if (mounted) {
      setState(() {
        _attendanceRate = rate;
      });
    }
  }

  void _refreshData() {
    setState(() => _isLoading = true);

    // Update weekday in case date changed
    final newWeekday = DateFormat('EEEE').format(DateTime.now());
    if (newWeekday != _currentWeekday) {
      setState(() => _currentWeekday = newWeekday);
    }

    // Clear caches that are time-sensitive
    _attendanceCache.clear();
    _routinesCache = [];
    _tasksCache = [];

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  bool _listEqualsById(
      List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['id'] != b[i]['id']) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(now);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(formattedDate),
              const SizedBox(height: 20),
              _buildTodaySummary(),
              const SizedBox(height: 20),
              _buildQuickActions(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String date) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Member Dashboard",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            _buildDateTimeSection(date),
            if (_memberData != null) ...[
              const SizedBox(height: 12),
              Text(
                "Welcome, ${_memberData!['name'] ?? 'Member'}!",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.calendar_today, color: Colors.green, size: 24),
              const SizedBox(height: 8),
              Text(
                date.split(',')[0],
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                date.split(',')[1].trim(),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.green.withOpacity(0.3),
          ),
          Column(
            children: [
              const Icon(Icons.access_time, color: Colors.green, size: 24),
              const SizedBox(height: 8),
              Text(
                _currentTime,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Text(
                'Current Time',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// Title text
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            /// -------- FIRST ROW --------
            Row(
              children: [

                /// --- Mark Prayer (SVG ICON) ---
                Expanded(
                  child: _buildActionButton(
                    "Mark Prayer",

                    /// SVG icon widget
                    SvgPicture.asset(
                      "assets/icons/mosque-svgrepo-com.svg",
                      height: 28,
                      width: 28,
                      color: Colors.green,   // apply color
                    ),

                    /// Navigation
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrayerAttendanceTab()),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// --- View Tasks (Normal Flutter Icon) ---
                Expanded(
                  child: _buildActionButton(
                    "View Tasks",
                    const Icon(Icons.assignment, color: Colors.green, size: 28),

                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MemberTasksTab()),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// -------- SECOND ROW --------
            Row(
              children: [

                /// --- My Groups (Flutter Icon) ---
                Expanded(
                  child: _buildActionButton(
                    "My Groups",
                    const Icon(Icons.group, color: Colors.green, size: 28),

                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MemberGroupsTab()),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// --- Routine (Flutter Icon) ---
                Expanded(
                  child: _buildActionButton(
                    "Routine",
                    const Icon(Icons.schedule, color: Colors.green, size: 28),

                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClassRoutineTab()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  /// Builds a reusable action button.
  ///
  /// [title] = text under the icon
  /// [iconWidget] = can be SvgPicture OR Icon()
  /// [onTap] = function to execute on click
  Widget _buildActionButton(String title, Widget iconWidget, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),

        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Icon area (can be SVG or Flutter icon)
            iconWidget,

            const SizedBox(height: 8),

            /// Text under icon
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TODAY'S SUMMARY SECTION
  Widget _buildTodaySummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Today's Activities",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Today's Routine
            const Text(
              "📘 Class Routine",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            _todayRoutines.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                "No class today",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            )
                : Column(
              children: _todayRoutines.map((routine) {
                // Show instructor avatar if available (field: instructorAvatar)
                final instructorName =
                (routine['instructor'] ?? '').toString();
                final instructorAvatar =
                routine['instructorAvatar'] as String?;
                final room = routine['room'] ?? '';
                final start = routine['startTime'] ?? '';
                final end = routine['endTime'] ?? '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  leading: _buildInstructorAvatar(
                      instructorAvatar, instructorName),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${routine['className']}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        instructorName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$start - $end",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            room.toString(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const SizedBox.shrink(),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            const Text(
              "📝 Today's Tasks",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            _todayTasks.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                "No tasks due today",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            )
                : Column(
              children: _todayTasks.map((task) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  leading: Icon(
                    task['status'] == 'completed'
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task['status'] == 'completed'
                        ? Colors.green
                        : Colors.black.withOpacity(0.5),
                    size: 24,
                  ),
                  title: Text(
                    task['title'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    task['description'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Chip(
                    label: Text(
                      (task['status'] ?? 'pending')
                          .toString()
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorAvatar(String? avatarUrl, String instructorName) {
    final initials = _getInitials(instructorName);

    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        Uri.tryParse(avatarUrl)?.hasAbsolutePath == true) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
      );
    } else {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.green.withOpacity(0.2),
        child: Text(
          initials,
          style:
          const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'IN';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    } else {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
  }
}
