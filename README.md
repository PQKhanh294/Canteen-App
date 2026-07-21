# Canteen App

## Chạy ứng dụng

Sau khi clone hoặc pull mã nguồn, cài dependencies:

```powershell
flutter pub get
```

Chạy ứng dụng với cấu hình Cloudinary dùng chung của nhóm:

```powershell
flutter run --dart-define-from-file=env/dev.json
```

`env/dev.json` chỉ chứa Cloudinary cloud name và unsigned upload preset, không
được thêm `API_SECRET` hoặc thông tin bí mật vào file này.
