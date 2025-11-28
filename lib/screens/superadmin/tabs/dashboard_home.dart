import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  // Cache for statistics
  final Map<String, dynamic> _quickStatsCache = {};
  final Map<String, dynamic> _detailedStatsCache = {};
  DateTime? _lastQuickStatsUpdate;
  DateTime? _lastDetailedStatsUpdate;
  final Duration _cacheDuration = const Duration(minutes: 2);

  // Stream controllers
  final StreamController<Map<String, dynamic>> _quickStatsController =
  StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _detailedStatsController =
  StreamController<Map<String, dynamic>>.broadcast();

  // Listeners
  List<StreamSubscription> _listeners = [];

  @override
  void initState() {
    super.initState();
    _initializeListeners();
  }

  @override
  void dispose() {
    _quickStatsController.close();
    _detailedStatsController.close();
    for (var listener in _listeners) {
      listener.cancel();
    }
    super.dispose();
  }

  void _initializeListeners() {
    // Listen to all collections for real-time updates
    _listeners = [
      FirebaseFirestore.instance.collection('users').snapshots().listen((_) {
        _fetchQuickStats(forceRefresh: true);
        _fetchDetailedStats(forceRefresh: true);
      }),
      FirebaseFirestore.instance.collection('meetings').snapshots().listen((_) {
        _fetchQuickStats(forceRefresh: true);
        _fetchDetailedStats(forceRefresh: true);
      }),
      FirebaseFirestore.instance.collection('tasks').snapshots().listen((_) {
        _fetchQuickStats(forceRefresh: true);
        _fetchDetailedStats(forceRefresh: true);
      }),
      FirebaseFirestore.instance.collection('groups').snapshots().listen((_) {
        _fetchQuickStats(forceRefresh: true);
        _fetchDetailedStats(forceRefresh: true);
      }),
    ];

    // Initial data fetch
    _fetchQuickStats();
    _fetchDetailedStats();
  }

  Future<void> _fetchQuickStats({bool forceRefresh = false}) async {
    final now = DateTime.now();

    // Check cache
    if (!forceRefresh &&
        _lastQuickStatsUpdate != null &&
        now.difference(_lastQuickStatsUpdate!) < _cacheDuration &&
        _quickStatsCache.isNotEmpty) {
      return;
    }

    try {
      // Use count queries for better performance
      final counts = await Future.wait([
        FirebaseFirestore.instance.collection('users').count().get(),
        FirebaseFirestore.instance.collection('meetings').count().get(),
        FirebaseFirestore.instance.collection('tasks').count().get(),
        FirebaseFirestore.instance.collection('groups').count().get(),
      ]);

      final stats = {
        'totalUsers': counts[0].count,
        'totalMeetings': counts[1].count,
        'totalTasks': counts[2].count,
        'activeGroups': counts[3].count,
      };

      // Update cache and stream
      _quickStatsCache.clear();
      _quickStatsCache.addAll(stats);
      _lastQuickStatsUpdate = now;

      if (_quickStatsController.hasListener && !_quickStatsController.isClosed) {
        _quickStatsController.add(stats);
      }
    } catch (e) {
      print('Error fetching quick stats: $e');
      // Emit cached data even if there's an error
      if (_quickStatsCache.isNotEmpty && _quickStatsController.hasListener) {
        _quickStatsController.add(_quickStatsCache);
      }
    }
  }

  Future<void> _fetchDetailedStats({bool forceRefresh = false}) async {
    final now = DateTime.now();

    // Check cache
    if (!forceRefresh &&
        _lastDetailedStatsUpdate != null &&
        now.difference(_lastDetailedStatsUpdate!) < _cacheDuration &&
        _detailedStatsCache.isNotEmpty) {
      return;
    }

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Fetch all data in parallel with optimized queries
      final results = await Future.wait([
        // Users with role distribution
        FirebaseFirestore.instance.collection('users').get(),
        // Meetings with date filter for monthly count
        FirebaseFirestore.instance.collection('meetings')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .get(),
        // All meetings for total count
        FirebaseFirestore.instance.collection('meetings').get(),
        // Tasks with status
        FirebaseFirestore.instance.collection('tasks').get(),
        // Groups
        FirebaseFirestore.instance.collection('groups').get(),
        // Routines
        FirebaseFirestore.instance.collection('routines').get(),
        // Today's prayers
        FirebaseFirestore.instance.collection('prayer_attendance')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .get(),
        // All prayers for attendance rate
        FirebaseFirestore.instance.collection('prayer_attendance').get(),
      ]);

      final userDocs = results[0].docs;
      final monthlyMeetingDocs = results[1].docs;
      final allMeetingDocs = results[2].docs;
      final taskDocs = results[3].docs;
      final groupDocs = results[4].docs;
      final routineDocs = results[5].docs;
      final todayPrayerDocs = results[6].docs;
      final allPrayerDocs = results[7].docs;

      // Calculate user distribution
      int superAdmins = 0, admins = 0, members = 0;
      for (var doc in userDocs) {
        final role = doc.data()['role'] as String? ?? 'Member';
        switch (role) {
          case 'SuperAdmin': superAdmins++; break;
          case 'Admin': admins++; break;
          case 'Member': members++; break;
        }
      }

      // Calculate task statistics
      final completedTasks = taskDocs.where((doc) {
        return (doc.data()['status'] as String? ?? '') == 'completed';
      }).length;

      final pendingTasks = taskDocs.where((doc) {
        final status = doc.data()['status'] as String? ?? '';
        return status == 'pending' || status == 'in progress';
      }).length;

      // Calculate prayer statistics
      final attendedPrayers = allPrayerDocs.where((doc) {
        return doc.data()['attended'] == true;
      }).length;

      final avgPrayerAttendance = allPrayerDocs.isNotEmpty
          ? (attendedPrayers / allPrayerDocs.length) * 100
          : 0.0;

      // Calculate group statistics
      int totalGroupMembers = 0;
      for (var group in groupDocs) {
        final data = group.data();
        final members = data['members'] as List?;
        if (members != null) {
          totalGroupMembers += members.length;
        }
      }

      final avgGroupMembers = groupDocs.isNotEmpty
          ? totalGroupMembers / groupDocs.length
          : 0.0;

      // Calculate routine statistics
      final activeRoutines = routineDocs.where((doc) {
        return doc.data()['isActive'] == true;
      }).length;

      final routineCompletion = routineDocs.isNotEmpty
          ? (activeRoutines / routineDocs.length) * 100
          : 0.0;

      // Simplified meeting attendance (you can enhance this based on your actual data structure)
      final avgMeetingAttendance = allMeetingDocs.isNotEmpty && userDocs.isNotEmpty
          ? 75.0 // Placeholder - replace with actual calculation
          : 0.0;

      final stats = {
        'superAdmins': superAdmins,
        'admins': admins,
        'members': members,
        'totalMeetings': allMeetingDocs.length,
        'avgMeetingAttendance': avgMeetingAttendance,
        'monthlyMeetings': monthlyMeetingDocs.length,
        'totalPrayers': allPrayerDocs.length,
        'avgPrayerAttendance': avgPrayerAttendance,
        'todayPrayers': todayPrayerDocs.length,
        'totalTasks': taskDocs.length,
        'completedTasks': completedTasks,
        'pendingTasks': pendingTasks,
        'totalGroups': groupDocs.length,
        'activeGroups': groupDocs.length, // Assuming all groups are active
        'avgGroupMembers': avgGroupMembers,
        'totalRoutines': routineDocs.length,
        'activeRoutines': activeRoutines,
        'routineCompletion': routineCompletion,
      };

      // Update cache and stream
      _detailedStatsCache.clear();
      _detailedStatsCache.addAll(stats);
      _lastDetailedStatsUpdate = now;

      if (_detailedStatsController.hasListener && !_detailedStatsController.isClosed) {
        _detailedStatsController.add(stats);
      }
    } catch (e) {
      print('Error fetching detailed stats: $e');
      // Emit cached data even if there's an error
      if (_detailedStatsCache.isNotEmpty && _detailedStatsController.hasListener) {
        _detailedStatsController.add(_detailedStatsCache);
      }
    }
  }

  Stream<Map<String, dynamic>> get _quickStatsStream {
    return _quickStatsController.stream.startWith(_quickStatsCache);
  }

  Stream<Map<String, dynamic>> get _detailedStatsStream {
    return _detailedStatsController.stream.startWith(_detailedStatsCache);
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchQuickStats(forceRefresh: true),
      _fetchDetailedStats(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildHeader(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickStatsRow(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildDetailedStatistics(context),
                ),
              ),
            ],
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
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time organization analytics',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM dd').format(now),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.green),
                    const SizedBox(width: 6),
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
      stream: _quickStatsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard('Failed to load quick stats');
        }

        final stats = snapshot.data ?? _quickStatsCache;
        final totalUsers = stats['totalUsers'] ?? 0;
        final totalMeetings = stats['totalMeetings'] ?? 0;
        final totalTasks = stats['totalTasks'] ?? 0;
        final activeGroups = stats['activeGroups'] ?? 0;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getCrossAxisCountForQuickStats(context),
          childAspectRatio: _getChildAspectRatioForQuickStats(context),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            _buildQuickStatCard(
              title: 'Total Users',
              value: totalUsers,
              icon: Icons.people_outline,
              color: Colors.green,
            ),
            _buildQuickStatCard(
              title: 'Total Meetings',
              value: totalMeetings,
              icon: Icons.video_library_outlined,
              color: Colors.blue,
            ),
            _buildQuickStatCard(
              title: 'Total Tasks',
              value: totalTasks,
              icon: Icons.assignment_outlined,
              color: Colors.orange,
            ),
            _buildQuickStatCard(
              title: 'Active Groups',
              value: activeGroups,
              icon: Icons.group_outlined,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                Text(
                  _formatNumber(value),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
                child: Icon(Icons.analytics_outlined,
                    color: Colors.green.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detailed Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<Map<String, dynamic>>(
          stream: _detailedStatsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorCard('Failed to load detailed analytics');
            }

            final stats = snapshot.data ?? _detailedStatsCache;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: _getCrossAxisCountForDetailedStats(context),
              childAspectRatio: _getChildAspectRatioForDetailedStats(context),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDetailedStatCard(
                  title: 'User Distribution',
                  icon: Icons.pie_chart_outline,
                  color: Colors.green,
                  stats: [
                    _buildStatItem('Super Admins', stats['superAdmins'] ?? 0),
                    _buildStatItem('Admins', stats['admins'] ?? 0),
                    _buildStatItem('Members', stats['members'] ?? 0),
                  ],
                ),
                _buildDetailedStatCard(
                  title: 'Meeting Analytics',
                  icon: Icons.meeting_room_outlined,
                  color: Colors.blue,
                  stats: [
                    _buildStatItem('Total', stats['totalMeetings'] ?? 0),
                    _buildStatItem(
                      'Avg Attendance',
                      '${stats['avgMeetingAttendance']?.toStringAsFixed(1) ?? '0'}%',
                    ),
                    _buildStatItem('This Month', stats['monthlyMeetings'] ?? 0),
                  ],
                ),
                _buildDetailedStatCard(
                  title: 'Prayer Attendance',
                  icon: Icons.mosque_outlined,
                  color: Colors.orange,
                  stats: [
                    _buildStatItem('Total Records', stats['totalPrayers'] ?? 0),
                    _buildStatItem(
                      'Attendance Rate',
                      '${stats['avgPrayerAttendance']?.toStringAsFixed(1) ?? '0'}%',
                    ),
                    _buildStatItem('Today', stats['todayPrayers'] ?? 0),
                  ],
                ),
                _buildDetailedStatCard(
                  title: 'Task Management',
                  icon: Icons.task_alt,
                  color: Colors.purple,
                  stats: [
                    _buildStatItem('Total', stats['totalTasks'] ?? 0),
                    _buildStatItem('Completed', stats['completedTasks'] ?? 0),
                    _buildStatItem('Pending', stats['pendingTasks'] ?? 0),
                  ],
                ),
              ],
            );
          },
        ),
      ],
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: stats,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
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

  // Responsive layout methods
  int _getCrossAxisCountForQuickStats(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1000) return 4;
    if (width > 600) return 2;
    return 2;
  }

  double _getChildAspectRatioForQuickStats(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1000) return 1.3;
    if (width > 600) return 1.2;
    return 1.1;
  }

  int _getCrossAxisCountForDetailedStats(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1000) return 4;
    if (width > 800) return 2;
    return 1;
  }

  double _getChildAspectRatioForDetailedStats(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1000) return 1.2;
    if (width > 800) return 1.1;
    return 1.0;
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
}

// Extension for stream startWith functionality
extension StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}