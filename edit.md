# BÁO CÁO CÔNG VIỆC SV2 – TRẦN THỊ CẨM VÂN (TUẦN 2)
**Phân công:** Network / Middleware  
**Dự án:** GardenMist - Hệ thống Phun sương tự động  
**Thời lượng thực hiện:** 6 giờ  

---

## 1. Tìm hiểu MQTT trên Wokwi

- **Wi-Fi giả lập:** Wokwi cung cấp Access Point ảo `Wokwi-GUEST` (không có mật khẩu).
- **Thư viện:** `WiFi.h` kết hợp `PubSubClient` để tạo MQTT Client trên ESP32.
- **MQTT Broker:** `broker.hivemq.com` (Cổng `1883`).

---

## 2. Mô phỏng Publish dữ liệu (Yêu cầu chính SV2)

ESP32 đọc dữ liệu từ SV1 và Publish lên 2 topic chuẩn JSON theo đúng yêu cầu đề bài:

| Topic | Định dạng Payload (JSON) | Nội dung |
| :--- | :--- | :--- |
| `garden/mist/temp` | `{"temp": 32.50}` | Gửi nhiệt độ đo được từ DHT22 |
| `garden/mist/rain` | `{"isRaining": false}` | Gửi trạng thái cảm biến mưa (`true`/`false`) |

---

## 3. Ghi chú Kỹ thuật (Chuẩn bị Tuần 4)

### 3.1. Liệt kê chân GPIO đã sử dụng

| Linh kiện | Chân GPIO | Chế độ | Ý nghĩa |
| :--- | :--- | :--- | :--- |
| **DHT22** | `GPIO 4` | `INPUT` | Đọc nhiệt độ môi trường |
| **Rain Sensor (Slide Switch)** | `GPIO 5` | `INPUT_PULLUP` | Đọc trạng thái mưa (`LOW` = Có mưa) |
| **Relay Module** | `GPIO 18` | `OUTPUT` | Điều khiển Máy bơm (`HIGH` = Bật) |

### 3.2. Tần suất gửi dữ liệu (Publish Interval)
- **Chu kỳ gửi:** `4000 ms` (4 giây - đạt yêu cầu 3–5 giây).
- **Xử lý non-blocking:** Dùng `millis()` giúp code chạy mượt, không bị treo `delay()`.

---

## 4. Hướng dẫn kiểm tra với MQTT Explorer

1. Mở phần mềm **MQTT Explorer**.
2. Cấu hình Host: `broker.hivemq.com`, Port: `1883`.
3. Thêm Subscription: `garden/mist/#`
4. Bấm **Connect** và xem dữ liệu JSON nhảy real-time từ Wokwi.
