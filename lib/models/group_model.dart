import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String groupName;
  final String projectId;
  final String projectName;
  final String leaderUid; // Người tạo nhóm mặc định là Leader
  final List<String> memberUids;
  final String lecturerUid;
  final String status; // 'Chờ duyệt', 'Đang triển khai', 'Đã hoàn tất'
  final int progressPercent;
  final DateTime createdAt;
  final String cancelReason;
  final String finalScore;
  final String teacherFeedback;
  final List<dynamic> milestones;

  GroupModel({
    required this.groupId,
    required this.groupName,
    required this.projectId,
    this.projectName = '',
    required this.leaderUid,
    required this.memberUids,
    this.lecturerUid = '',
    required this.status,
    required this.progressPercent,
    required this.createdAt,
    this.cancelReason = '',
    this.milestones = const [],
    this.finalScore = '',
    this.teacherFeedback = '',
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    }

    return GroupModel(
      groupId: docId,
      groupName: map['groupName'] ?? 'Chưa đặt tên',
      projectId: map['projectId'] ?? '',
      projectName: map['projectName'] ?? 'Đang cập nhật...',
      leaderUid: map['leaderUid'] ?? '',
      memberUids: List<String>.from(map['memberUids'] ?? []),
      lecturerUid: map['lecturerUid'] ?? '',
      status: map['status'] ?? 'Chờ duyệt',
      progressPercent: map['progressPercent'] ?? 0,
      cancelReason: map['cancelReason'] ?? '',
      milestones: map['milestones'] ?? [], // Khởi tạo mốc tiến độ
      createdAt: parsedDate, // Sử dụng biến đã được xử lý an toàn
      finalScore: map['finalScore']?.toString() ?? '',
      teacherFeedback: map['teacherFeedback'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'projectId': projectId,
      'projectName': projectName,
      'leaderUid': leaderUid,
      'memberUids': memberUids,
      'lecturerUid': lecturerUid,
      'status': status,
      'progressPercent': progressPercent,
      'cancelReason': cancelReason,
      'milestones': milestones,
      'finalScore': finalScore,
      'teacherFeedback': teacherFeedback,
      'createdAt': Timestamp.fromDate(
        createdAt,
      ), // Đẩy lên Firebase dưới dạng Timestamp chuẩn
    };
  }

  // Phân quyền rõ ràng cho Nhóm trưởng
  bool isLeader(String uid) {
    return leaderUid == uid;
  }

  bool hasMember(String uid) {
    return memberUids.contains(uid);
  }
}
