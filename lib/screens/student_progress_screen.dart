import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unimate_huit/widgets/stage_card_widget.dart';
import 'package:unimate_huit/services/group_service.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({Key? key}) : super(key: key);

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  String? selectedGroupId;

  void _showSubmitLinkDialog(BuildContext context, int index, String groupId, List<dynamic> currentMilestones, int currentProgressPercent) {
    TextEditingController linkController = TextEditingController(
      text: currentMilestones[index]['fileUrl'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nộp báo cáo'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(
            hintText: 'Nhập link Google Drive / GitHub...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              String newLink = linkController.text.trim();
              Navigator.pop(context);

              List<dynamic> updatedMilestones = List.from(currentMilestones);
              updatedMilestones[index]['fileUrl'] = newLink;
              updatedMilestones[index]['status'] = 'ĐÃ NỘP';

              await GroupService().updateMilestone(groupId, updatedMilestones, currentProgressPercent);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã nộp bài thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Nộp bài'),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String urlString) async {
    if (urlString.trim().isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Lỗi đăng nhập")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const UniMateAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('memberUids', arrayContains: uid)
            .where('status', whereIn: ['Đang triển khai', 'Đã hoàn tất'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Bạn chưa có nhóm đang triển khai đồ án.'));
          }

          final groups = snapshot.data!.docs;

          if (selectedGroupId == null || !groups.any((doc) => doc.id == selectedGroupId)) {
            selectedGroupId = groups.first.id;
          }

          final currentGroupDoc = groups.firstWhere((doc) => doc.id == selectedGroupId);
          final data = currentGroupDoc.data() as Map<String, dynamic>;
          final String projectName = data['projectName'] ?? 'Chưa rõ đề tài';
          final int progressPercent = data['progressPercent'] ?? 0;
          final List<dynamic> milestones = data['milestones'] ?? [];
          final String groupStatus = data['status'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown chọn đề tài
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedGroupId,
                      items: groups.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final name = d['projectName'] ?? 'Chưa rõ đề tài';
                        final group = d['groupName'] ?? '';
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(
                            "$name ${group.isNotEmpty ? '($group)' : ''}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedGroupId = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00346F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ĐỀ TÀI ĐANG THỰC HIỆN",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        projectName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Progress Bar
                LinearProgressIndicator(
                  value: progressPercent / 100,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 24),

                // Danh sách Mốc (Milestones)
                Column(
                  children: List.generate(milestones.length, (index) {
                    final m = milestones[index];
                    String displayStatus = m['status'] ?? 'CHƯA NỘP';

                    return StageCardWidget(
                      stageNumber: "MỐC ${m['step']}",
                      title: "Giai đoạn ${m['step']} (${m['percent']}%)",
                      description: "Hoàn thành ${m['percent']}% khối lượng công việc.",
                      status: displayStatus,
                      extraContent: Column(
                        children: [
                          if (m['comment'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                "GV góp ý: ${m['comment']}",
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          if (m['score'] != null && m['score'] != 0.0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                "Điểm: ${m['score']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              if (m['fileUrl'].toString().isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () => _openLink(m['fileUrl']),
                                  icon: const Icon(Icons.link, size: 16),
                                  label: const Text('Xem bài'),
                                ),
                              const SizedBox(width: 8),
                              if (displayStatus != 'ĐÃ CHẤM' && groupStatus != 'Đã hoàn tất')
                                ElevatedButton.icon(
                                  onPressed: () => _showSubmitLinkDialog(context, index, currentGroupDoc.id, milestones, progressPercent),
                                  icon: const Icon(Icons.upload, size: 16),
                                  label: Text(
                                    m['fileUrl'].toString().isEmpty ? 'Nộp bài' : 'Sửa link',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

