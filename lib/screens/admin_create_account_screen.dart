import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unimate_huit/models/user_model.dart';
import 'package:unimate_huit/services/user_service.dart';
import 'package:unimate_huit/services/system_data_service.dart';
import 'package:unimate_huit/models/classes_model.dart';

class AdminCreateAccountScreen extends StatefulWidget {
  const AdminCreateAccountScreen({super.key});

  @override
  State<AdminCreateAccountScreen> createState() =>
      _AdminCreateAccountScreenState();
}

class _AdminCreateAccountScreenState extends State<AdminCreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedRole = 'student'; // 'student' or 'lecturer'
  String? _selectedClassName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = '123456'; // Mặc định là 123456 theo yêu cầu
    final code = _codeController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ Tên, Email và Mã!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email không đúng định dạng!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (code.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã số (MSSV/MSGV) phải bao gồm đúng 10 chữ số!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


    if (_selectedRole == 'student' &&
        (_selectedClassName == null || _selectedClassName!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Lớp học phần cho Sinh viên!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final newUser = UserModel(
      uid: '', // Sẽ được gán trong service
      name: name,
      email: email,
      code: code,
      role: _selectedRole,
      className: _selectedRole == 'student'
          ? _selectedClassName!
          : 'Khoa Công nghệ thông tin',
      phone: phone,
    );

    final success = await UserService().createAccountByAdmin(newUser, password);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo tài khoản thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo tài khoản thất bại. Email có thể đã tồn tại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF2),
      appBar: AppBar(
        title: const Text(
          "Thêm Tài Khoản Mới",
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
          children: [
            _buildSectionCard(
              icon: Icons.person_add,
              title: 'Thông tin tài khoản',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VAI TRÒ (ROLE)', style: _labelStyle),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                      DropdownMenuItem(value: 'lecturer', child: Text('Giảng viên')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedRole = val!;
                        if (_selectedRole == 'lecturer') {
                          _selectedClassName = null;
                        }
                      });
                    },
                    hint: 'Chọn vai trò',
                  ),
                  const SizedBox(height: 16),
                  const Text('HỌ VÀ TÊN', style: _labelStyle),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Nhập họ và tên...',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  const Text('EMAIL', style: _labelStyle),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Nhập địa chỉ email...',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),
                  const Text('MSSV / MSGV', style: _labelStyle),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _codeController,
                    hint: 'Nhập mã số sinh viên/giảng viên...',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('SỐ ĐIỆN THOẠI (Tuỳ chọn)', style: _labelStyle),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneController,
                    hint: 'Nhập số điện thoại...',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  if (_selectedRole == 'student') ...[
                    const SizedBox(height: 16),
                    const Text('LỚP HỌC PHẦN', style: _labelStyle),
                    const SizedBox(height: 8),
                    StreamBuilder<List<CourseClassModel>>(
                      stream: SystemDataService().streamAllClasses(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'Lỗi: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final classes = snapshot.data!;
                        if (classes.isEmpty) {
                          return const Text(
                            'Chưa có lớp học phần nào.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        return _buildDropdown<String>(
                          value: _selectedClassName,
                          items: classes.map((c) {
                            return DropdownMenuItem(
                              value: c.name,
                              child: Text(c.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedClassName = val;
                            });
                          },
                          hint: 'Chọn lớp học phần',
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
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
                        'Tạo tài khoản',
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

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );

  Widget _buildSectionCard({
    required IconData icon,
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
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: const Color(0xFFF0F4F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
