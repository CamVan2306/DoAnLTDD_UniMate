# UniMate 🎓

UniMate là ứng dụng di động hỗ trợ quản lý đồ án, bài tập lớn và hoạt động nhóm dành cho sinh viên và giảng viên. Ứng dụng được xây dựng trên nền tảng Flutter kết hợp với hệ sinh thái Firebase để cung cấp trải nghiệm mượt mà, đồng bộ dữ liệu theo thời gian thực (Real-time).

## 🌟 Chức năng nổi bật 

Hệ thống được chia thành 3 vai trò chính với các chức năng chuyên biệt:

### 1. Vai trò Quản trị viên (Admin)
- Quản lý danh sách tài khoản (Giảng viên, Sinh viên).
- Quản lý danh sách Nhóm và Đồ án trên toàn hệ thống.
- Cấp quyền và xử lý các sự cố liên quan đến hệ thống.

### 2. Vai trò Giảng viên (Teacher)
- **Quản lý Đồ án:** Tạo mới, chỉnh sửa thông tin và yêu cầu của các đồ án.
- **Giao đồ án đích danh:** Giao trực tiếp đồ án cho một sinh viên (Nhóm trưởng) cụ thể bằng MSSV.
- **Quản lý file nộp:** Xem trước (preview) và tải về các file báo cáo sinh viên nộp trên hệ thống.
- **Chấm điểm & Nhận xét:** Đánh giá, chấm điểm và để lại lời nhận xét cho từng nhóm.
- **Tương tác trực tiếp:** Trò chuyện, giải đáp thắc mắc của sinh viên thông qua Chatbox.

### 3. Vai trò Sinh viên (Student)
- **Quản lý Nhóm học tập:** Tạo nhóm mới, tham gia nhóm bằng mã (Group Code), duyệt thành viên vào nhóm.
- **Đăng ký Đồ án:** Xem danh sách đồ án được phân công hoặc đăng ký các đồ án đang mở.
- **Nộp bài (Submit):** Upload file báo cáo (PDF, Word) lên hệ thống trước hạn chót (Deadline).
- **Xem điểm số:** Theo dõi tiến độ, xem điểm và nhận xét từ giảng viên.

---

## 🚀 Công nghệ sử dụng (Tech Stack)

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend & Database:** 
  - Firebase Authentication (Đăng nhập Email/Password).
  - Cloud Firestore (Lưu trữ dữ liệu NoSQL Real-time).
  - Firebase Cloud Storage (Lưu trữ file upload của sinh viên).
- **State Management:** (Tuỳ thuộc vào dự án: Provider, GetX, BLoC...)
---

## 🛠️ Hướng dẫn cài đặt (Installation)

### Yêu cầu hệ thống
- Flutter SDK (`>= 3.0.0`)
- Android Studio / VS Code
- Môi trường giả lập Android (Emulator) hoặc thiết bị thật.

### Các bước chạy dự án
1. **Clone dự án về máy:**
   ```bash
   git clone <đường-dẫn-repo-của-bạn>
   cd unimate_huit
   ```

2. **Cài đặt các thư viện (Dependencies):**
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase:**
   - Đảm bảo file `google-services.json` (dành cho Android) và `GoogleService-Info.plist` (dành cho iOS) đã được đặt đúng thư mục.
   - Hoặc sử dụng FlutterFire CLI để cấu hình tự động nếu chưa có.

4. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

---

## 🔮 Hướng phát triển trong tương lai (Future Roadmap)

- [ ] **Web Admin Panel:** Xây dựng phiên bản Web riêng cho Giảng viên và Admin.
- [ ] **Import Data:** Hỗ trợ tạo tài khoản, thêm đề tài hàng loạt bằng file Excel/CSV.
- [ ] **Group Chat:** Hệ thống chat nội bộ mã hóa dành riêng cho các thành viên trong nhóm.
- [ ] **Push Notifications:** Tích hợp Firebase Cloud Messaging (FCM) thông báo deadline, tin nhắn mới.
- [ ] **Google Sign-In:** Tích hợp đăng nhập nhanh bằng tài khoản Google.
- [ ] **Smart Suggestion:** Thuật toán gợi ý đề tài tự động dựa trên dữ liệu học tập.

---

**© App chạy được là nộp - Đồ án lập trình di động**
