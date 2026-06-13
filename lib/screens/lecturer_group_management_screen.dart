import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import '../services/project_service.dart';
import 'project_detail_screen.dart';

class LecturerGroupManagementScreen extends StatefulWidget {
  const LecturerGroupManagementScreen({super.key});

  @override
  State<LecturerGroupManagementScreen> createState() =>
      _LecturerGroupManagementScreenState();
}

class _LecturerGroupManagementScreenState
    extends State<LecturerGroupManagementScreen> {
  final GroupService _groupService = GroupService();
  final String? lecturerUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (lecturerUid == null) {
      return const Scaffold(
        body: Center(child: Text("Lỗi: Không tìm thấy thông tin đăng nhập.")),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: const UniMateAppBar(
          bottom: TabBar(
            labelColor: Color(0xFF00346F),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF00346F),
            isScrollable: true,
            tabs: [
              Tab(text: "Chờ duyệt"),
              Tab(text: "Triển khai"),
              Tab(text: "Hoàn tất"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            _buildGroupList('Chờ GV duyệt'),
            _buildGroupList('Đang triển khai'),
            _buildGroupList('Đã hoàn tất'),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList(String status) {
    return StreamBuilder<QuerySnapshot>(
      // Truy vấn kết hợp: Lọc theo status VÀ lecturerUid
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('status', isEqualTo: status)
          .where('lecturerUid', isEqualTo: lecturerUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Lỗi truy vấn: Vui lòng kiểm tra Firebase Index trong Console.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Không có nhóm nào ở trạng thái: $status"));
        }

        final groups = snapshot.data!.docs
            .map(
              (doc) => GroupModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return _buildGroupCard(groups[index]);
          },
        );
      },
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.groupName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Đề tài: ${group.projectName}",
              style: const TextStyle(color: Colors.grey),
            ),
            if (group.status == 'Đã hoàn tất' &&
                group.finalScore.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Điểm tổng kết: ${group.finalScore}",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final project = await ProjectService().getProjectById(
                  group.projectId,
                );
                if (project != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProjectDetailScreen(project: project),
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không tìm thấy thông tin đề tài.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.remove_red_eye, size: 16),
              label: const Text('Xem chi tiết đồ án'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00346F),
                side: const BorderSide(color: Color(0xFF00346F)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (group.status == 'Chờ GV duyệt')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _handleReview(group, 'Đang triển khai'),
                      child: const Text(
                        "Duyệt",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _handleReview(group, 'Từ chối'),
                      child: const Text("Từ chối"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _handleReview(GroupModel group, String newStatus) async {
    bool success = await _groupService.reviewGroupRegistration(
      groupId: group.groupId,
      projectId: group.projectId,
      status: newStatus,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Đã cập nhật trạng thái nhóm!" : "Có lỗi xảy ra!",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
