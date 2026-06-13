import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unimate_huit/models/project_model.dart';
import 'package:unimate_huit/services/project_service.dart';
import 'package:unimate_huit/services/system_data_service.dart';
import 'package:unimate_huit/models/subject_model.dart';
import 'package:unimate_huit/models/classes_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LecturerCreateProjectScreen extends StatefulWidget {
  final ProjectModel? projectToEdit;

  const LecturerCreateProjectScreen({Key? key, this.projectToEdit})
    : super(key: key);

  @override
  State<LecturerCreateProjectScreen> createState() =>
      _LecturerCreateProjectScreenState();
}

class _LecturerCreateProjectScreenState
    extends State<LecturerCreateProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _requirementController = TextEditingController();

  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String? _selectedClassId;
  String? _selectedClassName;

  int _maxMembers = 4;
  String _projectType = 'Nhóm';
  DateTime? _selectedDeadline;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.projectToEdit;
    if (p != null) {
      _nameController.text = p.title;
      _descriptionController.text = p.description;
      _requirementController.text = p.requirements;
      _selectedSubjectName = p.subjectName;
      _selectedClassName = p.courseClass;
      _maxMembers = p.maxMembers;
      _projectType = p.projectType;
      try {
        _selectedDeadline = DateFormat('dd/MM/yyyy').parse(p.deadline);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _requirementController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 7)),
      firstDate: today,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() => _selectedDeadline = picked);
    }
  }

  void _submitProject() async {
    if (_nameController.text.trim().isEmpty ||
        _selectedSubjectName == null ||
        _selectedClassName == null ||
        _selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng điền đủ Tên đồ án, Môn học, Lớp học phần và Hạn chót!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isEditing = widget.projectToEdit != null;

    try {
      String lecturerNameToSave = '';
      if (isEditing) {
        lecturerNameToSave = widget.projectToEdit!.lecturerName;
      } else {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();
        if (userDoc.exists) {
          lecturerNameToSave = userDoc.data()?['name'] ?? '';
        }
      }

      if (isEditing) {
        await ProjectService().updateProject(widget.projectToEdit!.projectId, {
          'title': _nameController.text.trim(),
          'lecturerName': lecturerNameToSave,
          'description': _descriptionController.text.trim(),
          'requirements': _requirementController.text.trim(),
          'maxMembers': _maxMembers,
          'deadline': DateFormat('dd/MM/yyyy').format(_selectedDeadline!),
          'subjectName': _selectedSubjectName!,
          'projectType': _projectType,
          'courseClass': _selectedClassName!,
        });
      } else {
        final newProject = ProjectModel(
          projectId: '',
          title: _nameController.text.trim(),
          lecturerName: lecturerNameToSave,
          lecturerUid: currentUid,
          description: _descriptionController.text.trim(),
          requirements: _requirementController.text.trim(),
          maxMembers: _maxMembers,
          currentMembers: 0,
          deadline: DateFormat('dd/MM/yyyy').format(_selectedDeadline!),
          status: 'Trống',
          subjectName: _selectedSubjectName!,
          projectType: _projectType,
          courseClass: _selectedClassName!,
        );
        await ProjectService().createProject(newProject);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Đã cập nhật đồ án thành công!'
                  : 'Đã đăng đồ án lên hệ thống thành công!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thất bại: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF2),
      appBar: AppBar(
        title: const Text(
          "Đăng Đề tài Mới",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              icon: Icons.info,
              title: 'Thông tin chung',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MÔN HỌC',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<SubjectModel>>(
                    stream: SystemDataService().streamSubjects(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Lỗi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final subjects = snapshot.data!;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSubjectId,
                            isExpanded: true,
                            hint: const Text('Chọn môn học'),
                            items: subjects.map((subj) {
                              return DropdownMenuItem(
                                value: subj.id,
                                child: Text(subj.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedSubjectId = val;
                                _selectedSubjectName = subjects
                                    .firstWhere((s) => s.id == val)
                                    .name;
                                _selectedClassId = null;
                                _selectedClassName = null;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'LỚP HỌC PHẦN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<CourseClassModel>>(
                    stream: SystemDataService().streamClassesBySubject(
                      _selectedSubjectId ?? '',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Lỗi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      if (!snapshot.hasData) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Vui lòng chọn môn học trước',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      final classes = snapshot.data!;
                      if (classes.isEmpty && _selectedSubjectId != null) {
                        return const Text(
                          'Môn học này chưa có lớp nào',
                          style: TextStyle(color: Colors.red),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClassId,
                            isExpanded: true,
                            hint: const Text('Chọn lớp học phần'),
                            items: classes.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedClassId = val;
                                _selectedClassName = classes
                                    .firstWhere((c) => c.id == val)
                                    .name;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'HÌNH THỨC THỰC HIỆN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Nhóm',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: 'Nhóm',
                          groupValue: _projectType,
                          contentPadding: EdgeInsets.zero,
                          activeColor: const Color(0xFF005A9E),
                          onChanged: (val) {
                            setState(() {
                              _projectType = val!;
                              if (_maxMembers < 2) {
                                _maxMembers = 4;
                              }
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Cá nhân',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: 'Cá nhân',
                          groupValue: _projectType,
                          contentPadding: EdgeInsets.zero,
                          activeColor: const Color(0xFF005A9E),
                          onChanged: (val) {
                            setState(() {
                              _projectType = val!;
                              _maxMembers = 1; // Ép buộc 1 thành viên
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'TÊN ĐỀ TÀI',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Nhập tên đề tài đồ án...',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.description,
              title: 'Nội dung chi tiết',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MÔ TẢ ĐỀ TÀI',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descriptionController,
                    hint: 'Nhập mục tiêu, phạm vi đề tài...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'YÊU CẦU KỸ THUẬT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _requirementController,
                    hint: 'Vd: Kiến thức Flutter, Dart...',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.group,
              title: 'Giới hạn nhóm',
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SỐ THÀNH VIÊN TỐI ĐA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        // Khóa nút giảm nếu là Cá nhân hoặc số lượng <= 2
                        onPressed: (_projectType == 'Nhóm' && _maxMembers > 2)
                            ? () => setState(() => _maxMembers--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF005A9E),
                      ),
                      Text(
                        '$_maxMembers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _projectType == 'Cá nhân'
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      IconButton(
                        // Khóa nút tăng nếu là Cá nhân hoặc số lượng >= 10
                        onPressed: (_projectType == 'Nhóm' && _maxMembers < 10)
                            ? () => setState(() => _maxMembers++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF005A9E),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Colors.white,
              title: Text(
                _selectedDeadline == null
                    ? 'CHỌN HẠN CHÓT ĐĂNG KÝ'
                    : 'HẠN CHÓT: ${DateFormat('dd/MM/yyyy').format(_selectedDeadline!)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _selectedDeadline == null
                      ? Colors.red
                      : Colors.black87,
                ),
              ),
              trailing: const Icon(
                Icons.calendar_today,
                color: Color(0xFF005A9E),
              ),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A9E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Đăng tải đề tài',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    IconData? icon,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF005A9E)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: const Color(0xFFF0F4F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
