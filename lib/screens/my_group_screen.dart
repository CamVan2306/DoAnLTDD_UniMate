import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';
import '../models/group_model.dart';
import 'group_detail_screen.dart';
import '../services/group_service.dart';

class MyGroupsScreen extends StatelessWidget {
  const MyGroupsScreen({super.key});

  final Color primaryColor = const Color(0xFF00346F);
  final Color backgroundColor = const Color(0xFFF4F7FB);

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const UniMateAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              "Đồ án / Nhóm của tôi",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GroupModel>>(
              stream: GroupService().streamMyGroups(currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Lỗi: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyStateUI();
                }

                List<GroupModel> myGroups = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: myGroups.length,
                  itemBuilder: (context, index) {
                    GroupModel group = myGroups[index];
                    return _buildGroupCard(context, group, currentUid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'ĐANG GOM NHÓM':
        return Colors.blue.shade50;
      case 'CHỜ GV DUYỆT':
        return Colors.orange.shade50;
      case 'ĐANG TRIỂN KHAI':
        return const Color(0xFFDCE8F5);
      case 'TỪ CHỐI':
      case 'HỦY':
        return Colors.red.shade50;
      case 'ĐÃ HOÀN TẤT':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'ĐANG GOM NHÓM':
        return Colors.blue.shade800;
      case 'CHỜ GV DUYỆT':
        return Colors.orange.shade800;
      case 'ĐANG TRIỂN KHAI':
        return primaryColor;
      case 'TỪ CHỐI':
      case 'HỦY':
        return Colors.red.shade800;
      case 'ĐÃ HOÀN TẤT':
        return Colors.green.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  Widget _buildGroupCard(
    BuildContext context,
    GroupModel group,
    String currentUid,
  ) {
    bool isLeader = group.isLeader(currentUid);

    if (group.projectId.isEmpty || group.leaderUid.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('projects').doc(group.projectId).get(),
      builder: (context, projectSnap) {
        bool isIndividual = false;
        if (projectSnap.hasData && projectSnap.data!.exists) {
          final data = projectSnap.data!.data() as Map<String, dynamic>;
          isIndividual = data['projectType'] == 'Cá nhân';
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags: Trạng thái + Tiến độ
              Row(
                children: [
                  _buildTag(
                    group.status,
                    _getStatusBgColor(group.status),
                    _getStatusTextColor(group.status),
                  ),
                  const SizedBox(width: 8),
                  _buildTag(
                    "Tiến độ: ${group.progressPercent}%",
                    Colors.blue.shade50,
                    Colors.blue.shade800,
                  ),
                  if (isIndividual) ...[
                    const SizedBox(width: 8),
                    _buildTag(
                      "Cá nhân",
                      Colors.purple.shade50,
                      Colors.purple.shade800,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(
                group.projectName.isNotEmpty
                    ? group.projectName
                    : "Đang cập nhật đề tài...",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              
              if (!isIndividual)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    children: [
                      const TextSpan(text: "Nhóm: "),
                      TextSpan(
                        text: group.groupName,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isIndividual) const SizedBox(height: 8),

              // Tên trưởng nhóm
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(group.leaderUid)
                    .get(),
                builder: (context, userSnap) {
                  String leaderName = "Đang tải...";
                  if (userSnap.hasData && userSnap.data!.exists) {
                    leaderName =
                        (userSnap.data!.data() as Map<String, dynamic>)['name'] ??
                        'Không rõ';
                  }
                  return Row(
                    children: [
                      Icon(isIndividual ? Icons.person : Icons.person_pin, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        isIndividual ? "Sinh viên: " : "Trưởng nhóm: ",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Expanded(
                        child: Text(
                          leaderName,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              if (!isIndividual)
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    const Text(
                      "Vai trò của bạn: ",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      isLeader ? "Nhóm trưởng" : "Thành viên",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              if (!isIndividual) const SizedBox(height: 24),
              if (isIndividual) const SizedBox(height: 16),

              // Nút xem chi tiết / quản lý
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GroupDetailScreen(group: group, isLeader: isLeader),
                    ),
                  );
                },
                icon: Icon(
                  isLeader
                      ? Icons.settings_outlined
                      : Icons.remove_red_eye_outlined,
                  size: 18,
                ),
                label: Text(isLeader ? "Quản lý" : "Xem chi tiết"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),

              // Nút "Chốt danh sách & Nộp GV" – chỉ hiện cho Trưởng nhóm ở giai đoạn Gom nhóm
              if (isLeader && group.status == 'Đang gom nhóm') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _submitGroupToLecturer(context, group),
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text(
                      'Chốt danh sách & Nộp GV',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelGroupRegistration(context, group),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text(
                      'Hủy đăng ký đề tài',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _cancelGroupRegistration(BuildContext context, GroupModel group) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đăng ký đề tài'),
        content: const Text(
          'Sau khi hủy, đề tài sẽ được trả về trạng thái trống và nhóm sẽ bị giải thể. Bạn có chắc chắn muốn hủy không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await GroupService().cancelGroupRegistration(
        group.groupId,
        group.projectId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã hủy đăng ký đề tài thành công!'
                  : 'Có lỗi xảy ra, thử lại sau!',
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  void _submitGroupToLecturer(BuildContext context, GroupModel group) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận nộp Đồ án'),
        content: const Text(
          'Sau khi nộp, bạn sẽ không thể thêm/xóa thành viên. Tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Chốt & Nộp'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await GroupService().submitGroupToLecturer(
        groupId: group.groupId,
        projectId: group.projectId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã nộp thành công, chờ GV duyệt!'
                  : 'Có lỗi xảy ra, thử lại sau!',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyStateUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.group_off_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Bạn chưa tham gia nhóm nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Hãy vào danh sách đề tài, chọn một đề tài phù hợp và tạo nhóm hoặc cá nhân.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
