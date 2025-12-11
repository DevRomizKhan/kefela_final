import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Meeting {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String location;
  final String meetingType; // 'General', 'Board', 'Committee'
  final bool isOnline;
  final String? meetingLink;
  final DateTime createdAt;
  final String createdBy;

  Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.meetingType,
    required this.isOnline,
    this.meetingLink,
    required this.createdAt,
    required this.createdBy,
  });

  factory Meeting.fromFirestore(String id, Map<String, dynamic> data) {
    return Meeting(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: _parseTime(data['startTime']),
      endTime: _parseTime(data['endTime']),
      location: data['location'] ?? '',
      meetingType: data['type'] ?? 'General',
      isOnline: data['isOnline'] ?? false,
      meetingLink: data['meetingLink'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  static TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null) return const TimeOfDay(hour: 0, minute: 0);
    final parts = timeStr.split(':');
    final hourPart = parts[0];
    final minutePart = parts[1].split(' ')[0];
    final isPM = timeStr.contains('PM');
    
    int hour = int.parse(hourPart);
    int minute = int.parse(minutePart);
    
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    
    return TimeOfDay(hour: hour, minute: minute);
  }

  String get formattedDate => 
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
  String get formattedStartTime {
    final hour = startTime.hourOfPeriod == 0 ? 12 : startTime.hourOfPeriod;
    final period = startTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${startTime.minute.toString().padLeft(2, '0')} $period';
  }

  String get formattedEndTime {
    final hour = endTime.hourOfPeriod == 0 ? 12 : endTime.hourOfPeriod;
    final period = endTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${endTime.minute.toString().padLeft(2, '0')} $period';
  }
}
