import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy Stream User đang đăng nhập
  Stream<UserModel> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // SỬA LỖI: Model mới của bạn chỉ cần truyền Map data, không cần snapshot.id
        return UserModel.fromMap(snapshot.data()!);
      } else {
        throw Exception("Không tìm thấy dữ liệu người dùng!");
      }
    });
  }

  // Tìm User bằng Code (MSSV/MSGV)
  Future<UserModel?> findUserByCode(String code) async {
    try {
      var querySnapshot = await _db
          .collection('users')
          .where('code', isEqualTo: code.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi khi tìm user bằng Mã: $e");
      return null;
    }
  }

  // [ADMIN] Tạo tài khoản mới (Sử dụng Secondary App để không bị đăng xuất Admin)
  Future<bool> createAccountByAdmin(UserModel newUser, String password) async {
    FirebaseApp? tempApp;
    try {
      // 1. Khởi tạo App phụ với tên duy nhất (tránh lỗi trùng tên App)
      String tempAppName = 'TemporaryApp_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );

      // 2. Tạo User trên App phụ
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
              email: newUser.email, password: password);

      if (userCredential.user != null) {
        // 3. Gán UID mới và lưu vào Firestore qua App chính
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          name: newUser.name,
          email: newUser.email,
          code: newUser.code,
          role: newUser.role,
          className: newUser.className,
          phone: newUser.phone,
        );

        await _db
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi tạo tài khoản Admin: $e");
      return false;
    } finally {
      // 4. Xóa App phụ để dọn dẹp
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  // [ADMIN] Lấy danh sách toàn bộ Users (để quản lý)
  Stream<List<UserModel>> streamAllUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }
}
