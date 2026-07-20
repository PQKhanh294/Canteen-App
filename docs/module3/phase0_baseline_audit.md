# 📋 MODULE 3 — Phase 0 Baseline Audit

> **Dự án:** Canteen App (PRM393 - Nhóm 4)  
> **Người thực hiện:** An (MODULE 3 - Cart + Checkout + Order + Voucher + Tracking)  
> **Mục tiêu:** Tạo baseline kỹ thuật, kiểm tra khả năng biên dịch, ghi lại toàn bộ lỗi hiện tại và các mối tương quan với MODULE 1.

---

## 1. Environment (Môi trường)

- **Date:** 15/07/2026
- **Flutter:** 3.41.9 • channel stable • https://github.com/flutter/flutter.git
- **Dart:** 3.11.5
- **Branch:** `feature/module-3-cart`
- **Commit:** `12fe9c9` (chore: stop tracking google-services.json and update gitignore)
- **Devices:**
  - Windows (desktop) • `windows` • `windows-x64`
  - Chrome (web) • `chrome` • `web-javascript`
  - Edge (web) • `edge` • `web-javascript`
- **Firebase Project:** Đã cấu hình và khởi chạy ở `main.dart` (chưa có DefaultFirebaseOptions cụ thể trên repo do gitignore).
- **Integration Branch:** `main` (trùng khớp với `origin/dev` tại commit `12fe9c9`).

---

## 2. Baseline Results (Kết quả chạy thử ban đầu)

- **`flutter pub get`:** Thành công với thông báo: "Got dependencies!".
- **`flutter analyze`:** **THÀNH CÔNG** (Sau khi sửa các lỗi biên dịch của Module 1, bộ phân tích chạy sạch không còn lỗi Error nào, chỉ còn các cảnh báo Info/Warning về style/deprecation).
- **`flutter test`:** **THẤT BẠI** do file `test/widget_test.dart` là test mặc định của Flutter (Counter increments smoke test) không tương thích với cấu trúc của `CanteenApp` (CanteenApp khởi chạy màn hình Splash, không có nút bấm tăng giảm và text counter). Không liên quan đến Module 3.
- **`flutter run`:** **THÀNH CÔNG** (Ứng dụng đã có thể biên dịch thành công sau khi sửa các lỗi cú pháp).
- **Smoke test:** Đã sửa các lỗi biên dịch, ứng dụng sẵn sàng biên dịch thành công.

---

## 3. Provider Registration (Đăng ký Provider)

Đăng ký tại [lib/main.dart](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/main.dart):

| Provider | Type | Dependency | Notes / Risks |
|---|---|---|---|
| **AuthService** | `Provider` | Không | Cấu hình mặc định. |
| **FirestoreService** | `Provider` | Không | Cấu hình mặc định. |
| **StorageService** | `Provider` | Không | Cấu hình mặc định. |
| **NotificationService** | `Provider` | Không | Cấu hình mặc định. |
| **AuthViewModel** | `ChangeNotifierProxyProvider2` | `AuthService`, `NotificationService` | Khởi tạo với service tương ứng. |
| **MenuViewModel** | `ChangeNotifierProxyProvider` | `FirestoreService` | Phục vụ Module 2. |
| **CartViewModel** | `ChangeNotifierProxyProvider` | `FirestoreService` | **Rủi ro:** Chưa được khởi tạo theo User. Giỏ hàng không tự reset khi đăng xuất. |
| **OrderViewModel** | `ChangeNotifierProxyProvider` | `FirestoreService` | **Rủi ro:** Chưa được truyền user thông tin để truy vấn orders tương ứng. |
| **ReviewViewModel** | `ChangeNotifierProxyProvider` | `FirestoreService` | Phục vụ Module 2. |

---

## 4. Route Audit (Định tuyến Route)

Định tuyến bằng cơ chế `routes: {}` của MaterialApp tại [lib/app.dart](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/app.dart):

| Route | Exists | Current Widget | Status |
|---|---:|---|---|
| `/splash` | Có | `const SplashScreen()` | Thật (Module 1) |
| `/onboarding` | Có | `const OnboardingScreen()` | Thật (Module 1) |
| `/login` | Có | `const LoginScreen()` | Thật (Module 1) |
| `/register` | Có | `const RegisterScreen()` | Thật (Module 1) |
| `/forgot-password` | Có | `const ForgotPasswordScreen()` | Thật (Module 1) |
| `/change-password` | Có | `const ChangePasswordScreen()` | Thật (Module 1) |
| `/main-nav` | Có | `const MainNavigationScreen()` | Thật (Module 1) |
| `/home` | Có | `const HomeScreen()` | Thật (Module 1) |
| `/profile` | Có | `const ProfileScreen()` | Thật (Module 1) |
| `/edit-profile` | Có | `const EditProfileScreen()` | Thật (Module 1) |
| `/favorites` | Có | `const FavoritesScreen()` | Thật (Module 1) |
| `/notification-settings` | Có | `const NotificationSettingsScreen()` | Thật (Module 1) |
| `/daily-special` | Có | Mock Scaffold | Placeholder (Module 2) |
| `/admin` | Có | Mock Scaffold | Placeholder (Module 4) |
| `/cart` | Không | Chưa định nghĩa | **Cần bổ sung ở GĐ3** |
| `/checkout` | Không | Chưa định nghĩa | **Cần bổ sung ở GĐ5** |
| `/vouchers` | Không | Chưa định nghĩa | **Cần bổ sung ở GĐ4** |
| `/orders` | Không | Chưa định nghĩa | **Cần bổ sung ở GĐ6** |
| `/order-detail` | Không | Chưa định nghĩa | **Cần bổ sung ở GĐ6** |
| `/order-success` | Không | Chưa định nghĩa | **Cần bổ sung ở GĐ6** |
| `/order-tracking` | Không | Chưa định nghĩa | **Cần bổ sung ở GĐ7** |

---

## 5. Required Questions (8 câu hỏi bắt buộc)

| Câu hỏi | Kết quả thực tế | File/Dòng | Ảnh hưởng MODULE 3 |
|---|---|---|---|
| **AuthViewModel cung cấp user qua thuộc tính nào?** | `currentUser` (UserModel?) | [auth_viewmodel.dart#L24](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/viewmodels/auth_viewmodel.dart#L24) | Dùng để lấy UID và thông tin hiển thị của sinh viên khi checkout. |
| **UserModel dùng id, uid hay userId?** | `uid` (String) | [user_model.dart#L7](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/models/user_model.dart#L7) | Đảm bảo tính nhất quán của ID người dùng trong DB. |
| **Badge cart đọc field nào?** | `cartVM.itemCount` | [main_navigation_screen.dart#L34](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/views/student/main_navigation_screen.dart#L34) | Ta cần giữ nguyên getter này trong `CartViewModel` để tránh lỗi badge. |
| **Home quick reorder gọi hàm nào?** | Không gọi (chỉ là nút mock) | [home_screen.dart#L355](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/views/student/home_screen.dart#L355) | Cần cập nhật nút này gọi `orderVM.reorder()` sau khi bạn hoàn thành Task 3.8. |
| **Profile Stats query field order nào?** | Không query (ghim cứng dữ liệu) | [profile_screen.dart#L115](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/views/student/profile_screen.dart#L115) | Cần cập nhật để lắng nghe từ stream `OrderViewModel` để tính tổng chi tiêu thật. |
| **FoodModel.price là int hay double?** | `double` | [food_model.dart#L10](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/models/food_model.dart#L10) | Giữ nguyên kiểu `double` để tránh phá vỡ code của Hài/Khánh, dùng format VNĐ ở UI. |
| **StatusBadge chấp nhận status nào?** | `pending`, `preparing`, `ready`, `completed`, `cancelled` | [status_badge.dart#L22](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/widgets/status_badge.dart#L22) | Phải map đúng các chuỗi này khi ghi trạng thái đơn lên Firestore. |
| **/cart, /orders, /checkout đã có chưa?** | Chưa có | [app.dart](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/app.dart) | Cần đăng ký thêm các route này ở các giai đoạn sau. |

---

## 6. Model Audit (Đánh giá Model)

### FoodModel
- **ID field:** `id` (String) truyền ngoài qua constructor `fromMap(map, doc.id)`.
- **Price type:** `double`.
- **Availability field:** `available` (bool, mặc định `true`).
- **Serialization concerns:** Nhất quán, có hàm `toMap()`, `fromMap()`, và `copyWith()`.

### UserModel
- **Identity field:** `uid` (String).
- **Role:** `role` (String, giá trị `'student'` hoặc `'admin'`).
- **Nullable fields:** `avatarUrl` và `fcmToken` (mặc định chuỗi rỗng `''`).

### OrderModel
- **Current fields:** `id`, `userId`, `userName`, `items` (List<OrderItem>), `totalPrice`, `pickupTime`, `paymentMethod`, `status`, `createdAt`, `updatedAt`.
- **Current usage:** Khai báo cấu trúc đơn giản, chưa tích hợp Voucher, giảm giá (`discountAmount`), mã hiển thị đơn hàng (`displayCode`), số quầy nhận (`counterNumber`), lý do hủy (`cancelReason`).
- **Missing fields:** `displayCode`, `subtotal`, `discountAmount`, `finalTotal`, `promoId`, `promoCode`, `cancelReason`, `counterNumber`, `statusTimestamps`.
- **Compatibility risks:** Trung bình. Sẽ phải sửa cả `OrderModel` và `OrderItem` ở Giai đoạn 1 để hỗ trợ Voucher đầy đủ.

---

## 7. MODULE 1 Dependencies on MODULE 3

| Tính năng (Module 1) | Gốc phụ thuộc (Module 3) | Trạng thái hiện tại | Kế hoạch tương thích |
|---|---|---|---|
| **Giỏ hàng badge** | `CartViewModel.itemCount` | Đang đọc placeholder bằng `_items` rỗng | Giữ nguyên getter `itemCount` trong `CartViewModel` khi cập nhật logic. |
| **Quick reorder (Home)** | Nút Reorder | Fix cứng UI | Sẽ gọi hàm `orderVM.reorder()` và điều hướng sang `/cart`. |
| **Personal Stats** | Thống kê số đơn, chi tiêu | Fix cứng '12' đơn và '420.000đ' | Sẽ sửa [profile_screen.dart](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/views/student/profile_screen.dart) để đọc dữ liệu từ `ordersStream`. |

---

## 8. Issues (Danh sách lỗi phát hiện)

### 🔴 BLOCKER (Ứng dụng không thể build/run)
1.  **Lỗi Import trong [app_theme.dart](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/core/theme/app_theme.dart) (Dòng 2):**
    *   *Lỗi:* `import 'app_colors.dart';`
    *   *Trạng thái:* **ĐÃ KHẮC PHỤC** (Thay đổi thành `import '../constants/app_colors.dart';`).
2.  **Lỗi ThemeData `CardTheme` trong [app_theme.dart](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/core/theme/app_theme.dart) (Dòng 60):**
    *   *Lỗi:* `The argument type 'CardTheme' can't be assigned to the parameter type 'CardThemeData?'.`
    *   *Trạng thái:* **ĐÃ KHẮC PHỤC** (Thay đổi thành `CardThemeData(...)`).
3.  **Lỗi Trùng State trong [edit_profile_screen.dart](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/lib/views/student/edit_profile_screen.dart) (Dòng 20):**
    *   *Lỗi:* `The non-abstract class '_ProfileScreenState' is missing implementations for these members: State.build`
    *   *Trạng thái:* **ĐÃ KHẮC PHỤC** (Xóa bỏ class dư thừa `_ProfileScreenState`).
4.  **Lỗi cú pháp `MainAxisAlignment.between` ở các file UI:**
    *   *Lỗi:* `Member not found: 'between'.`
    *   *Trạng thái:* **ĐÃ KHẮC PHỤC** (Sửa thành `MainAxisAlignment.spaceBetween` ở `favorites_screen.dart`, `home_screen.dart` và `shimmer_loading.dart`).
5.  **Lỗi constructor trong [widget_test.dart](file:///d:/Ky8/PRM393/PROJECT/Canteen-App/test/widget_test.dart) (Dòng 16):**
    *   *Lỗi:* `Couldn't find constructor 'MyApp'.`
    *   *Trạng thái:* **ĐÃ KHẮC PHỤC** (Sửa thành `const CanteenApp()`).

### 🟡 HIGH (Vấn đề nghiệp vụ cần quyết định ở Giai đoạn 1)
1.  **Dữ liệu `price` kiểu double:** Đã quyết định giữ nguyên kiểu `double` để tránh phá vỡ logic các module khác, chỉ làm tròn và định dạng tiền tệ ở phần UI.
2.  **Khởi tạo `CartViewModel` theo User:** Cần giải quyết việc Cart được clear khi đăng xuất và load đúng local storage khi đăng nhập tài khoản khác.

---

## 9. Decisions for Phase 1 (Quyết định cho Giai đoạn 1)

1.  **Identity naming:** Sử dụng trường `uid` làm định danh duy nhất của User trong mọi quan hệ dữ liệu Firestore.
2.  **Price data type:** Giữ nguyên kiểu dữ liệu `double` trong `FoodModel`, `OrderItem`, và `OrderModel`.
3.  **Order status:** Sử dụng chuẩn 5 trạng thái: `pending`, `preparing`, `ready`, `completed`, `cancelled`.
4.  **Cart badge compatibility:** Giữ nguyên getter `itemCount` trong `CartViewModel` để phục vụ badge tab.
5.  **Service separation:** Sẽ tạo thêm các service riêng biệt `order_service.dart` và `promo_service.dart` để tránh phình to `firestore_service.dart`.

---

## 10. Phase 0 Result Check (Bảng kiểm hoàn thành)

- [x] Đang đứng trên nhánh `feature/module-3-cart`.
- [x] Đã đồng bộ code mới nhất của Module 1.
- [x] Đã chạy và ghi nhận kết quả `flutter pub get`.
- [x] Đã chạy `flutter analyze` và ghi lại 33 cảnh báo (0 lỗi biên dịch Error).
- [x] Đã chạy `flutter test` và ghi nhận kết quả (Lỗi do file test mặc định không tương thích với widget thực tế của dự án).
- [x] Đã xác định toàn bộ dependencies và routes hiện tại.
- [x] Ghi nhận đầy đủ các lỗi Blocker và **đã sửa thành công** để baseline biên dịch được.
- [x] Chưa thay đổi bất kỳ code nghiệp vụ nào của MODULE 3.
- [x] Đã commit tài liệu audit và các sửa đổi blocker lên branch.
