# Productivity Management Backend

Backend Node.js/Express + MySQL cho project Flutter.

## Chạy nhanh

```bash
cd backend
cp .env.example .env
npm install
npm run migrate
npm run seed
npm run dev
```

API mặc định chạy ở `http://localhost:3000/api`.

## MySQL Cloud

Cập nhật `.env` bằng thông tin cloud MySQL:

```env
DB_HOST=your-mysql-host
DB_PORT=3306
DB_USER=your-user
DB_PASSWORD=your-password
DB_NAME=productivity_management
DB_SSL=true

APP_PUBLIC_URL=https://your-backend-domain.example.com
REGISTRATION_OTP_TTL_MINUTES=10
REGISTRATION_MAX_ATTEMPTS=5

SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-gmail-address@gmail.com
SMTP_PASSWORD=your-16-character-google-app-password
EMAIL_FROM=Productivity Manager <your-gmail-address@gmail.com>
```

Nếu provider yêu cầu CA riêng, cấu hình SSL trong `src/server.js` có thể mở rộng thêm `ca`.

## Đăng ký và xác thực email

1. `POST /api/auth/register/request`: gửi OTP hoặc link xác thực.
2. `POST /api/auth/register/verify`: xác thực OTP/token và tạo user.
3. `GET /api/auth/register/verify-link?token=...`: xác thực trực tiếp từ email.

OTP và link chỉ được gửi qua email, API không trả mã hoặc link về ứng dụng.
Nếu SMTP chưa được cấu hình hoặc gửi email thất bại, yêu cầu đăng ký bị hủy và
API trả HTTP 503.

Với Gmail, bật xác minh 2 bước cho tài khoản Google rồi tạo **App Password**.
Dùng App Password 16 ký tự cho `SMTP_PASSWORD`, không dùng mật khẩu Gmail thường.

Mật khẩu mới phải có tối thiểu 6 ký tự, ít nhất một chữ hoa và một ký tự đặc biệt.

## Tài khoản seed

Tất cả tài khoản seed có mật khẩu `123456`.

- `admin@company.com` / Admin
- `manager@company.com` / Manager
- `nguyenvana@company.com` / Member
- `tranminh@company.com` / Member
- `lethic@company.com` / Member
- `hani@company.com` / Member

## Flutter base URL

Flutter client dùng biến build:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

Android emulator thường cần:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```
