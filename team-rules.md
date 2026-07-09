# 📏 Quy Tắc Làm Việc Nhóm & Tài Nguyên Sẵn Có (Canteen App)

> Tài liệu này là **bắt buộc đọc** trước khi bắt đầu viết bất kỳ dòng code nào.  
> Mọi thành viên phải tuân theo để đảm bảo code đẹp, không đụng chạm (conflict) và đồng bộ thiết kế.

---

## 🎁 1. Tài Nguyên Đã Có Sẵn (KHÔNG CẦN VIẾT LẠI)

Để tránh việc mọi người làm UI lệch nhau hoặc tự viết lại logic, dự án **đã cài đặt sẵn** các thành phần cốt lõi sau:

### 🎨 Bộ UI Kit dùng chung (Nằm trong `/lib/widgets/`)
Các bạn chỉ việc gọi ra sử dụng và truyền thuộc tính (không tự code lại để UI bị lệch màu/lệch góc bo):
*   `CanteenButton` (`canteen_button.dart`): Nút bấm gradient cam/trắng chuẩn UI, tự động hỗ trợ trạng thái xoay loading (`isLoading: true`).
*   `CanteenTextField` (`canteen_text_field.dart`): Ô nhập liệu bo góc lớn mượt, hỗ trợ icon đầu vào, nút bật/tắt hiển thị mật khẩu tự động và khung validation lỗi.
*   `CanteenCard` (`canteen_card.dart`): Khung card chứa thông tin đổ bóng mịn mượt 3D, hỗ trợ bắt sự kiện click (`onTap`).
*   `StatusBadge` (`status_badge.dart`): Huy hiệu tự động đổi màu theo trạng thái đơn hàng (Chờ xác nhận -> Đang nấu -> Sẵn sàng -> Hoàn thành -> Đã hủy).
*   `ShimmerLoading` (`shimmer_loading.dart`): Bộ xương tải trang giả lập (skeleton loader) cực đẹp khi đợi Firestore tải dữ liệu. Gọi `ShimmerLoading.foodListSkeleton()` để có danh sách load món ăn mẫu.

### ⚙️ Logic Cốt Lõi Đã Cấu Hình Sẵn
*   **State Management:** Đã kết nối `MultiProvider` sẵn trong `main.dart` cho tất cả các ViewModel: `AuthViewModel`, `MenuViewModel`, `CartViewModel`, `OrderViewModel`, `ReviewViewModel`. Mọi người chỉ cần dùng `context.read<T>()` hoặc `context.watch<T>()` trong màn hình của mình.
*   **Database & Storage Services:** `AuthService`, `FirestoreService`, `StorageService`, `NotificationService` đã được viết khung hàm đầy đủ (Đăng nhập, thêm món, tạo đơn, cập nhật trạng thái đơn, upload ảnh, lấy dữ liệu realtime...). Mọi người gọi trực tiếp thông qua các ViewModel tương ứng.
*   **Theme & Colors:**
    *   `AppColors` (`lib/core/constants/app_colors.dart`): Chứa mã màu chuẩn của app (Màu chính: Cam `#FF6B35`, màu phụ, màu chữ, màu trạng thái). **Cấm dùng mã màu cứng `Color(0xFF...)`** trong view.
    *   `AppTheme` (`lib/core/theme/app_theme.dart`): Đã set cấu hình font, nút bấm mặc định của Material 3.

---

## 🌿 2. Phân Chia Git & Nhánh (GitFlow)

Mọi người làm việc trên nhánh **`dev`** làm nhánh tích hợp gốc.

```
main       ← Chỉ merge khi nộp bài (Khánh quản lý)
dev        ← Nhánh tích hợp chung (Mọi người tạo Pull Request vào đây)
feature/   ← Nhánh riêng của mỗi người tự checkout từ dev ra
```

### Quy trình làm việc hàng ngày của mỗi người:
```bash
# 1. Chuyển sang nhánh dev và lấy code mới nhất về
git checkout dev
git pull origin dev

# 2. Tạo nhánh tính năng của bạn (ví dụ An làm giỏ hàng)
git checkout -b feature/cart

# 3. Tiến hành code theo hướng dẫn trong docs/superpowers/plans/implementation_plan.md
# 4. Khi làm xong, đẩy code lên nhánh của mình
git add .
git commit -m "feat(cart): implement checkout screen UI"
git push origin feature/cart

# 5. Lên Github tạo Pull Request (PR) từ nhánh 'feature/cart' vào nhánh 'dev'
# 6. Nhắn nhóm trưởng Khánh duyệt và bấm Merge.
```

---

## 📝 3. Quy chuẩn viết Commit (Commit Convention)

Viết commit theo mẫu: **`type(module): nội dung mô tả ngắn`**

*   `feat`: Tính năng mới (ví dụ: `feat(auth): add register view`)
*   `fix`: Sửa lỗi (ví dụ: `fix(cart): repair item quantity decrement`)
*   `ui`: Sửa giao diện (ví dụ: `ui(menu): adjust food card padding`)
*   `chore`: Thêm thư viện hoặc cấu hình (ví dụ: `chore: add image_picker dependency`)

---

## 📁 4. Phân vùng File để tránh xung đột (Conflict)

Để khi merge code không bị đè lên nhau, các thành viên cam kết chỉ thao tác trong phạm vi của mình:

| Thành viên | Thư mục sở hữu (Tự do code) | File Shared (Báo trước khi sửa) |
|---|---|---|
| **Khánh** | `lib/views/auth/`, `lib/viewmodels/auth_viewmodel.dart`, `lib/services/auth_service.dart`, `lib/models/user_model.dart` | `lib/app.dart`, `lib/main.dart` |
| **Hài** | `lib/views/student/` (phần menu + chi tiết), `lib/viewmodels/menu_viewmodel.dart`, `lib/viewmodels/review_viewmodel.dart`, `lib/models/food_model.dart`, `lib/models/review_model.dart` | `lib/services/firestore_service.dart` |
| **An** | `lib/views/student/` (phần giỏ hàng + đơn hàng), `lib/viewmodels/cart_viewmodel.dart`, `lib/viewmodels/order_viewmodel.dart`, `lib/models/order_model.dart` | `lib/services/firestore_service.dart` |
| **Quý** | `lib/views/admin/`, `lib/viewmodels/admin_viewmodel.dart`, `lib/services/storage_service.dart`, `lib/services/notification_service.dart` | `lib/services/firestore_service.dart` |

---

## 🎨 5. Quy tắc viết code (Clean Code)

1.  **Không viết logic xử lý dữ liệu trong file UI (`_screen.dart`):** File screen chỉ được gọi widget UI và gọi hàm của ViewModel (ví dụ: `authVM.login()`).
2.  **Đặt tên rõ ràng:**
    *   Tên file: `snake_case.dart` (ví dụ: `food_card.dart`).
    *   Tên Class: `PascalCase` (ví dụ: `FoodCard`).
    *   Tên biến / hàm: `camelCase` (ví dụ: `totalPrice`).
3.  **Tối ưu hóa Widget:** Dùng `const` cho các widget tĩnh không thay đổi trạng thái để tăng hiệu năng ứng dụng.
