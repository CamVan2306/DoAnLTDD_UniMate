import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationModel {
  final String invitationId;
  final String groupId;
  final String groupName;
  final String projectId;
  final String projectName;
  final String inviterUid;
  final String inviteeUid;
  final String status;
  final DateTime? createdAt;

  InvitationModel({
    required this.invitationId,
    required this.groupId,
    required this.groupName,
    required this.projectId,
    required this.projectName,
    required this.inviterUid,
    required this.inviteeUid,
    required this.status,
    this.createdAt,
  });

  factory InvitationModel.fromMap(Map<String, dynamic> map, String id) {
    return InvitationModel(
      invitationId: id,
      groupId: map['group_id'] ?? '',
      groupName: map['group_name'] ?? '',
      projectId: map['project_id'] ?? '',
      projectName: map['project_name'] ?? '',
      inviterUid: map['inviter_uid'] ?? '',
      inviteeUid: map['invitee_uid'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'project_id': projectId,
      'project_name': projectName,
      'inviter_uid': inviterUid,
      'invitee_uid': inviteeUid,
      'status': status,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
