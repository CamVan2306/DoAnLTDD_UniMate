class SubjectModel {
  final String id;
  final String name;

  SubjectModel({
    required this.id,
    required this.name,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map, String docId) {
    return SubjectModel(
      id: docId,
      name: map['name'] ?? 'Chưa xác định',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
