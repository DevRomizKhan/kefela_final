// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
// class PrayerAttendanceTab extends StatefulWidget {
//   const PrayerAttendanceTab({super.key});
//
//   @override
//   State<PrayerAttendanceTab> createState() => _PrayerAttendanceTabState();
// }
//
// class _PrayerAttendanceTabState extends State<PrayerAttendanceTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   List<PrayerTime> _prayerTimes = [];
//   bool _isLoading = true;
//   int _markedCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializePrayerTimes();
//     _fetchTodayAttendance();
//   }
//
//   void _initializePrayerTimes() {
//     setState(() {
//       _prayerTimes = [
//         PrayerTime(name: 'Fajr', time: '5:30 AM', isMarked: false),
//         PrayerTime(name: 'Dhuhr', time: '1:00 PM', isMarked: false),
//         PrayerTime(name: 'Asr', time: '4:30 PM', isMarked: false),
//         PrayerTime(name: 'Maghrib', time: '6:45 PM', isMarked: false),
//         PrayerTime(name: 'Isha', time: '8:00 PM', isMarked: false),
//       ];
//     });
//   }
//
//   Future<void> _fetchTodayAttendance() async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//         final doc = await _firestore
//             .collection('prayer_attendance')
//             .doc(user.uid)
//             .collection('records')
//             .doc(today)
//             .get();
//         if (doc.exists) {
//           final data = doc.data()!;
//           setState(() {
//             for (var prayer in _prayerTimes) {
//               final prayerKey = prayer.name.toLowerCase();
//               if (data.containsKey(prayerKey) && data[prayerKey] == true) {
//                 prayer.isMarked = true;
//               }
//             }
//             _markedCount = _prayerTimes.where((p) => p.isMarked).length;
//           });
//         }
//       }
//     } catch (e) {
//       print('Error fetching prayer attendance: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final today = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Prayer Attendance',
//               style: TextStyle(
//                 color: Colors.black,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 20,
//               ),
//             ),
//             Text(
//               today,
//               style: const TextStyle(
//                 color: Colors.black54,
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//         centerTitle: false,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.green),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Progress Card
//               Card(
//                 color: Colors.white,
//                 elevation: 4,
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Row(
//                     children: [
//                       // Progress Circle
//                       Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           SizedBox(
//                             width: 80,
//                             height: 80,
//                             child: CircularProgressIndicator(
//                               value: _markedCount / 5,
//                               backgroundColor: Colors.grey[200],
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 _getProgressColor(_markedCount),
//                               ),
//                               strokeWidth: 8,
//                             ),
//                           ),
//                           Column(
//                             children: [
//                               Text(
//                                 '$_markedCount',
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: _getProgressColor(_markedCount),
//                                 ),
//                               ),
//                               Text(
//                                 '/5',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.black54,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       const SizedBox(width: 20),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               _getProgressMessage(_markedCount),
//                               style: const TextStyle(
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Mark your daily prayers using the checkboxes below',
//                               style: TextStyle(
//                                 color: Colors.black54,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // Prayer Times List
//               Expanded(
//                 child: _isLoading
//                     ? const Center(child: CircularProgressIndicator(color: Colors.green))
//                     : ListView.builder(
//                   itemCount: _prayerTimes.length,
//                   itemBuilder: (context, index) {
//                     final prayer = _prayerTimes[index];
//                     return _buildPrayerCard(prayer, index);
//                   },
//                 ),
//               ),
//               // Quick Actions
//               Card(
//                 color: Colors.white,
//                 elevation: 4,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       _buildActionButton(
//                         'Mark All',
//                         Icons.checklist,
//                         Colors.green,
//                         _markAllPrayers,
//                       ),
//                       _buildActionButton(
//                         'Clear All',
//                         Icons.clear_all,
//                         Colors.red,
//                         _clearAllPrayers,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPrayerCard(PrayerTime prayer, int index) {
//     return Card(
//       color: prayer.isMarked
//           ? Colors.green.withOpacity(0.1)
//           : Colors.white,
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: prayer.isMarked
//               ? Colors.green.withOpacity(0.5)
//               : Colors.transparent,
//           width: 2,
//         ),
//       ),
//       child: ListTile(
//         leading: Container(
//           width: 60,
//           height: 60,
//           decoration: BoxDecoration(
//             color: prayer.isMarked
//                 ? Colors.green.withOpacity(0.2)
//                 : Colors.grey[200],
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             Icons.mosque,
//             color: prayer.isMarked ? Colors.green : Colors.black54,
//             size: 30,
//           ),
//         ),
//         title: Text(
//           prayer.name,
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//             decoration: prayer.isMarked ? TextDecoration.lineThrough : null,
//           ),
//         ),
//         subtitle: Text(
//           prayer.time,
//           style: TextStyle(
//             color: prayer.isMarked ? Colors.green : Colors.black54,
//             fontSize: 14,
//           ),
//         ),
//         trailing: Transform.scale(
//           scale: 1.3,
//           child: Checkbox(
//             value: prayer.isMarked,
//             onChanged: (value) => _togglePrayerAttendance(index, value ?? false),
//             activeColor: Colors.green,
//             checkColor: Colors.white,
//             side: BorderSide(
//               color: Colors.black54,
//               width: 2,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       ),
//     );
//   }
//
//   Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
//     return Expanded(
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: onTap,
//             borderRadius: BorderRadius.circular(12),
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: color.withOpacity(0.3)),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(icon, color: color, size: 24),
//                   const SizedBox(height: 8),
//                   Text(
//                     title,
//                     style: TextStyle(
//                       color: color,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _togglePrayerAttendance(int index, bool isMarked) async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         final prayer = _prayerTimes[index];
//         final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//         await _firestore
//             .collection('prayer_attendance')
//             .doc(user.uid)
//             .collection('records')
//             .doc(today)
//             .set({
//           prayer.name.toLowerCase(): isMarked,
//           'date': today,
//           'timestamp': Timestamp.now(),
//           'updatedAt': Timestamp.now(),
//         }, SetOptions(merge: true));
//         setState(() {
//           _prayerTimes[index].isMarked = isMarked;
//           _markedCount = _prayerTimes.where((p) => p.isMarked).length;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               isMarked
//                   ? '${prayer.name} marked as prayed!'
//                   : '${prayer.name} attendance removed',
//             ),
//             backgroundColor: isMarked ? Colors.green : Colors.red.withOpacity(0.2),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error updating attendance: $e'),
//           backgroundColor: Colors.red.withOpacity(0.2),
//         ),
//       );
//     }
//   }
//
//   Future<void> _markAllPrayers() async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//         final Map<String, dynamic> attendanceData = {
//           'date': today,
//           'timestamp': Timestamp.now(),
//           'updatedAt': Timestamp.now(),
//         };
//         for (var prayer in _prayerTimes) {
//           attendanceData[prayer.name.toLowerCase()] = true;
//         }
//         await _firestore
//             .collection('prayer_attendance')
//             .doc(user.uid)
//             .collection('records')
//             .doc(today)
//             .set(attendanceData);
//         setState(() {
//           for (var prayer in _prayerTimes) {
//             prayer.isMarked = true;
//           }
//           _markedCount = 5;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('All prayers marked as prayed!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error marking all prayers: $e'),
//           backgroundColor: Colors.red.withOpacity(0.2),
//         ),
//       );
//     }
//   }
//
//   Future<void> _clearAllPrayers() async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//         await _firestore
//             .collection('prayer_attendance')
//             .doc(user.uid)
//             .collection('records')
//             .doc(today)
//             .delete();
//         setState(() {
//           for (var prayer in _prayerTimes) {
//             prayer.isMarked = false;
//           }
//           _markedCount = 0;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('All prayers cleared!'),
//             backgroundColor: Colors.redAccent,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error clearing prayers: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Color _getProgressColor(int count) {
//     if (count == 5) return Colors.green;
//     if (count >= 3) return Colors.orange;
//     return Colors.red;
//   }
//
//   String _getProgressMessage(int count) {
//     switch (count) {
//       case 0:
//         return 'Start your day with prayers';
//       case 1:
//       case 2:
//         return 'Keep going!';
//       case 3:
//       case 4:
//         return 'Almost there!';
//       case 5:
//         return 'Perfect! All prayers completed';
//       default:
//         return 'Track your prayers';
//     }
//   }
// }
//
// class PrayerTime {
//   final String name;
//   final String time;
//   bool isMarked;
//   PrayerTime({
//     required this.name,
//     required this.time,
//     required this.isMarked,
//   });
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PrayerAttendanceTab extends StatefulWidget {
  const PrayerAttendanceTab({super.key});

  @override
  State<PrayerAttendanceTab> createState() =>
      _PrayerAttendanceTabState();
}

class _PrayerAttendanceTabState extends State<PrayerAttendanceTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<PrayerTime> _prayerTimes = [];
  bool _isLoading = true;
  int _markedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializePrayerTimes();
    _fetchTodayAttendance();
  }

  void _initializePrayerTimes() {
    setState(() {
      _prayerTimes = [
        PrayerTime(name: 'Fajr', time: '5:30 AM', isMarked: false),
        PrayerTime(name: 'Dhuhr', time: '1:00 PM', isMarked: false),
        PrayerTime(name: 'Asr', time: '4:30 PM', isMarked: false),
        PrayerTime(name: 'Maghrib', time: '6:45 PM', isMarked: false),
        PrayerTime(name: 'Isha', time: '8:00 PM', isMarked: false),
      ];
    });
  }

  Future<void> _fetchTodayAttendance() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final doc = await _firestore
            .collection('prayer_attendance')
            .doc(user.uid)
            .collection('records')
            .doc(today)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            for (var prayer in _prayerTimes) {
              final prayerKey = prayer.name.toLowerCase();
              if (data.containsKey(prayerKey) && data[prayerKey] == true) {
                prayer.isMarked = true;
              }
            }
            _markedCount = _prayerTimes.where((p) => p.isMarked).length;
          });
        }
      }
    } catch (e) {
      print('Error fetching prayer attendance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prayer Attendance',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              today,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10,),
              // Prayer Times List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    : ListView.builder(
                  itemCount: _prayerTimes.length,
                  itemBuilder: (context, index) {
                    final prayer = _prayerTimes[index];
                    return _buildPrayerCard(prayer, index);
                  },
                ),
              ),
              // Quick Actions - Buttons will remain at the bottom
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mark All Button
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _markAllPrayers,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.checklist, color: Colors.green,size: 16,),
                                SizedBox(width: 8),
                                Text('Mark All',style: TextStyle(fontSize: 12),),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Vertical divider
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),

                    // Clear All Button
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _clearAllPrayers,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.clear_all, color: Colors.red,size: 16,),
                                SizedBox(width: 8),
                                Text('Clear All',style: TextStyle(fontSize: 12),),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(PrayerTime prayer, int index) {
    return Card(
      color: Colors.white, // Always white background
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Colors.grey, // Always grey border
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => _togglePrayerAttendance(index, !prayer.isMarked),
        onSecondaryTap: () => _togglePrayerAttendance(index, !prayer.isMarked),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Colors.white, // Always white background
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mosque,
              color: prayer.isMarked ? Colors.green : Colors.black.withOpacity(.25), // Only icon changes color
              size: 16,
            ),
          ),
          title: Text(
            prayer.name,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w400,
              fontSize: 16,
              // No line-through decoration
            ),
          ),

          trailing: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _togglePrayerAttendance(index, !prayer.isMarked),
              onSecondaryTap: () => _togglePrayerAttendance(index, !prayer.isMarked),
              child:
              prayer.isMarked ? Container(
                width: 16, // Reduced from 28
                height: 16, // Reduced from 28
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16, // Increased from 12 for better visibility
                ),
              )
                  : Container(
                width: 16, // Reduced from 28
                height: 16, // Reduced from 28
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black54,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
              ),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          minLeadingWidth: 40,
          dense: true,
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _togglePrayerAttendance(int index, bool isMarked) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final prayer = _prayerTimes[index];
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await _firestore
            .collection('prayer_attendance')
            .doc(user.uid)
            .collection('records')
            .doc(today)
            .set({
          prayer.name.toLowerCase(): isMarked,
          'date': today,
          'timestamp': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
        setState(() {
          _prayerTimes[index].isMarked = isMarked;
          _markedCount = _prayerTimes.where((p) => p.isMarked).length;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMarked
                  ? '${prayer.name} marked as prayed!'
                  : '${prayer.name} prayer removed',
            ),
            backgroundColor: isMarked ?
            Colors.green.withOpacity(0.5) :
            Colors.red.withOpacity(0.5),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content : Text('Error updating attendance: $e'),
          backgroundColor : Colors.red.withOpacity(0.5),
        ),
      );
    }
  }

  Future<void> _markAllPrayers() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final Map<String, dynamic> attendanceData = {
          'date': today,
          'timestamp': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };
        for (var prayer in _prayerTimes) {
          attendanceData
          [prayer.name.toLowerCase()] = true;
        }
        await _firestore
            .collection('prayer_attendance')
            .doc(user.uid)
            .collection('records')
            .doc(today)
            .set(attendanceData);
        setState(() {
          for (var prayer in _prayerTimes) {
            prayer.isMarked = true;
          }
          _markedCount = 5;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All prayers marked as prayed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking all prayers: $e'),
          backgroundColor: Colors.red.withOpacity(0.2),
        ),
      );
    }
  }

  Future<void> _clearAllPrayers() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await _firestore
            .collection('prayer_attendance')
            .doc(user.uid)
            .collection('records')
            .doc(today)
            .delete();
        setState(() {
          for (var prayer in _prayerTimes) {
            prayer.isMarked = false;
          }
          _markedCount = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All prayers cleared!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing prayers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class PrayerTime {
  final String name;
  final String time;
  bool isMarked;
  PrayerTime({
    required this.name,
    required this.time,
    required this.isMarked,
  });
}
