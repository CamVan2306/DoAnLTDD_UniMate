import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';

class TeacherEvaluationScreen extends StatefulWidget {
  const TeacherEvaluationScreen({Key? key}) : super(key: key);

  @override
  State<TeacherEvaluationScreen> createState() =>
      _TeacherEvaluationScreenState();
}

class _TeacherEvaluationScreenState extends State<TeacherEvaluationScreen> {
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  GroupModel? selectedGroup;
  List<GroupModel> teacherGroups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherGroups();
  }

  Future<void> _fetchTeacherGroups() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      // Lấy các nhóm do giảng viên này hướng dẫn
      var groupsSnap = await FirebaseFirestore.instance
          .collection('groups')
          .where('lecturerUid', isEqualTo: uid)
          .where('status', isEqualTo: 'Đang triển khai')
          .get();

      setState(() {
        teacherGroups = groupsSnap.docs
            .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải nhóm: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _submitEvaluation() async {
    if (selectedGroup == null) return;

    final scoreStr = _scoreController.text.trim();
    if (scoreStr.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập điểm số!'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }
    final score = double.tryParse(scoreStr);
    if (score == null || score < 0 || score > 10) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Điểm phải là số từ 0 đến 10!'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(selectedGroup!.groupId)
          .update({
            'finalScore': _scoreController.text,
            'teacherFeedback': _feedbackController.text,
            'status': 'Đã hoàn tất',
          });

      setState(() {
        teacherGroups.remove(selectedGroup);
        selectedGroup = null;
        _scoreController.clear();
        _feedbackController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hoàn tất đánh giá đồ án!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi cập nhật. Vui lòng thử lại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Đánh giá đồ án',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: teacherGroups.isEmpty
                      ? const Center(
                          child: Text("Không có nhóm nào cần đánh giá."),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: teacherGroups.length,
                          itemBuilder: (context, index) {
                            final group = teacherGroups[index];
                            final isSelected =
                                selectedGroup?.groupId == group.groupId;

                            return Card(
                              elevation: isSelected ? 4 : 0,
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.transparent,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  group.groupName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(group.projectName),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                      )
                                    : null,
                                onTap: () => setState(() {
                                  selectedGroup = group;
                                  _scoreController.text =
                                      ''; // Reset form khi chọn nhóm mới
                                  _feedbackController.text = '';
                                }),
                              ),
                            );
                          },
                        ),
                ),
                if (selectedGroup != null) _buildEvaluationPanel(),
              ],
            ),
    );
  }

  Widget _buildEvaluationPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Đánh giá: ${selectedGroup!.groupName}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _scoreController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Điểm số (0-10)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feedbackController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Nhận xét',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitEvaluation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00346F),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Xác nhận & Hoàn tất',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
