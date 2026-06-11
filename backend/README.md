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
```

Nếu provider yêu cầu CA riêng, cấu hình SSL trong `src/server.js` có thể mở rộng thêm `ca`.

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
