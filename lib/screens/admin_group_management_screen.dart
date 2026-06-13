import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimate_huit/services/system_data_service.dart';
import 'package:unimate_huit/models/subject_model.dart';
import 'package:unimate_huit/models/classes_model.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';
import 'package:unimate_huit/services/project_service.dart';
import 'package:unimate_huit/screens/project_detail_screen.dart';

class AdminGroupManagementScreen extends StatefulWidget {
  const AdminGroupManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminGroupManagementScreen> createState() =>
      _AdminGroupManagementScreenState();
}

class _AdminGroupManagementScreenState
    extends State<AdminGroupManagementScreen> {
  String? selectedSubjectFilter;
  String? selectedClassFilter;
  String? selectedStatusFilter;

  late Stream<List<SubjectModel>> _subjectStream;
  late Stream<List<CourseClassModel>> _classStream;

  @override
  void initState() {
    super.initState();
    _subjectStream = SystemDataService().streamSubjects();
    _classStream = SystemDataService().streamAllClasses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const UniMateAppBar(),
      body: Column(
        children: [

          // Row chứa các bộ lọc (Môn, Lớp, Trạng thái)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<SubjectModel>>(
                        stream: _subjectStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final subjects = snapshot.data!;
                          return DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Tất cả môn học'),
                            value: selectedSubjectFilter,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Tất cả môn học'),
                              ),
                              ...subjects.map(
                                (s) => DropdownMenuItem(
                                  value: s.name,
                                  child: Text(
                                    s.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => selectedSubjectFilter = val),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StreamBuilder<List<CourseClassModel>>(
                        stream: _classStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final classes = snapshot.data!;
                          return DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Tất cả lớp'),
                            value: selectedClassFilter,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Tất cả lớp'),
                              ),
                              ...classes.map(
                                (c) => DropdownMenuItem(
                                  value: c.name,
                                  child: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => selectedClassFilter = val),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Tất cả trạng thái'),
                        value: selectedStatusFilter,
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Tất cả trạng thái'),
                          ),
                          DropdownMenuItem(
                            value: 'Đang gom nhóm',
                            child: Text('Đang gom nhóm'),
                          ),
                          DropdownMenuItem(
                            value: 'Chờ duyệt',
                            child: Text('Chờ duyệt'),
                          ),
                          DropdownMenuItem(
                            value: 'Chờ GV duyệt',
                            child: Text('Chờ GV duyệt'),
                          ),
                          DropdownMenuItem(
                            value: 'Đang triển khai',
                            child: Text('Đang triển khai'),
                          ),
                          DropdownMenuItem(
                            value: 'Đã hoàn tất',
                            child: Text('Đã hoàn tất'),
                          ),
                          DropdownMenuItem(
                            value: 'Từ chối',
                            child: Text('Từ chối'),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => selectedStatusFilter = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Danh sách các nhóm (kết hợp với projects để lấy được môn/lớp)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .snapshots(),
              builder: (context, projectSnap) {
                if (projectSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!projectSnap.hasData) return const SizedBox();

                // Tạo map để tra cứu thông tin dự án
                Map<String, Map<String, dynamic>> projectMap = {};
                for (var doc in projectSnap.data!.docs) {
                  projectMap[doc.id] = doc.data() as Map<String, dynamic>;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .snapshots(),
                  builder: (context, groupSnap) {
                    if (groupSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!groupSnap.hasData || groupSnap.data!.docs.isEmpty) {
                      return _buildEmptyState(
                        'Chưa có nhóm nào trong hệ thống.',
                      );
                    }

                    // Lọc dữ liệu
                    List<QueryDocumentSnapshot> filteredGroups = groupSnap
                        .data!
                        .docs
                        .where((groupDoc) {
                          final groupData =
                              groupDoc.data() as Map<String, dynamic>;
                          final projectId = groupData['projectId'] ?? '';
                          final projectData = projectMap[projectId] ?? {};

                          final subjectName = projectData['subjectName'] ?? '';
                          final className = projectData['courseClass'] ?? '';
                          final status = groupData['status'] ?? '';

                          if (selectedSubjectFilter != null &&
                              subjectName != selectedSubjectFilter)
                            return false;
                          if (selectedClassFilter != null &&
                              className != selectedClassFilter)
                            return false;
                          if (selectedStatusFilter != null &&
                              status != selectedStatusFilter)
                            return false;

                          return true;
                        })
                        .toList();

                    if (filteredGroups.isEmpty) {
                      return _buildEmptyState(
                        'Không tìm thấy nhóm phù hợp với bộ lọc.',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredGroups.length,
                      itemBuilder: (context, index) {
                        final groupData =
                            filteredGroups[index].data()
                                as Map<String, dynamic>;
                        final groupId = filteredGroups[index].id;
                        final projectId = groupData['projectId'] ?? '';
                        final projectData = projectMap[projectId] ?? {};
                        final status = groupData['status'] ?? 'KHÔNG RÕ';
                        final lecturerName =
                            projectData['lecturerName'] ?? 'Không rõ';
                        final subjectName =
                            projectData['subjectName'] ?? 'Không rõ';
                        final className =
                            projectData['courseClass'] ?? 'Không rõ';
                        final progressPercent =
                            groupData['progressPercent'] ?? 0;
                        final memberCount =
                            (groupData['memberUids'] as List?)?.length ?? 0;
                        final maxMembers = projectData['maxMembers'] ?? 0;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        groupData['groupName']
                                                ?.toString()
                                                .toUpperCase() ??
                                            'CHƯA ĐẶT TÊN',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF00346F),
                                        ),
                                      ),
                                    ),
                                    _buildStatusBadge(status),
                                  ],
                                ),
                                const Divider(height: 24),
                                Text(
                                  'Đề tài: ${groupData['projectName'] ?? 'Không rõ'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Môn học: $subjectName',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'Lớp: $className',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'GVHD: $lecturerName',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'Thành viên: $memberCount/$maxMembers',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: progressPercent / 100,
                                        backgroundColor: Colors.grey.shade200,
                                        color: Colors.blue,
                                        minHeight: 8,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$progressPercent%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          _showGroupDetailsDialog(
                                            context,
                                            groupData,
                                            projectData,
                                            status,
                                            subjectName,
                                            className,
                                            lecturerName,
                                            memberCount,
                                            maxMembers,
                                            progressPercent,
                                          );
                                        },
                                        child: const Text('Chi tiết nhóm'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final project = await ProjectService().getProjectById(projectId);
                                          if (project != null && context.mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ProjectDetailScreen(project: project),
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
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00346F),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Chi tiết đề tài'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupDetailsDialog(
    BuildContext context,
    Map<String, dynamic> groupData,
    Map<String, dynamic> projectData,
    String status,
    String subjectName,
    String className,
    String lecturerName,
    int memberCount,
    int maxMembers,
    int progressPercent,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(groupData['groupName'] ?? 'Chi tiết nhóm'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Đề tài:', groupData['projectName'] ?? 'Không rõ'),
                _detailRow('Trạng thái:', status),
                _detailRow('Môn học:', subjectName),
                _detailRow('Lớp:', className),
                _detailRow('GVHD:', lecturerName),
                _detailRow('Số lượng TV:', '$memberCount/$maxMembers'),
                _detailRow('Tiến độ:', '$progressPercent%'),
                const Divider(),
                const Text(
                  'Thành viên:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...(groupData['memberUids'] as List<dynamic>? ?? []).map((uid) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text('- Đang tải...');
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      final name = userData?['name'] ?? 'Không rõ';
                      final isLeader = groupData['leaderUid'] == uid;
                      return Text('- $name ${isLeader ? '(Trưởng nhóm)' : ''}');
                    },
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    status = status.toUpperCase();
    if (status == 'ĐÃ DUYỆT' ||
        status == 'ĐÃ HOÀN TẤT' ||
        status == 'ĐANG TRIỂN KHAI') {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (status.contains('HỦY') || status.contains('TỪ CHỐI')) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    } else {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

}
