# 📋 Implementation Plan — Canteen App (Nhóm 4 người)

> **Cập nhật:** 2026-07-09  
> **Mục tiêu scope:** 3.5–4x so với solo project cá nhân (≈ 48 màn hình)  
> **Thầy yêu cầu:** Project nhóm 4 người phải có scope gấp 3-4 lần project cá nhân.

---

## 📊 Tổng quan phân chia (Overview)

| Thành viên | Module | Số màn hình | Độ khó |
|---|---|---|---|
| **Khánh** | Auth + Onboarding + Home + Profile | 12 màn hình | 🟡 Trung bình khá |
| **Hài** | Menu + Search + Filter + Review | 10 màn hình | 🟡 Trung bình khá |
| **An** | Cart + Order + Voucher + Tracking | 12 màn hình | 🟠 Khó |
| **Quý** | Admin Full Panel + Analytics + Broadcast | 14 màn hình | 🔴 Khó nhất |
| **Tổng** | | **48 màn hình** | |

---

## ⚠️ QUY TẮC BẮT BUỘC TRƯỚC KHI LÀM

1. **Kéo code mới nhất từ `dev` trước khi tạo nhánh:**
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feature/module-{n}-{tên}
   ```

2. **Chỉ làm trong thư mục được phân công** (xem mục Phân vùng file trong `team-rules.md`).

3. **Dùng UI Kit dùng chung** — KHÔNG tự thiết kế lại nút, ô nhập liệu, card từ đầu:
   - `CanteenButton` — Nút bấm
   - `CanteenTextField` — Ô nhập liệu
   - `CanteenCard` — Khung chứa thông tin
   - `StatusBadge` — Huy hiệu trạng thái đơn hàng
   - `ShimmerLoading` — Hiệu ứng chờ tải dữ liệu

4. **Commit đúng chuẩn:** `feat(module): mô tả ngắn`

5. **Tạo Pull Request vào `dev`** khi xong mỗi tính năng để có bằng chứng đóng góp nộp thầy.

---

---

# 👤 MODULE 1 — KHÁNH (Auth + Onboarding + Home + Profile)

**Nhánh:** `feature/module-1-auth`  
**Thư mục chính:** `lib/views/auth/`, `lib/views/student/`

---

## Task 1.1 — Splash Screen + Kiểm tra phiên đăng nhập

**Tệp cần tạo:** `lib/views/splash_screen.dart`

**Yêu cầu:**
- Hiển thị logo app + tên "Canteen FPT" trong 2 giây với hiệu ứng fade-in.
- Sau 2 giây, kiểm tra `SharedPreferences` xem user đã đăng nhập chưa:
  - Có → Điều hướng thẳng vào `/home` (student) hoặc `/admin` (admin).
  - Chưa → Điều hướng vào `/onboarding` (lần đầu) hoặc `/login`.
- Lưu key `has_seen_onboarding` vào `SharedPreferences` để phân biệt lần đầu mở app.

**Commit:** `feat(auth): add splash screen with auth state check and role routing`

---

## Task 1.2 — Onboarding (3 slides)

**Tệp cần tạo:** `lib/views/onboarding/onboarding_screen.dart`

**Yêu cầu:**
- 3 slide PageView với nội dung:
  - Slide 1: "Đặt đồ ăn nhanh chóng" — Icon tô phở, mô tả ngắn.
  - Slide 2: "Theo dõi đơn hàng realtime" — Icon đồng hồ, mô tả ngắn.
  - Slide 3: "Thanh toán dễ dàng" — Icon ví tiền, mô tả ngắn.
- Indicator chấm tròn ở dưới hiển thị đang ở slide nào.
- Nút "Tiếp theo" và "Bắt đầu ngay" ở slide cuối → điều hướng vào `/login`.
- Lưu `has_seen_onboarding = true` khi người dùng nhấn "Bắt đầu ngay".

**Commit:** `feat(auth): implement 3-slide onboarding with PageView and dot indicators`

---

## Task 1.3 — Login Screen (nâng cấp)

**Tệp cần sửa:** `lib/views/auth/login_screen.dart` *(Đã có khung cơ bản)*

**Yêu cầu:**
- Dùng `CanteenTextField` và `CanteenButton` từ UI Kit.
- Validate form: Email không rỗng, Password >= 6 ký tự.
- Hiển thị SnackBar lỗi màu đỏ khi đăng nhập thất bại.
- Link "Quên mật khẩu?" → `/forgot-password`.
- Link "Đăng ký ngay" → `/register`.
- Điều hướng theo role sau đăng nhập: `student` → `/home`, `admin` → `/admin`.

**Commit:** `feat(auth): upgrade login screen with validation and role-based routing`

---

## Task 1.4 — Register Screen

**Tệp cần sửa:** `lib/views/auth/register_screen.dart` *(Đã có khung cơ bản)*

**Yêu cầu:**
- Form: Họ tên, Email, Mật khẩu, Xác nhận mật khẩu.
- Validate đầy đủ (email đúng định dạng, password trùng khớp).
- Sau đăng ký thành công → quay lại `/login`.

**Commit:** `feat(auth): complete register screen with full form validation`

---

## Task 1.5 — Forgot Password + Change Password

**Tệp cần tạo:**
- `lib/views/auth/forgot_password_screen.dart` *(Đã có khung)*
- `lib/views/auth/change_password_screen.dart`

**Yêu cầu — Forgot Password:**
- Nhập email, gọi `authVM.resetPassword()`, hiển thị thông báo đã gửi link.

**Yêu cầu — Change Password (trong app khi đã đăng nhập):**
- Form: Mật khẩu hiện tại, Mật khẩu mới, Xác nhận mật khẩu mới.
- Gọi Firebase Auth `updatePassword()` sau khi re-authenticate.
- Truy cập từ màn hình Profile.

**Commit:** `feat(auth): add forgot password and change password screens`

---

## Task 1.6 — Home Dashboard (Màn hình chính của Sinh viên)

**Tệp cần tạo:** `lib/views/student/home_screen.dart`

**Yêu cầu:**
- **Header:** Chào user theo tên ("Xin chào, Khánh 👋"), avatar nhỏ góc phải.
- **Banner carousel:** 3 banner quảng cáo tự chạy (dùng `PageView` + Timer).
- **"Món Hôm Nay":** Section hiển thị tối đa 4 món được Admin ghim là "featured".
- **"Danh mục":** Grid 2 cột các danh mục món ăn (Cơm, Bún, Nước...) → tap vào mở MenuScreen filter sẵn danh mục đó.
- **"Đặt lại nhanh":** Section hiển thị 3 món ăn từ đơn hàng gần nhất của user để đặt lại chỉ 1 click.
- **Bottom Navigation Bar:** Tab Home / Menu / Giỏ hàng / Đơn hàng / Cá nhân.

**Commit:** `feat(home): build student home dashboard with banner, featured foods, categories, and quick-reorder`

---

## Task 1.7 — Bottom Navigation Bar

**Tệp cần tạo:** `lib/views/student/main_navigation_screen.dart`

**Yêu cầu:**
- Widget bao ngoài bọc 5 tab: Home, Menu, Cart (badge số lượng), Orders, Profile.
- Giữ state của từng tab (không reload khi chuyển tab).
- Badge đỏ trên tab Cart hiển thị số món trong giỏ hàng realtime (lấy từ `CartViewModel`).

**Commit:** `feat(home): add bottom navigation bar with cart badge indicator`

---

## Task 1.8 — Profile Screen + Edit Profile

**Tệp cần sửa:** `lib/views/student/profile_screen.dart` *(Đã có khung)*  
**Tệp cần tạo:** `lib/views/student/edit_profile_screen.dart`

**Yêu cầu — Profile Screen:**
- Hiển thị Avatar, Tên, Email, Role.
- Menu các tùy chọn: Chỉnh sửa hồ sơ, Đổi mật khẩu, Cài đặt thông báo, Đăng xuất.

**Yêu cầu — Edit Profile:**
- Cho phép đổi tên hiển thị.
- Upload avatar mới bằng `image_picker` → gọi `StorageService.uploadAvatar()` → cập nhật Firestore.

**Commit:** `feat(profile): complete profile screen and add edit profile with avatar upload`

---

## Task 1.9 — Favorites Screen (Món yêu thích)

**Tệp cần tạo:** `lib/views/student/favorites_screen.dart`

**Yêu cầu:**
- Lưu yêu thích vào Firestore sub-collection: `/users/{userId}/favorites/{foodId}`.
- Nút trái tim ❤️ trên FoodCard và FoodDetail — tap để toggle yêu thích.
- Màn hình Favorites hiển thị danh sách món đã lưu dạng grid 2 cột.
- Nhấn vào món → điều hướng sang FoodDetail.
- Thêm tab "Yêu thích" vào màn hình Profile.

**Commit:** `feat(favorites): implement favorites with Firestore sub-collection and toggle UI`

---

## Task 1.10 — Notification Settings + Personal Stats

**Tệp cần tạo:**
- `lib/views/student/notification_settings_screen.dart`
- Widget Stats trong `profile_screen.dart`

**Yêu cầu — Notification Settings:**
- Toggle bật/tắt thông báo khi đơn hàng được xác nhận.
- Toggle bật/tắt thông báo khi đơn hàng sẵn sàng lấy.
- Lưu preference vào `SharedPreferences`.

**Yêu cầu — Personal Stats (trong Profile):**
- Truy vấn Firestore lấy tất cả đơn hàng của user hiện tại.
- Hiển thị: Tổng số đơn đã đặt, Tổng tiền đã chi tiêu, Món ăn đặt nhiều nhất.

**Commit:** `feat(profile): add notification settings and personal spending stats`

---

---

# 🍱 MODULE 2 — HÀI (Menu + Search + Filter + Review System)

**Nhánh:** `feature/module-2-menu`  
**Thư mục chính:** `lib/views/student/` (phần menu), `lib/viewmodels/menu_viewmodel.dart`

---

## Task 2.1 — FoodCard Widget

**Tệp cần tạo:** `lib/widgets/food_card.dart`

**Yêu cầu:**
- Layout: Ảnh món (CachedNetworkImage), Tên, Giá, Rating trung bình.
- Badge động: "Mới" (nếu thêm trong 7 ngày), "Bán chạy" (nếu totalReviews > 20), "Hết hàng" (nếu available = false).
- Nút "+" thêm vào giỏ hàng góc dưới phải — disabled và mờ đi khi hết hàng.
- Nút ❤️ toggle yêu thích góc trên phải.
- Hiệu ứng shimmer khi đang tải (dùng `ShimmerLoading.foodListSkeleton()`).

**Commit:** `ui(menu): create food card widget with badges, favorites toggle, and shimmer loading`

---

## Task 2.2 — Menu Screen (Danh sách món)

**Tệp cần tạo:** `lib/views/student/menu_screen.dart`

**Yêu cầu:**
- Thanh tìm kiếm ở đầu trang.
- Thanh chip danh mục cuộn ngang (Tất cả / Cơm / Bún / Nước / Tráng miệng / Ăn vặt).
- Nút "Bộ lọc" mở bottom sheet lọc nâng cao.
- `StreamBuilder` lắng nghe `menuVM.foodsStream` — hiển thị dạng grid 2 cột.
- Hiển thị số lượng kết quả: "Tìm thấy 12 món".

**Commit:** `feat(menu): implement menu list screen with category chips and grid layout`

---

## Task 2.3 — Search Screen (Tìm kiếm nâng cao)

**Tệp cần tạo:** `lib/views/student/search_screen.dart`

**Yêu cầu:**
- Ô tìm kiếm với debounce 300ms (không gọi API liên tục khi đang gõ).
- Highlight từ khóa tìm kiếm trong kết quả (tô màu cam phần text trùng khớp).
- Hiển thị "Tìm kiếm gần đây" (lưu lịch sử 5 từ khóa vào `SharedPreferences`).
- Empty state đẹp khi không tìm thấy kết quả ("Không tìm thấy món nào 😢").

**Commit:** `feat(menu): build search screen with debounce, keyword highlight, and history`

---

## Task 2.4 — Advanced Filter Bottom Sheet

**Tệp cần tạo:** `lib/widgets/filter_bottom_sheet.dart`  
**Tệp cần sửa:** `lib/viewmodels/menu_viewmodel.dart`

**Yêu cầu:**
- Sắp xếp: Mặc định / Giá tăng dần / Giá giảm dần / Rating cao nhất / Mới nhất.
- Lọc theo khoảng giá: Slider chọn min-max giá.
- Lọc chỉ hiện "Còn hàng".
- Nút "Áp dụng" → cập nhật `menuVM` → rebuild danh sách.
- Nút "Đặt lại" xóa hết bộ lọc.

**Commit:** `feat(menu): add advanced filter bottom sheet with price range slider and sorting`

---

## Task 2.5 — Food Detail Screen

**Tệp cần tạo:** `lib/views/student/food_detail_screen.dart`

**Yêu cầu:**
- Ảnh lớn ở đầu (hỗ trợ tap để xem toàn màn hình).
- Tên món, mô tả chi tiết, giá, số sao trung bình + số lượt review.
- **Rating Breakdown:** Biểu đồ thanh ngang hiển thị % đánh giá 5⭐ 4⭐ 3⭐ 2⭐ 1⭐.
- Nút "Thêm vào giỏ hàng" sticky ở dưới cùng màn hình.
- Section "Đánh giá" — hiển thị 5 review mới nhất + nút "Xem tất cả".

**Commit:** `feat(menu): build food detail screen with rating breakdown and sticky add-to-cart`

---

## Task 2.6 — Image Full-Screen Viewer

**Tệp cần tạo:** `lib/views/student/image_viewer_screen.dart`

**Yêu cầu:**
- Mở ảnh fullscreen khi tap vào ảnh trong FoodDetail.
- Hỗ trợ zoom (pinch-to-zoom bằng `InteractiveViewer`).
- Nút đóng (X) góc trên phải.

**Commit:** `ui(menu): add full-screen image viewer with pinch-to-zoom`

---

## Task 2.7 — Write Review Screen + All Reviews Screen

**Tệp cần tạo:**
- `lib/views/student/write_review_screen.dart`
- `lib/views/student/all_reviews_screen.dart`

**Yêu cầu — Write Review:**
- Chọn số sao 1-5 (dùng `flutter_rating_bar`).
- Ô nhập bình luận text.
- Validate: Phải chọn sao, bình luận >= 10 ký tự.
- Chỉ cho phép đánh giá sau khi đơn có trạng thái `completed`.
- Gọi `reviewVM.submitReview()` để lưu vào Firestore và cập nhật `avgRating` của món.

**Yêu cầu — All Reviews:**
- Danh sách toàn bộ đánh giá của 1 món, sắp xếp theo mới nhất.
- Hiển thị: Avatar, Tên user, Số sao, Bình luận, Ngày đánh giá.

**Commit:** `feat(review): implement write review screen and all reviews list`

---

## Task 2.8 — "Món Hôm Nay" — Daily Special Screen

**Tệp cần tạo:** `lib/views/student/daily_special_screen.dart`

**Yêu cầu:**
- Màn hình hiển thị các món được Admin đánh dấu `isFeatured: true` trong Firestore.
- Layout đặc biệt: Ảnh to hơn, có thể có giá ưu đãi đặc biệt hôm nay.
- Accessible từ HomeScreen section "Món Hôm Nay".

**Commit:** `feat(menu): add daily special screen for featured foods`

---

---

# 🛒 MODULE 3 — AN (Cart + Checkout + Order + Voucher + Tracking)

**Nhánh:** `feature/module-3-cart`  
**Thư mục chính:** `lib/views/student/` (phần cart/order)

---

## Task 3.1 — Cart Screen

**Tệp cần tạo:** `lib/views/student/cart_screen.dart`

**Yêu cầu:**
- Hiển thị danh sách món trong giỏ (dùng `CartViewModel`).
- Mỗi item: Ảnh nhỏ, Tên món, Giá đơn vị, nút tăng/giảm số lượng, nút xóa.
- Footer: Tổng tiền tạm tính + Nút "Tiến hành thanh toán".
- Empty state khi giỏ trống: Icon giỏ hàng + nút "Khám phá thực đơn".
- Swipe-to-delete để xóa nhanh một món.

**Commit:** `feat(cart): build cart screen with quantity control, swipe-to-delete, and empty state`

---

## Task 3.2 — Voucher Browse Screen (Danh sách mã giảm giá)

**Tệp cần tạo:** `lib/views/student/voucher_screen.dart`

**Yêu cầu:**
- Hiển thị danh sách các mã giảm giá đang active (từ Firestore collection `/promos`).
- Mỗi voucher card: Mã code, Mô tả giảm giá, Ngày hết hạn, Nút "Áp dụng".
- Khi nhấn "Áp dụng" → tự động điền mã vào Checkout và quay lại.
- Badge "Hết hạn" nếu voucher đã qua ngày hết hạn.

**Commit:** `feat(cart): implement voucher browse screen with active promo codes`

---

## Task 3.3 — Checkout Screen (Thanh toán)

**Tệp cần tạo:** `lib/views/student/checkout_screen.dart`

**Yêu cầu:**
- Tóm tắt đơn hàng (danh sách món, tổng tiền tạm tính).
- Chọn giờ nhận đồ ăn (slot: 11:00, 11:30, 12:00, 12:30, 17:00, 17:30).
- Ô nhập mã giảm giá + nút "Áp dụng" → gọi Firestore kiểm tra mã hợp lệ → hiển thị số tiền được giảm.
- Nút shortcut "Chọn từ Voucher của tôi" → mở VoucherScreen.
- Chọn phương thức thanh toán: Tiền mặt / Ví điện tử (mock).
- Tổng tiền cuối (sau giảm giá).
- Nút "Xác nhận đặt hàng" → gọi `cartVM.checkout()`.

**Commit:** `feat(cart): build checkout screen with promo code validation and payment method`

---

## Task 3.4 — Order Success Screen

**Tệp cần tạo:** `lib/views/student/order_success_screen.dart`

**Yêu cầu:**
- Hiệu ứng animation checkmark xanh (dùng Lottie hoặc AnimatedContainer).
- Hiển thị: Mã đơn hàng, Giờ nhận dự kiến, Tổng tiền.
- Nút "Theo dõi đơn hàng" → `/orders/{orderId}/tracking`.
- Nút "Về trang chính".

**Commit:** `feat(order): add order success confirmation screen with animation`

---

## Task 3.5 — Order History Screen

**Tệp cần tạo:** `lib/views/student/order_history_screen.dart`

**Yêu cầu:**
- Tab lọc: Tất cả / Đang xử lý / Hoàn thành / Đã hủy.
- Mỗi đơn hàng: Ngày đặt, Số món, Tổng tiền, `StatusBadge` trạng thái.
- Pull-to-refresh để làm mới danh sách.
- Nhấn vào đơn → sang Order Detail Screen.

**Commit:** `feat(order): implement order history with tab filters and pull-to-refresh`

---

## Task 3.6 — Order Detail Screen

**Tệp cần tạo:** `lib/views/student/order_detail_screen.dart`

**Yêu cầu:**
- Chi tiết đầy đủ: Mã đơn, Ngày đặt, Giờ lấy, Phương thức TT, Mã giảm giá đã dùng (nếu có).
- Danh sách từng món (tên, số lượng, thành tiền).
- Tổng tiền (trước và sau giảm giá).
- `StatusBadge` trạng thái hiện tại.
- Nút "Hủy đơn" nếu trạng thái còn là `pending`.
- Nút "Đánh giá" nếu trạng thái là `completed` và chưa đánh giá.

**Commit:** `feat(order): build order detail screen with cancel and review actions`

---

## Task 3.7 — Realtime Order Tracking (Stepper động)

**Tệp cần tạo:** `lib/views/student/order_tracking_screen.dart`

**Yêu cầu:**
- `StreamBuilder` lắng nghe trực tiếp document đơn hàng từ Firestore.
- Hiển thị **Stepper 4 bước** có animation chuyển trạng thái mượt mà:
  `Chờ xác nhận` → `Đang chuẩn bị` → `Sẵn sàng lấy` → `Hoàn thành`
- Mỗi bước: Icon, label, timestamp khi chuyển trạng thái.
- Bước hiện tại highlight màu cam, bước đã qua màu xanh, bước chưa đến màu xám.
- Khi đơn chuyển sang `ready` → hiển thị banner nhắc "Đến lấy đồ ở quầy số X".

**Commit:** `feat(order): implement animated stepper for realtime order tracking`

---

## Task 3.8 — Cancel Order + Reorder

**Tệp cần sửa:** `lib/views/student/order_detail_screen.dart`  
**Tệp cần tạo:** `lib/views/student/reorder_screen.dart`

**Yêu cầu — Cancel Order:**
- Dialog xác nhận hủy đơn với lý do (Đặt nhầm / Đổi ý / Không lấy được).
- Gọi `firestoreService.updateOrderStatus(orderId, 'cancelled')`.
- Chỉ cho phép hủy khi trạng thái `pending`.

**Yêu cầu — Reorder:**
- Từ Order Detail, nút "Đặt lại đơn này".
- Tự động thêm lại các món của đơn cũ vào giỏ hàng và mở CartScreen.

**Commit:** `feat(order): implement cancel order with reason and one-click reorder`

---

---

# 👨‍🍳 MODULE 4 — QUÝ (Admin Full Panel + Analytics + Broadcast)

**Nhánh:** `feature/module-4-admin`  
**Thư mục chính:** `lib/views/admin/`, `lib/services/`

---

## Task 4.1 — Admin Navigation & Dashboard Home

**Tệp cần tạo:**
- `lib/views/admin/admin_main_navigation.dart`
- `lib/views/admin/admin_dashboard_screen.dart`

**Yêu cầu — Navigation:**
- Drawer hoặc Bottom Nav riêng cho Admin: Dashboard / Đơn hàng / Menu / Khách hàng / Thống kê.

**Yêu cầu — Dashboard:**
- **4 Cards tổng quan:** Đơn hàng hôm nay, Doanh thu hôm nay, Tổng số món ăn, Số món đang hết hàng.
- **Đơn hàng gần nhất:** List 5 đơn mới nhất với StatusBadge.
- **Quick Actions:** Nút tắt nhanh "Thêm món mới", "Xem đơn mới".

**Commit:** `feat(admin): build admin dashboard home with stats cards and quick actions`

---

## Task 4.2 — Admin Orders Management (Realtime)

**Tệp cần tạo:** `lib/views/admin/admin_orders_screen.dart`  
**Tệp cần tạo:** `lib/views/admin/admin_order_detail_screen.dart`

**Yêu cầu — Orders List:**
- `StreamBuilder` lắng nghe tất cả đơn hàng realtime từ Firestore.
- Tab lọc: Tất cả / Chờ xác nhận / Đang làm / Sẵn sàng / Hoàn thành.
- Badge số lượng trên tab "Chờ xác nhận" để Admin biết ngay có đơn mới.

**Yêu cầu — Order Detail (Admin):**
- Xem chi tiết đơn: Thông tin người đặt, danh sách món, giờ lấy.
- **Nút cập nhật trạng thái nhanh:** Xác nhận → Đang làm → Sẵn sàng.
- Sau khi cập nhật sang `ready` → tự động trigger gửi FCM notification đến sinh viên.

**Commit:** `feat(admin): implement realtime order management with status updates and FCM trigger`

---

## Task 4.3 — Food Management CRUD + Image Upload

**Tệp cần tạo:**
- `lib/views/admin/admin_food_list_screen.dart`
- `lib/views/admin/admin_food_form_screen.dart`

**Yêu cầu — Food List:**
- Danh sách tất cả món ăn (bao gồm cả hết hàng).
- Toggle on/off trạng thái "Còn hàng / Hết hàng" ngay trên list.
- Nút xóa món (có dialog xác nhận).
- Nút "Thêm món mới" FAB.

**Yêu cầu — Food Form (Thêm/Sửa):**
- Form: Tên món, Danh mục (Dropdown), Giá, Mô tả, Toggle `isFeatured`.
- Upload ảnh: Chọn ảnh từ thư viện hoặc chụp ảnh bằng `image_picker` → Upload lên Firebase Storage → lưu URL vào Firestore.
- Preview ảnh trước khi lưu.
- Dùng cùng form cho cả Thêm mới và Sửa.

**Commit:** `feat(admin): build food CRUD with image picker and Firebase Storage upload`

---

## Task 4.4 — Category Management

**Tệp cần tạo:** `lib/views/admin/admin_category_screen.dart`

**Yêu cầu:**
- Danh sách danh mục hiện có.
- Thêm danh mục mới (tên + icon).
- Sửa tên danh mục.
- Xóa danh mục (có cảnh báo nếu còn món ăn thuộc danh mục này).
- Lưu danh mục vào Firestore collection `/categories`.

**Commit:** `feat(admin): add category management screen with CRUD operations`

---

## Task 4.5 — Promo Code Management (Quản lý mã giảm giá)

**Tệp cần tạo:** `lib/views/admin/admin_promo_screen.dart`

**Yêu cầu:**
- Danh sách mã giảm giá đang có.
- Mỗi promo: Mã code, Loại giảm (% hoặc số tiền cố định), Giá trị, Ngày hết hạn, Trạng thái.
- Toggle bật/tắt mã giảm giá.
- Form thêm mã mới: Code, Loại giảm (dropdown), Giá trị, Ngày hết hạn.
- Lưu vào Firestore collection `/promos`.

**Commit:** `feat(admin): implement promo code management with percentage and fixed discount types`

---

## Task 4.6 — Customer Management (Quản lý khách hàng)

**Tệp cần tạo:** `lib/views/admin/admin_customer_screen.dart`

**Yêu cầu:**
- Danh sách tất cả sinh viên đã đăng ký.
- Mỗi sinh viên: Avatar, Tên, Email, Tổng số đơn đã đặt, Tổng chi tiêu.
- Nhấn vào sinh viên → xem lịch sử đơn hàng của sinh viên đó.
- Tìm kiếm sinh viên theo tên hoặc email.

**Commit:** `feat(admin): add customer management with order history per student`

---

## Task 4.7 — Revenue Analytics Dashboard (fl_chart)

**Tệp cần tạo:** `lib/views/admin/admin_stats_screen.dart`

**Yêu cầu:**
- **Biểu đồ doanh thu:** Bar chart doanh thu 7 ngày gần nhất (dùng `fl_chart`).
- **Biểu đồ giờ cao điểm:** Bar chart số đơn theo từng giờ trong ngày (giờ nào đông nhất).
- **Top 5 món ăn:** List các món được đặt nhiều nhất trong tuần (kèm số lượt, doanh thu).
- **Bộ lọc thời gian:** Hôm nay / Tuần này / Tháng này.
- **Các số liệu tổng quan:** Tổng đơn, Tổng doanh thu, Đơn trung bình/ngày.

**Commit:** `feat(admin): build analytics dashboard with fl_chart bar charts and top foods`

---

## Task 4.8 — Send Broadcast Notification (Gửi thông báo hàng loạt)

**Tệp cần tạo:** `lib/views/admin/admin_broadcast_screen.dart`

**Yêu cầu:**
- Form: Tiêu đề thông báo, Nội dung thông báo.
- Nút "Gửi đến tất cả sinh viên".
- Lưu lịch sử thông báo đã gửi vào Firestore collection `/broadcasts`.
- Danh sách các thông báo đã gửi trước đó (Tiêu đề, Thời gian gửi, Số người nhận).

**Commit:** `feat(admin): implement broadcast notification screen with history`

---

## Task 4.9 — Export Revenue Report (Xuất báo cáo)

**Tệp cần sửa:** `lib/views/admin/admin_stats_screen.dart`

**Yêu cầu:**
- Nút "Xuất báo cáo CSV" trong màn hình Analytics.
- Khi nhấn: Tạo file text/CSV chứa dữ liệu doanh thu theo ngày.
- Lưu file vào thư mục Documents của thiết bị.
- Hiển thị SnackBar xác nhận đã xuất thành công kèm đường dẫn file.

**Commit:** `feat(admin): implement revenue report export to local CSV file`

---

---

## 🏁 Quy trình Merge và Nộp Bài

```
1. Hoàn thành từng Task → git add . → git commit → git push origin feature/...
2. Lên GitHub tạo Pull Request từ nhánh feature/ vào nhánh dev
3. Nhóm trưởng Khánh review và Merge PR
4. Khi 4 module xong và test tích hợp ổn → Khánh tạo PR từ dev → main
5. Nhánh main = phiên bản demo nộp thầy
```

---

## 📌 Ước tính thời gian

| Thành viên | Tổng tasks | Thời gian ước tính |
|---|---|---|
| Khánh | 10 tasks | 2.5 - 3 tuần |
| Hài | 8 tasks | 2 - 2.5 tuần |
| An | 8 tasks | 2.5 - 3 tuần |
| Quý | 9 tasks | 3 - 3.5 tuần |
