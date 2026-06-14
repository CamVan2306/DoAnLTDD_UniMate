import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../models/invitation_model.dart';
import '../services/user_service.dart';
import '../services/project_service.dart';
import '../services/group_service.dart';
import '../services/invitation_service.dart';
import '../widgets/dialog_util.dart';
import 'create_group_screen.dart';
import 'lecturer_project_form_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final ProjectModel project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chi tiết đồ án',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: uid == null
          ? const Center(child: Text("Vui lòng đăng nhập lại"))
          : StreamBuilder<UserModel>(
              stream: UserService().streamUser(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = snapshot.data;
                final isStudent = user?.isStudent ?? false;
                final isLecturer = user?.isLecturer ?? false;
                final isOwner = isLecturer && user?.uid == project.lecturerUid;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag môn học
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5EFFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          project.subjectName.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF0056A6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003B73),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Thông tin chung
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.person,
                              'Giảng viên:',
                              project.lecturerName,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Hạn đăng ký:',
                              project.deadline,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              project.projectType == 'Nhóm'
                                  ? Icons.groups
                                  : Icons.person_outline,
                              'Loại hình:',
                              project.projectType,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.data_usage,
                              'Sỉ số hiện tại:',
                              '${project.currentMembers}/${project.maxMembers} sinh viên',
                              valueColor: project.isAvailable
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.info_outline,
                              'Trạng thái:',
                              project.status,
                              valueColor: _getStatusColor(project.status),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Mô tả
                      const Text(
                        'MÔ TẢ ĐỀ TÀI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        project.description.isEmpty
                            ? 'Không có mô tả thêm.'
                            : project.description,
                        style: const TextStyle(
                          height: 1.6,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Yêu cầu
                      const Text(
                        'YÊU CẦU ĐỀ TÀI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        project.requirements.isEmpty
                            ? 'Giảng viên chưa cập nhật yêu cầu.'
                            : project.requirements,
                        style: const TextStyle(
                          height: 1.6,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Thông tin nhóm đã đăng ký (nếu có)
                      if (project.registeredGroupId.isNotEmpty)
                        _buildRegisteredGroupInfo(),

                      // ── NÚT HÀNH ĐỘNG ─
                      if (isStudent)
                        _buildStudentActions(context, uid)
                      else if (isOwner)
                        _buildLecturerActions(context)
                      else
                        // Giảng viên xem đề tài người khác hoặc Admin
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Chỉ Sinh viên mới có quyền thao tác.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Trống':
        return Colors.green;
      case 'Đang gom nhóm':
        return Colors.blue;
      case 'Chờ GV duyệt':
        return Colors.orange;
      case 'Đang triển khai':
        return const Color(0xFF005A9E);
      case 'Đã hoàn tất':
        return Colors.green.shade700;
      case 'Đã khóa':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ── PHẦN SINH VIÊN ───
  Widget _buildStudentActions(BuildContext context, String uid) {
    // Nếu đề tài trống thì cho phép đăng ký
    if (project.isAvailable) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0056A6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateGroupScreen(project: project),
            ),
          ),
          child: const Text(
            'Đăng ký (Mặc định làm Trưởng nhóm)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Nếu đề tài trống nhưng đã hết hạn
    if (project.registeredGroupId.isEmpty && project.status == 'Đã khóa' && project.isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer_off_outlined,
              color: Colors.red.shade700,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đề tài này đã hết hạn đăng ký.',
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (project.registeredGroupId.isNotEmpty &&
        (project.status == 'Đang gom nhóm' ||
            project.status == 'Chờ GV duyệt')) {
      return StreamBuilder<List<InvitationModel>>(
        stream: InvitationService().streamInvitationForGroup(
          myUid: uid,
          groupId: project.registeredGroupId,
        ),
        builder: (context, invSnap) {
          final invitations = invSnap.data ?? [];

          if (invitations.isNotEmpty) {
            // SV có lời mời thì hiện 2 nút Chấp nhận / Từ chối
            final invitation = invitations.first;
            return _buildInvitationActionCard(context, invitation, uid);
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    project.status == 'Đang gom nhóm'
                        ? 'Đề tài đang được một nhóm gom thành viên.'
                        : 'Đề tài đang chờ giảng viên phê duyệt.',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Trạng thái khác (Đang triển khai, Đã hoàn tất…)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Text(
        'Đề tài này đã được nhóm nhận và đang triển khai.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Card hành động khi SV có lời mời pending
  Widget _buildInvitationActionCard(
    BuildContext context,
    InvitationModel invitation,
    String uid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0056A6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                color: Color(0xFF0056A6),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'BẠN ĐƯỢC MỜI VÀO NHÓM NÀY',
                style: TextStyle(
                  color: Color(0xFF0056A6),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nhóm "${invitation.groupName}" đã mời bạn tham gia đề tài này.',
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await InvitationService().declineInvitation(
                      invitationId: invitation.invitationId,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok ? 'Đã từ chối lời mời.' : 'Có lỗi xảy ra!',
                          ),
                          backgroundColor: ok ? Colors.orange : Colors.red,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Từ chối',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showAcceptInvitationDialog(
                      context: context,
                      invitationId: invitation.invitationId,
                      groupId: invitation.groupId,
                      projectId: invitation.projectId,
                      myUid: uid,
                      maxMembers: project.maxMembers,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056A6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Chấp nhận',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PHẦN GIẢNG VIÊN ──
  Widget _buildLecturerActions(BuildContext context) {
    // Đề tài trống thì cho Chỉnh sửa / Xóa
    if (project.status == 'Trống') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LecturerCreateProjectScreen(projectToEdit: project),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Chỉnh sửa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF005A9E),
                side: const BorderSide(color: Color(0xFF005A9E)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Xóa đề tài'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    // Nhóm đang gom thành viên thì hiển thị thông tin trạng thái
    if (project.status == 'Đang gom nhóm') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.group_add_outlined,
              color: Colors.blue.shade700,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nhóm đang trong giai đoạn gom thành viên. Hệ thống sẽ tự động thông báo khi nhóm đã chốt danh sách.',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Nhóm chờ GV duyệt thì hiện 2 nút Chấp nhận / Từ chối
    if (project.status == 'Chờ GV duyệt') {
      return _buildLecturerApprovalButtons(context);
    }

    // Đang triển khai hoặc Đã hoàn tất thì thông báo
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green.shade700,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đề tài đang được triển khai. Theo dõi tiến độ trong NHÓM.',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturerApprovalButtons(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('projectId', isEqualTo: project.projectId)
          .where('status', isEqualTo: 'Chờ GV duyệt')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final groupDoc = snap.data!.docs.first;
        final groupId = groupDoc.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pending_actions_outlined,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nhóm đã chốt danh sách và đang chờ bạn phê duyệt.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmReject(context, groupId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveGroup(context, groupId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Chấp nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveGroup(BuildContext context, String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phê duyệt nhóm'),
        content: const Text('Xác nhận chấp nhận nhóm này thực hiện đề tài?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Duyệt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final ok = await GroupService().reviewGroupRegistration(
        groupId: groupId,
        projectId: project.projectId,
        status: 'Đã duyệt',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã duyệt nhóm thành công!' : 'Có lỗi xảy ra!'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        if (ok) Navigator.pop(context);
      }
    }
  }

  Future<void> _confirmReject(BuildContext context, String groupId) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối nhóm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đề tài sẽ trở về trạng thái Trống. Lý do từ chối:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do (tùy chọn)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final ok = await GroupService().reviewGroupRegistration(
        groupId: groupId,
        projectId: project.projectId,
        status: 'Từ chối',
        cancelReason: reasonController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Đã từ chối nhóm. Đề tài trở về trống.' : 'Có lỗi xảy ra!',
            ),
            backgroundColor: ok ? Colors.orange : Colors.red,
          ),
        );
        if (ok) Navigator.pop(context);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa đề tài'),
        content: Text(
          'Bạn có chắc chắn muốn xóa đề tài "${project.title}" không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await ProjectService().deleteProject(project.projectId);
      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa đề tài thành công.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa thất bại. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Khối thông tin nhóm đã đăng ký đề tài
  Widget _buildRegisteredGroupInfo() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('projectId', isEqualTo: project.projectId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final groupData =
            snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final groupName = groupData['groupName'] ?? 'Không tên';
        final memberUids = List<String>.from(groupData['memberUids'] ?? []);
        final leaderUid = groupData['leaderUid'] ?? '';
        final groupStatus = groupData['status'] ?? '';

        Color statusColor;
        switch (groupStatus) {
          case 'Đang gom nhóm':
            statusColor = Colors.blue;
            break;
          case 'Chờ GV duyệt':
            statusColor = Colors.orange;
            break;
          default:
            statusColor = Colors.grey;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_outlined, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "ĐỀ TÀI ĐÃ CÓ NHÓM NHẬN",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      groupStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Text(
                    "Tên nhóm: ",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Expanded(
                    child: Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Số thành viên đã xác nhận: ${memberUids.length}/${project.maxMembers}",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .where(
                      FieldPath.documentId,
                      whereIn: memberUids.isNotEmpty ? memberUids : ['dummy'],
                    )
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const Text("Đang tải danh sách thành viên...");
                  }
                  final users = userSnap.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isLeader = doc.id == leaderUid;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Row(
                          children: [
                            Icon(
                              isLeader ? Icons.star : Icons.person,
                              size: 16,
                              color: isLeader ? Colors.orange : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${data['name'] ?? 'Không tên'} ${isLeader ? '(Trưởng nhóm)' : ''}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: isLeader
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
