import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unimate_huit/widgets/stage_card_widget.dart';
import 'package:unimate_huit/services/group_service.dart';
import 'package:unimate_huit/models/group_model.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';
import 'package:url_launcher/url_launcher.dart';

class LecturerProgressScreen extends StatefulWidget {
  const LecturerProgressScreen({Key? key}) : super(key: key);

  @override
  State<LecturerProgressScreen> createState() => _TeacherProgressScreenState();
}

class _TeacherProgressScreenState extends State<LecturerProgressScreen> {
  final String? lecturerUid = FirebaseAuth.instance.currentUser?.uid;

  // FIX: Chỉ lưu groupId thay vì lưu cả Object GroupModel
  String? selectedGroupId;

  @override
  Widget build(BuildContext context) {
    if (lecturerUid == null) {
      return const Scaffold(body: Center(child: Text("Lỗi đăng nhập")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const UniMateAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('lecturerUid', isEqualTo: lecturerUid)
            .where('status', whereIn: ['Đang triển khai', 'Đã hoàn tất'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Giảng viên chưa có nhóm nào."));
          }

          final groups = snapshot.data!.docs
              .map(
                (doc) => GroupModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          // FIX: Gán ID mặc định nếu chưa chọn, hoặc nếu ID đã chọn không còn tồn tại
          if (selectedGroupId == null ||
              !groups.any((g) => g.groupId == selectedGroupId)) {
            selectedGroupId = groups.first.groupId;
          }

          // Tìm lại group dựa trên ID
          final currentGroup = groups.firstWhere(
            (g) => g.groupId == selectedGroupId,
          );

          return Column(
            children: [
              // --- Dropdown chọn nhóm ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: DropdownButton<String>(
                    // FIX: Dropdown kiểu String
                    isExpanded: true,
                    value: selectedGroupId,
                    items: groups
                        .map(
                          (g) => DropdownMenuItem<String>(
                            value: g.groupId,
                            child: Text(
                              g.status.toUpperCase() == 'ĐÃ HOÀN TẤT'
                                  ? "${g.groupName} - Hoàn tất (100%)"
                                  : "${g.groupName} - Tiến độ: ${g.progressPercent}%",
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedGroupId = val);
                      }
                    },
                  ),
                ),
              ),

              // --- Thông tin nhóm & Tiến độ ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentGroup.projectName.isNotEmpty
                            ? currentGroup.projectName
                            : "Chưa rõ đề tài",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00346F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentGroup.status.toUpperCase() == 'ĐÃ HOÀN TẤT'
                                ? "Trạng thái: Đã hoàn tất"
                                : "Tiến độ dự án",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "${currentGroup.progressPercent}%",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00346F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: currentGroup.progressPercent / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // --- Danh sách Milestones ---
              Expanded(
                child: currentGroup.milestones.isEmpty
                    ? const Center(
                        child: Text("Nhóm này chưa có mốc tiến độ nào."),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: currentGroup.milestones.length,
                              itemBuilder: (context, index) {
                                final m = currentGroup.milestones[index];

                                // FIX: Đảm bảo biến xử lý an toàn không bị dính null string "null"
                                final comment = m['comment'] ?? '';
                                final fileUrl = m['fileUrl'] ?? '';

                                return StageCardWidget(
                                  stageNumber: "MỐC ${m['step'] ?? index + 1}",
                                  title:
                                      "Giai đoạn ${m['step'] ?? index + 1} (${m['percent'] ?? 0}%)",
                                  description:
                                      "Yêu cầu: ${m['percent'] ?? 0}% khối lượng",
                                  status: m['status'] ?? 'CHƯA NỘP',
                                  extraContent: Column(
                                    children: [
                                        if (comment.toString().trim().isNotEmpty)
                                          Text(
                                            "Nhận xét: $comment",
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        if (m['score'] != null && m['score'] != 0.0)
                                          Text(
                                            "Điểm: ${m['score']}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          if (fileUrl.toString().trim().isNotEmpty)
                                            ElevatedButton.icon(
                                              onPressed: () => launchUrl(
                                                Uri.parse(fileUrl.toString()),
                                              ),
                                              icon: const Icon(Icons.link, size: 16),
                                              label: const Text('Xem bài'),
                                            ),
                                          const SizedBox(width: 8),
                                          if (m['status'] == 'ĐÃ NỘP')
                                            ElevatedButton(
                                              onPressed: () => _showGradeDialog(
                                                context,
                                                index,
                                                currentGroup,
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                              ),
                                              child: const Text(
                                                'Chấm điểm',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  bool confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Hoàn tất đồ án'),
                                      content: const Text('Bạn có chắc chắn muốn đánh dấu đồ án này là đã hoàn tất?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Hủy'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Xác nhận'),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;

                                  if (confirm) {
                                    bool success = await GroupService().completeProject(currentGroup.groupId, currentGroup.projectId);
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã hoàn tất đồ án!'), backgroundColor: Colors.green),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00346F),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Hoàn tất đồ án', style: TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // FIX: Thêm tham số currentGroup để cập nhật chính xác
  void _showGradeDialog(
    BuildContext context,
    int index,
    GroupModel currentGroup,
  ) {
    final milestone = currentGroup.milestones[index];
    final currentScore = milestone['score'];
    TextEditingController feedbackController = TextEditingController(text: milestone['comment']?.toString() ?? '');
    TextEditingController scoreController = TextEditingController(text: currentScore != null && currentScore != 0.0 ? currentScore.toString() : '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chấm điểm giai đoạn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Nhập điểm số (vd: 8.5)...',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập nhận xét...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scoreStr = scoreController.text.trim();
              if (scoreStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập điểm!'), backgroundColor: Colors.red));
                return;
              }
              final score = double.tryParse(scoreStr);
              if (score == null || score < 0 || score > 10) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Điểm phải là số từ 0 đến 10!'), backgroundColor: Colors.red));
                return;
              }

              // Cập nhật mốc
              List<dynamic> updated = List.from(currentGroup.milestones);
              updated[index]['status'] = 'ĐÃ CHẤM';
              updated[index]['comment'] = feedbackController.text.trim();
              updated[index]['score'] = score;

              int newProgressPercent = 0;
              for (var m in updated) {
                if (m['status'] == 'ĐÃ CHẤM') {
                  newProgressPercent += (m['percent'] as num?)?.toInt() ?? 0;
                }
              }

              await GroupService().updateMilestone(
                currentGroup.groupId,
                updated,
                newProgressPercent,
              );

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
