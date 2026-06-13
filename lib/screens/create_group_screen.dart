import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/group_model.dart'; // BỔ SUNG: Import GroupModel
import '../services/invitation_service.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';

class CreateGroupScreen extends StatefulWidget {
  final ProjectModel project;
  const CreateGroupScreen({super.key, required this.project});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _mssvController = TextEditingController();

  List<UserModel> addedMembers = [];
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLeader();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _mssvController.dispose();
    super.dispose();
  }

  void _loadCurrentLeader() async {
    try {
      final user = await UserService().streamUser(myUid).first;
      if (mounted) {
        setState(() {
          addedMembers.add(user); // Người đăng ký mặc định làm Trưởng nhóm
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thông tin người dùng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addNewMember() async {
    final mssv = _mssvController.text.trim();
    if (mssv.isEmpty) return;

    if (addedMembers.length >= widget.project.maxMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nhóm đã đạt số lượng tối đa ${widget.project.maxMembers} thành viên!',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (addedMembers.any((m) => m.code == mssv)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sinh viên này đã nằm trong danh sách!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Đóng bàn phím khi bấm tìm kiếm
    FocusManager.instance.primaryFocus?.unfocus();

    final studentData = await InvitationService().findStudentByMSSV(mssv);
    if (studentData != null) {
      setState(() {
        addedMembers.add(UserModel.fromMap(studentData));
        _mssvController.clear();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy sinh viên hợp lệ!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submitGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đặt tên cho nhóm/cá nhân!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // FIX: 1. Tự sinh ID nhóm trước khi đẩy lên Firebase
    final String newGroupId = FirebaseFirestore.instance
        .collection('groups')
        .doc()
        .id;

    // FIX: 2. Dùng GroupModel thay vì Map để khớp với Service
    final GroupModel newGroup = GroupModel(
      groupId: newGroupId,
      groupName: groupName,
      projectId: widget.project.projectId,
      projectName: widget.project.title,
      lecturerUid: widget.project.lecturerUid,
      leaderUid: myUid,
      memberUids: [
        myUid,
      ], // Khi mới tạo, Database chỉ có Trưởng nhóm. Các bạn khác phải bấm Đồng ý mới vào mảng này.
      status: 'Chờ duyệt',
      progressPercent: 0,
      createdAt: DateTime.now(),
      // Milestones sẽ được Service tự động sinh
    );

    // Gọi hàm Service (trả về bool)
    final bool isSuccess = await GroupService().createGroupAndLockProject(
      newGroup,
      widget.project.projectId,
      isIndividual: widget.project.projectType == 'Cá nhân',
    );

    if (isSuccess) {
      // 3. Gửi lời mời cho các thành viên đã thêm (bỏ qua index 0 là trưởng nhóm)
      for (int i = 1; i < addedMembers.length; i++) {
        await InvitationService().sendInvitation(
          groupId: newGroupId,
          groupName: groupName,
          projectId: widget.project.projectId, // ✅ Truyền đúng projectId
          projectName: widget.project.title,   // ✅ Truyền tên đề tài
          inviterUid: myUid,
          inviteeUid: addedMembers[i].uid,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đăng ký thành công, đề tài đã được khóa để chờ duyệt!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        ); // Về lại trang chủ
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thất bại, vui lòng thử lại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isIndividual = widget.project.projectType == 'Cá nhân';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thiết lập thông tin đăng ký',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Thông tin đồ án ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F0FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF00346F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.title,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF00346F),
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Loại hình: ${widget.project.projectType}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- 2. Tên nhóm ---
              TextField(
                controller: _groupNameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: isIndividual ? 'TÊN ĐẠI DIỆN' : 'TÊN NHÓM DỰ KIẾN',
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF0F4F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF00346F),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- 3. Thêm thành viên (Bị ẨN nếu là cá nhân) ---
              if (!isIndividual) ...[
                Text(
                  'THÊM THÀNH VIÊN (Tối đa ${widget.project.maxMembers} người)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mssvController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Nhập MSSV cần tìm...',
                          hintStyle: const TextStyle(fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF0F4F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00346F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        onPressed: _addNewMember,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Danh sách thành viên đã thêm
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: addedMembers.length,
                  itemBuilder: (context, index) {
                    final user = addedMembers[index];
                    final isLeader = index == 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLeader
                              ? const Color(0xFF00346F)
                              : Colors.grey.shade400,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(user.code),
                        trailing: isLeader
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Trưởng nhóm',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 11,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => setState(
                                  () => addedMembers.removeAt(index),
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],

              // --- 4. Nút Gửi Đăng ký ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00346F),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isIndividual
                              ? 'Xác nhận đăng ký đồ án'
                              : 'Xác nhận gửi đơn tạo nhóm',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
