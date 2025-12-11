import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../../../../core/constants/firebase_constants.dart';

class GroupsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Group>> getAllGroups() {
    return _firestore
        .collection(FirebaseConstants.groupsCollection)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList());
  }

  Future<List<Member>> getMembers() async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .where('role', isEqualTo: FirebaseConstants.roleMember)
        .limit(100)
        .get();

    return snapshot.docs
        .map((doc) => Member.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> createGroup(Group group) async {
    await _firestore
        .collection(FirebaseConstants.groupsCollection)
        .add(group.toFirestore());
  }

  Future<void> updateGroup(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore
        .collection(FirebaseConstants.groupsCollection)
        .doc(id)
        .update(data);
  }

  Future<void> deleteGroup(String id) async {
    await _firestore
        .collection(FirebaseConstants.groupsCollection)
        .doc(id)
        .delete();
  }
}
