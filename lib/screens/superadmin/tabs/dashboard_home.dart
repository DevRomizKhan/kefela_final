









































































































































































































































































































































































































































































































































































































































import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildQuickStatsRow(context),
                const SizedBox(height: 24),
                _buildDetailedStatistics(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(now);
    final formattedTime = DateFormat('hh:mm a').format(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Real-time organization analytics',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _getQuickStatsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard('Failed to load quick stats');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid(4);
        }

        final stats = snapshot.data ?? {};
        final totalUsers = stats['totalUsers'] ?? 0;
        final totalMeetings = stats['totalMeetings'] ?? 0;
        final totalTasks = stats['totalTasks'] ?? 0;
        final activeGroups = stats['activeGroups'] ?? 0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final crossAxisCount = isWide ? 4 : 2;
            final childAspectRatio = isWide ? 1.3 : 1.5;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildQuickStatCard(
                  title: 'Total Users',
                  value: totalUsers,
                  icon: Icons.people_outline,
                  gradient: [Colors.green, Colors.green],
                ),
                _buildQuickStatCard(
                  title: 'Total Meetings',
                  value: totalMeetings,
                  icon: Icons.video_library_outlined,
                  gradient: [Colors.green, Colors.green],
                ),
                _buildQuickStatCard(
                  title: 'Total Tasks',
                  value: totalTasks,
                  icon: Icons.assignment_outlined,
                  gradient: [Colors.green, Colors.green],
                ),
                _buildQuickStatCard(
                  title: 'Active Groups',
                  value: activeGroups,
                  icon: Icons.group_outlined,
                  gradient: [Colors.green, Colors.green],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailedStatistics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics_outlined, color: Colors.green.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detailed Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<Map<String, dynamic>>(
          stream: _getDetailedStatsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorCard('Failed to load detailed analytics: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingGrid(6);
            }

            final stats = snapshot.data ?? {};

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                final childAspectRatio = _getChildAspectRatio(constraints.maxWidth);

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDetailedStatCard(
                      title: 'User Distribution',
                      icon: Icons.pie_chart_outline,
                      color: Colors.green.shade600,
                      stats: [
                        _buildStatItem('Super Admins', stats['superAdmins'] ?? 0, Icons.verified_user),
                        _buildStatItem('Admins', stats['admins'] ?? 0, Icons.admin_panel_settings),
                        _buildStatItem('Members', stats['members'] ?? 0, Icons.person),
                      ],
                    ),
                    _buildDetailedStatCard(
                      title: 'Meeting Analytics',
                      icon: Icons.meeting_room_outlined,
                      color: Colors.purple.shade600,
                      stats: [
                        _buildStatItem('Total', stats['totalMeetings'] ?? 0, Icons.video_library),
                        _buildStatItem('Avg Attendance', '${stats['avgMeetingAttendance']?.toStringAsFixed(1) ?? '0'}%', Icons.people),
                        _buildStatItem('This Month', stats['monthlyMeetings'] ?? 0, Icons.calendar_month),
                      ],
                    ),
                    _buildDetailedStatCard(
                      title: 'Prayer Attendance',
                      icon: Icons.mosque_outlined,
                      color: Colors.green.shade600,
                      stats: [
                        _buildStatItem('Total Records', stats['totalPrayers'] ?? 0, Icons.format_list_numbered),
                        _buildStatItem('Attendance Rate', '${stats['avgPrayerAttendance']?.toStringAsFixed(1) ?? '0'}%', Icons.trending_up),
                        _buildStatItem('Today', stats['todayPrayers'] ?? 0, Icons.today),
                      ],
                    ),
                    _buildDetailedStatCard(
                      title: 'Task Management',
                      icon: Icons.task_alt,
                      color: Colors.orange.shade600,
                      stats: [
                        _buildStatItem('Total', stats['totalTasks'] ?? 0, Icons.assignment),
                        _buildStatItem('Completed', stats['completedTasks'] ?? 0, Icons.check_circle),
                        _buildStatItem('Pending', stats['pendingTasks'] ?? 0, Icons.pending),
                      ],
                    ),
                    _buildDetailedStatCard(
                      title: 'Group Analytics',
                      icon: Icons.group_work_outlined,
                      color: Colors.red.shade600,
                      stats: [
                        _buildStatItem('Total Groups', stats['totalGroups'] ?? 0, Icons.groups),
                        _buildStatItem('Active', stats['activeGroups'] ?? 0, Icons.circle),
                        _buildStatItem('Avg Members', stats['avgGroupMembers']?.toStringAsFixed(1) ?? '0', Icons.person_outline),
                      ],
                    ),
                    _buildDetailedStatCard(
                      title: 'Routine Stats',
                      icon: Icons.schedule_outlined,
                      color: Colors.teal.shade600,
                      stats: [
                        _buildStatItem('Total', stats['totalRoutines'] ?? 0, Icons.list_alt),
                        _buildStatItem('Active', stats['activeRoutines'] ?? 0, Icons.play_circle),
                        _buildStatItem('Completion', '${stats['routineCompletion']?.toStringAsFixed(1) ?? '0'}%', Icons.percent),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required String title,
    required int value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatNumber(value),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> stats,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...stats,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid(int itemCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: List.generate(itemCount, (index) => _buildShimmerCard()),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }

  double _getChildAspectRatio(double width) {
    if (width > 1200) return 1.5;
    if (width > 800) return 1.3;
    return 1.1;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Stream<Map<String, dynamic>> _getQuickStatsStream() async* {
    
    yield await _fetchQuickStats();

    
    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      yield await _fetchQuickStats();
    }
  }

  Future<Map<String, dynamic>> _fetchQuickStats() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').get(),
        FirebaseFirestore.instance.collection('meetings').get(),
        FirebaseFirestore.instance.collection('tasks').get(),
        FirebaseFirestore.instance.collection('groups').get(),
      ]);

      return {
        'totalUsers': results[0].docs.length,
        'totalMeetings': results[1].docs.length,
        'totalTasks': results[2].docs.length,
        'activeGroups': results[3].docs.length,
      };
    } catch (e) {
      print('Error fetching quick stats: $e');
      return {};
    }
  }

  Stream<Map<String, dynamic>> _getDetailedStatsStream() async* {
    
    yield await _fetchDetailedStats();

    
    await for (final _ in Stream.periodic(const Duration(seconds: 45))) {
      yield await _fetchDetailedStats();
    }
  }

  Future<Map<String, dynamic>> _fetchDetailedStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfDay = DateTime(now.year, now.month, now.day);

      
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').get(),
        FirebaseFirestore.instance.collection('meetings').get(),
        FirebaseFirestore.instance.collection('prayer_attendance').get(),
        FirebaseFirestore.instance.collection('tasks').get(),
        FirebaseFirestore.instance.collection('groups').get(),
        FirebaseFirestore.instance.collection('routines').get(),
      ]);

      final userDocs = results[0].docs;
      final meetingDocs = results[1].docs;
      final prayerDocs = results[2].docs;
      final taskDocs = results[3].docs;
      final groupDocs = results[4].docs;
      final routineDocs = results[5].docs;

      
      int superAdmins = 0, admins = 0, members = 0;
      for (var doc in userDocs) {
        final role = doc.data()['role'] as String?;
        if (role == 'SuperAdmin') superAdmins++;
        else if (role == 'Admin') admins++;
        else if (role == 'Member') members++;
      }

      
      final monthlyMeetings = meetingDocs.where((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        return timestamp != null && timestamp.toDate().isAfter(startOfMonth);
      }).length;

      
      int totalAttendanceRecords = 0;
      for (var meeting in meetingDocs) {
        try {
          final attendanceSnapshot = await FirebaseFirestore.instance
              .collection('meetings')
              .doc(meeting.id)
              .collection('attendance')
              .get();
          totalAttendanceRecords += attendanceSnapshot.docs.length;
        } catch (e) {
          print('Error fetching attendance for meeting ${meeting.id}: $e');
        }
      }

      final avgMeetingAttendance = meetingDocs.isNotEmpty && userDocs.isNotEmpty
          ? (totalAttendanceRecords / (meetingDocs.length * userDocs.length)) * 100
          : 0.0;

      
      final todayPrayers = prayerDocs.where((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        return timestamp != null && timestamp.toDate().isAfter(startOfDay);
      }).length;

      final attendedPrayers = prayerDocs.where((doc) {
        final data = doc.data();
        return data['attended'] == true;
      }).length;

      final avgPrayerAttendance = prayerDocs.isNotEmpty
          ? (attendedPrayers / prayerDocs.length) * 100
          : 0.0;

      
      final completedTasks = taskDocs.where((doc) {
        final data = doc.data();
        return data['status'] == 'completed';
      }).length;

      final pendingTasks = taskDocs.where((doc) {
        final data = doc.data();
        return data['status'] == 'pending';
      }).length;

      
      int totalGroupMembers = 0;
      for (var group in groupDocs) {
        try {
          final data = group.data();
          final members = data['members'] as List?;
          if (members != null) {
            totalGroupMembers += members.length;
          } else {
            
            final membersSnapshot = await FirebaseFirestore.instance
                .collection('groups')
                .doc(group.id)
                .collection('members')
                .get();
            totalGroupMembers += membersSnapshot.docs.length;
          }
        } catch (e) {
          print('Error counting members for group ${group.id}: $e');
        }
      }

      final avgGroupMembers = groupDocs.isNotEmpty
          ? totalGroupMembers / groupDocs.length
          : 0.0;

      
      final activeRoutines = routineDocs.where((doc) {
        final data = doc.data();
        return data['isActive'] == true;
      }).length;

      final routineCompletion = routineDocs.isNotEmpty
          ? (activeRoutines / routineDocs.length) * 100
          : 0.0;

      return {
        'superAdmins': superAdmins,
        'admins': admins,
        'members': members,
        'totalMeetings': meetingDocs.length,
        'avgMeetingAttendance': avgMeetingAttendance,
        'monthlyMeetings': monthlyMeetings,
        'totalPrayers': prayerDocs.length,
        'avgPrayerAttendance': avgPrayerAttendance,
        'todayPrayers': todayPrayers,
        'totalTasks': taskDocs.length,
        'completedTasks': completedTasks,
        'pendingTasks': pendingTasks,
        'totalGroups': groupDocs.length,
        'activeGroups': groupDocs.length,
        'avgGroupMembers': avgGroupMembers,
        'totalRoutines': routineDocs.length,
        'activeRoutines': activeRoutines,
        'routineCompletion': routineCompletion,
      };
    } catch (e) {
      print('Error fetching detailed stats: $e');
      rethrow;
    }
  }
}

extension StreamExtension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}