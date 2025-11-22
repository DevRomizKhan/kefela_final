import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClassRoutineTab extends StatefulWidget {
  const ClassRoutineTab({super.key});

  @override
  State<ClassRoutineTab> createState() => _ClassRoutineTabState();
}

class _ClassRoutineTabState extends State<ClassRoutineTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> _allRoutines = {};
  bool _isLoading = true;
  List<String> _availableDays = []; // Will contain only days that have classes

  @override
  void initState() {
    super.initState();
    _fetchAllRoutines();
  }

  Future <void> _fetchAllRoutines() async {
    try {
      final snapshot = await _firestore
          .collection('routines')
          .orderBy('day')
          .orderBy('startTime')
          .get();

      Map<String, List<Map<String, dynamic>>> routinesMap = {};
      List<String> availableDays = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final day = data['day'] ?? 'Monday';

        if (!routinesMap.containsKey(day)) {
          routinesMap[day] = [];
          availableDays.add(day);
        }

        routinesMap[day]!.add({
          'id': doc.id,
          'className': data['className'] ?? 'No Name',
          'instructor': data['instructor'] ?? 'Unknown',
          'room': data['room'] ?? 'N/A',
          'startTime': data['startTime'] ?? 'N/A',
          'endTime': data['endTime'] ?? 'N/A',
          'day': day,
        });
      }

      // Sort available days according to week order
      final dayOrder = {
        'Friday': 1,
        'Saturday': 2,
        'Sunday': 3,
        'Monday': 4,
        'Tuesday': 5,
        'Wednesday': 6,
        'Thursday': 7,
      };

      availableDays.sort((a, b) => (dayOrder[a] ?? 8).compareTo(dayOrder[b] ?? 8));

      setState( () {
        _allRoutines = routinesMap;
        _availableDays = availableDays;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching routines: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    return DateFormat('EEEE').format(now);
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = _getCurrentDay();

    return Scaffold(
      backgroundColor : Colors.white,
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
                        Icons.schedule,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Class Routine',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${_availableDays.length}'
                                ' day${_availableDays.length != 1 ? 's' : ''} with classes',
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

            // Routine List - All days vertically
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _availableDays.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No classes scheduled',
                      style: TextStyle(color: Colors.black54),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check back later!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                )
                : ListView.builder(
                padding: const EdgeInsets.
                symmetric(horizontal: 16, vertical: 8),
                itemCount: _availableDays.length,
                itemBuilder: (context, dayIndex) {
                  final day = _availableDays[dayIndex];
                  final dayRoutines = _allRoutines[day] ?? [];
                  final isToday = day == currentDay;
                  return _DaySection(
                    day: day,
                    routines: dayRoutines,
                    isToday: isToday,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final String day;
  final List<Map<String, dynamic>> routines;
  final bool isToday;

  const _DaySection({
    required this.day,
    required this.routines,
    required this.isToday,
  });

  @override
  Widget build (BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.
                  symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday ? Colors.green : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.green : Colors.green,
                          fontSize: 16,
                        ),
                      ),
                      if (isToday) ...[
                        SizedBox(width: 6),
                        Icon(Icons.circle, size: 8, color: Colors.green),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '${routines.length} class${routines.length != 1 ? 'es' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Classes List
            Column(
              children: routines.map((routine) =>
                  _RoutineItem(routine: routine)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineItem extends StatelessWidget {
  final Map<String, dynamic> routine;

  const _RoutineItem({ required this.routine });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Time Section
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _isClassNow(routine['startTime'], routine['endTime'])
                  ? Colors.green.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isClassNow(routine['startTime'], routine['endTime'])
                    ? Colors.green
                    : Colors.grey[300]!,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  routine['startTime'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isClassNow(routine['startTime'], routine['endTime'])
                        ? Colors.green
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 20,
                  height: 1,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 2),
                Text(
                  routine['endTime'],
                  style: TextStyle(
                    fontSize: 12,
                    color: _isClassNow(routine['startTime'], routine['endTime'])
                        ? Colors.green
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Class Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine['className'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      routine['instructor'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.room,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      routine['room'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //   decoration: BoxDecoration(
          //     color: _isClassNow(routine['startTime'], routine['endTime'])
          //         ? Colors.green.withOpacity(0.1)
          //         : Colors.green.withOpacity(0.1),
          //     borderRadius : BorderRadius.circular(12),
          //   ),
          //   child: Text(
          //     _isClassNow(routine['startTime'],routine['endTime'])
          //         ? 'Now'
          //         : 'Upcoming',
          //     style: TextStyle(
          //       color: _isClassNow(routine['startTime'], routine['endTime'])
          //           ? Colors.green
          //           : Colors.green,
          //       fontSize: 10,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  bool _isClassNow(String startTime, String endTime) {
    final now = TimeOfDay.now();
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    return _isTimeBetween(now, start, end);
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      int adjustedHour = hour;
      if (isPm && hour != 12) adjustedHour = hour + 12;
      if (!isPm && hour == 12) adjustedHour = 0;
      return TimeOfDay(hour: adjustedHour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  bool _isTimeBetween(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowInMinutes = now.hour * 60 + now.minute;
    final startInMinutes = start.hour * 60 + start.minute;
    final endInMinutes = end.hour * 60 + end.minute;
    return
      nowInMinutes >= startInMinutes && nowInMinutes <= endInMinutes;
  }
}