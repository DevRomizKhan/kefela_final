//
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// // Import member tabs
// import 'tabs/member_dashboard_tab.dart';
// import 'tabs/prayer_attendance_tab.dart';
// import 'tabs/class_routine_tab.dart';
// import 'tabs/tasks_tab.dart';
// import 'tabs/groups_tab.dart';
// import 'tabs/activity_tab.dart';
// import 'tabs/member_profile_tab.dart';
//
// class MemberDashboard extends StatefulWidget {
//   const MemberDashboard({super.key});
//
//   @override
//   State<MemberDashboard> createState() => _MemberDashboardState();
// }
//
// class _MemberDashboardState extends State<MemberDashboard> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   int _currentIndex = 0;
//   Map<String, dynamic>? _memberData;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchMemberData();
//   }
//
//   Future<void> _fetchMemberData() async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         final doc = await _firestore.collection('users').doc(user.uid).get();
//         if (doc.exists) {
//           setState(() {
//             _memberData = doc.data()!;
//           });
//         }
//       }
//     } catch (e) {
//       print('Error fetching member data: $e');
//     }
//   }
//
//   // List of all member tab screens
//   final List<Widget> _screens = [
//     const MemberDashboardTab(),
//     const PrayerAttendanceTab(),
//     const ClassRoutineTab(),
//     const MemberTasksTab(),
//     const MemberGroupsTab(),
//     const MemberActivityTab(),
//     const MemberProfileTab(),
//   ];
//
//   // Navigation bar items
//   final List<BottomNavigationBarItem> _navItems = [
//     const BottomNavigationBarItem(
//       icon: Icon(Icons.dashboard),
//       label: 'Dashboard',
//     ),
//     const BottomNavigationBarItem(
//       icon: Icon(Icons.mosque),
//       label: 'Prayer',
//     ),
//     const BottomNavigationBarItem(
//       icon: Icon(Icons.schedule),
//       label: 'Routine',
//     ),
//     const BottomNavigationBarItem(
//       icon: Icon(Icons.assignment),
//       label: 'Tasks',
//     ),
//     const BottomNavigationBarItem(
//       icon: Icon(Icons.group),
//       label: 'Groups',
//     ),
//     const BottomNavigationBarItem(
//       icon: Icon(Icons.analytics),
//       label: 'Activity',
//     ),
//     const BottomNavigationBarItem(
//       icon: Icon(Icons.person),
//       label: 'Profile',
//     ),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white, // Changed to pure white
//       body: _screens[_currentIndex],
//       bottomNavigationBar: _buildBottomNavigationBar(),
//     );
//   }
//
//   Widget _buildBottomNavigationBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white, // Changed to pure white
//         border: const Border(
//           top: BorderSide(color: Colors.grey, width: 0.5), // Changed to light grey for contrast
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1), // Lighter shadow for white background
//             blurRadius: 4,
//             offset: const Offset(0, -1),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: SizedBox(
//           height: kBottomNavigationBarHeight,
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             physics: const BouncingScrollPhysics(),
//             child: SizedBox(
//               width: _navItems.length * 100.0,
//               child: BottomNavigationBar(
//                 currentIndex: _currentIndex,
//                 onTap: (index) => setState(() => _currentIndex = index),
//                 type: BottomNavigationBarType.fixed,
//                 backgroundColor: Colors.white, // Changed to pure white
//                 selectedItemColor: Colors.green, // Green accent
//                 unselectedItemColor: Colors.black, // Changed to black
//                 selectedLabelStyle: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                   color: Colors.green, // Green accent
//                 ),
//                 unselectedLabelStyle: const TextStyle(
//                   fontWeight: FontWeight.normal,
//                   fontSize: 12,
//                   color: Colors.black, // Changed to black
//                 ),
//                 iconSize: 22,
//                 items: _navItems,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
// }
//
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// Import member tabs
import 'tabs/member_dashboard_tab.dart';
import 'tabs/prayer_attendance_tab.dart';
import 'tabs/class_routine_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/groups_tab.dart';
import 'tabs/activity_tab.dart';
import 'tabs/member_profile_tab.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;
  Map<String, dynamic>? _memberData;

  @override
  void initState() {
    super.initState();
    _fetchMemberData();
  }

  Future<void> _fetchMemberData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _memberData = doc.data()!;
          });
        }
      }
    } catch (e) {
      print('Error fetching member data: $e');
    }
  }

  final List<Widget> _screens = [
    const MemberDashboardTab(),
    const PrayerAttendanceTab(),
    const ClassRoutineTab(),
    const MemberTasksTab(),
    const MemberGroupsTab(),
    const MemberActivityTab(),
    const MemberProfileTab(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.mosque),
      label: 'Prayer',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.schedule),
      label: 'Routine',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assignment),
      label: 'Tasks',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.group),
      label: 'Groups',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Activity',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: kBottomNavigationBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _navItems.length,
                  (index) => _buildNavItem(
                iconData: (_navItems[index].icon as Icon).icon!,
                label: _navItems[index].label!,
                isSelected: _currentIndex == index,
                onTap: () => setState(() => _currentIndex = index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData iconData,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 22,
              color: isSelected ? Colors.green : Colors.black,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

