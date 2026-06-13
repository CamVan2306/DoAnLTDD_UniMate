import 'package:flutter/material.dart';
import '../services/invitation_service.dart';
import '../screens/registration_success_screen.dart'; // Import màn hình chúc mừng

// BỔ SUNG: Thêm tham số projectId để cập nhật sỉ số (currentMembers) trên Firebase
void showAcceptInvitationDialog({
  required BuildContext context,
  required String invitationId,
  required String groupId,
  required String projectId,
  required String myUid,
  int maxMembers = 0, // THÊM MỚI: để auto-submit khi đủ người
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- 1. ICON ---
              Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCE8F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_add_outlined,
                  color: Color(0xFF00346F),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. TIÊU ĐỀ ---
              const Text(
                "Xác nhận Đồng ý Lời mời",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // --- 3. NỘI DUNG ---
              const Text(
                "Bạn có chắc chắn muốn tham gia nhóm cho đồ án này không? Bạn chỉ có thể tham gia 1 nhóm duy nhất.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),

              // --- 4. NÚT HỦY ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDDE6F3),
                    foregroundColor: const Color(0xFF00346F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Hủy",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // --- 5. NÚT XÁC NHẬN ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    bool success = await InvitationService().acceptInvitation(
                      invitationId: invitationId,
                      groupId: groupId,
                      projectId: projectId,
                      myUid: myUid,
                      maxMembers: maxMembers, // TRUYỀN VÀO để tự động chuyển trạng thái
                    );

                    // Nếu thành công, chuyển hướng sang trang chúc mừng
                    if (success && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RegistrationSuccessScreen(),
                        ),
                      );
                    } else if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Có lỗi xảy ra, vui lòng thử lại!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00346F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Xác nhận",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
