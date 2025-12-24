import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kafela/screens/admin/tabs/donation_admin.dart';
import 'package:kafela/screens/admin/tabs/splash_content_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/routine_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/groups_tab.dart';
import 'tabs/admin_books_tab.dart';
import 'tabs/logout_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;

  // Management grid items
  final List<Map<String, dynamic>> _managementItems = [
    {
      'icon': Icons.list_alt_outlined,
      'label': 'Presence',
      'color': Colors.blue,
      'screen': const AttendanceTab(),
    },
    {
      'icon': Icons.schedule,
      'label': 'Routine',
      'color': Colors.green,
      'screen': const RoutineTab(),
    },
    {
      'icon': Icons.assignment,
      'label': 'Tasks',
      'color': Colors.orange,
      'screen': const TasksTab(),
    },
    {
      'icon': Icons.group,
      'label': 'Groups',
      'color': Colors.purple,
      'screen': const GroupsTab(),
    },
    {
      'icon': Icons.book,
      'label': 'Books',
      'color': Colors.teal,
      'screen': const AdminBooksTab(),
    },
    {
      'icon': Icons.auto_stories,
      'label': 'Verses & Hadiths',
      'color': Colors.green.shade700,
      'screen': const SplashContentTab(),
    },
  ];

  // Main tabs
  final List<Widget> _screens = [
    const DashboardTab(),
    const ReportsTab(selectedMemberId: '', selectedMemberName: ''),
    const DonationTab(),
    // Management tab with grid view
    Container(), // Placeholder, will be built separately
    const LogoutTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _getCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getCurrentScreen() {
    if (_currentIndex == 3) {
      return _buildManagementGrid();
    }
    return _screens[_currentIndex];
  }

  Widget _buildManagementGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Manage different aspects of your organization',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 1,
                  ),
                  itemCount: _managementItems.length,
                  itemBuilder: (context, index) {
                    final item = _managementItems[index];
                    return _buildGridItem(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                      color: item['color'] as Color,
                      screen: item['screen'] as Widget,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String label,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to open',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final List<Map<String, dynamic>> mainNavItems = [
      {'icon': Icons.dashboard, 'label': 'Home'},
      {'icon': Icons.analytics, 'label': 'Reports'},
      {'icon': Icons.volunteer_activism, 'label': 'Eyanot'},
      {'icon': Icons.manage_accounts, 'label': 'Management'},
      {'icon': Icons.logout, 'label': 'Logout'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Important: set top to false
        child: SizedBox(
          height: 60, // Fixed height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              mainNavItems.length,
                  (index) => _buildNavItem(
                iconData: mainNavItems[index]['icon'] as IconData,
                label: mainNavItems[index]['label'] as String,
                isSelected: _currentIndex == index,
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
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
              size: 24,
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