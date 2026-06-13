import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // [SINH VIÊN] Lấy danh sách đồ án theo Lớp học phần
  Stream<List<ProjectModel>> streamProjectsByClass(String courseClass) {
    return _db
        .collection('projects')
        .where('courseClass', isEqualTo: courseClass)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map<ProjectModel>(
                (doc) => ProjectModel.fromMap(doc.data(), doc.id),
              )
              .toList(),
        );
  }

  // [GIẢNG VIÊN] Lấy danh sách đồ án do mình tạo
  Stream<List<ProjectModel>> streamProjectsByLecturer(String lecturerUid) {
    return _db
        .collection('projects')
        .where('lecturerUid', isEqualTo: lecturerUid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map<ProjectModel>(
                (doc) => ProjectModel.fromMap(doc.data(), doc.id),
              )
              .toList(),
        );
  }

  // [ADMIN] Lấy toàn bộ đồ án
  Stream<List<ProjectModel>> streamAllProjects() {
    return _db
        .collection('projects')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map<ProjectModel>(
                (doc) => ProjectModel.fromMap(doc.data(), doc.id),
              )
              .toList(),
        );
  }

  // Lấy đồ án theo ID
  Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      final doc = await _db.collection('projects').doc(projectId).get();
      if (doc.exists && doc.data() != null) {
        return ProjectModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Tạo đồ án mới
  Future<bool> createProject(ProjectModel project) async {
    try {
      await _db.collection('projects').add(project.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Sửa đồ án (Chỉ cho phép khi chưa có nhóm đăng ký)
  Future<bool> updateProject(
    String projectId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection('projects').doc(projectId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Xóa đồ án
  Future<bool> deleteProject(String projectId) async {
    try {
      await _db.collection('projects').doc(projectId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
