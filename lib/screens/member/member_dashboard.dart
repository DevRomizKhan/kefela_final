
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kafela/screens/member/tabs/donation_tab.dart';
// Import member tabs
import 'tabs/member_dashboard_tab.dart';
import 'tabs/activity/activity_tab.dart';
import 'tabs/member_profile_tab.dart';
import 'tabs/books_tab.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;

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
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching member data: $e');
      }
    }
  }

  final List<Widget> _screens = [
    const MemberDashboardTab(),
    // const PrayerAttendanceTab(),
    // const ClassRoutineTab(),
    // const MemberTasksTab(),
    // const MemberGroupsTab(),
    const MemberActivityTab(),
    const MemberDonationPanel(),
    const BooksTab(),
    const MemberProfileTab(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    // const BottomNavigationBarItem(
    //   icon: Icon(Icons.mosque),
    //   label: 'Prayer',
    // ),
    // const BottomNavigationBarItem(
    //   icon: Icon(Icons.schedule),
    //   label: 'Routine',
    // ),
    // const BottomNavigationBarItem(
    //   icon: Icon(Icons.assignment),
    //   label: 'Tasks',
    // ),

    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Activity',
  ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.group),
        label: 'Donation',
      ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: 'Books',
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

