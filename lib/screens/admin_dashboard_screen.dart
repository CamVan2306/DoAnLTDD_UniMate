import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';
import 'project_list_screen.dart';
import 'admin_group_management_screen.dart' as unimate_admin_group;

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  final Color primaryColor = const Color(0xFF00346F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: const UniMateAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('projects').snapshots(),
        builder: (context, projectSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('groups').snapshots(),
            builder: (context, groupSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
                builder: (context, subjectSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('classes').snapshots(),
                    builder: (context, classSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
                        builder: (context, userSnapshot) {
                          if (!projectSnapshot.hasData ||
                              !groupSnapshot.hasData ||
                              !subjectSnapshot.hasData ||
                              !classSnapshot.hasData ||
                              !userSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          // Tính toán dữ liệu từ snapshot
                          final totalProjects = projectSnapshot.data!.docs.length;
                          final totalGroups = groupSnapshot.data!.docs.length;
                          final pendingGroups = groupSnapshot.data!.docs
                              .where((doc) => doc['status'] == 'Chờ duyệt')
                              .length;
                          final availableProjects = projectSnapshot.data!.docs
                              .where((doc) => doc['status'] == 'Trống')
                              .length;
                          final totalSubjects = subjectSnapshot.data!.docs.length;
                          final totalClasses = classSnapshot.data!.docs.length;
                          final totalStudents = userSnapshot.data!.docs
                              .where((doc) => doc['role'] == 'student')
                              .length;
                          final totalLecturers = userSnapshot.data!.docs
                              .where((doc) => doc['role'] == 'lecturer')
                              .length;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GridView.count(
                                  shrinkWrap: true,
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.1,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildStatCard(
                                      title: "Tổng Đồ án",
                                      value: "$totalProjects",
                                      icon: Icons.assignment,
                                      color: Colors.blue,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ProjectListScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildStatCard(
                                      title: "Tổng Nhóm",
                                      value: "$totalGroups",
                                      icon: Icons.group,
                                      color: Colors.indigo,
                                      onTap: () {
                                        import_admin_group_management(context);
                                      },
                                    ),
                                    _buildStatCard(
                                      title: "Nhóm Chờ Duyệt",
                                      value: "$pendingGroups",
                                      icon: Icons.pending_actions,
                                      color: Colors.orange,
                                      onTap: () {
                                        import_admin_group_management(context);
                                      },
                                    ),
                                    _buildStatCard(
                                      title: "Đồ án trống",
                                      value: "$availableProjects",
                                      icon: Icons.event_available,
                                      color: Colors.green,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ProjectListScreen(initialStatusFilter: 'Trống'),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildStatCard(
                                      title: "Tổng Môn Học",
                                      value: "$totalSubjects",
                                      icon: Icons.menu_book,
                                      color: Colors.purple,
                                    ),
                                    _buildStatCard(
                                      title: "Tổng Lớp",
                                      value: "$totalClasses",
                                      icon: Icons.class_,
                                      color: Colors.teal,
                                    ),
                                    _buildStatCard(
                                      title: "Tổng Sinh viên",
                                      value: "$totalStudents",
                                      icon: Icons.school_outlined,
                                      color: Colors.cyan.shade700,
                                    ),
                                    _buildStatCard(
                                      title: "Tổng Giảng viên",
                                      value: "$totalLecturers",
                                      icon: Icons.person_pin_outlined,
                                      color: Colors.deepOrange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void import_admin_group_management(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const unimate_admin_group.AdminGroupManagementScreen(),
      ),
    );
  }
}
