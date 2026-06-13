import 'package:flutter/material.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';
import 'package:unimate_huit/services/system_data_service.dart';
import 'package:unimate_huit/models/subject_model.dart';
import 'package:unimate_huit/screens/admin_create_account_screen.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final Color primaryColor = const Color(0xFF00346F);

  void _showAddClassDialog(BuildContext context) {
    String? selectedSubjectId;
    final TextEditingController classController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Thêm Lớp Học Phần',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00346F),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<List<SubjectModel>>(
                    stream: SystemDataService().streamSubjects(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Lỗi tải môn học: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final subjects = snapshot.data!;
                      if (subjects.isEmpty) {
                        return const Text(
                          'Chưa có môn học nào trong hệ thống.',
                        );
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: selectedSubjectId,
                        decoration: InputDecoration(
                          hintText: 'Chọn môn học',
                          filled: true,
                          fillColor: const Color(0xFFF0F4F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: subjects
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => selectedSubjectId = val);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: classController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên lớp học phần',
                      filled: true,
                      fillColor: const Color(0xFFF0F4F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedSubjectId != null &&
                        classController.text.trim().isNotEmpty) {
                      await SystemDataService().addClass(
                        name: classController.text.trim(),
                        subjectId: selectedSubjectId!,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thêm lớp học phần thành công!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chọn môn và nhập tên lớp!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Thêm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: const UniMateAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quản Trị Hệ Thống',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00346F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lựa chọn chức năng quản trị bên dưới để thiết lập hệ thống.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Card: Tạo Tài Khoản
              _buildManagementCard(
                context: context,
                title: 'Tạo Tài Khoản',
                description: 'Thêm tài khoản sinh viên hoặc giảng viên mới vào cơ sở dữ liệu hệ thống.',
                icon: Icons.person_add_alt_1_rounded,
                startColor: const Color(0xFF8E2DE2),
                endColor: const Color(0xFF4A00E0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminCreateAccountScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Card: Thêm Lớp Mới
              _buildManagementCard(
                context: context,
                title: 'Thêm Lớp Mới',
                description: 'Tạo thêm lớp học phần mới trực thuộc các môn học sẵn có.',
                icon: Icons.class_rounded,
                startColor: const Color(0xFF00B4DB),
                endColor: const Color(0xFF0083B0),
                onTap: () => _showAddClassDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color startColor,
    required Color endColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Icon container with gradient
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [startColor, endColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Chevron icon
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
