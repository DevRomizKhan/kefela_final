import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final List<String> members;
  final List<String> memberNames;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.members,
    required this.memberNames,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      memberNames: List<String>.from(data['memberNames'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'members': members,
      'memberNames': memberNames,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class Member {
  final String uid;
  final String name;
  final String email;

  Member({
    required this.uid,
    required this.name,
    required this.email,
  });

  factory Member.fromMap(String uid, Map<String, dynamic> data) {
    return Member(
      uid: uid,
      name: data['name'] ?? 'Unknown Member',
      email: data['email'] ?? 'No email',
    );
  }
}
