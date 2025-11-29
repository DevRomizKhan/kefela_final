// // member_activity_tab.dart
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:intl/intl.dart';
//
// /// MemberActivityTab
// /// Shows 3 summary cards (Prayer, Tasks, Meetings) filtered from user's createdAt.
// /// Tapping a card opens a detail page with real-time list (also filtered).
// class MemberActivityTab extends StatefulWidget {
//   const MemberActivityTab({super.key});
//
//   @override
//   State<MemberActivityTab> createState() => _MemberActivityTabState();
// }
//
// class _MemberActivityTabState extends State<MemberActivityTab>
//     with WidgetsBindingObserver {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   // User createdAt timestamp (used to filter everything)
//   Timestamp? _userCreatedAt;
//   bool _loadingCreatedAt = true;
//
//   // In-memory caches & counts
//   int _prayerCount = 0;
//   int _taskCount = 0;
//   int _meetingPoints = 0; // total attendance points (start+end across meetings)
//   int _meetingPossiblePoints = 0; // 2 * meetingsCount
//   int _meetingsCount = 0;
//
//   DateTime? _prayerLatest;
//   DateTime? _taskLatest;
//   DateTime? _meetingLatest;
//
//   // Streams/subscriptions
//   StreamSubscription<QuerySnapshot>? _prayerSub;
//   StreamSubscription<QuerySnapshot>? _taskSub;
//   StreamSubscription<QuerySnapshot>? _meetingsSub;
//
//   // Attendance doc listeners per meeting (meetingId -> subscription)
//   final Map<String, StreamSubscription<DocumentSnapshot>> _attendanceListeners =
//   {};
//
//   // caches for detail pages: id -> data
//   final Map<String, Map<String, dynamic>> _prayerCache = {};
//   final Map<String, Map<String, dynamic>> _taskCache = {};
//   final Map<String, Map<String, dynamic>> _meetingAttendanceCache =
//   {}; // key: meetingId -> attendance data for current user
//
//   // auto-clear cache timer
//   Timer? _cacheClearTimer;
//   final int _cacheClearIntervalMinutes = 10;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//
//     // Enable Firestore persistence (should be set in app init ideally)
//     try {
//       _firestore.settings = const Settings(persistenceEnabled: true);
//     } catch (_) {}
//
//     _startAutoClearTimer();
//     _loadUserCreatedAtAndSubscribe();
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _prayerSub?.cancel();
//     _taskSub?.cancel();
//     _meetingsSub?.cancel();
//     for (var s in _attendanceListeners.values) {
//       s.cancel();
//     }
//     _cacheClearTimer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       _clearCaches();
//     }
//   }
//
//   void _startAutoClearTimer() {
//     _cacheClearTimer?.cancel();
//     _cacheClearTimer =
//         Timer.periodic(Duration(minutes: _cacheClearIntervalMinutes), (_) {
//           if (!mounted) return;
//           _clearCaches();
//         });
//   }
//
//   void _clearCaches() {
//     _prayerCache.clear();
//     _taskCache.clear();
//     _meetingAttendanceCache.clear();
//     // Do not cancel attendance listeners — we keep listeners but clear stored data;
//     // they will repopulate shortly.
//     setState(() {});
//   }
//
//   Future<void> _loadUserCreatedAtAndSubscribe() async {
//     final user = _auth.currentUser;
//     if (user == null) {
//       setState(() => _loadingCreatedAt = false);
//       return;
//     }
//
//     try {
//       final userDoc = await _firestore.collection('users').doc(user.uid).get();
//       if (userDoc.exists && userDoc.data()!.containsKey('createdAt')) {
//         final c = userDoc['createdAt'];
//         if (c is Timestamp)
//           _userCreatedAt = c;
//         else if (c is DateTime) _userCreatedAt = Timestamp.fromDate(c);
//       } else {
//         _userCreatedAt =
//             Timestamp.fromMillisecondsSinceEpoch(0); // fallback include all
//       }
//     } catch (e) {
//       _userCreatedAt = Timestamp.fromMillisecondsSinceEpoch(0);
//     } finally {
//       if (mounted) setState(() => _loadingCreatedAt = false);
//       _subscribePrayer();
//       _subscribeTasks();
//       _subscribeMeetings();
//     }
//   }
//
//   // -------------------------
//   // Subscriptions / Listeners
//   // -------------------------
//
//   void _subscribePrayer() {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     _prayerSub?.cancel();
//
//     Query q = _firestore
//         .collection('prayer_attendance')
//         .doc(user.uid)
//         .collection('records')
//         .orderBy('updatedAt', descending: true);
//
//     // filter by user createdAt if present
//     if (_userCreatedAt != null) {
//       q = q.where('updatedAt', isGreaterThanOrEqualTo: _userCreatedAt!);
//     }
//
//     _prayerSub = q.snapshots().listen((snap) {
//       int count = 0;
//       DateTime? latest;
//       _prayerCache.clear();
//
//       for (var doc in snap.docs) {
//         final data = doc.data() as Map<String, dynamic>;
//         // each record document: has booleans for prayers; count true entries
//         final ts = (data['updatedAt'] ?? data['createdAt']) as Timestamp?;
//         if (ts != null) {
//           final dt = ts.toDate();
//           if (latest == null || dt.isAfter(latest)) latest = dt;
//         }
//         for (var e in data.entries) {
//           final k = e.key;
//           final v = e.value;
//           if (k == 'updatedAt' || k == 'createdAt') continue;
//           if (v == true) count++;
//         }
//         _prayerCache[doc.id] = {...data, 'id': doc.id};
//       }
//
//       if (mounted) {
//         setState(() {
//           _prayerCount = count;
//           _prayerLatest = latest;
//         });
//       }
//     }, onError: (e) {
//       // ignore or log
//     });
//   }
//
//   void _subscribeTasks() {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     _taskSub?.cancel();
//
//     // tasks is a global collection; for member, we show tasks assignedTo == user.uid
//     Query q = _firestore
//         .collection('tasks')
//         .where('assignedTo', isEqualTo: user.uid)
//         .orderBy('updatedAt', descending: true);
//
//     // filter by user's createdAt if available (only tasks created after user joined)
//     if (_userCreatedAt != null) {
//       q = q.where('createdAt', isGreaterThanOrEqualTo: _userCreatedAt!);
//     }
//
//     _taskSub = q.snapshots().listen((snap) {
//       int count = 0;
//       DateTime? latest;
//       _taskCache.clear();
//
//       for (var doc in snap.docs) {
//         final data = doc.data() as Map<String, dynamic>;
//         count++;
//         final ts = (data['updatedAt'] ?? data['createdAt']) as Timestamp?;
//         if (ts != null) {
//           final dt = ts.toDate();
//           if (latest == null || dt.isAfter(latest)) latest = dt;
//         }
//         _taskCache[doc.id] = {...data, 'id': doc.id};
//       }
//
//       if (mounted) {
//         setState(() {
//           _taskCount = count;
//           _taskLatest = latest;
//         });
//       }
//     }, onError: (e) {});
//   }
//
//   void _subscribeMeetings() {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     // Cancel previous meeting stream and attendance listeners
//     _meetingsSub?.cancel();
//     for (var s in _attendanceListeners.values) {
//       s.cancel();
//     }
//     _attendanceListeners.clear();
//     _meetingAttendanceCache.clear();
//
//     // Listen to all meetings metadata (we will watch attendance doc per meeting for this user)
//     Query meetingsQuery =
//     _firestore.collection('meetings').orderBy('date', descending: true);
//
//     // If user has createdAt, we will ignore meetings earlier than that by checking attendance timestamp when reading attendance doc
//     _meetingsSub = meetingsQuery.snapshots().listen((meetingSnap) {
//       // For each meeting, set up a listener on attendance doc for current user (doc id == user.uid)
//       int totalPoints = 0;
//       int meetingCount = 0;
//       DateTime? latest;
//
//       for (var meetingDoc in meetingSnap.docs) {
//         final meetingId = meetingDoc.id;
//         final attendanceDocRef = _firestore
//             .collection('meetings')
//             .doc(meetingId)
//             .collection('attendance')
//             .doc(user.uid);
//
//         // if we already have a listener for this meeting, skip creating again
//         if (!_attendanceListeners.containsKey(meetingId)) {
//           final sub = attendanceDocRef.snapshots().listen((attendanceSnap) {
//             final data = attendanceSnap.exists
//                 ? (attendanceSnap.data() as Map<String, dynamic>)
//                 : null;
//
//             // check createdAt filter
//             final ts = data != null && data['timestamp'] is Timestamp
//                 ? data['timestamp'] as Timestamp
//                 : null;
//             if (_userCreatedAt != null && ts != null) {
//               if (ts.compareTo(_userCreatedAt!) < 0) {
//                 // attendance before user joined -> ignore
//                 _meetingAttendanceCache.remove(meetingId);
//               } else {
//                 _meetingAttendanceCache[meetingId] = {
//                   ...?data,
//                   'id': attendanceSnap.id,
//                   'meetingId': meetingId
//                 };
//               }
//             } else {
//               // if no userCreatedAt or no timestamp, include attendance if exists and doc id is this user
//               if (data != null) {
//                 _meetingAttendanceCache[meetingId] = {
//                   ...data,
//                   'id': attendanceSnap.id,
//                   'meetingId': meetingId
//                 };
//               } else
//                 _meetingAttendanceCache.remove(meetingId);
//             }
//
//             // recompute counts from cache
//             _recomputeMeetingCountsFromCache();
//           }, onError: (_) {
//             // ignore individual attendance errors
//           });
//
//           _attendanceListeners[meetingId] = sub;
//         }
//
//         // We will compute counts from cache (listener callbacks update cache and call recompute)
//       }
//
//       // After ensuring listeners created, recompute counts
//       _recomputeMeetingCountsFromCache();
//     }, onError: (e) {
//       // handle meeting list error
//     });
//   }
//
//   void _recomputeMeetingCountsFromCache() {
//     int points = 0;
//     int meetCount = 0;
//     int possible = 0;
//     DateTime? latest;
//
//     for (var entry in _meetingAttendanceCache.entries) {
//       final data = entry.value;
//       if (data == null) continue;
//       // attendance doc corresponds to a meeting for current user
//       final bool s = data['startAttended'] == true;
//       final bool e = data['endAttended'] == true;
//       final int p = (s ? 1 : 0) + (e ? 1 : 0);
//
//       // check timestamp vs createdAt
//       final ts = data['timestamp'] as Timestamp?;
//       if (_userCreatedAt != null &&
//           ts != null &&
//           ts.compareTo(_userCreatedAt!) < 0) {
//         // skip this attendance
//         continue;
//       }
//
//       points += p;
//       meetCount++;
//       possible += 2;
//       if (ts != null) {
//         final dt = ts.toDate();
//         if (latest == null || dt.isAfter(latest)) latest = dt;
//       }
//     }
//
//     if (mounted) {
//       setState(() {
//         _meetingPoints = points;
//         _meetingsCount = meetCount;
//         _meetingPossiblePoints = possible;
//         _meetingLatest = latest;
//       });
//     }
//   }
//
//   // -------------------------
//   // Navigation to detail pages
//   // -------------------------
//
//   void _openPrayerDetails() {
//     final user = _auth.currentUser;
//     if (user == null) return;
//     Navigator.push(
//         context,
//         MaterialPageRoute(
//             builder: (_) => PrayerDetailsPage(
//               userId: user.uid,
//               createdAt:
//               _userCreatedAt ?? Timestamp.fromMillisecondsSinceEpoch(0),
//               cache: _prayerCache,
//             )));
//   }
//
//   void _openTaskDetails() {
//     final user = _auth.currentUser;
//     if (user == null) return;
//     Navigator.push(
//         context,
//         MaterialPageRoute(
//             builder: (_) => TaskDetailsPage(
//               userId: user.uid,
//               createdAt:
//               _userCreatedAt ?? Timestamp.fromMillisecondsSinceEpoch(0),
//               cache: _taskCache,
//             )));
//   }
//
//   void _openMeetingDetails() {
//     final user = _auth.currentUser;
//     if (user == null) return;
//     Navigator.push(
//         context,
//         MaterialPageRoute(
//             builder: (_) => MeetingDetailsPage(
//               userId: user.uid,
//               createdAt:
//               _userCreatedAt ?? Timestamp.fromMillisecondsSinceEpoch(0),
//               cache: _meetingAttendanceCache,
//             )));
//   }
//
//   // -------------------------
//   // UI
//   // -------------------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         centerTitle: true,
//         title: const Text(
//           'My Activity',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: SafeArea(
//         child: _loadingCreatedAt
//             ? const Center(
//             child: CircularProgressIndicator(color: Colors.green))
//             : Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               // Three Summary Cards
//               Expanded(
//                 child: ListView(
//                   children: [
//                     _buildSummaryCard(
//                       title: 'Prayer Reports',
//                       count: _prayerCount.toString(),
//                       subtitle: 'Latest: ${_latestLabel(_prayerLatest)}',
//                       icon: 'assets/icons/mosque-svgrepo-com.svg',
//                       color: Colors.green,
//                       onTap: _openPrayerDetails,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildSummaryCard(
//                       title: 'Task Reports',
//                       count: _taskCount.toString(),
//                       subtitle: 'Latest: ${_latestLabel(_taskLatest)}',
//                       icon: Icons.assignment,
//                       color: Colors.green,
//                       onTap: _openTaskDetails,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildSummaryCard(
//                       title: 'Meeting Reports',
//                       count: _meetingsCount.toString(),
//                       subtitle: _meetingPossiblePoints > 0
//                           ? 'Rate: ${((_meetingPoints / _meetingPossiblePoints) * 100).toStringAsFixed(0)}%'
//                           : 'Rate: —',
//                       icon: Icons.meeting_room,
//                       color: Colors.green,
//                       onTap: _openMeetingDetails,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryCard({
//     required String title,
//     required String count,
//     required String subtitle,
//     required dynamic icon, // Can be IconData or String (for SVG path)
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 24,
//                 backgroundColor: color.withOpacity(0.12),
//                 child: icon is String
//                     ? SvgPicture.asset(
//                   icon,
//                   height: 24,
//                   width: 24,
//                   color: color,
//                 )
//                     : Icon(
//                   icon as IconData,
//                   color: color,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title,
//                         style: const TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 4),
//                     Text(subtitle,
//                         style: const TextStyle(
//                             color: Colors.black54, fontSize: 14)),
//                   ],
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(count,
//                       style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: color)),
//                   const SizedBox(height: 4),
//                   const Text('View Details',
//                       style: TextStyle(color: Colors.black, fontSize: 12)),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _latestLabel(DateTime? dt) {
//     if (dt == null) return '—';
//     final now = DateTime.now();
//     final diff = now.difference(dt);
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
//     if (diff.inHours < 24) return '${diff.inHours}h ago';
//     return DateFormat('MMM dd').format(dt);
//   }
// }
//
// // ---------------------------
// // Details pages (Prayer / Tasks / Meetings)
// // ---------------------------
//
// /// PrayerDetailsPage - shows prayer attendance documents from createdAt onwards.
// /// Expects records under: prayer_attendance/{uid}/records
// class PrayerDetailsPage extends StatelessWidget {
//   final String userId;
//   final Timestamp createdAt;
//   final Map<String, Map<String, dynamic>> cache;
//
//   const PrayerDetailsPage(
//       {required this.userId,
//         required this.createdAt,
//         required this.cache,
//         super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final FirebaseFirestore firestore = FirebaseFirestore.instance;
//
//     Query q = firestore
//         .collection('prayer_attendance')
//         .doc(userId)
//         .collection('records')
//         .orderBy('updatedAt', descending: true);
//     if (createdAt != null) {
//       q = q.where('updatedAt', isGreaterThanOrEqualTo: createdAt);
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Prayer Reports'),
//         backgroundColor: Colors.white,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: q.snapshots(),
//         builder: (context, snap) {
//           if (snap.hasError) {
//             return const Center(child: Text('Error loading prayer records'));
//           }
//
//           if (!snap.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           final docs = snap.data!.docs;
//
//           if (docs.isEmpty) {
//             return const Center(child: Text('No prayer records found'));
//           }
//
//           return ListView.builder(
//             padding: const EdgeInsets.all(12),
//             itemCount: docs.length,
//             itemBuilder: (context, idx) {
//               final doc = docs[idx];
//               final data = doc.data() as Map<String, dynamic>;
//               final ts = (data['updatedAt'] ?? data['createdAt']) as Timestamp?;
//               final dt = ts?.toDate();
//               final prayerKeys = data.entries
//                   .where((e) =>
//               e.key != 'updatedAt' &&
//                   e.key != 'createdAt' &&
//                   e.value == true)
//                   .map((e) => e.key)
//                   .toList();
//
//               return Card(
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.green.withOpacity(0.12),
//                     child: SvgPicture.asset(
//                       "assets/icons/mosque-svgrepo-com.svg",
//                       height: 20,
//                       width: 20,
//                       color: Colors.green,
//                     ),
//                   ),
//                   title: Text('Prayers: ${prayerKeys.join(', ')}'),
//                   subtitle: Text(
//                     dt != null
//                         ? DateFormat('MMM dd, yyyy — hh:mm a').format(dt)
//                         : '—',
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
//
// /// TaskDetailsPage - shows tasks assigned to user from createdAt onwards
// class TaskDetailsPage extends StatelessWidget {
//   final String userId;
//   final Timestamp createdAt;
//   final Map<String, Map<String, dynamic>> cache;
//
//   const TaskDetailsPage(
//       {required this.userId,
//         required this.createdAt,
//         required this.cache,
//         super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final FirebaseFirestore firestore = FirebaseFirestore.instance;
//
//     Query q = firestore
//         .collection('tasks')
//         .where('assignedTo', isEqualTo: userId)
//         .orderBy('updatedAt', descending: true);
//
//     if (createdAt.millisecondsSinceEpoch > 0) {
//       q = q.where('createdAt', isGreaterThanOrEqualTo: createdAt);
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//           title: const Text('Task Reports'), backgroundColor: Colors.white),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: q.snapshots(),
//         builder: (context, snap) {
//           if (snap.hasError) {
//             print('Task loading error: ${snap.error}');
//             return const Center(child: Text('Error loading tasks'));
//           }
//           if (!snap.hasData)
//             return const Center(child: CircularProgressIndicator());
//           final docs = snap.data!.docs;
//           if (docs.isEmpty) return const Center(child: Text('No tasks found'));
//
//           return ListView.builder(
//             padding: const EdgeInsets.all(12),
//             itemCount: docs.length,
//             itemBuilder: (context, idx) {
//               final doc = docs[idx];
//               final data = doc.data() as Map<String, dynamic>;
//               final ts = (data['updatedAt'] ?? data['createdAt']) as Timestamp?;
//               final dt = ts?.toDate();
//               return Card(
//                 child: ListTile(
//                   leading: CircleAvatar(
//                       backgroundColor: Colors.orange.withOpacity(0.12),
//                       child:
//                       const Icon(Icons.assignment, color: Colors.green)),
//                   title: Text(data['title'] ?? 'No title'),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(data['description'] ?? ''),
//                       const SizedBox(height: 6),
//                       Text(
//                           'Status: ${data['status'] ?? '—'} • Due: ${data['dueDate'] != null ? DateFormat('MMM dd, yyyy').format((data['dueDate'] as Timestamp).toDate()) : '—'}'),
//                       if (dt != null)
//                         Text(DateFormat('MMM dd, yyyy — hh:mm a').format(dt),
//                             style: const TextStyle(
//                                 fontSize: 12, color: Colors.black54)),
//                       if (data['feedback'] != null) ...[
//                         const SizedBox(height: 6),
//                         Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.green.withOpacity(0.08),
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Feedback: ${data['feedback']}',
//                                   style:
//                                   const TextStyle(color: Colors.black87)),
//                               if (data['feedbackAt'] != null)
//                                 Text(
//                                     'On: ${DateFormat('MMM dd, yyyy — hh:mm a').format((data['feedbackAt'] as Timestamp).toDate())}',
//                                     style: const TextStyle(
//                                         fontSize: 11, color: Colors.black54)),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
//
// /// MeetingDetailsPage - shows meetings attendance documents for current user across meetings
// class MeetingDetailsPage extends StatelessWidget {
//   final String userId;
//   final Timestamp createdAt;
//   final Map<String, Map<String, dynamic>> cache;
//
//   const MeetingDetailsPage(
//       {required this.userId,
//         required this.createdAt,
//         required this.cache,
//         super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final FirebaseFirestore firestore = FirebaseFirestore.instance;
//
//     final Query meetingsQuery = firestore
//         .collection('meetings')
//         .where('date', isGreaterThanOrEqualTo: createdAt)
//         .orderBy('date', descending: true);
//
//     return Scaffold(
//       appBar: AppBar(
//           title: const Text('Meeting Reports'), backgroundColor: Colors.white),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: meetingsQuery.snapshots(),
//         builder: (context, snap) {
//           if (snap.hasError) {
//             print('Meeting loading error: ${snap.error}');
//             return const Center(child: Text('Error loading meetings'));
//           }
//           if (!snap.hasData)
//             return const Center(child: CircularProgressIndicator());
//           final meetingDocs = snap.data!.docs;
//
//           if (meetingDocs.isEmpty) {
//             return const Center(
//                 child: Text('No meetings found from your join date'));
//           }
//
//           return ListView.builder(
//             padding: const EdgeInsets.all(12),
//             itemCount: meetingDocs.length,
//             itemBuilder: (context, idx) {
//               final meetingDoc = meetingDocs[idx];
//               final meetingId = meetingDoc.id;
//               final meetingData = meetingDoc.data() as Map<String, dynamic>;
//
//               final attendanceRef = firestore
//                   .collection('meetings')
//                   .doc(meetingId)
//                   .collection('attendance')
//                   .doc(userId);
//
//               return FutureBuilder<DocumentSnapshot>(
//                 future: attendanceRef.get(),
//                 builder: (context, attSnap) {
//                   if (attSnap.connectionState == ConnectionState.waiting) {
//                     return Card(
//                       child: ListTile(
//                         leading: CircleAvatar(
//                             backgroundColor: Colors.black.withOpacity(0.12),
//                             child: const Icon(Icons.meeting_room,
//                                 color: Colors.green)),
//                         title: Text(meetingData['title'] ?? 'Meeting'),
//                         subtitle: const Text('Loading attendance...'),
//                       ),
//                     );
//                   }
//
//                   if (attSnap.hasError) {
//                     return Card(
//                       child: ListTile(
//                         leading: CircleAvatar(
//                             backgroundColor: Colors.black.withOpacity(0.12),
//                             child: const Icon(Icons.meeting_room,
//                                 color: Colors.green)),
//                         title: Text(meetingData['title'] ?? 'Meeting'),
//                         subtitle: const Text('Error loading attendance'),
//                       ),
//                     );
//                   }
//
//                   if (!attSnap.data!.exists) {
//                     return Card(
//                       child: ListTile(
//                         leading: CircleAvatar(
//                             backgroundColor: Colors.black.withOpacity(0.12),
//                             child: const Icon(Icons.meeting_room,
//                                 color: Colors.green)),
//                         title: Text(meetingData['title'] ?? 'Meeting'),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             if (meetingData['date'] != null &&
//                                 meetingData['date'] is Timestamp)
//                               Text(
//                                   'Date: ${DateFormat('MMM dd, yyyy — hh:mm a').format((meetingData['date'] as Timestamp).toDate())}'),
//                             const SizedBox(height: 6),
//                             const Text('Attendance: Absent',
//                                 style: TextStyle(color: Colors.red)),
//                           ],
//                         ),
//                       ),
//                     );
//                   }
//
//                   final attData = attSnap.data!.data() as Map<String, dynamic>?;
//                   final s = attData?['startAttended'] == true;
//                   final e = attData?['endAttended'] == true;
//                   String status = 'Absent';
//                   Color statusColor = Colors.red;
//
//                   if (s && e) {
//                     status = 'Full Attendance';
//                     statusColor = Colors.green;
//                   } else if (s || e) {
//                     status = 'Partial Attendance';
//                     statusColor = Colors.orange;
//                   }
//
//                   return Card(
//                     child: ListTile(
//                       leading: CircleAvatar(
//                           backgroundColor: Colors.black.withOpacity(0.12),
//                           child: const Icon(Icons.meeting_room,
//                               color: Colors.green)),
//                       title: Text(meetingData['title'] ?? 'Meeting'),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           if (meetingData['date'] != null &&
//                               meetingData['date'] is Timestamp)
//                             Text(
//                                 'Date: ${DateFormat('MMM dd, yyyy — hh:mm a').format((meetingData['date'] as Timestamp).toDate())}'),
//                           const SizedBox(height: 6),
//                           Text(
//                               'Start: ${s ? "✅" : "❌"} • End: ${e ? "✅" : "❌"}'),
//                           const SizedBox(height: 4),
//                           Text('Status: $status',
//                               style: TextStyle(
//                                   color: statusColor,
//                                   fontWeight: FontWeight.bold)),
//                           if (attData?['timestamp'] != null)
//                             Text(
//                                 'Recorded: ${DateFormat('MMM dd, yyyy — hh:mm a').format((attData!['timestamp'] as Timestamp).toDate())}',
//                                 style: const TextStyle(
//                                     fontSize: 12, color: Colors.black54)),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// Updated member_activity_tab.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

/// MemberActivityTab
/// Shows 4 summary cards (Prayer, Tasks, Meetings, Donations) filtered from user's createdAt.
class MemberActivityTab extends StatefulWidget {
  const MemberActivityTab({super.key});

  @override
  State<MemberActivityTab> createState() => _MemberActivityTabState();
}

class _MemberActivityTabState extends State<MemberActivityTab>
    with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User createdAt timestamp (used to filter everything)
  Timestamp? _userCreatedAt;
  bool _loadingCreatedAt = true;

  // In-memory caches & counts
  int _prayerCount = 0;
  int _taskCount = 0;
  int _meetingPoints = 0;
  int _meetingPossiblePoints = 0;
  int _meetingsCount = 0;
  int _donationCount = 0;
  double _totalDonationAmount = 0;

  DateTime? _prayerLatest;
  DateTime? _taskLatest;
  DateTime? _meetingLatest;
  DateTime? _donationLatest;

  // Streams/subscriptions
  StreamSubscription<QuerySnapshot>? _prayerSub;
  StreamSubscription<QuerySnapshot>? _taskSub;
  StreamSubscription<QuerySnapshot>? _meetingsSub;
  StreamSubscription<QuerySnapshot>? _donationSub;

  // Attendance doc listeners per meeting
  final Map<String, StreamSubscription<DocumentSnapshot>> _attendanceListeners =
      {};

  // caches for detail pages
  final Map<String, Map<String, dynamic>> _prayerCache = {};
  final Map<String, Map<String, dynamic>> _taskCache = {};
  final Map<String, Map<String, dynamic>> _meetingAttendanceCache = {};
  final Map<String, Map<String, dynamic>> _donationCache = {};

  // auto-clear cache timer
  Timer? _cacheClearTimer;
  final int _cacheClearIntervalMinutes = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    try {
      _firestore.settings = const Settings(persistenceEnabled: true);
    } catch (_) {}

    _startAutoClearTimer();
    _loadUserCreatedAtAndSubscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prayerSub?.cancel();
    _taskSub?.cancel();
    _meetingsSub?.cancel();
    _donationSub?.cancel();
    for (var s in _attendanceListeners.values) {
      s.cancel();
    }
    _cacheClearTimer?.cancel();
    super.dispose();
  }

  void _startAutoClearTimer() {
    _cacheClearTimer?.cancel();
    _cacheClearTimer =
        Timer.periodic(Duration(minutes: _cacheClearIntervalMinutes), (_) {
      if (!mounted) return;
      _clearCaches();
    });
  }

  void _clearCaches() {
    _prayerCache.clear();
    _taskCache.clear();
    _meetingAttendanceCache.clear();
    _donationCache.clear();
    setState(() {});
  }

  Future<void> _loadUserCreatedAtAndSubscribe() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loadingCreatedAt = false);
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()!.containsKey('createdAt')) {
        final c = userDoc['createdAt'];
        if (c is Timestamp)
          _userCreatedAt = c;
        else if (c is DateTime) _userCreatedAt = Timestamp.fromDate(c);
      } else {
        _userCreatedAt = Timestamp.fromMillisecondsSinceEpoch(0);
      }
    } catch (e) {
      _userCreatedAt = Timestamp.fromMillisecondsSinceEpoch(0);
    } finally {
      if (mounted) setState(() => _loadingCreatedAt = false);
      _subscribePrayer();
      _subscribeTasks();
      _subscribeMeetings();
      _subscribeDonations();
    }
  }

  // NEW: Donation Subscription
  void _subscribeDonations() {
    final user = _auth.currentUser;
    if (user == null) return;

    _donationSub?.cancel();

    Query q = _firestore
        .collection('donations')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    if (_userCreatedAt != null) {
      q = q.where('createdAt', isGreaterThanOrEqualTo: _userCreatedAt!);
    }

    _donationSub = q.snapshots().listen((snap) {
      int count = 0;
      double totalAmount = 0;
      DateTime? latest;
      _donationCache.clear();

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        count++;
        totalAmount += (data['amount'] ?? 0).toDouble();

        final ts = data['createdAt'] as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          if (latest == null || dt.isAfter(latest)) latest = dt;
        }
        _donationCache[doc.id] = {...data, 'id': doc.id};
      }

      if (mounted) {
        setState(() {
          _donationCount = count;
          _totalDonationAmount = totalAmount;
          _donationLatest = latest;
        });
      }
    }, onError: (e) {
      print('Donation subscription error: $e');
    });
  }

  void _subscribePrayer() {
    final user = _auth.currentUser;
    if (user == null) return;

    _prayerSub?.cancel();

    Query q = _firestore
        .collection('prayer_attendance')
        .doc(user.uid)
        .collection('records')
        .orderBy('updatedAt', descending: true);

    if (_userCreatedAt != null) {
      q = q.where('updatedAt', isGreaterThanOrEqualTo: _userCreatedAt!);
    }

    _prayerSub = q.snapshots().listen((snap) {
      int count = 0;
      DateTime? latest;
      _prayerCache.clear();

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = (data['updatedAt'] ?? data['createdAt']) as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          if (latest == null || dt.isAfter(latest)) latest = dt;
        }
        for (var e in data.entries) {
          final k = e.key;
          final v = e.value;
          if (k == 'updatedAt' || k == 'createdAt') continue;
          if (v == true) count++;
        }
        _prayerCache[doc.id] = {...data, 'id': doc.id};
      }

      if (mounted) {
        setState(() {
          _prayerCount = count;
          _prayerLatest = latest;
        });
      }
    }, onError: (e) {});
  }

  void _subscribeTasks() {
    final user = _auth.currentUser;
    if (user == null) return;

    _taskSub?.cancel();

    Query q = _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true);

    if (_userCreatedAt != null) {
      q = q.where('createdAt', isGreaterThanOrEqualTo: _userCreatedAt!);
    }

    _taskSub = q.snapshots().listen((snap) {
      int count = 0;
      DateTime? latest;
      _taskCache.clear();

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        count++;
        final ts = (data['updatedAt'] ?? data['createdAt']) as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          if (latest == null || dt.isAfter(latest)) latest = dt;
        }
        _taskCache[doc.id] = {...data, 'id': doc.id};
      }

      if (mounted) {
        setState(() {
          _taskCount = count;
          _taskLatest = latest;
        });
      }
    }, onError: (e) {});
  }

  void _subscribeMeetings() {
    final user = _auth.currentUser;
    if (user == null) return;

    _meetingsSub?.cancel();
    for (var s in _attendanceListeners.values) {
      s.cancel();
    }
    _attendanceListeners.clear();
    _meetingAttendanceCache.clear();

    Query meetingsQuery =
        _firestore.collection('meetings').orderBy('date', descending: true);

    _meetingsSub = meetingsQuery.snapshots().listen((meetingSnap) {
      int totalPoints = 0;
      int meetingCount = 0;
      DateTime? latest;

      for (var meetingDoc in meetingSnap.docs) {
        final meetingId = meetingDoc.id;
        final attendanceDocRef = _firestore
            .collection('meetings')
            .doc(meetingId)
            .collection('attendance')
            .doc(user.uid);

        if (!_attendanceListeners.containsKey(meetingId)) {
          final sub = attendanceDocRef.snapshots().listen((attendanceSnap) {
            final data = attendanceSnap.exists
                ? (attendanceSnap.data() as Map<String, dynamic>)
                : null;

            final ts = data != null && data['timestamp'] is Timestamp
                ? data['timestamp'] as Timestamp
                : null;
            if (_userCreatedAt != null && ts != null) {
              if (ts.compareTo(_userCreatedAt!) < 0) {
                _meetingAttendanceCache.remove(meetingId);
              } else {
                _meetingAttendanceCache[meetingId] = {
                  ...?data,
                  'id': attendanceSnap.id,
                  'meetingId': meetingId
                };
              }
            } else {
              if (data != null) {
                _meetingAttendanceCache[meetingId] = {
                  ...data,
                  'id': attendanceSnap.id,
                  'meetingId': meetingId
                };
              } else
                _meetingAttendanceCache.remove(meetingId);
            }

            _recomputeMeetingCountsFromCache();
          }, onError: (_) {});

          _attendanceListeners[meetingId] = sub;
        }
      }

      _recomputeMeetingCountsFromCache();
    }, onError: (e) {});
  }

  void _recomputeMeetingCountsFromCache() {
    int points = 0;
    int meetCount = 0;
    int possible = 0;
    DateTime? latest;

    for (var entry in _meetingAttendanceCache.entries) {
      final data = entry.value;
      if (data == null) continue;
      final bool s = data['startAttended'] == true;
      final bool e = data['endAttended'] == true;
      final int p = (s ? 1 : 0) + (e ? 1 : 0);

      final ts = data['timestamp'] as Timestamp?;
      if (_userCreatedAt != null &&
          ts != null &&
          ts.compareTo(_userCreatedAt!) < 0) {
        continue;
      }

      points += p;
      meetCount++;
      possible += 2;
      if (ts != null) {
        final dt = ts.toDate();
        if (latest == null || dt.isAfter(latest)) latest = dt;
      }
    }

    if (mounted) {
      setState(() {
        _meetingPoints = points;
        _meetingsCount = meetCount;
        _meetingPossiblePoints = possible;
        _meetingLatest = latest;
      });
    }
  }

  // NEW: Donation Details Navigation
  void _openDonationDetails() {
    final user = _auth.currentUser;
    if (user == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DonationDetailsPage(
                  userId: user.uid,
                  createdAt:
                      _userCreatedAt ?? Timestamp.fromMillisecondsSinceEpoch(0),
                  cache: _donationCache,
                )));
  }

  // Keep existing navigation methods
  void _openPrayerDetails() {
    final user = _auth.currentUser;
    if (user == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PrayerDetailsPage(
                  userId: user.uid,
                  createdAt:
                      _userCreatedAt ?? Timestamp.fromMillisecondsSinceEpoch(0),
                  cache: _prayerCache,
                )));
  }

  void _openTaskDetails() {
    final user = _auth.currentUser;
    if (user == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TaskDetailsPage(
                  userId: user.uid,
                  createdAt:
                      _userCreatedAt ?? Timestamp.fromMillisecondsSinceEpoch(0),
                  cache: _taskCache,
                )));
  }

  void _openMeetingDetails() {
    final user = _auth.currentUser;
    if (user == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MeetingDetailsPage(
                  userId: user.uid,
                  createdAt:
                      _userCreatedAt ?? Timestamp.fromMillisecondsSinceEpoch(0),
                  cache: _meetingAttendanceCache,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'My Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _loadingCreatedAt
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Four Summary Cards (Added Donation)
                    Expanded(
                      child: ListView(
                        children: [
                          _buildSummaryCard(
                            title: 'Prayer Reports',
                            count: _prayerCount.toString(),
                            subtitle: 'Latest: ${_latestLabel(_prayerLatest)}',
                            icon: 'assets/icons/mosque-svgrepo-com.svg',
                            color: Colors.green,
                            onTap: _openPrayerDetails,
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryCard(
                            title: 'Task Reports',
                            count: _taskCount.toString(),
                            subtitle: 'Latest: ${_latestLabel(_taskLatest)}',
                            icon: Icons.assignment,
                            color: Colors.green,
                            onTap: _openTaskDetails,
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryCard(
                            title: 'Meeting Reports',
                            count: _meetingsCount.toString(),
                            subtitle: _meetingPossiblePoints > 0
                                ? 'Rate: ${((_meetingPoints / _meetingPossiblePoints) * 100).toStringAsFixed(0)}%'
                                : 'Rate: —',
                            icon: Icons.meeting_room,
                            color: Colors.green,
                            onTap: _openMeetingDetails,
                          ),
                          const SizedBox(height: 12),
                          // NEW: Donation Card
                          _buildSummaryCard(
                            title: 'Donation Reports',
                            count:
                                '৳${_totalDonationAmount.toStringAsFixed(0)}',
                            subtitle:
                                '${_donationCount} donations • Latest: ${_latestLabel(_donationLatest)}',
                            icon: Icons.volunteer_activism,
                            color: Colors.green,
                            onTap: _openDonationDetails,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required String subtitle,
    required dynamic icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.12),
                child: icon is String
                    ? SvgPicture.asset(
                        icon,
                        height: 24,
                        width: 24,
                        color: color,
                      )
                    : Icon(
                        icon as IconData,
                        color: color,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 14)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(count,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 4),
                  const Text('View Details',
                      style: TextStyle(color: Colors.black, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _latestLabel(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM dd').format(dt);
  }
}

// ---------------------------
// Details pages (Prayer / Tasks / Meetings / Donations)
// ---------------------------

/// PrayerDetailsPage - shows prayer attendance documents from createdAt onwards.
class PrayerDetailsPage extends StatelessWidget {
  final String userId;
  final Timestamp createdAt;
  final Map<String, Map<String, dynamic>> cache;

  const PrayerDetailsPage({
    required this.userId,
    required this.createdAt,
    required this.cache,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    Query q = firestore
        .collection('prayer_attendance')
        .doc(userId)
        .collection('records')
        .orderBy('updatedAt', descending: true);
    if (createdAt.millisecondsSinceEpoch > 0) {
      q = q.where('updatedAt', isGreaterThanOrEqualTo: createdAt);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Reports'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Error loading prayer records'));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No prayer records found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              final data = doc.data() as Map<String, dynamic>;
              final ts = (data['updatedAt'] ?? data['createdAt']) as Timestamp?;
              final dt = ts?.toDate();
              final prayerKeys = data.entries
                  .where((e) =>
                      e.key != 'updatedAt' &&
                      e.key != 'createdAt' &&
                      e.value == true)
                  .map((e) => e.key)
                  .toList();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.12),
                    child: SvgPicture.asset(
                      "assets/icons/mosque-svgrepo-com.svg",
                      height: 20,
                      width: 20,
                      color: Colors.green,
                    ),
                  ),
                  title: Text('Prayers: ${prayerKeys.join(', ')}'),
                  subtitle: Text(
                    dt != null
                        ? DateFormat('MMM dd, yyyy — hh:mm a').format(dt)
                        : '—',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// TaskDetailsPage - shows tasks assigned to user from createdAt onwards
class TaskDetailsPage extends StatelessWidget {
  final String userId;
  final Timestamp createdAt;
  final Map<String, Map<String, dynamic>> cache;

  const TaskDetailsPage({
    required this.userId,
    required this.createdAt,
    required this.cache,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    Query q = firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .orderBy('updatedAt', descending: true);

    if (createdAt.millisecondsSinceEpoch > 0) {
      q = q.where('createdAt', isGreaterThanOrEqualTo: createdAt);
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text('Task Reports'), backgroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            print('Task loading error: ${snap.error}');
            return const Center(child: Text('Error loading tasks'));
          }
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No tasks found'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              final data = doc.data() as Map<String, dynamic>;
              final ts = (data['updatedAt'] ?? data['createdAt']) as Timestamp?;
              final dt = ts?.toDate();
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.12),
                      child: const Icon(Icons.assignment, color: Colors.green)),
                  title: Text(data['title'] ?? 'No title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['description'] ?? ''),
                      const SizedBox(height: 6),
                      Text(
                          'Status: ${data['status'] ?? '—'} • Due: ${data['dueDate'] != null ? DateFormat('MMM dd, yyyy').format((data['dueDate'] as Timestamp).toDate()) : '—'}'),
                      if (dt != null)
                        Text(DateFormat('MMM dd, yyyy — hh:mm a').format(dt),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      if (data['feedback'] != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Feedback: ${data['feedback']}',
                                  style:
                                      const TextStyle(color: Colors.black87)),
                              if (data['feedbackAt'] != null)
                                Text(
                                    'On: ${DateFormat('MMM dd, yyyy — hh:mm a').format((data['feedbackAt'] as Timestamp).toDate())}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// MeetingDetailsPage - shows meetings attendance documents for current user across meetings
class MeetingDetailsPage extends StatelessWidget {
  final String userId;
  final Timestamp createdAt;
  final Map<String, Map<String, dynamic>> cache;

  const MeetingDetailsPage({
    required this.userId,
    required this.createdAt,
    required this.cache,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final Query meetingsQuery = firestore
        .collection('meetings')
        .where('date', isGreaterThanOrEqualTo: createdAt)
        .orderBy('date', descending: true);

    return Scaffold(
      appBar: AppBar(
          title: const Text('Meeting Reports'), backgroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: meetingsQuery.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            print('Meeting loading error: ${snap.error}');
            return const Center(child: Text('Error loading meetings'));
          }
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final meetingDocs = snap.data!.docs;

          if (meetingDocs.isEmpty) {
            return const Center(
                child: Text('No meetings found from your join date'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: meetingDocs.length,
            itemBuilder: (context, idx) {
              final meetingDoc = meetingDocs[idx];
              final meetingId = meetingDoc.id;
              final meetingData = meetingDoc.data() as Map<String, dynamic>;

              final attendanceRef = firestore
                  .collection('meetings')
                  .doc(meetingId)
                  .collection('attendance')
                  .doc(userId);

              return FutureBuilder<DocumentSnapshot>(
                future: attendanceRef.get(),
                builder: (context, attSnap) {
                  if (attSnap.connectionState == ConnectionState.waiting) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.12),
                            child: const Icon(Icons.meeting_room,
                                color: Colors.green)),
                        title: Text(meetingData['title'] ?? 'Meeting'),
                        subtitle: const Text('Loading attendance...'),
                      ),
                    );
                  }

                  if (attSnap.hasError) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.12),
                            child: const Icon(Icons.meeting_room,
                                color: Colors.green)),
                        title: Text(meetingData['title'] ?? 'Meeting'),
                        subtitle: const Text('Error loading attendance'),
                      ),
                    );
                  }

                  if (!attSnap.data!.exists) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.12),
                            child: const Icon(Icons.meeting_room,
                                color: Colors.green)),
                        title: Text(meetingData['title'] ?? 'Meeting'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (meetingData['date'] != null &&
                                meetingData['date'] is Timestamp)
                              Text(
                                  'Date: ${DateFormat('MMM dd, yyyy — hh:mm a').format((meetingData['date'] as Timestamp).toDate())}'),
                            const SizedBox(height: 6),
                            const Text('Attendance: Absent',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    );
                  }

                  final attData = attSnap.data!.data() as Map<String, dynamic>?;
                  final s = attData?['startAttended'] == true;
                  final e = attData?['endAttended'] == true;
                  String status = 'Absent';
                  Color statusColor = Colors.red;

                  if (s && e) {
                    status = 'Full Attendance';
                    statusColor = Colors.green;
                  } else if (s || e) {
                    status = 'Partial Attendance';
                    statusColor = Colors.orange;
                  }

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.12),
                          child: const Icon(Icons.meeting_room,
                              color: Colors.green)),
                      title: Text(meetingData['title'] ?? 'Meeting'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (meetingData['date'] != null &&
                              meetingData['date'] is Timestamp)
                            Text(
                                'Date: ${DateFormat('MMM dd, yyyy — hh:mm a').format((meetingData['date'] as Timestamp).toDate())}'),
                          const SizedBox(height: 6),
                          Text(
                              'Start: ${s ? "✅" : "❌"} • End: ${e ? "✅" : "❌"}'),
                          const SizedBox(height: 4),
                          Text('Status: $status',
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold)),
                          if (attData?['timestamp'] != null)
                            Text(
                                'Recorded: ${DateFormat('MMM dd, yyyy — hh:mm a').format((attData!['timestamp'] as Timestamp).toDate())}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// NEW: DonationDetailsPage - shows donation history for current user
class DonationDetailsPage extends StatelessWidget {
  final String userId;
  final Timestamp createdAt;
  final Map<String, Map<String, dynamic>> cache;

  const DonationDetailsPage({
    required this.userId,
    required this.createdAt,
    required this.cache,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    Query q = firestore
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (createdAt.millisecondsSinceEpoch > 0) {
      q = q.where('createdAt', isGreaterThanOrEqualTo: createdAt);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Reports'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Error loading donation records'));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volunteer_activism, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No donations found',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          // Calculate total amount
          double totalAmount = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalAmount += (data['amount'] ?? 0).toDouble();
          }

          return Column(
            children: [
              // Total Donation Summary
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Donation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '৳${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '${docs.length} donation${docs.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Donation List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final doc = docs[idx];
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = data['amount'] ?? 0;
                    final method = data['paymentMethod'] ?? 'Unknown';
                    final fund = data['fundType'] ?? 'General';
                    final transactionId = data['transactionId'] ?? 'N/A';
                    final status = data['status'] ?? 'pending';
                    final note = data['note'] ?? '';
                    final createdAt = (data['createdAt'] as Timestamp).toDate();

                    Color statusColor = Colors.orange;
                    String statusText = 'Pending';

                    if (status == 'verified') {
                      statusColor = Colors.green;
                      statusText = 'Verified';
                    } else if (status == 'rejected') {
                      statusColor = Colors.red;
                      statusText = 'Rejected';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.volunteer_activism,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '৳${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$method • $fund'),
                            Text('Txn: $transactionId'),
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Note: $note',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a')
                                  .format(createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
