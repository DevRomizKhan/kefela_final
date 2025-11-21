//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
//
// class ClassRoutineTab extends StatefulWidget {
//   const ClassRoutineTab({super.key});
//
//   @override
//   State<ClassRoutineTab> createState() => _ClassRoutineTabState();
// }
//
// class _ClassRoutineTabState extends State<ClassRoutineTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String, dynamic>> _routines = [];
//   bool _isLoading = true;
//   String _selectedDay = 'Monday';
//   final List<String> _days = [
//     'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchRoutines();
//   }
//
//   Future<void> _fetchRoutines() async {
//     try {
//       final snapshot = await _firestore
//           .collection('routines')
//           .where('day', isEqualTo: _selectedDay)
//           .orderBy('startTime')
//           .get();
//       setState(() {
//         _routines = snapshot.docs.map((doc) {
//           final data = doc.data();
//           return {
//             'id': doc.id,
//             'className': data['className'] ?? 'No Name',
//             'instructor': data['instructor'] ?? 'Unknown',
//             'room': data['room'] ?? 'N/A',
//             'startTime': data['startTime'] ?? 'N/A',
//             'endTime': data['endTime'] ?? 'N/A',
//             'day': data['day'] ?? 'Monday',
//           };
//         }).toList();
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching routines: $e');
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header
//             Card(
//               color: Colors.white,
//               elevation: 4,
//               margin: const EdgeInsets.all(16),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withOpacity(0.2),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.schedule,
//                         color: Colors.green,
//                         size: 24,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     const Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Class Routine',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             'View your class schedule',
//                             style: TextStyle(
//                               color: Colors.black54,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             // Day Selector
//             SizedBox(
//               height: 60,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: _days.length,
//                 itemBuilder: (context, index) {
//                   final day = _days[index];
//                   final isSelected = day == _selectedDay;
//                   return GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         _selectedDay = day;
//                         _isLoading = true;
//                       });
//                       _fetchRoutines();
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isSelected ? Colors.green : Colors.grey[200],
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Center(
//                         child: Text(
//                           day.substring(0, 3),
//                           style: TextStyle(
//                             color: isSelected ? Colors.white : Colors.black54,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 16),
//             // Routine List
//             Expanded(
//               child: _isLoading
//                   ? const Center(child: CircularProgressIndicator(color: Colors.green))
//                   : _routines.isEmpty
//                   ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.schedule, size: 64, color: Colors.grey),
//                     const SizedBox(height: 16),
//                     Text(
//                       'No classes scheduled for $_selectedDay',
//                       style: const TextStyle(color: Colors.black54),
//                     ),
//                   ],
//                 ),
//               )
//                   : ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: _routines.length,
//                 itemBuilder: (context, index) {
//                   final routine = _routines[index];
//                   return Card(
//                     color: Colors.white,
//                     elevation: 2,
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: ListTile(
//                       leading: Container(
//                         width: 50,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           color: Colors.green.withOpacity(0.2),
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Icons.school,
//                           color: Colors.green,
//                         ),
//                       ),
//                       title: Text(
//                         routine['className'],
//                         style: const TextStyle(
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '${routine['startTime']} - ${routine['endTime']}',
//                             style: const TextStyle(color: Colors.black54),
//                           ),
//                           Text(
//                             '${routine['instructor']} • ${routine['room']}',
//                             style: const TextStyle(
//                               color: Colors.black54,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                       trailing: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: _isClassNow(routine['startTime'], routine['endTime'])
//                               ? Colors.green.withOpacity(0.2)
//                               : Colors.transparent,
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: _isClassNow(routine['startTime'], routine['endTime'])
//                                 ? Colors.green
//                                 : Colors.transparent,
//                           ),
//                         ),
//                         child: Text(
//                           _isClassNow(routine['startTime'], routine['endTime'])
//                               ? 'Now'
//                               : 'Upcoming',
//                           style: TextStyle(
//                             color: _isClassNow(routine['startTime'], routine['endTime'])
//                                 ? Colors.green
//                                 : Colors.black54,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   bool _isClassNow(String startTime, String endTime) {
//     final now = TimeOfDay.now();
//     final start = _parseTime(startTime);
//     final end = _parseTime(endTime);
//     return _isTimeBetween(now, start, end);
//   }
//
//   TimeOfDay _parseTime(String timeString) {
//     try {
//       final parts = timeString.split(' ');
//       final timeParts = parts[0].split(':');
//       final hour = int.parse(timeParts[0]);
//       final minute = int.parse(timeParts[1]);
//       final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
//       int adjustedHour = hour;
//       if (isPm && hour != 12) adjustedHour = hour + 12;
//       if (!isPm && hour == 12) adjustedHour = 0;
//       return TimeOfDay(hour: adjustedHour, minute: minute);
//     } catch (e) {
//       return TimeOfDay.now();
//     }
//   }
//
//   bool _isTimeBetween(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
//     final nowInMinutes = now.hour * 60 + now.minute;
//     final startInMinutes = start.hour * 60 + start.minute;
//     final endInMinutes = end.hour * 60 + end.minute;
//     return nowInMinutes >= startInMinutes && nowInMinutes <= endInMinutes;
//   }
// }
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
  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllRoutines();
  }

  Future<void> _fetchAllRoutines() async {
    try {
      final snapshot = await _firestore
          .collection('routines')
          .orderBy('day')
          .orderBy('startTime')
          .get();

      Map<String, List<Map<String, dynamic>>> routinesMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final day = data['day'] ?? 'Monday';

        if (!routinesMap.containsKey(day)) {
          routinesMap[day] = [];
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

      setState(() {
        _allRoutines = routinesMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching routines: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    return DateFormat('EEEE').format(now); // Returns full day name (Monday, Tuesday, etc.)
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = _getCurrentDay();
    final todayRoutines = _allRoutines[currentDay] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
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
                            'Today\'s Class Routine',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$currentDay • ${todayRoutines.length} class${todayRoutines.length != 1 ? 'es' : ''}',
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

            // Routine List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : todayRoutines.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No classes scheduled for today',
                      style: TextStyle(color: Colors.black54),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enjoy your day!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: todayRoutines.length,
                itemBuilder: (context, index) {
                  final routine = todayRoutines[index];
                  return _RoutineItem(routine: routine);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineItem extends StatelessWidget {
  final Map<String, dynamic> routine;

  const _RoutineItem({required this.routine});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isClassNow(routine['startTime'], routine['endTime'])
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isClassNow(routine['startTime'], routine['endTime'])
                    ? 'Now'
                    : 'Upcoming',
                style: TextStyle(
                  color: _isClassNow(routine['startTime'], routine['endTime'])
                      ? Colors.green
                      : Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
    return nowInMinutes >= startInMinutes && nowInMinutes <= endInMinutes;
  }
}
