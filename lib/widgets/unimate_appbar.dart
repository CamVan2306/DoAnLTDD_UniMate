import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/pending_invitation_screen.dart';
import '../services/invitation_service.dart';

class UniMateAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const UniMateAppBar({super.key, this.bottom, this.actions});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: Navigator.canPop(context)
          ? null
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {},
                child: uid == null
                    ? const CircleAvatar(
                        backgroundColor: Color(0xFF00346F),
                        child: Text('?', style: TextStyle(color: Colors.white)),
                      )
                    : StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String? photoUrl;
                          String initials = '??';

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            photoUrl = data?['photoUrl'] as String?;
                            final name = (data?['name'] ?? '') as String;
                            final parts = name.trim().split(' ');
                            if (parts.length >= 2) {
                              initials = '${parts.first[0]}${parts.last[0]}'
                                  .toUpperCase();
                            } else if (parts.isNotEmpty &&
                                parts.first.isNotEmpty) {
                              initials = parts.first[0].toUpperCase();
                            }
                          }

                          if (photoUrl != null && photoUrl.isNotEmpty) {
                            return CircleAvatar(
                              backgroundImage: NetworkImage(photoUrl),
                              backgroundColor: const Color(0xFF00346F),
                            );
                          }

                          return CircleAvatar(
                            backgroundColor: const Color(0xFF00346F),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
      title: const Text(
        "UniMate",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      actions: actions ?? [_NotificationBell(uid: uid)],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

class _NotificationBell extends StatelessWidget {
  final String? uid;
  const _NotificationBell({this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return IconButton(
        icon: const Icon(
          Icons.notifications_none_outlined,
          color: Colors.black87,
        ),
        onPressed: () {},
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, userSnap) {
        final role = userSnap.hasData && userSnap.data!.exists
            ? ((userSnap.data!.data() as Map<String, dynamic>?)?['role'] ?? '')
                  as String
            : '';

        Stream<int> badgeStream;
        if (role == 'student') {
          badgeStream = InvitationService().streamPendingInvitationsCount(uid!);
        } else if (role == 'lecturer') {
          badgeStream = InvitationService().streamPendingGroupsCountForLecturer(
            uid!,
          );
        } else {
          return IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black87,
            ),
            onPressed: () => _navigateToNotifications(context, role),
          );
        }

        return StreamBuilder<int>(
          stream: badgeStream,
          builder: (context, countSnap) {
            final count = countSnap.data ?? 0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.black87,
                  ),
                  onPressed: () => _navigateToNotifications(context, role),
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToNotifications(BuildContext context, String role) {
    if (role == 'student') {
      // SV → màn hình lời mời đang chờ
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PendingInvitationsScreen(),
        ),
      );
    } else if (role == 'lecturer') {
      // GV → chuyển sang tab "Chờ GV duyệt" trong màn hình quản lý nhóm
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vào tab NHÓM để xem các nhóm đang chờ duyệt.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF00346F),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
