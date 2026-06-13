import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/invitation_service.dart';

class InviteMemberBottomSheet extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String projectId;
  final String projectName;
  final String currentUid;

  const InviteMemberBottomSheet({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.projectId,
    required this.projectName,
    required this.currentUid,
  });

  static void show(
    BuildContext context, {
    required String groupId,
    required String groupName,
    required String projectId,
    required String projectName,
    required String currentUid,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteMemberBottomSheet(
        groupId: groupId,
        groupName: groupName,
        projectId: projectId,
        projectName: projectName,
        currentUid: currentUid,
      ),
    );
  }

  @override
  State<InviteMemberBottomSheet> createState() =>
      _InviteMemberBottomSheetState();
}

class _InviteMemberBottomSheetState extends State<InviteMemberBottomSheet> {
  final TextEditingController _mssvController = TextEditingController();
  bool _isLoading = false;
  bool _isInviting = false;
  UserModel? _foundUser;
  String _errorMessage = '';

  String? _inviteStatus;

  void _searchUser() async {
    final mssv = _mssvController.text.trim();
    if (mssv.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _foundUser = null;
      _inviteStatus = null;
    });

    final studentData = await InvitationService().findStudentByMSSV(mssv);
    String? status;
    if (studentData != null) {
      status = await InvitationService().checkInvitationStatus(
        groupId: widget.groupId,
        inviteeUid: studentData['uid'],
      );
    }

    setState(() {
      _isLoading = false;
      if (studentData != null) {
        _foundUser = UserModel.fromMap(studentData);
        _inviteStatus = status;
      } else {
        _errorMessage = 'Không tìm thấy sinh viên hợp lệ!';
      }
    });
  }

  void _sendInvite() async {
    if (_foundUser == null) return;

    setState(() => _isInviting = true);

    bool success = await InvitationService().sendInvitation(
      groupId: widget.groupId,
      groupName: widget.groupName,
      projectId: widget.projectId,
      projectName: widget.projectName,
      inviterUid: widget.currentUid,
      inviteeUid: _foundUser!.uid,
    );

    setState(() => _isInviting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lời mời thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi lời mời thất bại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mssvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thêm thành viên',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mssvController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Nhập MSSV cần tìm...',
                    filled: true,
                    fillColor: const Color(0xFFF0F4F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _searchUser(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00346F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search, color: Colors.white),
                  onPressed: _isLoading ? null : _searchUser,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          if (_foundUser != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF00346F),
                  child: Text(
                    _foundUser!.name.isNotEmpty
                        ? _foundUser!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  _foundUser!.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(_foundUser!.code),
                trailing: ElevatedButton(
                  onPressed: (_isInviting || _inviteStatus != null)
                      ? null
                      : _sendInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _inviteStatus != null
                        ? Colors.grey
                        : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isInviting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _inviteStatus == 'already_invited'
                              ? 'Đã được mời'
                              : _inviteStatus == 'already_in_group'
                              ? 'Đã tham gia'
                              : 'Mời',
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
