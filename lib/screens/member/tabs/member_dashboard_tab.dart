// 1st version of member dashboard

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
// import 'package:kafela/screens/member/tabs/prayer_attendance_tab.dart';
// import 'package:kafela/screens/member/tabs/tasks_tab.dart';
//
// import 'class_routine_tab.dart';
// import 'groups_tab.dart';
// import 'all_attendance_screen.dart';
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
//   int _totalTasks = 0;
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
//   @override
//   void initState() {
//     super.initState();
//     _fetchDashboardData();
//   }
//
//   Future<void> _fetchDashboardData() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;
//
//       final today = DateTime.now();
//       final weekday = DateFormat('EEEE').format(today); // Monday, Tuesday...
//
//       final startOfDay = DateTime(today.year, today.month, today.day);
//       final endOfDay = startOfDay.add(const Duration(hours: 24));
//
//       final results = await Future.wait([
//         _firestore.collection('users').doc(user.uid).get(),
//
//         // all tasks for stats
//         _firestore
//             .collection('tasks')
//             .where('assignedTo', isEqualTo: user.uid)
//             .get(),
//
//         // groups count
//         _firestore
//             .collection('groups')
//             .where('members', arrayContains: user.uid)
//             .get(),
//
//         // meetings for attendance
//         _firestore
//             .collection('meetings')
//             .orderBy('date', descending: true)
//             .limit(10)
//             .get(),
//
//         // routines for today
//         _firestore
//             .collection('routines')
//             .where('day', isEqualTo: weekday)
//             .get(),
//
//         // today's tasks by dueDate timestamp
//         _firestore
//             .collection('tasks')
//             .where('assignedTo', isEqualTo: user.uid)
//             .where('dueDate', isGreaterThanOrEqualTo: startOfDay)
//             .where('dueDate', isLessThan: endOfDay)
//             .get(),
//       ]);
//
//       final memberDoc = results[0] as DocumentSnapshot;
//       final tasksSnap = results[1] as QuerySnapshot;
//       final groupsSnap = results[2] as QuerySnapshot;
//       final meetingsSnap = results[3] as QuerySnapshot;
//       final routinesSnap = results[4] as QuerySnapshot;
//       final todayTaskSnap = results[5] as QuerySnapshot;
//
//       int totalMeetings = meetingsSnap.docs.length;
//       int attendedMeetings = 0;
//
//       for (var meeting in meetingsSnap.docs) {
//         final attendance = await meeting.reference
//             .collection('attendance')
//             .doc(user.uid)
//             .get();
//         if (attendance.exists) attendedMeetings++;
//       }
//
//       setState(() {
//         _memberData = memberDoc.data() as Map<String, dynamic>?;
//
//         _totalTasks = tasksSnap.docs.length;
//         _completedTasks =
//             tasksSnap.docs.where((d) => d['status'] == 'completed').length;
//         _pendingTasks = _totalTasks - _completedTasks;
//
//         _totalGroups = groupsSnap.docs.length;
//         _attendanceRate =
//             totalMeetings > 0 ? (attendedMeetings / totalMeetings) * 100 : 0;
//
//         _todayRoutines = routinesSnap.docs
//             .map((e) => e.data() as Map<String, dynamic>)
//             .toList();
//         _todayTasks = todayTaskSnap.docs
//             .map((e) => e.data() as Map<String, dynamic>)
//             .toList();
//
//         _isLoading = false;
//       });
//     } catch (e) {
//       print("Error fetching data: $e");
//       setState(() => _isLoading = false);
//     }
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
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeader(formattedDate, formattedTime),
//               const SizedBox(height: 20),
//               _buildTodaySummary(),
//               const SizedBox(height: 20),
//               _buildQuickActions(),
//               const SizedBox(height: 20),
//               _isLoading
//                   ? const Center(
//                       child: CircularProgressIndicator(color: Colors.green))
//                   : _buildQuickStats(),
//             ],
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
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             _buildDateTimeSection(date, time),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDateTimeSection(String date, String time) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.green.withOpacity(0.3)),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           Column(
//             children: [
//               const Icon(Icons.calendar_today, color: Colors.green, size: 20),
//               const SizedBox(height: 4),
//               Text(
//                 date.split(',')[0],
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//               Text(
//                 date.split(',')[1].trim(),
//                 style: const TextStyle(
//                   color: Colors.black54,
//                   fontSize: 10,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             width: 1,
//             height: 40,
//             color: Colors.green.withOpacity(0.3),
//           ),
//           Column(
//             children: [
//               const Icon(Icons.access_time, color: Colors.green, size: 20),
//               const SizedBox(height: 4),
//               Text(
//                 time,
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//               const Text(
//                 'Current Time',
//                 style: TextStyle(
//                   color: Colors.black54,
//                   fontSize: 10,
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
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const Text("Quick Actions",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildActionButton(
//                     "Mark Prayer",
//                     Icons.mosque,
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => PrayerAttendanceTab()),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildActionButton(
//                     "View Tasks",
//                     Icons.assignment,
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const MemberTasksTab()),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildActionButton(
//                     "My Groups",
//                     Icons.group,
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const MemberGroupsTab()),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildActionButton(
//                     "Routine",
//                     Icons.schedule,
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const ClassRoutineTab()),
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
//   Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.green.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: Colors.green),
//             const SizedBox(height: 8),
//             Text(title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     fontWeight: FontWeight.bold, color: Colors.green)),
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
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 16),
//             // Today's Routine
//             const Text("📘 Class Routine",
//                 style: TextStyle(fontWeight: FontWeight.w600)),
//             const SizedBox(height: 6),
//
//             _todayRoutines.isEmpty
//                 ? const Text("No class today",
//                     style: TextStyle(color: Colors.grey))
//                 : Column(
//                     children: _todayRoutines.map((routine) {
//                       return ListTile(
//                         leading: const Icon(Icons.class_, color: Colors.green),
//                         title: Row(
//                           children: [
//                             Text(
//                                 "${routine['className']} - ${routine['instructor']}"
//                             ),
//                           ],
//                         ),
//                         subtitle: Text(
//                             "${routine['startTime']} - ${routine['endTime']}"),
//                         trailing: Text(routine['room']),
//                       );
//                     }).toList(),
//                   ),
//
//             const SizedBox(height: 16),
//
//             const Text("📝 Tasks",
//                 style: TextStyle(fontWeight: FontWeight.w600)),
//             const SizedBox(height: 6),
//
//             _todayTasks.isEmpty
//                 ? const Text("No tasks due today",
//                     style: TextStyle(color: Colors.grey))
//                 : Column(
//                     children: _todayTasks.map((task) {
//                       return ListTile(
//                         leading: const Icon(Icons.task_alt,
//                             color: Colors.green),
//                         title: Text(task['title']),
//                         subtitle: Text(task['description']),
//                         trailing: Text(task['status']),
//                       );
//                     }).toList(),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickStats() {
//     return Column(
//       children: [
//         const Text(
//           "Quick Stats",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 16),
//         GridView.count(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           crossAxisCount: 2,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 1.0,
//           children: [
//             _buildStatCard("Tasks", "$_completedTasks/$_totalTasks",
//                 Icons.assignment_turned_in, Colors.green),
//             _buildStatCard(
//               "Attendance",
//               "${_attendanceRate.toStringAsFixed(1)}%",
//               Icons.analytics,
//               _getPerformanceColor(_attendanceRate),
//               onTap: () {
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (_) => AllAttendanceScreen()));
//               },
//             ),
//             _buildStatCard(
//                 "Groups", "$_totalGroups", Icons.group, Colors.green),
//             _buildStatCard("Pending", "$_pendingTasks", Icons.pending_actions,
//                 Colors.green),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildStatCard(String title, String value, IconData icon, Color color,
//       {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircleAvatar(
//                 radius: 20,
//                 backgroundColor: color.withOpacity(0.2),
//                 child: Icon(icon, color: color),
//               ),
//               const SizedBox(height: 8),
//               Text(value,
//                   style: TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold, color: color)),
//               const SizedBox(height: 4),
//               Text(title, style: const TextStyle(color: Colors.black54)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Color _getPerformanceColor(double percentage) {
//     if (percentage >= 80) return Colors.green;
//     if (percentage >= 60) return Colors.orange;
//     return Colors.red;
//   }
// }



// 2nd version of member dashboard


// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
// import 'package:kafela/screens/member/tabs/prayer_attendance_tab.dart';
// import 'package:kafela/screens/member/tabs/tasks_tab.dart';
//
// import 'class_routine_tab.dart';
// import 'groups_tab.dart';
// import 'all_attendance_screen.dart';
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
//   int _totalTasks = 0;
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
//   List<StreamSubscription> _subscriptions = [];
//   String _currentWeekday = '';
//
//   @override
//   void initState() {
//     super.initState();
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
//     _subscriptions.add(
//       _firestore.collection('users').doc(user.uid).snapshots().listen((snapshot) {
//         if (snapshot.exists) {
//           setState(() {
//             _memberData = snapshot.data() as Map<String, dynamic>;
//           });
//         }
//       }),
//     );
//
//     // Listen to all tasks for stats
//     _subscriptions.add(
//       _firestore
//           .collection('tasks')
//           .where('assignedTo', isEqualTo: user.uid)
//           .snapshots()
//           .listen((snapshot) {
//         _calculateTaskStats(snapshot.docs);
//       }),
//     );
//
//     // Listen to groups count
//     _subscriptions.add(
//       _firestore
//           .collection('groups')
//           .where('members', arrayContains: user.uid)
//           .snapshots()
//           .listen((snapshot) {
//         setState(() {
//           _totalGroups = snapshot.docs.length;
//         });
//       }),
//     );
//
//     // Listen to today's routines
//     _subscriptions.add(
//       _firestore
//           .collection('routines')
//           .where('day', isEqualTo: _currentWeekday)
//           .snapshots()
//           .listen((snapshot) {
//         setState(() {
//           _todayRoutines = snapshot.docs
//               .map((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             data['id'] = doc.id;
//             return data;
//           })
//               .toList();
//         });
//       }),
//     );
//
//     // Listen to today's tasks
//     _subscriptions.add(
//       _firestore
//           .collection('tasks')
//           .where('assignedTo', isEqualTo: user.uid)
//           .where('dueDate', isGreaterThanOrEqualTo: startOfDay)
//           .where('dueDate', isLessThan: endOfDay)
//           .snapshots()
//           .listen((snapshot) {
//         setState(() {
//           _todayTasks = snapshot.docs
//               .map((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             data['id'] = doc.id;
//             return data;
//           })
//               .toList();
//         });
//       }),
//     );
//
//     // Listen to meetings for attendance rate
//     _subscriptions.add(
//       _firestore
//           .collection('meetings')
//           .orderBy('date', descending: true)
//           .limit(20)
//           .snapshots()
//           .listen((meetingsSnapshot) async {
//         await _calculateAttendanceRate(meetingsSnapshot.docs, user.uid);
//       }),
//     );
//
//     // Set loading to false after a short delay
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     });
//   }
//
//   void _calculateTaskStats(List<QueryDocumentSnapshot> taskDocs) {
//     int total = taskDocs.length;
//     int completed = taskDocs.where((doc) => doc['status'] == 'completed').length;
//     int pending = total - completed;
//
//     if (mounted) {
//       setState(() {
//         _totalTasks = total;
//         _completedTasks = completed;
//         _pendingTasks = pending;
//       });
//     }
//   }
//
//   Future<void> _calculateAttendanceRate(List<QueryDocumentSnapshot> meetings, String userId) async {
//     int totalMeetings = meetings.length;
//     int attendedMeetings = 0;
//
//     for (var meeting in meetings) {
//       final attendanceDoc = await meeting.reference
//           .collection('attendance')
//           .doc(userId)
//           .get();
//
//       if (attendanceDoc.exists) {
//         attendedMeetings++;
//       }
//     }
//
//     if (mounted) {
//       setState(() {
//         _attendanceRate = totalMeetings > 0 ? (attendedMeetings / totalMeetings) * 100 : 0.0;
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
//     Future.delayed(const Duration(milliseconds: 1000), () {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     });
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
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeader(formattedDate, formattedTime),
//                 const SizedBox(height: 16),
//                 _buildTodaySummary(),
//                 const SizedBox(height: 16),
//                 _buildQuickActions(),
//                 const SizedBox(height: 16),
//                 _isLoading
//                     ? const Center(
//                     child: CircularProgressIndicator(color: Colors.green))
//                     : _buildQuickStats(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader(String date, String time) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const Text(
//               "Member Dashboard",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             _buildDateTimeSection(date, time),
//             if (_memberData != null) ...[
//               const SizedBox(height: 8),
//               Text(
//                 "Welcome, ${_memberData!['name'] ?? 'Member'}!",
//                 style: const TextStyle(
//                   fontSize: 14,
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
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.green.withOpacity(0.3)),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           Column(
//             children: [
//               const Icon(Icons.calendar_today, color: Colors.green, size: 16),
//               const SizedBox(height: 4),
//               Text(
//                 date.split(',')[0],
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 10,
//                 ),
//               ),
//               Text(
//                 date.split(',')[1].trim(),
//                 style: const TextStyle(
//                   color: Colors.black54,
//                   fontSize: 8,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             width: 1,
//             height: 30,
//             color: Colors.green.withOpacity(0.3),
//           ),
//           Column(
//             children: [
//               const Icon(Icons.access_time, color: Colors.green, size: 16),
//               const SizedBox(height: 4),
//               Text(
//                 time,
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 10,
//                 ),
//               ),
//               const Text(
//                 'Current Time',
//                 style: TextStyle(
//                   color: Colors.black54,
//                   fontSize: 8,
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
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           children: [
//             const Text("Quick Actions",
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildActionButton(
//                     "Mark Prayer",
//                     Icons.mosque,
//                         () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => PrayerAttendanceTab()),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: _buildActionButton(
//                     "View Tasks",
//                     Icons.assignment,
//                         () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const MemberTasksTab()),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildActionButton(
//                     "My Groups",
//                     Icons.group,
//                         () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const MemberGroupsTab()),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: _buildActionButton(
//                     "Routine",
//                     Icons.schedule,
//                         () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const ClassRoutineTab()),
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
//   Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//         decoration: BoxDecoration(
//           color: Colors.green.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.green, size: 20),
//             const SizedBox(height: 4),
//             Text(title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // TODAY'S SUMMARY SECTION
//   Widget _buildTodaySummary() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Center(
//               child: Text(
//                 "Today's Activities",
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 12),
//             // Today's Routine
//             const Text("📘 Class Routine",
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//             const SizedBox(height: 4),
//
//             _todayRoutines.isEmpty
//                 ? const Padding(
//               padding: EdgeInsets.symmetric(vertical: 8.0),
//               child: Text("No class today",
//                   style: TextStyle(fontSize: 12, color: Colors.grey)),
//             )
//                 : Column(
//               children: _todayRoutines.map((routine) {
//                 return ListTile(
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 4),
//                   dense: true,
//                   leading: const Icon(Icons.class_, color: Colors.green, size: 20),
//                   title: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "${routine['className']}",
//                         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
//                       ),
//                       Text(
//                         "${routine['instructor']}",
//                         style: const TextStyle(
//                           fontSize: 10,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                   subtitle: Text(
//                       "${routine['startTime']} - ${routine['endTime']}",
//                       style: const TextStyle(fontSize: 10)),
//                   trailing: Text(routine['room'] ?? '',
//                       style: const TextStyle(fontSize: 10)),
//                 );
//               }).toList(),
//             ),
//
//             const SizedBox(height: 12),
//             const Divider(height: 1),
//             const SizedBox(height: 12),
//
//             const Text("📝 Today's Tasks",
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//             const SizedBox(height: 4),
//
//             _todayTasks.isEmpty
//                 ? const Padding(
//               padding: EdgeInsets.symmetric(vertical: 8.0),
//               child: Text("No tasks due today",
//                   style: TextStyle(fontSize: 12, color: Colors.grey)),
//             )
//                 : Column(
//               children: _todayTasks.map((task) {
//                 return ListTile(
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 4),
//                   dense: true,
//                   leading: Icon(
//                     task['status'] == 'completed'
//                         ? Icons.check_circle
//                         : Icons.radio_button_unchecked,
//                     color: task['status'] == 'completed'
//                         ? Colors.green
//                         : Colors.orange,
//                     size: 20,
//                   ),
//                   title: Text(task['title'] ?? '',
//                       style: const TextStyle(fontSize: 12)),
//                   subtitle: Text(task['description'] ?? '',
//                       style: const TextStyle(fontSize: 10)),
//                   trailing: Chip(
//                     label: Text(
//                       (task['status'] ?? 'pending').toString().toUpperCase(),
//                       style: const TextStyle(fontSize: 8),
//                     ),
//                     backgroundColor: _getStatusColor(task['status']),
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     visualDensity: VisualDensity.compact,
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickStats() {
//     return Column(
//       children: [
//         const Text(
//           "Quick Stats",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 12),
//         GridView.count(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           crossAxisCount: 2,
//           crossAxisSpacing: 8,
//           mainAxisSpacing: 8,
//           childAspectRatio: 1.2, // Reduced aspect ratio for smaller cards
//           children: [
//             _buildStatCard("Tasks", "$_completedTasks/$_totalTasks",
//                 Icons.assignment_turned_in, Colors.green),
//             _buildStatCard(
//               "Attendance",
//               "${_attendanceRate.toStringAsFixed(1)}%",
//               Icons.analytics,
//               _getPerformanceColor(_attendanceRate),
//               onTap: () {
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (_) => AllAttendanceScreen()));
//               },
//             ),
//             _buildStatCard(
//                 "Groups", "$_totalGroups", Icons.group, Colors.green),
//             _buildStatCard("Pending", "$_pendingTasks", Icons.pending_actions,
//                 Colors.orangeAccent),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildStatCard(String title, String value, IconData icon, Color color,
//       {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         child: Padding(
//           padding: const EdgeInsets.all(8), // Reduced padding
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircleAvatar(
//                 radius: 16, // Reduced radius
//                 backgroundColor: color.withOpacity(0.2),
//                 child: Icon(icon, color: color, size: 16), // Reduced icon size
//               ),
//               const SizedBox(height: 4), // Reduced spacing
//               Text(value,
//                   style: TextStyle(
//                       fontSize: 14, // Reduced font size
//                       fontWeight: FontWeight.bold,
//                       color: color)),
//               const SizedBox(height: 2), // Reduced spacing
//               Text(title,
//                   style: const TextStyle(
//                       fontSize: 10, // Reduced font size
//                       color: Colors.black54
//                   )),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Color _getPerformanceColor(double percentage) {
//     if (percentage >= 80) return Colors.green;
//     if (percentage >= 60) return Colors.orange;
//     return Colors.red;
//   }
//
//   Color _getStatusColor(String? status) {
//     switch (status) {
//       case 'completed':
//         return Colors.green.withOpacity(0.2);
//       case 'in progress':
//         return Colors.blue.withOpacity(0.2);
//       case 'pending':
//         return Colors.orange.withOpacity(0.2);
//       default:
//         return Colors.grey.withOpacity(0.2);
//     }
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:kafela/screens/member/tabs/prayer_attendance_tab.dart';
import 'package:kafela/screens/member/tabs/tasks_tab.dart';

import 'class_routine_tab.dart';
import 'groups_tab.dart';
import 'all_attendance_screen.dart';

class MemberDashboardTab extends StatefulWidget {
  const MemberDashboardTab({super.key});

  @override
  State<MemberDashboardTab> createState() => _MemberDashboardTabState();
}

class _MemberDashboardTabState extends State<MemberDashboardTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _memberData;

  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _totalGroups = 0;
  double _attendanceRate = 0.0;

  bool _isLoading = true;

  List<Map<String, dynamic>> _todayRoutines = [];
  List<Map<String, dynamic>> _todayTasks = [];

  final List<StreamSubscription> _subscriptions = [];
  String _currentWeekday = '';

  @override
  void initState() {
    super.initState();
    _currentWeekday = DateFormat('EEEE').format(DateTime.now());
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    // Cancel all subscriptions when widget is disposed
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _setupRealtimeListeners() {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(hours: 24));

    // Listen to member data
    _subscriptions.add(
      _firestore.collection('users').doc(user.uid).snapshots().listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            _memberData = snapshot.data() as Map<String, dynamic>;
          });
        }
      }),
    );

    // Listen to all tasks for stats
    _subscriptions.add(
      _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        _calculateTaskStats(snapshot.docs);
      }),
    );

    // Listen to groups count
    _subscriptions.add(
      _firestore
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _totalGroups = snapshot.docs.length;
        });
      }),
    );

    // Listen to today's routines
    _subscriptions.add(
      _firestore
          .collection('routines')
          .where('day', isEqualTo: _currentWeekday)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _todayRoutines = snapshot.docs
              .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
              .toList();
        });
      }),
    );

    // Listen to today's tasks
    _subscriptions.add(
      _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: user.uid)
          .where('dueDate', isGreaterThanOrEqualTo: startOfDay)
          .where('dueDate', isLessThan: endOfDay)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _todayTasks = snapshot.docs
              .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
              .toList();
        });
      }),
    );

    // Listen to meetings for attendance rate
    _subscriptions.add(
      _firestore
          .collection('meetings')
          .orderBy('date', descending: true)
          .limit(20)
          .snapshots()
          .listen((meetingsSnapshot) async {
        await _calculateAttendanceRate(meetingsSnapshot.docs, user.uid);
      }),
    );

    // Set loading to false after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _calculateTaskStats(List<QueryDocumentSnapshot> taskDocs) {
    int total = taskDocs.length;
    int completed = taskDocs.where((doc) => doc['status'] == 'completed').length;
    int pending = total - completed;

    if (mounted) {
      setState(() {
        _totalTasks = total;
        _completedTasks = completed;
        _pendingTasks = pending;
      });
    }
  }

  Future<void> _calculateAttendanceRate(List<QueryDocumentSnapshot> meetings, String userId) async {
    int totalMeetings = meetings.length;
    int attendedMeetings = 0;

    for (var meeting in meetings) {
      final attendanceDoc = await meeting.reference
          .collection('attendance')
          .doc(userId)
          .get();

      if (attendanceDoc.exists) {
        attendedMeetings++;
      }
    }

    if (mounted) {
      setState(() {
        _attendanceRate = totalMeetings > 0 ? (attendedMeetings / totalMeetings) * 100 : 0.0;
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

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(now);
    final formattedTime = DateFormat('hh:mm a').format(now);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(formattedDate, formattedTime),
                const SizedBox(height: 20),
                _buildTodaySummary(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(
                    child: CircularProgressIndicator(color: Colors.green))
                    : _buildQuickStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String date, String time) {
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
            _buildDateTimeSection(date, time),
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

  Widget _buildDateTimeSection(String date, String time) {
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
                time,
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
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    "Mark Prayer",
                    Icons.mosque,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PrayerAttendanceTab()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    "View Tasks",
                    Icons.assignment,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MemberTasksTab()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    "My Groups",
                    Icons.group,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MemberGroupsTab()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    "Routine",
                    Icons.schedule,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ClassRoutineTab()),
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

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
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
            Icon(icon, color: Colors.green, size: 28),
            const SizedBox(height: 8),
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
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: const Icon(Icons.class_, color: Colors.green, size: 24),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${routine['className']}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "${routine['instructor']}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    "${routine['startTime']} - ${routine['endTime']}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    routine['room'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Icon(
                    task['status'] == 'completed'
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task['status'] == 'completed'
                        ? Colors.green
                        : Colors.orange,
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
                      (task['status'] ?? 'pending').toString().toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: _getStatusColor(task['status']),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      children: [
        const Text(
          "Quick Stats",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            _buildStatCard("Tasks", "$_completedTasks/$_totalTasks",
                Icons.assignment_turned_in, Colors.green),
            _buildStatCard(
              "Attendance",
              "${_attendanceRate.toStringAsFixed(1)}%",
              Icons.analytics,
              _getPerformanceColor(_attendanceRate),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AllAttendanceScreen()));
              },
            ),
            _buildStatCard(
                "Groups", "$_totalGroups", Icons.group, Colors.green),
            _buildStatCard("Pending", "$_pendingTasks", Icons.pending_actions,
                Colors.orangeAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green.withOpacity(0.2);
      case 'in progress':
        return Colors.blue.withOpacity(0.2);
      case 'pending':
        return Colors.orange.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }
}

