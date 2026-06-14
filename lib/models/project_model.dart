class ProjectModel {
  final String projectId;
  final String title;
  final String lecturerName;
  final String lecturerUid;
  final int maxMembers;
  final int currentMembers;
  final String deadline;
  final String requirements;
  final String
  status; // Trạng thái: 'Trống', 'Đang gom nhóm','Chờ duyệt', 'Đã duyệt'
  final String subjectName;
  final String courseClass;
  final String projectType; // 'Nhóm' hoặc 'Cá nhân'
  final String
  registeredGroupId; // ID của nhóm đã đăng ký (để khóa không cho nhóm khác đăng ký)
  final String description;

  ProjectModel({
    required this.projectId,
    required this.title,
    required this.lecturerName,
    required this.lecturerUid,
    required this.maxMembers,
    this.currentMembers = 0,
    required this.deadline,
    required this.requirements,
    required this.status,
    this.subjectName = 'Chưa phân loại',
    required this.courseClass,
    required this.projectType,
    this.registeredGroupId = '',
    required this.description,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map, String docId) {
    String currentStatus = map['status'] ?? 'Trống';
    String deadlineStr = map['deadline'] ?? '';

    bool expired = false;
    try {
      if (deadlineStr.isNotEmpty) {
        final parts = deadlineStr.split('/');
        if (parts.length == 3) {
          final deadlineDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
            23,
            59,
            59,
          );
          if (DateTime.now().isAfter(deadlineDate)) {
            expired = true;
          }
        }
      }
    } catch (e) {}

    if (expired && currentStatus == 'Trống') {
      currentStatus = 'Đã khóa';
    }

    return ProjectModel(
      projectId: docId,
      title: map['title'] ?? '',
      lecturerName: map['lecturerName'] ?? '',
      lecturerUid: map['lecturerUid'] ?? '',
      maxMembers:
          map['maxMembers'] ?? (map['projectType'] == 'Cá nhân' ? 1 : 0),
      currentMembers: map['currentMembers'] ?? 0,
      deadline: deadlineStr,
      requirements: map['requirements'] ?? '',
      status: currentStatus,
      subjectName: map['subjectName'] ?? 'Chưa phân loại',
      courseClass: map['courseClass'] ?? 'Dành cho tất cả',
      projectType: map['projectType'] ?? 'Nhóm',
      registeredGroupId: map['registeredGroupId'] ?? '',
      description:
          map['description'] ??
          'Không có mô tả. Thắc mắc vui lòng liên hệ GVHD.',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'lecturerName': lecturerName,
      'lecturerUid': lecturerUid,
      'maxMembers': maxMembers,
      'currentMembers': currentMembers,
      'deadline': deadline,
      'requirements': requirements,
      'status': status,
      'subjectName': subjectName,
      'courseClass': courseClass,
      'projectType': projectType,
      'registeredGroupId': registeredGroupId,
      'description': description,
    };
  }

  // Kiểm tra đề tài đã quá hạn đăng ký chưa
  bool get isExpired {
    try {
      if (deadline.isEmpty) return false;
      final parts = deadline.split('/');
      if (parts.length != 3) return false;
      // Ngày hết hạn tính đến 23:59:59 của ngày đó
      final deadlineDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
        23,
        59,
        59,
      );
      return DateTime.now().isAfter(deadlineDate);
    } catch (e) {
      return false;
    }
  }

  // Hàm kiểm tra đồ án còn trống không và còn hạn
  bool get isAvailable =>
      registeredGroupId.isEmpty && status == 'Trống' && !isExpired;
}
