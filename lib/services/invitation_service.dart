import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invitation_model.dart';

class InvitationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tìm sinh viên bằng MSSV
  Future<Map<String, dynamic>?> findStudentByMSSV(String mssv) async {
    try {
      QuerySnapshot query = await _db
          .collection('users')
          .where('code', isEqualTo: mssv.trim())
          .get();

      if (query.docs.isNotEmpty) {
        var userData = query.docs.first.data() as Map<String, dynamic>;
        if (userData['role'] == 'student') {
          userData['uid'] = query.docs.first.id;
          return userData;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Kiểm tra xem sinh viên đã được mời chưa hoặc đã trong nhóm chưa
  Future<String?> checkInvitationStatus({
    required String groupId,
    required String inviteeUid,
  }) async {
    try {
      final groupSnap = await _db.collection('groups').doc(groupId).get();
      if (groupSnap.exists) {
        final data = groupSnap.data() as Map<String, dynamic>;
        final members = List<String>.from(data['memberUids'] ?? []);
        if (members.contains(inviteeUid) || data['leaderUid'] == inviteeUid) {
          return 'already_in_group';
        }
      }

      final invSnap = await _db
          .collection('invitations')
          .where('group_id', isEqualTo: groupId)
          .where('invitee_uid', isEqualTo: inviteeUid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (invSnap.docs.isNotEmpty) {
        return 'already_invited';
      }

      return null;
    } catch (e) {
      return 'error';
    }
  }

  // Gửi lời mời tham gia nhóm
  Future<bool> sendInvitation({
    required String groupId,
    required String groupName,
    required String projectId,
    required String projectName,
    required String inviterUid,
    required String inviteeUid,
  }) async {
    try {
      await _db.collection('invitations').add({
        'group_id': groupId,
        'group_name': groupName,
        'project_id': projectId,
        'project_name': projectName,
        'inviter_uid': inviterUid,
        'invitee_uid': inviteeUid,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Đồng ý tham gia nhóm
  Future<bool> acceptInvitation({
    required String invitationId,
    required String groupId,
    required String projectId,
    required String myUid,
    required int maxMembers,
  }) async {
    try {
      WriteBatch batch = _db.batch();

      // 1. Giấy mời thành 'accepted'
      DocumentReference invRef = _db
          .collection('invitations')
          .doc(invitationId);
      batch.update(invRef, {'status': 'accepted'});

      // 2. Thêm vào mảng memberUids
      DocumentReference groupRef = _db.collection('groups').doc(groupId);
      batch.update(groupRef, {
        'memberUids': FieldValue.arrayUnion([myUid]),
      });

      // 3. Tăng currentMembers bên Project lên 1
      DocumentReference projectRef = _db.collection('projects').doc(projectId);
      batch.update(projectRef, {'currentMembers': FieldValue.increment(1)});

      await batch.commit();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Từ chối lời mời
  Future<bool> declineInvitation({required String invitationId}) async {
    try {
      await _db.collection('invitations').doc(invitationId).update({
        'status': 'declined',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Stream lời mời đang chờ của sinh viên (dùng cho màn hình PendingInvitations)
  Stream<List<InvitationModel>> streamMyInvitations(String myUid) {
    return _db
        .collection('invitations')
        .where('invitee_uid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // [BADGE] Đếm lời mời pending của Sinh viên → dùng cho badge chuông
  Stream<int> streamPendingInvitationsCount(String myUid) {
    return _db
        .collection('invitations')
        .where('invitee_uid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // [BADGE] Đếm nhóm "Chờ GV duyệt" thuộc về Giảng viên → dùng cho badge chuông GV
  Stream<int> streamPendingGroupsCountForLecturer(String lecturerUid) {
    return _db
        .collection('groups')
        .where('lecturerUid', isEqualTo: lecturerUid)
        .where('status', isEqualTo: 'Chờ GV duyệt')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Kiểm tra SV hiện tại có lời mời pending cho nhóm cụ thể không
  Stream<List<InvitationModel>> streamInvitationForGroup({
    required String myUid,
    required String groupId,
  }) {
    return _db
        .collection('invitations')
        .where('invitee_uid', isEqualTo: myUid)
        .where('group_id', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
