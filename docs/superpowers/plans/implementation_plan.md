# 📋 Kế Hoạch Triển Khai Chi Tiết (Implementation Plan)

> **Dành cho nhóm:** Khánh (Nhóm trưởng), Hài, An, Quý.  
> **Mục tiêu:** Mỗi thành viên tự triển khai code trên nhánh riêng, tạo commit đúng chuẩn, tự tạo Pull Request (PR) để có bằng chứng làm việc gửi thầy.

---

## 👨‍💻 Nhiệm Vụ Thành Viên 1: Khánh (Auth + Profile)

### Thông tin nhánh:
*   Nhánh làm việc: `feature/module-1-auth`
*   Thư mục quản lý chính: `lib/views/auth/`, `lib/viewmodels/auth_viewmodel.dart`, `lib/services/auth_service.dart`, `lib/models/user_model.dart`

### Các bước thực hiện:

#### 1. Cấu hình Firebase & Kiểm tra Đăng nhập
*   **Tệp cần sửa:** `lib/main.dart`
*   **Nhiệm vụ:**
    *   Tải cấu hình `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) từ Firebase Console về máy, đặt vào đúng thư mục tương ứng.
    *   Bỏ comment dòng `await Firebase.initializeApp();` trong `main.dart`.
    *   Chạy lệnh test: `flutter run` để đảm bảo app khởi tạo Firebase thành công mà không crash.
    *   **Commit:** `chore: setup firebase configuration and check integration`

#### 2. Xây dựng giao diện Đăng Ký (RegisterScreen)
*   **Tệp cần tạo:** `lib/views/auth/register_screen.dart`
*   **Giao diện:** Ô nhập Họ tên, Email, Mật khẩu, Nút chọn Role (Student / Admin để dễ test đồ án).
*   **Logic:**
    *   Sử dụng `Form` + `TextFormField` kèm validation cơ bản (Email không rỗng, Password >= 6 ký tự).
    *   Gọi `authVM.register(...)` khi nhấn Đăng ký.
    *   Hiển thị SnackBar báo lỗi nếu đăng ký thất bại hoặc quay lại màn đăng nhập nếu thành công.
*   **Commit:** `feat(auth): build register screen with role selection`

#### 3. Xây dựng giao diện Quên Mật Khẩu (ForgotPasswordScreen)
*   **Tệp cần tạo:** `lib/views/auth/forgot_password_screen.dart`
*   **Nhiệm vụ:** Nhập Email, gọi `authVM.resetPassword(email)` và hiển thị thông báo đã gửi link reset qua email.
*   **Commit:** `feat(auth): implement forgot password screen`

#### 4. Xây dựng trang thông tin cá nhân (ProfileScreen)
*   **Tệp cần tạo:** `lib/views/student/profile_screen.dart`
*   **Nhiệm vụ:**
    *   Hiển thị thông tin user hiện tại (Tên, Email, Role).
    *   Thêm nút cho phép đổi tên hiển thị (gọi Update Firestore) và nút Đăng xuất (gọi `authVM.logout()`).
*   **Commit:** `feat(profile): build profile screen with update name and logout`

---

## 👨‍💻 Nhiệm Vụ Thành Viên 2: Hài (Menu + Chi tiết + Đánh giá)

### Thông tin nhánh:
*   Nhánh làm việc: `feature/module-2-menu`
*   Thư mục quản lý chính: `lib/views/student/menu_screen.dart`, `lib/views/student/food_detail_screen.dart`, `lib/viewmodels/menu_viewmodel.dart`, `lib/viewmodels/review_viewmodel.dart`, `lib/widgets/food_card.dart`

### Các bước thực hiện:

#### 1. Xây dựng widget thẻ món ăn (FoodCard)
*   **Tệp cần tạo:** `lib/widgets/food_card.dart`
*   **Nhiệm vụ:** Thiết kế UI hiển thị một món ăn gồm: Ảnh đại diện (sử dụng `CachedNetworkImage` để load mượt), tên món, giá tiền, số sao đánh giá trung bình. Khi click vào thẻ sẽ điều hướng tới màn hình chi tiết món ăn.
*   **Commit:** `ui(menu): create reusable food card widget`

#### 2. Xây dựng trang danh sách món ăn (MenuScreen / HomeScreen)
*   **Tệp cần tạo:** `lib/views/student/menu_screen.dart`
*   **Nhiệm vụ:**
    *   Hiển thị thanh tìm kiếm ở đầu trang để tìm món ăn.
    *   Hiển thị thanh lựa chọn danh mục món (Cơm, Bún, Nước uống, Tráng miệng).
    *   Sử dụng `StreamBuilder` lắng nghe dữ liệu từ `menuVM.foodsStream` để hiển thị danh sách `FoodCard` theo thời gian thực từ Firestore.
*   **Commit:** `feat(menu): implement menu list screen with category filter and search`

#### 3. Xây dựng trang chi tiết món ăn (FoodDetailScreen)
*   **Tệp cần tạo:** `lib/views/student/food_detail_screen.dart`
*   **Nhiệm vụ:**
    *   Hiển thị ảnh to, mô tả món ăn chi tiết, giá cả.
    *   Thêm nút "Thêm vào giỏ hàng" (gọi `cartVM.addItem(food)`).
    *   Bên dưới hiển thị danh sách các review hiện có của món ăn đó (dùng `StreamBuilder` lấy từ `reviewVM.getReviewsStream`).
*   **Commit:** `feat(menu): build food detail screen with review stream`

#### 4. Giao diện Đánh giá món ăn (AddReviewDialog)
*   **Tệp cần tạo:** `lib/widgets/rating_bar.dart` hoặc dialog trong `food_detail_screen.dart`
*   **Nhiệm vụ:**
    *   Sau khi ăn xong, cho phép user click chọn số sao (1-5 sao) và viết comment.
    *   Gọi `reviewVM.submitReview(...)` để lưu vào Firestore.
*   **Commit:** `feat(review): implement review submission logic and rating UI`

---

## 👨‍💻 Nhiệm Vụ Thành Viên 3: An (Giỏ hàng + Đặt đơn + Theo dõi realtime)

### Thông tin nhánh:
*   Nhánh làm việc: `feature/module-3-cart`
*   Thư mục quản lý chính: `lib/views/student/cart_screen.dart`, `lib/views/student/checkout_screen.dart`, `lib/views/student/order_history_screen.dart`, `lib/views/student/order_tracking_screen.dart`

### Các bước thực hiện:

#### 1. Xây dựng trang Giỏ hàng (CartScreen)
*   **Tệp cần tạo:** `lib/views/student/cart_screen.dart`
*   **Nhiệm vụ:**
    *   Lắng nghe `CartViewModel` để hiển thị danh sách món đang chọn.
    *   Nút tăng/giảm số lượng của từng món ăn (gọi `cartVM.addItem` / `cartVM.decreaseQuantity`).
    *   Hiển thị tổng số tiền tạm tính.
    *   Thêm nút "Tiến hành đặt món" dẫn sang trang Checkout.
*   **Commit:** `feat(cart): build cart screen with quantity control`

#### 2. Xây dựng trang Đặt món (CheckoutScreen)
*   **Tệp cần tạo:** `lib/views/student/checkout_screen.dart`
*   **Nhiệm vụ:**
    *   Chọn giờ nhận đồ ăn (Slot thời gian như 11:30, 12:00, 12:30...).
    *   Chọn phương thức thanh toán (Tiền mặt / Ví điện tử giả lập).
    *   Nút "Xác nhận đặt hàng" -> gọi `cartVM.checkout(...)` -> nếu thành công thì điều hướng tới trang Theo dõi đơn hàng.
*   **Commit:** `feat(cart): implement checkout screen with pickup slot and mock payment`

#### 3. Xây dựng trang Lịch sử đơn hàng (OrderHistoryScreen)
*   **Tệp cần tạo:** `lib/views/student/order_history_screen.dart`
*   **Nhiệm vụ:** Hiển thị danh sách các đơn hàng sinh viên đã đặt (sử dụng `orderVM.getOrdersStream`). Mỗi đơn hàng hiển thị: Ngày đặt, tổng tiền, giờ hẹn lấy, trạng thái đơn hàng dưới dạng Badge màu sắc.
*   **Commit:** `feat(order): build order history screen with status badges`

#### 4. Giao diện Theo dõi đơn realtime (OrderTrackingScreen)
*   **Tệp cần tạo:** `lib/views/student/order_tracking_screen.dart`
*   **Nhiệm vụ:** Hiển thị chi tiết đơn hàng vừa đặt. Sử dụng `StreamBuilder` để hiển thị trạng thái động (Chờ xác nhận -> Đang chuẩn bị -> Sẵn sàng lấy -> Hoàn thành) thay đổi tự động khi Admin cập nhật trên Firestore.
*   **Commit:** `feat(order): implement realtime order status tracking screen`

---

## 👨‍💻 Nhiệm Vụ Thành Viên 4: Quý (Admin + Thống kê + Upload + FCM)

### Thông tin nhánh:
*   Nhánh làm việc: `feature/module-4-admin`
*   Thư mục quản lý chính: `lib/views/admin/`, `lib/viewmodels/admin_viewmodel.dart`, `lib/services/storage_service.dart`, `lib/services/notification_service.dart`

### Các bước thực hiện:

#### 1. Trang quản lý đơn hàng của căn tin (AdminOrdersScreen)
*   **Tệp cần tạo:** `lib/views/admin/admin_orders_screen.dart`
*   **Nhiệm vụ:**
    *   Stream toàn bộ đơn hàng của căn tin.
    *   Có nút bấm chuyển đổi trạng thái của đơn hàng nhanh (ví dụ: Xác nhận -> Đang nấu -> Báo sẵn sàng).
    *   Mỗi khi bấm nút cập nhật trạng thái đơn hàng lên Firestore.
*   **Commit:** `feat(admin): build order list view and status updater`

#### 2. Thêm/Sửa/Xóa món ăn (AdminFoodFormScreen)
*   **Tệp cần tạo:** `lib/views/admin/admin_food_form_screen.dart`
*   **Nhiệm vụ:**
    *   Form nhập: Tên món, danh mục, giá, mô tả.
    *   Sử dụng thư viện `image_picker` để chụp ảnh hoặc chọn ảnh từ thư viện máy.
    *   Upload ảnh lên Firebase Storage thông qua `StorageService.uploadFoodImage(...)` để lấy URL lưu vào Firestore.
*   **Commit:** `feat(admin): build menu item CRUD screen with image picker and storage upload`

#### 3. Báo cáo thống kê doanh thu (AdminStatsScreen)
*   **Tệp cần tạo:** `lib/views/admin/admin_stats_screen.dart`
*   **Nhiệm vụ:**
    *   Lấy các đơn hàng có trạng thái `completed` trong ngày/tuần.
    *   Tự tính tổng doanh thu và tổng số đơn hàng.
    *   Sử dụng thư viện `fl_chart` để vẽ biểu đồ doanh thu dạng cột đơn giản.
*   **Commit:** `feat(admin): implement simple revenue chart and metrics using fl_chart`

#### 4. Gửi thông báo đến sinh viên (Firebase Messaging Cloud Trigger)
*   **Tệp cần sửa:** `lib/services/notification_service.dart`
*   **Nhiệm vụ:** Lắng nghe FCM token và log thử hoặc gửi trigger báo trạng thái đơn hàng khi chạy giả lập ở thiết bị để chứng minh tính năng Push Notification hoạt động.
*   **Commit:** `feat(notification): integrate FCM token refresh and foreground message listener`

---

## 🏁 Quy trình Merge Code và Nộp Bài

1. Khi một thành viên hoàn thành module của mình trên local:
   ```bash
   git add .
   git commit -m "feat(module): description"
   git push origin feature/module-xxx
   ```
2. Lên GitHub/GitLab tạo Pull Request (PR) từ nhánh của mình vào nhánh `develop`.
3. Nhóm trưởng Khánh review code của các bạn, nếu chạy ổn không lỗi compile thì bấm **Merge**.
4. Khi cả 4 module đã merge vào `develop` và kiểm thử tích hợp không lỗi, Khánh tạo PR merge từ `develop` vào `main` để làm phiên bản demo chính thức nộp thầy!
