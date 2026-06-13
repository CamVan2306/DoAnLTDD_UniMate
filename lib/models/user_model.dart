class UserModel {
  final String uid;
  final String name;
  final String email;
  final String code; // MSSV/MSGV
  final String role; // 'student', 'lecturer', 'admin'
  final String className; // Đối với SV là Lớp học phần, GV/Admin có thể để rỗng
  final String phone;
  final String? photoUrl; // URL ảnh đại diện (null nếu chưa có)

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.code,
    required this.role,
    required this.className,
    required this.phone,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      code: data['code'] ?? '',
      role: data['role'] ?? 'student',
      className: data['class'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'] as String?, // null nếu chưa có ảnh
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'code': code,
      'role': role,
      'class': className,
      'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl, // chỉ ghi nếu có ảnh
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isLecturer => role == 'lecturer';
  bool get isStudent => role == 'student';
}
