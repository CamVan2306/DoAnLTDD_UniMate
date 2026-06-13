import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:unimate_huit/models/user_model.dart';
import 'package:unimate_huit/screens/login_screen.dart';
import 'package:unimate_huit/services/user_service.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryColor = const Color(0xFF00346F);
  final Color backgroundColor = const Color(0xFFE9EDF2);
  final Color cardColor = Colors.white;
  final Color textGreyColor = const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: UniMateAppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: currentUid.isEmpty
          ? _buildErrorUI(
              context,
              icon: Icons.login_outlined,
              message: "Phiên đăng nhập đã hết hạn.\nVui lòng đăng nhập lại.",
              showRetry: false,
            )
          : StreamBuilder<UserModel>(
              stream: UserService().streamUser(currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final err = snapshot.error.toString();
                  final bool isNotFound =
                      err.contains('Không tìm thấy') ||
                      err.contains('not found') ||
                      err.contains('No document');
                  return _buildErrorUI(
                    context,
                    icon: isNotFound
                        ? Icons.person_off_outlined
                        : Icons.wifi_off_outlined,
                    message: isNotFound
                        ? "Không tìm thấy thông tin tài khoản.\nVui lòng liên hệ quản trị viên."
                        : "Không thể tải dữ liệu.\nKiểm tra kết nối mạng và thử lại.",
                    showRetry: !isNotFound,
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final UserModel user = snapshot.data!;
                final bool isStudent = user.role == 'student';

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // --- 1. AVATAR ---
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child:
                                  user.photoUrl != null &&
                                      user.photoUrl!.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 46,
                                      backgroundImage: NetworkImage(
                                        user.photoUrl!,
                                      ),
                                      backgroundColor: const Color(0xFFF0F4F8),
                                    )
                                  : CircleAvatar(
                                      radius: 46,
                                      backgroundColor: const Color(0xFFF0F4F8),
                                      child: Text(
                                        _getInitials(user.name),
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _pickAndUploadAvatar(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00346F),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // TÊN
                        Text(
                          user.name.isNotEmpty ? user.name : "Chưa cập nhật",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),

                        // MÃ SỐ
                        Text(
                          isStudent
                              ? "MSSV: ${user.code.isNotEmpty ? user.code : '---'}"
                              : "MSGV: ${user.code.isNotEmpty ? user.code : '---'}",
                          style: TextStyle(fontSize: 16, color: textGreyColor),
                        ),
                        const SizedBox(height: 12),

                        // VAI TRÒ
                        const SizedBox(height: 10),

                        // --- 2. LIÊN HỆ ---
                        _buildInfoCard(
                          children: [
                            _buildInfoRow(
                              Icons.email_outlined,
                              "EMAIL",
                              user.email.isNotEmpty
                                  ? user.email
                                  : "Chưa cập nhật",
                            ),
                            const Divider(
                              height: 20,
                              thickness: 1,
                              color: Color(0xFFF3F4F6),
                            ),
                            _buildInfoRow(
                              Icons.phone_outlined,
                              "SỐ ĐIỆN THOẠI",
                              user.phone.isNotEmpty
                                  ? user.phone
                                  : "Chưa cập nhật",
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // --- 3. HỌC TẬP ---
                        _buildInfoCard(
                          children: [
                            _buildInfoRow(
                              Icons.school_outlined,
                              isStudent ? "LỚP" : "PHÒNG BAN",
                              user.className.isNotEmpty
                                  ? user.className
                                  : "Đang cập nhật",
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // --- 4. QUẢN LÝ TÀI KHOẢN ---
                        _buildSectionTitle("QUẢN LÝ TÀI KHOẢN"),
                        _buildInfoCard(
                          padding: EdgeInsets.zero,
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.security,
                                color: primaryColor,
                              ),
                              title: const Text(
                                "Đổi mật khẩu",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: () => _showChangePasswordDialog(context),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF3F4F6),
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.notifications_none_outlined,
                                color: primaryColor,
                              ),
                              title: const Text(
                                "Cài đặt thông báo",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: () =>
                                  _showNotificationSettingsDialog(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // --- 5. ĐĂNG XUẤT ---
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Đăng xuất'),
                                  content: const Text(
                                    'Bạn có chắc chắn muốn đăng xuất?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Hủy'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Đăng xuất',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              "Đăng xuất",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFEBEB),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildErrorUI(
    BuildContext context, {
    required IconData icon,
    required String message,
    bool showRetry = true,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            if (showRetry) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00346F),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 10.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: textGreyColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Đổi mật khẩu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu cũ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00346F),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (oldPasswordController.text.trim().isEmpty ||
                            newPasswordController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập đầy đủ thông tin!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() => isSubmitting = true);
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && user.email != null) {
                            // Xác thực lại trước khi đổi mật khẩu
                            final cred = EmailAuthProvider.credential(
                              email: user.email!,
                              password: oldPasswordController.text.trim(),
                            );
                            await user.reauthenticateWithCredential(cred);
                            await user.updatePassword(
                              newPasswordController.text.trim(),
                            );

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đổi mật khẩu thành công!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setState(() => isSubmitting = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Lỗi: Mật khẩu cũ không đúng hoặc có sự cố xảy ra!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Cập nhật',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNotificationSettingsDialog(BuildContext context) {
    bool emailNotif = true;
    bool pushNotif = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Cài đặt thông báo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Nhận email thông báo'),
                  value: emailNotif,
                  activeColor: const Color(0xFF00346F),
                  onChanged: (val) => setState(() => emailNotif = val),
                ),
                SwitchListTile(
                  title: const Text('Thông báo đẩy (Push)'),
                  value: pushNotif,
                  activeColor: const Color(0xFF00346F),
                  onChanged: (val) => setState(() => pushNotif = val),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00346F),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã lưu cài đặt thông báo!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Chọn ảnh đại diện',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF00346F),
                ),
                title: const Text('Chọn từ Thư viện'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Đang tải ảnh lên...'),
            ],
          ),
          duration: Duration(seconds: 60),
        ),
      );
    }

    try {
      // 1. Upload lên Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${user.uid}.jpg');
      await ref.putFile(File(pickedFile.path));
      final downloadUrl = await ref.getDownloadURL();

      // 2. Cập nhật Firebase Auth
      await user.updatePhotoURL(downloadUrl);

      // 3. Lưu vào Firestore → AppBar và Profile tự refresh qua stream
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'photoUrl': downloadUrl},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh đại diện thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
