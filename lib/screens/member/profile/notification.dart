import 'package:flutter/material.dart';

class Notifications extends StatefulWidget {
const Notifications({super.key});

@override
State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.white,
appBar: AppBar(
title: const Text(
'Notifications',
style: TextStyle(color: Colors.black),
),
centerTitle: true,
backgroundColor: Colors.white,
foregroundColor: Colors.black,
elevation: 0,
),
body: const Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.notifications_none,
size: 64,
color: Colors.green,
),
SizedBox(height: 16),
Text(
'Coming Soon!',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Colors.black,
),
),
],
),
),
);
}
}
// //
// 2nd version
// // import 'package:flutter/material.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// // import 'package:provider/provider.dart';
// //
// // /* -------------------------------------------------
// //    Main entry – replace your old notifications.dart
// // -------------------------------------------------- */
// //
// // class Notifications extends StatelessWidget {
// //   const Notifications({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return ChangeNotifierProvider(
// //       create: (_) => NotificationManager(),
// //       child: const NotificationScreen(),
// //     );
// //   }
// // }
// //
// // /* -------------------------------------------------
// //    UI layer
// // -------------------------------------------------- */
// //
// // class NotificationScreen extends StatefulWidget {
// //   const NotificationScreen({super.key});
// //
// //   @override
// //   State<NotificationScreen> createState() => _NotificationScreenState();
// // }
// //
// // class _NotificationScreenState extends State<NotificationScreen> {
// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       final manager = context.read<NotificationManager>();
// //       manager.init();
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final manager = context.watch<NotificationManager>();
// //
// //     return Scaffold(
// //       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
// //       appBar: AppBar(
// //         title: const Text('Notifications'),
// //         centerTitle: true,
// //         elevation: 0,
// //         actions: [
// //           if (manager.items.isNotEmpty) ...[
// //             IconButton(
// //               tooltip: 'Mark all read',
// //               icon: const Icon(Icons.done_all),
// //               onPressed: manager.markAllRead,
// //             ),
// //             IconButton(
// //               tooltip: 'Clear all',
// //               icon: const Icon(Icons.clear_all),
// //               onPressed: manager.clearAll,
// //             ),
// //           ]
// //         ],
// //       ),
// //       body: manager.items.isEmpty
// //           ? const EmptyNotificationState()
// //           : ListView.builder(
// //         padding: const EdgeInsets.all(12),
// //         itemCount: manager.items.length,
// //         itemBuilder: (context, index) {
// //           final item = manager.items[index];
// //           return DismissibleNotificationItem(
// //             key: ValueKey(item.id),
// //             item: item,
// //             onTap: () => manager.markRead(item.id),
// //             onDismissed: () => manager.remove(item.id),
// //           );
// //         },
// //       ),
// //       floatingActionButton: FloatingActionButton.extended(
// //         onPressed: () => context.read<NotificationManager>().scheduleDemoNotification(),
// //         icon: const Icon(Icons.add_alert),
// //         label: const Text('Test Notification'),
// //       ),
// //     );
// //   }
// // }
// //
// // /* -------------------------------------------------
// //    Empty state
// // -------------------------------------------------- */
// //
// // class EmptyNotificationState extends StatelessWidget {
// //   const EmptyNotificationState({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(
// //             Icons.notifications_off_outlined,
// //             size: 80,
// //             color: Colors.grey[400],
// //           ),
// //           const SizedBox(height: 16),
// //           Text(
// //             'No notifications yet',
// //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //               color: Colors.grey[600],
// //             ),
// //           ),
// //           const SizedBox(height: 8),
// //           Text(
// //             'Notifications will appear here',
// //             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
// //               color: Colors.grey[500],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // /* -------------------------------------------------
// //    Single notification card
// // -------------------------------------------------- */
// //
// // class DismissibleNotificationItem extends StatelessWidget {
// //   final NotificationItem item;
// //   final VoidCallback onTap;
// //   final VoidCallback onDismissed;
// //
// //   const DismissibleNotificationItem({
// //     super.key,
// //     required this.item,
// //     required this.onTap,
// //     required this.onDismissed,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Dismissible(
// //       key: key!,
// //       background: Container(
// //         color: Colors.red,
// //         alignment: Alignment.centerLeft,
// //         padding: const EdgeInsets.only(left: 20),
// //         child: const Icon(Icons.delete, color: Colors.white),
// //       ),
// //       secondaryBackground: Container(
// //         color: Colors.red,
// //         alignment: Alignment.centerRight,
// //         padding: const EdgeInsets.only(right: 20),
// //         child: const Icon(Icons.delete, color: Colors.white),
// //       ),
// //       confirmDismiss: (direction) async {
// //         return await showDialog(
// //           context: context,
// //           builder: (BuildContext context) {
// //             return AlertDialog(
// //               title: const Text("Confirm"),
// //               content: const Text("Are you sure you want to delete this notification?"),
// //               actions: <Widget>[
// //                 TextButton(
// //                   onPressed: () => Navigator.of(context).pop(false),
// //                   child: const Text("Cancel"),
// //                 ),
// //                 TextButton(
// //                   onPressed: () => Navigator.of(context).pop(true),
// //                   child: const Text("Delete"),
// //                 ),
// //               ],
// //             );
// //           },
// //         );
// //       },
// //       onDismissed: (direction) => onDismissed(),
// //       child: Card(
// //         margin: const EdgeInsets.symmetric(vertical: 6),
// //         color: item.read ? Colors.grey[50] : Colors.blue[50],
// //         elevation: 1,
// //         child: ListTile(
// //           onTap: onTap,
// //           leading: Container(
// //             width: 40,
// //             height: 40,
// //             decoration: BoxDecoration(
// //               color: item.read ? Colors.grey : Theme.of(context).primaryColor,
// //               shape: BoxShape.circle,
// //             ),
// //             child: Icon(
// //               item.read ? Icons.notifications_none : Icons.notifications_active,
// //               color: Colors.white,
// //               size: 20,
// //             ),
// //           ),
// //           title: Text(
// //             item.title,
// //             style: TextStyle(
// //               fontWeight: item.read ? FontWeight.normal : FontWeight.bold,
// //               color: item.read ? Colors.grey[600] : Colors.black87,
// //             ),
// //           ),
// //           subtitle: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(item.body),
// //               const SizedBox(height: 4),
// //               Text(
// //                 _formatTime(item.received),
// //                 style: TextStyle(
// //                   fontSize: 12,
// //                   color: Colors.grey[500],
// //                 ),
// //               ),
// //             ],
// //           ),
// //           trailing: item.read
// //               ? null
// //               : Container(
// //             width: 8,
// //             height: 8,
// //             decoration: const BoxDecoration(
// //               color: Colors.red,
// //               shape: BoxShape.circle,
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   String _formatTime(DateTime t) {
// //     final now = DateTime.now();
// //     final diff = now.difference(t);
// //
// //     if (diff.inDays > 365) {
// //       final years = (diff.inDays / 365).floor();
// //       return '$years year${years > 1 ? 's' : ''} ago';
// //     }
// //     if (diff.inDays > 30) {
// //       final months = (diff.inDays / 30).floor();
// //       return '$months month${months > 1 ? 's' : ''} ago';
// //     }
// //     if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
// //     if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
// //     if (diff.inMinutes > 0) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
// //     return 'Just now';
// //   }
// // }
// //
// // /* -------------------------------------------------
// //    Business logic – provider
// // -------------------------------------------------- */
// //
// // class NotificationManager extends ChangeNotifier {
// //   final List<NotificationItem> _items = [];
// //
// //   List<NotificationItem> get items => _items;
// //
// //   int get unreadCount => _items.where((e) => !e.read).length;
// //
// //   late FlutterLocalNotificationsPlugin _plugin;
// //
// //   /* ---------- initialise ---------- */
// //   Future<void> init() async {
// //     _plugin = FlutterLocalNotificationsPlugin();
// //
// //     const android = AndroidInitializationSettings('@mipmap/ic_launcher');
// //     const ios = DarwinInitializationSettings(
// //       requestAlertPermission: true,
// //       requestBadgePermission: true,
// //       requestSoundPermission: true,
// //     );
// //     const initSettings = InitializationSettings(android: android, iOS: ios);
// //
// //     await _plugin.initialize(
// //       initSettings,
// //       onDidReceiveNotificationResponse: _onNotificationResponse,
// //     );
// //
// //     // Request permissions
// //     await _requestPermissions();
// //
// //     // Load any existing notifications from storage
// //     _loadStoredNotifications();
// //   }
// //
// //   Future<void> _requestPermissions() async {
// //     try {
// //       await _plugin
// //           .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
// //           ?.requestPermission();
// //     } catch (e) {
// //       print("Android permission error: $e");
// //     }
// //
// //     try {
// //       await _plugin
// //           .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
// //           ?.requestPermissions(
// //         alert: true,
// //         badge: true,
// //         sound: true,
// //       );
// //     } catch (e) {
// //       print("iOS permission error: $e");
// //     }
// //   }
// //
// //   void _loadStoredNotifications() {
// //     // Here you can load notifications from local storage (SharedPreferences, Hive, etc.)
// //     // For now, we'll start with an empty list
// //     notifyListeners();
// //   }
// //
// //   void _saveStoredNotifications() {
// //     // Save notifications to local storage
// //     // Implement your preferred storage solution here
// //   }
// //
// //   /* ---------- demo notification ---------- */
// //   Future<void> scheduleDemoNotification() async {
// //     const android = AndroidNotificationDetails(
// //       'general_channel',
// //       'General Notifications',
// //       channelDescription: 'This channel is for general notifications',
// //       importance: Importance.high,
// //       priority: Priority.high,
// //       ticker: 'ticker',
// //     );
// //
// //     const ios = DarwinNotificationDetails(
// //       presentAlert: true,
// //       presentBadge: true,
// //       presentSound: true,
// //     );
// //
// //     const details = NotificationDetails(android: android, iOS: ios);
// //
// //     final id = DateTime.now().millisecondsSinceEpoch;
// //     await _plugin.show(
// //       id,
// //       'Test Notification',
// //       'This is a test notification from your app! 🎉',
// //       details,
// //       payload: 'test_payload',
// //     );
// //
// //     // Also add to local list
// //     add(NotificationItem(
// //       id: id,
// //       title: 'Test Notification',
// //       body: 'This is a test notification from your app! 🎉',
// //       received: DateTime.now(),
// //     ));
// //   }
// //
// //   /* ---------- handle notification response ---------- */
// //   void _onNotificationResponse(NotificationResponse response) {
// //     final id = DateTime.now().millisecondsSinceEpoch;
// //     add(NotificationItem(
// //       id: id,
// //       title: 'Notification Tapped',
// //       body: 'You tapped on a notification with payload: ${response.payload}',
// //       received: DateTime.now(),
// //     ));
// //   }
// //
// //   /* ---------- CRUD operations ---------- */
// //   void add(NotificationItem item) {
// //     _items.insert(0, item);
// //     _saveStoredNotifications();
// //     notifyListeners();
// //   }
// //
// //   void remove(int id) {
// //     final index = _items.indexWhere((item) => item.id == id);
// //     if (index != -1) {
// //       _items.removeAt(index);
// //       _saveStoredNotifications();
// //       notifyListeners();
// //     }
// //   }
// //
// //   void markRead(int id) {
// //     final index = _items.indexWhere((item) => item.id == id);
// //     if (index != -1) {
// //       _items[index] = _items[index].copyWith(read: true);
// //       _saveStoredNotifications();
// //       notifyListeners();
// //     }
// //   }
// //
// //   void markAllRead() {
// //     for (var i = 0; i < _items.length; i++) {
// //       _items[i] = _items[i].copyWith(read: true);
// //     }
// //     _saveStoredNotifications();
// //     notifyListeners();
// //   }
// //
// //   void clearAll() {
// //     _items.clear();
// //     _saveStoredNotifications();
// //     notifyListeners();
// //   }
// //
// //   // Method to schedule actual app notifications
// //   Future<void> scheduleAppNotification({
// //     required String title,
// //     required String body,
// //     required Duration delay,
// //     String? payload,
// //   }) async {
// //     const android = AndroidNotificationDetails(
// //       'app_channel',
// //       'App Notifications',
// //       channelDescription: 'This channel is for app-specific notifications',
// //       importance: Importance.high,
// //       priority: Priority.high,
// //     );
// //
// //     const ios = DarwinNotificationDetails(
// //       presentAlert: true,
// //       presentBadge: true,
// //       presentSound: true,
// //     );
// //
// //     const details = NotificationDetails(android: android, iOS: ios);
// //
// //     final id = DateTime.now().millisecondsSinceEpoch;
// //
// //     await _plugin.schedule(
// //       id,
// //       title,
// //       body,
// //       DateTime.now().add(delay),
// //       details,
// //       payload: payload,
// //     );
// //
// //     // Add to local list immediately
// //     add(NotificationItem(
// //       id: id,
// //       title: title,
// //       body: body,
// //       received: DateTime.now(),
// //     ));
// //   }
// // }
// //
// // extension on AndroidFlutterLocalNotificationsPlugin? {
// //   Future<void> requestPermission() async {}
// // }
// //
// // extension on FlutterLocalNotificationsPlugin {
// //   Future<void> schedule(int id, String title, String body, DateTime add, NotificationDetails details, {String? payload}) async {}
// // }
// //
// // /* -------------------------------------------------
// //    Data model
// // -------------------------------------------------- */
// //
// // @immutable
// // class NotificationItem {
// //   final int id;
// //   final String title;
// //   final String body;
// //   final DateTime received;
// //   final bool read;
// //
// //   const NotificationItem({
// //     required this.id,
// //     required this.title,
// //     required this.body,
// //     required this.received,
// //     this.read = false,
// //   });
// //
// //   NotificationItem copyWith({
// //     int? id,
// //     String? title,
// //     String? body,
// //     DateTime? received,
// //     bool? read,
// //   }) {
// //     return NotificationItem(
// //       id: id ?? this.id,
// //       title: title ?? this.title,
// //       body: body ?? this.body,
// //       received: received ?? this.received,
// //       read: read ?? this.read,
// //     );
// //   }
// //
// //   @override
// //   bool operator ==(Object other) {
// //     if (identical(this, other)) return true;
// //     return other is NotificationItem && other.id == id;
// //   }
// //
// //   @override
// //   int get hashCode => id.hashCode;
// // }
// //
//
//
// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;
//
// /* -------------------------------------------------
//    Main entry – replace your old notifications.dart
// -------------------------------------------------- */
//
// class Notifications extends StatelessWidget {
//   const Notifications({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => NotificationManager(),
//       child: const NotificationScreen(),
//     );
//   }
// }
//
// /* -------------------------------------------------
//    UI layer
// -------------------------------------------------- */
//
// class NotificationScreen extends StatefulWidget {
//   const NotificationScreen({super.key});
//
//   @override
//   State<NotificationScreen> createState() => _NotificationScreenState();
// }
//
// class _NotificationScreenState extends State<NotificationScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final manager = context.read<NotificationManager>();
//       manager.init();
//       manager.startListeningToFirebaseChanges();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final manager = context.watch<NotificationManager>();
//
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: const Text('Notifications'),
//         centerTitle: true,
//         elevation: 0,
//         actions: [
//           if (manager.items.isNotEmpty) ...[
//             IconButton(
//               tooltip: 'Mark all read',
//               icon: const Icon(Icons.done_all),
//               onPressed: manager.markAllRead,
//             ),
//             IconButton(
//               tooltip: 'Clear all',
//               icon: const Icon(Icons.clear_all),
//               onPressed: manager.clearAll,
//             ),
//           ]
//         ],
//       ),
//       body: manager.items.isEmpty
//           ? const EmptyNotificationState()
//           : ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: manager.items.length,
//         itemBuilder: (context, index) {
//           final item = manager.items[index];
//           return DismissibleNotificationItem(
//             key: ValueKey(item.id),
//             item: item,
//             onTap: () => manager.markRead(item.id),
//             onDismissed: () => manager.remove(item.id),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => context.read<NotificationManager>().scheduleDemoNotification(),
//         icon: const Icon(Icons.add_alert),
//         label: const Text('Test Notification'),
//       ),
//     );
//   }
// }
//
// /* -------------------------------------------------
//    Empty state
// -------------------------------------------------- */
//
// class EmptyNotificationState extends StatelessWidget {
//   const EmptyNotificationState({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.notifications_off_outlined,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No notifications yet',
//             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Notifications will appear here',
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /* -------------------------------------------------
//    Single notification card
// -------------------------------------------------- */
//
// class DismissibleNotificationItem extends StatelessWidget {
//   final NotificationItem item;
//   final VoidCallback onTap;
//   final VoidCallback onDismissed;
//
//   const DismissibleNotificationItem({
//     super.key,
//     required this.item,
//     required this.onTap,
//     required this.onDismissed,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Dismissible(
//       key: key!,
//       background: Container(
//         color: Colors.red,
//         alignment: Alignment.centerLeft,
//         padding: const EdgeInsets.only(left: 20),
//         child: const Icon(Icons.delete, color: Colors.white),
//       ),
//       secondaryBackground: Container(
//         color: Colors.red,
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         child: const Icon(Icons.delete, color: Colors.white),
//       ),
//       confirmDismiss: (direction) async {
//         return await showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: const Text("Confirm"),
//               content: const Text("Are you sure you want to delete this notification?"),
//               actions: <Widget>[
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(false),
//                   child: const Text("Cancel"),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(true),
//                   child: const Text("Delete"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//       onDismissed: (direction) => onDismissed(),
//       child: Card(
//         margin: const EdgeInsets.symmetric(vertical: 6),
//         color: item.read ? Colors.grey[50] : Colors.blue[50],
//         elevation: 1,
//         child: ListTile(
//           onTap: onTap,
//           leading: Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: item.read ? Colors.grey : _getNotificationColor(item.type),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               _getNotificationIcon(item.type),
//               color: Colors.white,
//               size: 20,
//             ),
//           ),
//           title: Text(
//             item.title,
//             style: TextStyle(
//               fontWeight: item.read ? FontWeight.normal : FontWeight.bold,
//               color: item.read ? Colors.grey[600] : Colors.black87,
//             ),
//           ),
//           subtitle: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(item.body),
//               const SizedBox(height: 4),
//               Text(
//                 _formatTime(item.received),
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[500],
//                 ),
//               ),
//             ],
//           ),
//           trailing: item.read
//               ? null
//               : Container(
//             width: 8,
//             height: 8,
//             decoration: const BoxDecoration(
//               color: Colors.red,
//               shape: BoxShape.circle,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Color _getNotificationColor(NotificationType type) {
//     switch (type) {
//       case NotificationType.classRoutine:
//         return Colors.green;
//       case NotificationType.task:
//         return Colors.blue;
//       case NotificationType.groupMessage:
//         return Colors.orange;
//       case NotificationType.general:
//       default:
//         return Colors.purple;
//     }
//   }
//
//   IconData _getNotificationIcon(NotificationType type) {
//     switch (type) {
//       case NotificationType.classRoutine:
//         return Icons.schedule;
//       case NotificationType.task:
//         return Icons.assignment;
//       case NotificationType.groupMessage:
//         return Icons.group;
//       case NotificationType.general:
//       default:
//         return Icons.notifications;
//     }
//   }
//
//   String _formatTime(DateTime t) {
//     final now = DateTime.now();
//     final diff = now.difference(t);
//
//     if (diff.inDays > 365) {
//       final years = (diff.inDays / 365).floor();
//       return '$years year${years > 1 ? 's' : ''} ago';
//     }
//     if (diff.inDays > 30) {
//       final months = (diff.inDays / 30).floor();
//       return '$months month${months > 1 ? 's' : ''} ago';
//     }
//     if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
//     if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
//     if (diff.inMinutes > 0) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
//     return 'Just now';
//   }
// }
//
// /* -------------------------------------------------
//    Business logic – provider
// -------------------------------------------------- */
//
// class NotificationManager extends ChangeNotifier {
//   final List<NotificationItem> _items = [];
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   List<StreamSubscription> _firebaseSubscriptions = [];
//
//   List<NotificationItem> get items => _items;
//
//   int get unreadCount => _items.where((e) => !e.read).length;
//
//   late FlutterLocalNotificationsPlugin _plugin;
//
//   /* ---------- initialise ---------- */
//   Future<void> init() async {
//     _plugin = FlutterLocalNotificationsPlugin();
//
//     const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const ios = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//     const initSettings = InitializationSettings(android: android, iOS: ios);
//
//     await _plugin.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: _onNotificationResponse,
//     );
//
//     // Initialize timezones
//     tz.initializeTimeZones();
//
//     // Load any existing notifications from storage
//     _loadStoredNotifications();
//   }
//
//   /* ---------- Start listening to Firebase changes ---------- */
//   void startListeningToFirebaseChanges() {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     // Listen for new class routines
//     _firebaseSubscriptions.add(
//       _firestore
//           .collection('routines')
//           .snapshots()
//           .listen((snapshot) {
//         for (var change in snapshot.docChanges) {
//           if (change.type == DocumentChangeType.added) {
//             final routine = change.doc.data() as Map<String, dynamic>?;
//             if (routine != null) {
//               _notifyNewClassRoutine(routine, change.doc.id);
//             }
//           }
//         }
//       }),
//     );
//
//     // Listen for new tasks assigned to current user
//     _firebaseSubscriptions.add(
//       _firestore
//           .collection('tasks')
//           .where('assignedTo', isEqualTo: user.uid)
//           .snapshots()
//           .listen((snapshot) {
//         for (var change in snapshot.docChanges) {
//           if (change.type == DocumentChangeType.added) {
//             final task = change.doc.data() as Map<String, dynamic>?;
//             if (task != null) {
//               _notifyNewTask(task, change.doc.id);
//             }
//           }
//         }
//       }),
//     );
//
//     // Listen for group messages in groups where user is a member
//     _firebaseSubscriptions.add(
//       _firestore
//           .collection('groups')
//           .where('members', arrayContains: user.uid)
//           .snapshots()
//           .listen((snapshot) {
//         for (var groupDoc in snapshot.docs) {
//           _listenToGroupMessages(groupDoc);
//         }
//       }),
//     );
//   }
//
//   void _listenToGroupMessages(DocumentSnapshot groupDoc) {
//     _firebaseSubscriptions.add(
//       _firestore
//           .collection('groups')
//           .doc(groupDoc.id)
//           .collection('messages')
//           .orderBy('timestamp', descending: true)
//           .limit(1)
//           .snapshots()
//           .listen((snapshot) {
//         for (var change in snapshot.docChanges) {
//           if (change.type == DocumentChangeType.added) {
//             final message = change.doc.data() as Map<String, dynamic>?;
//             final groupData = groupDoc.data() as Map<String, dynamic>?;
//             if (message != null && groupData != null) {
//               _notifyNewGroupMessage(message, groupData, change.doc.id);
//             }
//           }
//         }
//       }),
//     );
//   }
//
//   void _notifyNewClassRoutine(Map<String, dynamic> routine, String routineId) {
//     final className = routine['className'] ?? 'New Class';
//     final instructor = routine['instructor'] ?? '';
//     final day = routine['day'] ?? '';
//     final time = routine['startTime'] ?? '';
//
//     final notificationId = DateTime.now().millisecondsSinceEpoch;
//
//     _showLocalNotification(
//       id: notificationId,
//       title: '📚 New Class Routine',
//       body: '$className by $instructor on $day at $time',
//       payload: 'routine_$routineId',
//     );
//
//     add(NotificationItem(
//       id: notificationId,
//       title: 'New Class Routine',
//       body: '$className by $instructor scheduled for $day at $time',
//       received: DateTime.now(),
//       type: NotificationType.classRoutine,
//       payload: 'routine_$routineId',
//     ));
//   }
//
//   void _notifyNewTask(Map<String, dynamic> task, String taskId) {
//     final taskTitle = task['title'] ?? 'New Task';
//     final dueDate = task['dueDate'];
//     final description = task['description'] ?? '';
//
//     String dueText = '';
//     if (dueDate is Timestamp) {
//       final date = dueDate.toDate();
//       dueText = ' due ${DateFormat('MMM dd').format(date)}';
//     }
//
//     final notificationId = DateTime.now().millisecondsSinceEpoch;
//
//     _showLocalNotification(
//       id: notificationId,
//       title: '📝 New Task Assigned',
//       body: '$taskTitle$dueText',
//       payload: 'task_$taskId',
//     );
//
//     add(NotificationItem(
//       id: notificationId,
//       title: 'New Task Assigned',
//       body: '$taskTitle$dueText - $description',
//       received: DateTime.now(),
//       type: NotificationType.task,
//       payload: 'task_$taskId',
//     ));
//   }
//
//   void _notifyNewGroupMessage(Map<String, dynamic> message, Map<String, dynamic> group, String messageId) {
//     final senderId = message['senderId'];
//     final messageText = message['text'] ?? 'New message';
//     final groupName = group['name'] ?? 'Group';
//
//     // Don't notify if the message is from current user
//     if (senderId == _auth.currentUser?.uid) return;
//
//     final notificationId = DateTime.now().millisecondsSinceEpoch;
//
//     _showLocalNotification(
//       id: notificationId,
//       title: '👥 $groupName',
//       body: messageText.length > 50 ? '${messageText.substring(0, 50)}...' : messageText,
//       payload: 'group_${group['id']}_message_$messageId',
//     );
//
//     add(NotificationItem(
//       id: notificationId,
//       title: 'New message in $groupName',
//       body: messageText,
//       received: DateTime.now(),
//       type: NotificationType.groupMessage,
//       payload: 'group_${group['id']}_message_$messageId',
//     ));
//   }
//
//   Future<void> _showLocalNotification({
//     required int id,
//     required String title,
//     required String body,
//     required String payload,
//   }) async {
//     const android = AndroidNotificationDetails(
//       'app_updates_channel',
//       'App Updates',
//       channelDescription: 'Notifications for app updates and new content',
//       importance: Importance.high,
//       priority: Priority.high,
//       ticker: 'ticker',
//     );
//
//     const ios = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );
//
//     const details = NotificationDetails(android: android, iOS: ios);
//
//     await _plugin.show(
//       id,
//       title,
//       body,
//       details,
//       payload: payload,
//     );
//   }
//
//   void _loadStoredNotifications() {
//     // Here you can load notifications from local storage
//     // For now, we'll start with an empty list
//     notifyListeners();
//   }
//
//   void _saveStoredNotifications() {
//     // Save notifications to local storage
//   }
//
//   /* ---------- demo notification ---------- */
//   Future<void> scheduleDemoNotification() async {
//     final notificationId = DateTime.now().millisecondsSinceEpoch;
//
//     await _showLocalNotification(
//       id: notificationId,
//       title: 'Test Notification',
//       body: 'This is a test notification from your app! 🎉',
//       payload: 'test_payload',
//     );
//
//     add(NotificationItem(
//       id: notificationId,
//       title: 'Test Notification',
//       body: 'This is a test notification from your app! 🎉',
//       received: DateTime.now(),
//       type: NotificationType.general,
//     ));
//   }
//
//   /* ---------- handle notification response ---------- */
//   void _onNotificationResponse(NotificationResponse response) {
//     final id = DateTime.now().millisecondsSinceEpoch;
//     add(NotificationItem(
//       id: id,
//       title: 'Notification Tapped',
//       body: 'You tapped on a notification',
//       received: DateTime.now(),
//       type: NotificationType.general,
//     ));
//   }
//
//   /* ---------- CRUD operations ---------- */
//   void add(NotificationItem item) {
//     _items.insert(0, item);
//     _saveStoredNotifications();
//     notifyListeners();
//   }
//
//   void remove(int id) {
//     final index = _items.indexWhere((item) => item.id == id);
//     if (index != -1) {
//       _items.removeAt(index);
//       _saveStoredNotifications();
//       notifyListeners();
//     }
//   }
//
//   void markRead(int id) {
//     final index = _items.indexWhere((item) => item.id == id);
//     if (index != -1) {
//       _items[index] = _items[index].copyWith(read: true);
//       _saveStoredNotifications();
//       notifyListeners();
//     }
//   }
//
//   void markAllRead() {
//     for (var i = 0; i < _items.length; i++) {
//       _items[i] = _items[i].copyWith(read: true);
//     }
//     _saveStoredNotifications();
//     notifyListeners();
//   }
//
//   void clearAll() {
//     _items.clear();
//     _saveStoredNotifications();
//     notifyListeners();
//   }
//
//   @override
//   void dispose() {
//     // Cancel all Firebase subscriptions
//     for (var subscription in _firebaseSubscriptions) {
//       subscription.cancel();
//     }
//     super.dispose();
//   }
// }
//
// /* -------------------------------------------------
//    Data model and enums
// -------------------------------------------------- */
//
// enum NotificationType {
//   classRoutine,
//   task,
//   groupMessage,
//   general,
// }
//
// @immutable
// class NotificationItem {
//   final int id;
//   final String title;
//   final String body;
//   final DateTime received;
//   final bool read;
//   final NotificationType type;
//   final String? payload;
//
//   const NotificationItem({
//     required this.id,
//     required this.title,
//     required this.body,
//     required this.received,
//     this.read = false,
//     this.type = NotificationType.general,
//     this.payload,
//   });
//
//   NotificationItem copyWith({
//     int? id,
//     String? title,
//     String? body,
//     DateTime? received,
//     bool? read,
//     NotificationType? type,
//     String? payload,
//   }) {
//     return NotificationItem(
//       id: id ?? this.id,
//       title: title ?? this.title,
//       body: body ?? this.body,
//       received: received ?? this.received,
//       read: read ?? this.read,
//       type: type ?? this.type,
//       payload: payload ?? this.payload,
//     );
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is NotificationItem && other.id == id;
//   }
//
//   @override
//   int get hashCode => id.hashCode;
// }