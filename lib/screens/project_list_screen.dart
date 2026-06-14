import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unimate_huit/services/project_service.dart';
import 'package:unimate_huit/services/system_data_service.dart';
import 'package:unimate_huit/models/subject_model.dart';
import 'package:unimate_huit/models/classes_model.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'project_detail_screen.dart';
import 'lecturer_project_form_screen.dart';

class ProjectListScreen extends StatefulWidget {
  final String? initialStatusFilter;
  const ProjectListScreen({super.key, this.initialStatusFilter});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  String? selectedSubjectFilter;
  String? selectedSubjectId;
  String? selectedClassFilter;

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
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Vui lòng đăng nhập lại")),
      );
    }

    return StreamBuilder<UserModel>(
      stream: UserService().streamUser(uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Không tải được thông tin hệ thống.')),
          );
        }

        final user = userSnapshot.data!;

        Stream<List<ProjectModel>> projectStream;
        if (user.isLecturer) {
          projectStream = ProjectService().streamProjectsByLecturer(user.uid);
        } else {
          projectStream = ProjectService().streamAllProjects();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F8),
          appBar: const UniMateAppBar(),
          floatingActionButton: user.isLecturer
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LecturerCreateProjectScreen(),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF005A9E),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Đăng đề tài",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // --- BỘ LỌC DROPDOWN TỪ FIREBASE ---
                Row(
                  children: [
                    // Dropdown Môn học
                    Expanded(
                      child: StreamBuilder<List<SubjectModel>>(
                        stream: _subjectStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              'Lỗi: ${snapshot.error}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                              ),
                            );
                          }
                          final subjects = snapshot.data ?? [];
                          return _buildDropdownBox(
                            defaultLabel: 'Môn',
                            value: selectedSubjectFilter,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Tất cả',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              ...subjects.map((s) => s.name).toSet().map(
                                (name) => DropdownMenuItem<String?>(
                                  value: name,
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (newValue) {
                              setState(() {
                                selectedSubjectFilter = newValue;
                                if (newValue == null) {
                                  selectedSubjectId = null;
                                  _classStream = SystemDataService()
                                      .streamAllClasses();
                                } else {
                                  final found = subjects.where(
                                    (s) => s.name == newValue,
                                  );
                                  selectedSubjectId = found.isNotEmpty
                                      ? found.first.id
                                      : null;
                                  if (selectedSubjectId != null) {
                                    _classStream = SystemDataService()
                                        .streamClassesBySubject(
                                          selectedSubjectId!,
                                        );
                                  } else {
                                    _classStream = SystemDataService()
                                        .streamAllClasses();
                                  }
                                }
                                selectedClassFilter = null;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    if (!user.isStudent) ...[
                      const SizedBox(width: 12),
                      // Dropdown Lớp học phần
                      Expanded(
                        child: StreamBuilder<List<CourseClassModel>>(
                          stream: _classStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                'Lỗi: ${snapshot.error}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                ),
                              );
                            }
                            final classes = snapshot.data ?? [];
                            if (snapshot.connectionState ==
                                    ConnectionState.active &&
                                selectedClassFilter != null &&
                                !classes.any(
                                  (c) => c.name == selectedClassFilter,
                                )) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() => selectedClassFilter = null);
                                }
                              });
                            }
                            return _buildDropdownBox(
                              defaultLabel: 'Lớp',
                              value: selectedClassFilter,
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(
                                    'Tất cả',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                ...classes.map((c) => c.name).toSet().map(
                                  (name) => DropdownMenuItem<String?>(
                                    value: name,
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (newValue) {
                                setState(() => selectedClassFilter = newValue);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  user.isLecturer
                      ? 'Đồ án của tôi'
                      : (user.isAdmin ? 'Quản lý Đồ án' : 'Danh sách đề tài'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003B73),
                  ),
                ),
                const SizedBox(height: 12),

                // --- DANH SÁCH ĐỒ ÁN ---
                Expanded(
                  child: StreamBuilder<List<ProjectModel>>(
                    stream: projectStream,
                    builder: (context, projectSnapshot) {
                      if (projectSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!projectSnapshot.hasData ||
                          projectSnapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Chưa có đồ án nào trong hệ thống.'),
                        );
                      }

                      var projects = projectSnapshot.data!;

                      // --- LỌC TỰ ĐỘNG CHO SINH VIÊN ---
                      // Sinh viên chỉ thấy đồ án thuộc lớp của mình (hoặc đồ án dành cho tất cả)
                      if (user.isStudent && user.className.isNotEmpty) {
                        projects = projects.where((p) {
                          return p.courseClass == user.className ||
                              p.courseClass == 'Dành cho tất cả' ||
                              p.courseClass.isEmpty;
                        }).toList();
                      }

                      // Lọc theo Môn học
                      if (selectedSubjectFilter != null) {
                        projects = projects
                            .where(
                              (p) => p.subjectName == selectedSubjectFilter,
                            )
                            .toList();
                      }

                      // Lọc theo Lớp học phần
                      if (selectedClassFilter != null) {
                        projects = projects
                            .where((p) => p.courseClass == selectedClassFilter)
                            .toList();
                      }

                      // Lọc theo trạng thái ban đầu
                      if (widget.initialStatusFilter != null) {
                        projects = projects
                            .where(
                              (p) => p.status == widget.initialStatusFilter,
                            )
                            .toList();
                      }

                      if (projects.isEmpty) {
                        return const Center(
                          child: Text('Không tìm thấy đồ án phù hợp.'),
                        );
                      }

                      return ListView.builder(
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          return ProjectCard(project: projects[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownBox({
    required String defaultLabel,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(
            defaultLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003B73),
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF003B73)),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((DropdownMenuItem<String?> item) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.value ?? defaultLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003B73),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}

// ─── PROJECT CARD  ──

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  const ProjectCard({super.key, required this.project});

  Color _getStatusColor() {
    switch (project.status) {
      case 'Trống':
        return Colors.green;
      case 'Đang gom nhóm':
        return Colors.blue;
      case 'Chờ GV duyệt':
        return Colors.deepOrange;
      case 'Đang triển khai':
        return const Color(0xFF005A9E);
      case 'Đã hoàn tất':
        return Colors.green.shade700;
      case 'Đã khóa':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EFFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  project.subjectName.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF0056A6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  project.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Giảng viên: ${project.lecturerName}  •  Lớp: ${project.courseClass}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                project.projectType == 'Nhóm' ? Icons.groups : Icons.person,
                size: 16,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${project.projectType} • Đã đăng ký: ${project.currentMembers}/${project.maxMembers} SV',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056A6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectDetailScreen(project: project),
                  ),
                );
              },
              child: const Text(
                'Xem chi tiết đề tài',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
