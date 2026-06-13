import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimate_huit/screens/invite_member_bottom_sheet.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class GroupDetailScreen extends StatelessWidget {
  final GroupModel group;
  final bool isLeader;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.isLeader,
  });

  bool get _isCompleted => group.status.toUpperCase() == 'ĐÃ HOÀN TẤT';
  bool get _isAssembling => group.status.toUpperCase() == 'ĐANG GOM NHÓM';

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: const UniMateAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- THÔNG TIN NHÓM ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00346F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đề tài: ${group.projectName.isNotEmpty ? group.projectName : "Đang cập nhật..."}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(group.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Trạng thái: ${group.status}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(group.status),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- DANH SÁCH THÀNH VIÊN ---
            const Text(
              'Danh sách thành viên',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<UserModel>>(
              future: _loadMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Không thể tải danh sách thành viên');
                }

                final members = snapshot.data!;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 70,
                      color: Color(0xFFF0F4F8),
                    ),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final bool isMemberLeader = member.uid == group.leaderUid;
                      // Nhóm trưởng có thể xóa thành viên (không phải chính mình),
                      // chỉ khi nhóm đang gom nhóm và chưa hoàn tất
                      final bool canRemove =
                          isLeader &&
                          !isMemberLeader &&
                          _isAssembling &&
                          !_isCompleted;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isMemberLeader
                              ? const Color(0xFF00346F)
                              : const Color(0xFFDCE8F5),
                          child: Text(
                            member.name[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isMemberLeader
                                  ? Colors.white
                                  : const Color(0xFF00346F),
                            ),
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(member.code),
                        trailing: isMemberLeader
                            ? const Chip(
                                label: Text(
                                  'Trưởng nhóm',
                                  style: TextStyle(fontSize: 10),
                                ),
                              )
                            : canRemove
                            ? IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Xóa thành viên',
                                onPressed: () =>
                                    _confirmRemoveMember(context, member),
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // --- TIẾN ĐỘ & ĐIỂM SỐ ---
            if (group.milestones.isNotEmpty || group.finalScore.isNotEmpty) ...[
              const Text(
                'Tiến độ & Điểm số',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    if (group.milestones.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: group.milestones.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF0F4F8)),
                        itemBuilder: (context, index) {
                          final m = group.milestones[index];
                          final score = m['score'] ?? 0.0;
                          return ListTile(
                            title: Text(
                              "Giai đoạn ${m['step']} (${m['percent']}%)",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(m['status'] ?? 'CHƯA NỘP'),
                            trailing: Text(
                              score > 0 ? "Điểm: $score" : "Chưa chấm",
                              style: TextStyle(
                                color: score > 0 ? Colors.red : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    if (group.finalScore.isNotEmpty) ...[
                      if (group.milestones.isNotEmpty)
                        const Divider(height: 1, color: Color(0xFFF0F4F8)),
                      ListTile(
                        title: const Text(
                          "Điểm Tổng Kết",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: group.teacherFeedback.isNotEmpty
                            ? Text("Nhận xét: ${group.teacherFeedback}")
                            : null,
                        trailing: Text(
                          group.finalScore,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],

            // --- CÁC HÀNH ĐỘNG CỦA TRƯỞNG NHÓM ---
            if (isLeader && !_isCompleted) ...[
              // Nút mời thành viên: chỉ hiện khi đang gom nhóm
              if (_isAssembling) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      InviteMemberBottomSheet.show(
                        context,
                        groupId: group.groupId,
                        groupName: group.groupName,
                        projectId: group.projectId,
                        projectName: group.projectName,
                        currentUid: currentUid,
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Mời thêm thành viên'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF00346F)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<List<UserModel>> _loadMembers() async {
    final futures = group.memberUids
        .map((uid) => UserService().streamUser(uid).first)
        .toList();
    return Future.wait(futures);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ĐÃ DUYỆT':
      case 'ĐANG TRIỂN KHAI':
        return Colors.green;
      case 'CHỜ GV DUYỆT':
        return Colors.orange;
      case 'ĐANG GOM NHÓM':
        return Colors.blue;
      case 'HỦY':
      case 'TỪ CHỐI':
        return Colors.red;
      case 'ĐÃ HOÀN TẤT':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    UserModel member,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thành viên'),
        content: Text('Bạn có chắc muốn xóa "${member.name}" khỏi nhóm không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(group.groupId)
            .update({
              'memberUids': FieldValue.arrayRemove([member.uid]),
            });
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(group.projectId)
            .update({'currentMembers': FieldValue.increment(-1)});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa "${member.name}" khỏi nhóm.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Có lỗi xảy ra. Vui lòng thử lại!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
