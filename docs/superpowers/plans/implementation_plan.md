# 📋 Kế Hoạch Triển Khai Chi Tiết (Implementation Plan) - Cập Nhật Nâng Cao

> **Dành cho nhóm:** Khánh (Nhóm trưởng), Hài, An, Quý.  
> **Mục tiêu:** Cân bằng khối lượng công việc (workload) giữa các thành viên, bổ sung các tính năng nâng cao để đồ án đạt điểm tối đa (A+).

---

## 👨‍💻 Nhiệm Vụ Thành Viên 1: Khánh (Auth + Profile + Yêu Thích + Thống Kê Cá Nhân)

### Thông tin nhánh:
*   Nhánh làm việc: `feature/module-1-auth`
*   Thư mục quản lý chính: `lib/views/auth/`, `lib/views/student/profile_screen.dart`, `lib/views/student/favorites_screen.dart`

### Các bước thực hiện & Commits:

#### 1. Cấu hình Firebase & Đăng ký / Đăng nhập / Quên mật khẩu (Đã hoàn thành)
*   Tạo giao diện đăng nhập, đăng ký và quên mật khẩu sử dụng bộ UI Kit dùng chung.
*   **Commit:** `feat(auth): implement login, register, forgot-password, and profile views using shared UI Kit`

#### 2. Xây dựng Danh sách món yêu thích (FavoritesScreen)
*   **Tệp cần tạo:** `lib/views/student/favorites_screen.dart`
*   **Nhiệm vụ:**
    *   Tạo Firestore sub-collection tại `/users/{userId}/favorites/{foodId}`.
    *   Khi người dùng xem menu, thêm nút icon Trái tim (Thả tim -> Lưu món yêu thích).
    *   Xây dựng màn hình hiển thị danh sách món đã thả tim để người dùng có thể nhấp vào đặt nhanh.
*   **Commit:** `feat(favorites): implement add to favorites and favorites list screen`

#### 3. Thống kê lịch sử chi tiêu cá nhân (Profile Stats)
*   **Tệp cần sửa:** `lib/views/student/profile_screen.dart`
*   **Nhiệm vụ:**
    *   Truy vấn Firestore collection `/orders` lọc theo `userId` của người dùng hiện tại.
    *   Tính toán và hiển thị các số liệu trên Profile: **Tổng số đơn đã đặt**, **Tổng số tiền đã chi tiêu tại căn tin**, **Món ăn đặt nhiều nhất**.
*   **Commit:** `feat(profile): add personal order statistics and spending metrics`

---

## 👨‍💻 Nhiệm Vụ Thành Viên 2: Hài (Menu + Bộ Lọc Nâng Cao + Rating Breakdown)

### Thông tin nhánh:
*   Nhánh làm việc: `feature/module-2-menu`
*   Thư mục quản lý chính: `lib/views/student/menu_screen.dart`, `lib/views/student/food_detail_screen.dart`

### Các bước thực hiện & Commits:

#### 1. Widget FoodCard & Màn hình danh sách món ăn (MenuScreen)
*   Hiển thị danh sách món realtime. Tách biệt danh mục rõ ràng.
*   **Commit:** `feat(menu): implement menu list screen with category filter and search`

#### 2. Bộ lọc nâng cao (Advanced Filters)
*   **Tệp cần sửa:** `lib/views/student/menu_screen.dart`, `lib/viewmodels/menu_viewmodel.dart`
*   **Nhiệm vụ:**
    *   Thêm bộ lọc sắp xếp: Sắp xếp theo giá tăng dần, giá giảm dần, và món ăn có rating cao nhất.
    *   Hiển thị huy hiệu "Hết hàng" nếu món ăn đó có thuộc tính `available: false` và vô hiệu hóa nút thêm vào giỏ.
*   **Commit:** `feat(menu): add sorting filters and availability tags`

#### 3. Trang chi tiết món ăn & Biểu đồ đánh giá (Rating Breakdown)
*   **Tệp cần sửa:** `lib/views/student/food_detail_screen.dart`
*   **Nhiệm vụ:**
    *   Xây dựng giao diện xem chi tiết món ăn kèm danh sách bình luận đánh giá.
    *   Thiết kế biểu đồ thanh ngang đơn giản hiển thị tỷ lệ phần trăm đánh giá từ 1 sao đến 5 sao (Breakdown) giúp UI trông chuyên nghiệp như Shopee/AppStore.
*   **Commit:** `feat(review): build rating breakdown widget in food details`

---

## 👨‍💻 Nhiệm Vụ Thành Viên 3: An (Giỏ Hàng + Đặt Món + Mã Giảm Giá + Stepper Động)

### Thông tin nhánh:
*   Nhánh làm việc: `feature/module-3-cart`
*   Thư mục quản lý chính: `lib/views/student/cart_screen.dart`, `lib/views/student/checkout_screen.dart`, `lib/views/student/order_tracking_screen.dart`

### Các bước thực hiện & Commits:

#### 1. Giỏ hàng & Checkout (Cart & Checkout Screen)
*   Thiết kế giỏ hàng tăng giảm số lượng, chọn slot giờ nhận thức ăn.
*   **Commit:** `feat(cart): build cart and checkout screen with pickup slot`

#### 2. Tích hợp hệ thống Mã giảm giá (Promo Code)
*   **Tệp cần sửa:** `lib/views/student/checkout_screen.dart`, `lib/viewmodels/cart_viewmodel.dart`
*   **Nhiệm vụ:**
    *   Thêm ô nhập Promo Code (ví dụ: nhập `FPT10` giảm 10%, `CANTEEN5` giảm 5.000đ).
    *   Tự động tính toán lại giá trị thanh toán cuối cùng và lưu thông tin mã giảm giá đã dùng vào Firestore của Đơn hàng.
*   **Commit:** `feat(promo): implement discount codes and price recalculation`

#### 3. Trình theo dõi đơn hàng dạng Stepper (Order Progress Stepper)
*   **Tệp cần sửa:** `lib/views/student/order_tracking_screen.dart`
*   **Nhiệm vụ:**
    *   Thay thế hiển thị trạng thái dạng chữ bằng một `Stepper` (hoặc `StepsIndicator`) động.
    *   Tự động đổi màu và vẽ đường nối trạng thái (Pending -> Preparing -> Ready -> Completed) realtime khi trạng thái thay đổi trên Database.
*   **Commit:** `feat(order): design progress stepper for realtime tracking`

---

## 👨‍💻 Nhiệm Vụ Thành Viên 4: Quý (Admin Dashboard + CRUD + Báo Cáo Doanh Thu + Xuất File)

### Thông tin nhánh:
*   Nhánh làm việc: `feature/module-4-admin`
*   Thư mục quản lý chính: `lib/views/admin/`, `lib/services/storage_service.dart`

### Các bước thực hiện & Commits:

#### 1. Màn hình quản lý đơn hàng realtime (AdminOrdersScreen)
*   Hiển thị đơn hàng đang chờ xử lý, có nút cập nhật nhanh trạng thái.
*   **Commit:** `feat(admin): build order list view and status updater`

#### 2. Thêm mới / Chỉnh sửa món ăn (CRUD + Upload Storage)
*   Form tạo món ăn, tích hợp `image_picker` chụp ảnh/chọn ảnh từ máy, tải lên Firebase Storage và ghi URL về Firestore.
*   **Commit:** `feat(admin): implement food CRUD with Firebase Storage upload`

#### 3. Biểu đồ báo cáo doanh thu nâng cao (fl_chart)
*   **Tệp cần tạo:** `lib/views/admin/admin_stats_screen.dart`
*   **Nhiệm vụ:**
    *   Truy vấn đơn hàng đã hoàn thành, gom nhóm doanh thu theo ngày trong tuần.
    *   Dùng thư viện `fl_chart` vẽ biểu đồ hình cột hoặc đường cong biểu diễn sự phát triển doanh thu của căn tin trường.
*   **Commit:** `feat(admin): design analytics dashboard with fl_chart visualization`

#### 4. Tính năng xuất báo cáo doanh thu ra File
*   **Tệp cần sửa:** `lib/views/admin/admin_stats_screen.dart`
*   **Nhiệm vụ:**
    *   Tạo nút "Xuất báo cáo". Khi nhấn, ứng dụng xuất dữ liệu doanh thu thành file text/CSV lưu tại thư mục Documents của điện thoại.
*   **Commit:** `feat(admin): implement sales report exporter to local CSV file`
