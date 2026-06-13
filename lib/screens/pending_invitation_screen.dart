import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unimate_huit/widgets/dialog_util.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';
import '../models/invitation_model.dart';
import '../services/invitation_service.dart';

class PendingInvitationsScreen extends StatelessWidget {
  const PendingInvitationsScreen({super.key});

  final Color primaryColor = const Color(0xFF00346F);
  final Color backgroundColor = const Color(0xFFF4F7FB);

  @override
  Widget build(BuildContext context) {
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const UniMateAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Lời mời đang chờ",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00346F),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Chấp nhận hoặc từ chối lời mời tham gia nhóm",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<InvitationModel>>(
                stream: InvitationService().streamMyInvitations(myUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Bạn hiện không có lời mời nào.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final invitations = snapshot.data!;
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: invitations.length,
                    itemBuilder: (context, index) {
                      return _buildInvitationCard(
                        context,
                        invitations[index],
                        myUid,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(
    BuildContext context,
    InvitationModel invitation,
    String myUid,
  ) {
    if (invitation.projectId.isEmpty || invitation.inviterUid.isEmpty) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('projects').doc(invitation.projectId).get(),
      builder: (context, projectSnapshot) {
        if (!projectSnapshot.hasData) return const SizedBox.shrink();
        
        final projectData = projectSnapshot.data!.data() as Map<String, dynamic>?;
        if (projectData == null) return const SizedBox.shrink();

        final courseClass = projectData['courseClass'] ?? '';
        final subjectName = projectData['subjectName'] ?? '';
        final currentMembers = projectData['currentMembers'] ?? 0;
        final maxMembers = projectData['maxMembers'] ?? 0;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(invitation.inviterUid).get(),
          builder: (context, userSnapshot) {
            String inviterName = 'Một ai đó';
            if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
              inviterName = (userSnapshot.data!.data() as Map<String, dynamic>)['name'] ?? inviterName;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border(left: BorderSide(color: primaryColor, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Avatar + Tên nhóm
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(
                          invitation.groupName.isNotEmpty
                              ? invitation.groupName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nhóm: ${invitation.groupName}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (invitation.projectName.isNotEmpty)
                              Text(
                                "Đề tài: ${invitation.projectName}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Thông tin chi tiết
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.book, "Môn học", subjectName),
                        const SizedBox(height: 6),
                        _buildDetailRow(Icons.class_, "Lớp", courseClass),
                        const SizedBox(height: 6),
                        _buildDetailRow(Icons.person, "Được mời bởi", inviterName),
                        const SizedBox(height: 6),
                        _buildDetailRow(Icons.group, "Thành viên", "$currentMembers/$maxMembers", isHighlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Bạn nhận được lời mời tham gia nhóm này.",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Từ chối"),
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
                              myUid: myUid,
                              maxMembers: maxMembers, // Truyền đúng maxMembers
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Đồng ý"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          "$label:",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? primaryColor : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
