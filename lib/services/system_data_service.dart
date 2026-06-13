import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';
import '../models/classes_model.dart';

class SystemDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- SUBJECTS ---
  Stream<List<SubjectModel>> streamSubjects() {
    return _db.collection('subjects').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // --- CLASSES: Lấy tất cả ---
  Stream<List<CourseClassModel>> streamAllClasses() {
    return _db.collection('classes').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CourseClassModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // --- CLASSES: Lọc theo subjectId ---
  Stream<List<CourseClassModel>> streamClassesBySubject(String subjectId) {
    return _db.collection('classes').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CourseClassModel.fromMap(doc.data(), doc.id))
          .where((courseClass) => courseClass.belongsToSubject(subjectId))
          .toList();
    });
  }

  // [ADMIN] Thêm Môn học mới
  Future<void> addSubject(String name) async {
    await _db.collection('subjects').add({'name': name});
  }

  // [ADMIN] Thêm Lớp học phần mới
  Future<void> addClass({
    required String name,
    required String subjectId,
  }) async {
    // 1. Kiểm tra xem tên lớp đã tồn tại chưa
    final querySnapshot = await _db
        .collection('classes')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Đã tồn tại -> Cập nhật thêm môn học vào lớp này
      final docId = querySnapshot.docs.first.id;
      final data = querySnapshot.docs.first.data();

      List<String> currentSubjectIds = [];
      if (data['subjectId'] is List) {
        currentSubjectIds = List<String>.from(data['subjectId']);
      } else if (data['subjectId'] is String) {
        currentSubjectIds = [data['subjectId']];
      }

      // Nếu lớp chưa có môn này thì thêm vào
      if (!currentSubjectIds.contains(subjectId)) {
        currentSubjectIds.add(subjectId);
        await _db.collection('classes').doc(docId).update({
          'subjectId': currentSubjectIds,
        });
      }
    } else {
      // Chưa tồn tại -> Tạo mới hoàn toàn
      await _db.collection('classes').add({
        'name': name,
        'subjectId': [subjectId],
      });
    }
  }
}
