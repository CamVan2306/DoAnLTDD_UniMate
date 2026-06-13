class CourseClassModel {
  final String id;
  final String name;
  final List<String> subjectIds;

  CourseClassModel({
    required this.id,
    required this.name,
    required this.subjectIds,
  });

  factory CourseClassModel.fromMap(Map<String, dynamic> map, String docId) {
    List<String> parsedSubjectIds = [];
    if (map['subjectId'] is List) {
      parsedSubjectIds = List<String>.from(map['subjectId']);
    } else if (map['subjectId'] is String) {
      parsedSubjectIds = [map['subjectId']];
    }

    return CourseClassModel(
      id: docId,
      name: map['name'] ?? 'Chưa xác định',
      subjectIds: parsedSubjectIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'subjectId': subjectIds};
  }

  // Kiểm tra lớp này có thuộc môn học không
  bool belongsToSubject(String subjectId) {
    return subjectIds.contains(subjectId);
  }
}
