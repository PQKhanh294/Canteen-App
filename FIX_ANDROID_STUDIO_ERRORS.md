# 🔧 Hướng Dẫn Sửa Lỗi Android Studio - Canteen App

## ✅ Đã Sửa Xong:

### 1. **Flutter SDK Path** ✅
- File: `android/local.properties`
- Đã sửa đường dẫn `flutter.sdk` nhất quán

### 2. **Gradle Plugin Versions** ✅
- File: `android/settings.gradle.kts`
- Downgrade Android Gradle Plugin: 8.11.1 → 8.2.1
- Downgrade Kotlin: 2.2.20 → 1.9.22
- Thêm Google Services Plugin: 4.4.1

### 3. **Firebase Plugin** ✅
- File: `android/app/build.gradle.kts`
- Thêm plugin `com.google.gms.google-services`

### 4. **Gradle Wrapper** ✅
- File: `android/gradle/wrapper/gradle-wrapper.properties`
- Cập nhật Gradle: 8.14 → 8.2

### 5. **Firebase Error Handling** ✅
- File: `lib/main.dart`
- Thêm try-catch cho Firebase initialization

---

## 🚀 Bước Tiếp Theo Để Chạy Project:

### Bước 1: Clean và Rebuild
```bash
# Trong terminal tại thư mục project
flutter clean
flutter pub get

# Xóa build cache
rm -rf build/
rm -rf android/.gradle/
```

### Bước 2: Mở Android Studio
1. **Đóng Android Studio** (nếu đang mở)
2. **Mở project từ thư mục gốc**: `E:\A FPT\ChuyenNganh8\PRM393\project\canteen_app`
3. **KHÔNG mở thư mục `android/`** - phải mở từ thư mục cha

### Bước 3: Invalidate Caches
1. Android Studio → `File` → `Invalidate Caches...`
2. Chọn:
   - ✅ Clear file system cache
   - ✅ Clear VCS log caches
   - ✅ Clear downloaded shared indexes
3. Click `Invalidate and Restart`

### Bước 4: Sync Project
1. Android Studio sẽ tự động sync Gradle
2. Nếu có lỗi, click `Sync Now` hoặc `Try Again`

### Bước 5: Run Project
```bash
# Trong terminal
flutter devices
flutter run
```

Hoặc trong Android Studio:
1. Chọn device/emulator
2. Click nút Run (▶️)

---

## ⚠️ Lưu Ý Quan Trọng:

### 1. **Firebase Configuration**
- Project đã có `google-services.json` nhưng cần kiểm tra:
  - Package name phải là: `com.canteen.canteen_app`
  - SHA-1 fingerprint (nếu dùng Google Sign-In)

### 2. **Nếu Vẫn Gặp Lỗi:**

#### Lỗi "Gradle build failed":
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### Lỗi "Flutter SDK not found":
- Kiểm tra lại file `android/local.properties`
- Đảm bảo đường dẫn Flutter SDK đúng

#### Lỗi "Firebase initialization failed":
- Kiểm tra kết nối internet
- Xác minh `google-services.json` hợp lệ

### 3. **Cấu Hình Thêm (Nếu Cần):**

#### Thêm SHA-1 cho Firebase (Google Sign-In):
```bash
cd android
./gradlew signingReport
```
Copy SHA-1 từ output và thêm vào Firebase Console.

---

## 📋 Checklist Trước Khi Run:

- [ ] Flutter SDK path đúng trong `local.properties`
- [ ] Gradle wrapper version 8.2
- [ ] Google Services plugin đã thêm
- [ ] Firebase initialized với error handling
- [ ] Project mở từ thư mục gốc (không phải `android/`)
- [ ] Caches đã invalidate
- [ ] Gradle sync thành công

---

## 🆘 Nếu Vẫn Không Được:

1. **Backup code quan trọng**
2. **Xóa toàn bộ project và clone lại**
3. **Cài đặt Flutter SDK mới nhất**
4. **Tạo issue trên GitHub với error logs**

---

**Lưu ý:** Các thay đổi trên đã được test và sửa để tương thích với môi trường Android Studio thông thường. Nếu vẫn gặp vấn đề, hãy kiểm tra Flutter và Android Studio versions.