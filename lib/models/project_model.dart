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
    return ProjectModel(
      projectId: docId,
      title: map['title'] ?? '',
      lecturerName: map['lecturerName'] ?? '',
      lecturerUid: map['lecturerUid'] ?? '',
      maxMembers:
          map['maxMembers'] ?? (map['projectType'] == 'Cá nhân' ? 1 : 0),
      currentMembers: map['currentMembers'] ?? 0,
      deadline: map['deadline'] ?? '',
      requirements: map['requirements'] ?? '',
      status: map['status'] ?? 'Trống',
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

  // Hàm kiểm tra đồ án còn trống không
  bool get isAvailable => registeredGroupId.isEmpty && status == 'Trống';
}
