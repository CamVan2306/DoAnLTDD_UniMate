import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<GroupModel>> streamMyGroups(String myUid) {
    return _db
        .collection('groups')
        .where('memberUids', arrayContains: myUid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<bool> createGroupAndLockProject(
    GroupModel newGroup,
    String projectId, {
    bool isIndividual = false,
  }) async {
    try {
      WriteBatch batch = _db.batch();
      DocumentReference groupRef = _db
          .collection('groups')
          .doc(newGroup.groupId);

      // Khởi tạo 4 mốc tiến độ rỗng cho nhóm mới
      List<Map<String, dynamic>> initialMilestones = List.generate(
        4,
        (index) => {
          'step': index + 1,
          'percent': 25,
          'fileUrl': '',
          'score': 0.0,
          'comment': '',
          'status': 'Chưa nộp', // 'Chưa nộp', 'Đã nộp', 'Đã chấm'
        },
      );

      // Thêm dữ liệu nhóm với status tương ứng
      Map<String, dynamic> groupData = newGroup.toMap();
      groupData['milestones'] = initialMilestones;
      String initialStatus = isIndividual ? 'Chờ GV duyệt' : 'Đang gom nhóm';
      groupData['status'] = initialStatus;
      batch.set(groupRef, groupData);

      DocumentReference projectRef = _db.collection('projects').doc(projectId);
      batch.update(projectRef, {
        'status': initialStatus,
        'registeredGroupId': groupRef.id,
        'currentMembers': 1, // Trưởng nhóm là người đầu tiên
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // [NHÓM TRƯỞNG] Chốt danh sách → Nộp lên Giảng viên duyệt
  Future<bool> submitGroupToLecturer({
    required String groupId,
    required String projectId,
  }) async {
    try {
      WriteBatch batch = _db.batch();
      DocumentReference groupRef = _db.collection('groups').doc(groupId);
      DocumentReference projectRef = _db.collection('projects').doc(projectId);

      batch.update(groupRef, {'status': 'Chờ GV duyệt'});
      batch.update(projectRef, {'status': 'Chờ GV duyệt'});

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // [NHÓM TRƯỞNG] Hủy đăng ký đồ án → Mở khóa đồ án cho nhóm khác
  Future<bool> cancelGroupRegistration(String groupId, String projectId) async {
    try {
      WriteBatch batch = _db.batch();

      // Xóa nhóm
      DocumentReference groupRef = _db.collection('groups').doc(groupId);
      batch.delete(groupRef);

      // Trả đồ án về trạng thái Trống
      DocumentReference projectRef = _db.collection('projects').doc(projectId);
      batch.update(projectRef, {
        'status': 'Trống',
        'registeredGroupId': '',
        'currentMembers': 0,
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // [GIẢNG VIÊN] Chốt duyệt hoặc Từ chối nhóm
  Future<bool> reviewGroupRegistration({
    required String groupId,
    required String projectId,
    required String status, // 'Đã duyệt' hoặc 'Từ chối'
    String cancelReason = '',
  }) async {
    try {
      WriteBatch batch = _db.batch();
      DocumentReference groupRef = _db.collection('groups').doc(groupId);
      DocumentReference projectRef = _db.collection('projects').doc(projectId);

      if (status == 'Đã duyệt') {
        batch.update(groupRef, {'status': 'Đang triển khai'});
        batch.update(projectRef, {'status': 'Đang triển khai'});
      } else {
        // Từ chối → Hủy nhóm, trả đồ án về trạng thái trống
        batch.update(groupRef, {
          'status': 'Từ chối',
          'cancelReason': cancelReason,
        });
        batch.update(projectRef, {
          'status': 'Trống',
          'registeredGroupId': '',
          'currentMembers': 0,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // [SV NỘP BÀI / GV CHẤM ĐIỂM] Cập nhật mốc tiến độ
  Future<bool> updateMilestone(
    String groupId,
    List<dynamic> updatedMilestones,
    int progressPercent,
  ) async {
    try {
      await _db.collection('groups').doc(groupId).update({
        'milestones': updatedMilestones,
        'progressPercent': progressPercent,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // [GIẢNG VIÊN] Hoàn tất đồ án
  Future<bool> completeProject(String groupId, String projectId) async {
    try {
      WriteBatch batch = _db.batch();
      DocumentReference groupRef = _db.collection('groups').doc(groupId);
      DocumentReference projectRef = _db.collection('projects').doc(projectId);

      batch.update(groupRef, {'status': 'Đã hoàn tất', 'progressPercent': 100});
      batch.update(projectRef, {'status': 'Đã hoàn tất'});

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }
}
