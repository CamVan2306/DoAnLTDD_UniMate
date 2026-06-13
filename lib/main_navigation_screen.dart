import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unimate_huit/screens/profile_screen.dart';
import 'package:unimate_huit/screens/project_list_screen.dart';
import 'package:unimate_huit/screens/my_group_screen.dart';
import 'package:unimate_huit/screens/student_progress_screen.dart';
import 'package:unimate_huit/screens/lecturer_group_management_screen.dart';
import 'package:unimate_huit/screens/lecturer_progress_screen.dart';
import 'package:unimate_huit/screens/admin_dashboard_screen.dart';
import 'package:unimate_huit/screens/admin_management_screen.dart';
import 'package:unimate_huit/screens/pending_invitation_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String userRole;

  const MainNavigationScreen({super.key, this.userRole = 'student'});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFF00346F);
  StreamSubscription? _invitationSub;

  @override
  void initState() {
    super.initState();
    if (widget.userRole == 'student') {
      _listenToInvitations();
    }
  }

  void _listenToInvitations() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _invitationSub = FirebaseFirestore.instance
        .collection('invitations')
        .where('invitee_uid', isEqualTo: user.uid) // Sửa: dùng đúng field name
        .where('status', isEqualTo: 'pending') // Sửa: dùng đúng status value
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                final groupName =
                    data['group_name'] ??
                    'Một nhóm'; // Sửa: dùng đúng field name
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bạn vừa nhận được lời mời tham gia $groupName!',
                      ),
                      backgroundColor: Colors.blue,
                      action: SnackBarAction(
                        label: 'Xem',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PendingInvitationsScreen(),
                            ),
                          );
                        },
                      ),
                      duration: const Duration(seconds: 10),
                    ),
                  );
                }
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _invitationSub?.cancel();
    super.dispose();
  }

  // --- LUỒNG SINH VIÊN ---
  List<Widget> get _studentScreens => [
    const ProjectListScreen(), // Tab 1: Đề tài của lớp
    const MyGroupsScreen(), // Tab 2: Nhóm của tôi
    const StudentProgressScreen(), // Tab 3: Tiến độ báo cáo 4 mốc
    const ProfileScreen(), // Tab 4: Cá nhân
  ];

  // --- LUỒNG GIẢNG VIÊN ---
  List<Widget> get _lecturerScreens => [
    const ProjectListScreen(), // Tab 1: Quản lý đề tài
    const LecturerGroupManagementScreen(), // Tab 2: Quản lý nhóm (Chờ duyệt/Đang triển khai)
    const LecturerProgressScreen(), // Tab 3: Chấm điểm
    const ProfileScreen(), // Tab 4: Cá nhân
  ];

  // --- LUỒNG ADMIN ---
  List<Widget> get _adminScreens => [
    const AdminDashboardScreen(), // Tab 1: Thống kê tổng quan
    const ProjectListScreen(), // Tab 2: Xem toàn bộ dự án toàn trường
    const AdminManagementScreen(), // Tab 3: Can thiệp nhóm
    const ProfileScreen(), // Tab 4: Cá nhân
  ];

  @override
  Widget build(BuildContext context) {
    bool isStudent = widget.userRole == 'student';
    bool isLecturer = widget.userRole == 'lecturer';

    List<Widget> activeScreens;
    List<NavigationDestination> destinations;

    if (isStudent) {
      activeScreens = _studentScreens;
      destinations = _studentDestinations;
    } else if (isLecturer) {
      activeScreens = _lecturerScreens;
      destinations = _lecturerDestinations;
    } else {
      activeScreens = _adminScreens;
      destinations = _adminDestinations;
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: activeScreens),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFFE3F0FA),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              );
            }
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            );
          }),
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.white,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() => _selectedIndex = index);
          },
          destinations: destinations,
        ),
      ),
    );
  }

  // --- ICON & LABEL ĐIỀU HƯỚNG ---
  List<NavigationDestination> get _studentDestinations => [
    NavigationDestination(
      icon: const Icon(Icons.home_outlined, color: Colors.grey),
      selectedIcon: Icon(Icons.home, color: primaryColor),
      label: "ĐỀ TÀI",
    ),
    NavigationDestination(
      icon: const Icon(Icons.people_outline, color: Colors.grey),
      selectedIcon: Icon(Icons.people, color: primaryColor),
      label: "NHÓM",
    ),
    NavigationDestination(
      icon: const Icon(Icons.bar_chart_outlined, color: Colors.grey),
      selectedIcon: Icon(Icons.bar_chart, color: primaryColor),
      label: "TIẾN ĐỘ",
    ),
    NavigationDestination(
      icon: const Icon(Icons.person_outline, color: Colors.grey),
      selectedIcon: Icon(Icons.person, color: primaryColor),
      label: "CÁ NHÂN",
    ),
  ];

  List<NavigationDestination> get _lecturerDestinations => [
    NavigationDestination(
      icon: const Icon(Icons.add_box_outlined, color: Colors.grey),
      selectedIcon: Icon(Icons.add_box, color: primaryColor),
      label: "ĐỀ TÀI",
    ),
    NavigationDestination(
      icon: const Icon(Icons.fact_check_outlined, color: Colors.grey),
      selectedIcon: Icon(Icons.fact_check, color: primaryColor),
      label: "NHÓM",
    ),
    NavigationDestination(
      icon: const Icon(Icons.grading_outlined, color: Colors.grey),
      selectedIcon: Icon(Icons.grading, color: primaryColor),
      label: "TIẾN ĐỘ",
    ),
    NavigationDestination(
      icon: const Icon(Icons.person_outline, color: Colors.grey),
      selectedIcon: Icon(Icons.person, color: primaryColor),
      label: "CÁ NHÂN",
    ),
  ];

  List<NavigationDestination> get _adminDestinations => [
    NavigationDestination(
      icon: const Icon(Icons.dashboard_outlined, color: Colors.grey),
      selectedIcon: Icon(Icons.dashboard, color: primaryColor),
      label: "TỔNG QUAN",
    ),
    NavigationDestination(
      icon: const Icon(Icons.list_alt_outlined, color: Colors.grey),
      selectedIcon: Icon(Icons.list_alt, color: primaryColor),
      label: "ĐỀ TÀI",
    ),
    NavigationDestination(
      icon: const Icon(Icons.group_outlined, color: Colors.grey),
      selectedIcon: Icon(Icons.group, color: primaryColor),
      label: "QUẢN LÝ",
    ),
    NavigationDestination(
      icon: const Icon(Icons.person_outline, color: Colors.grey),
      selectedIcon: Icon(Icons.person, color: primaryColor),
      label: "CÁ NHÂN",
    ),
  ];
}
