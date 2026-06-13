import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Đăng nhập
  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint("Lỗi đăng nhập: $e");
      return null;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Quên mật khẩu (Gửi link reset qua email)
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      debugPrint("Lỗi gửi email reset mật khẩu: $e");
      return false;
    }
  }

  // Lấy Role (student, lecturer, admin)
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] ?? 'student';
      }
      return 'student'; // Mặc định an toàn
    } catch (e) {
      debugPrint("Lỗi khi lấy thông tin quyền: $e");
      return 'student';
    }
  }
}
