# ⚖️ Đề Xuất Cân Bằng Workload — Chia Bớt Cho Quý

> **Mục tiêu:** Giảm tải Module 4 (Quý) từ 14 → 10-11 màn hình
> **Phương pháp:** Chuyển giao tasks có liên quan sang Module 2 (Hài) và Module 3 (An)

---

## 📊 SO SÁNH WORKLOAD HIỆN TẠI

| Thành viên | Màn hình | Độ khó | Ước tính |
|------------|----------|--------|----------|
| **Khánh** | 12 | 🟡 Trung bình | ✅ Hoàn thành |
| **Hài** | 10 | 🟡 Trung bình | 3-4 tuần |
| **An** | 12 | 🟠 Khó | 4-5 tuần |
| **Quý** | **14** | 🔴 **Rất khó** | **5-6 tuần** ⚠️ |

**Vấn đề:** Quý đang gánh **40% workload** và **khó nhất** → Rủi ro cao nhất!

---

## 🎯 ĐỀ XUẤT CHIA BỚT (3 Phương Án)

---

## 📦 PHƯƠNG ÁN 1: CHIA SẺ FOOD MANAGEMENT (Khuyến nghị)

### Chuyển từ Quý → Hài: **+3 màn hình**

**Lý do:** Hài đang làm Menu/Review → Hiểu rõ Food model nhất

| Task | Màn hình | Chuyển từ | Chuyển đến |
|------|----------|-----------|------------|
| 4.3 | Admin Food CRUD + Image Upload | Quý | Hài |
| 4.4 | Category Management | Quý | Hài |
| 4.5 | Promo Code Management | Quý | Hài |

**Kết quả sau chia:**

| Thành viên | Màn hình | Ghi chú |
|------------|----------|---------|
| **Hài** | **13** (+3) | Food CRUD + Category + Promo |
| **Quý** | **11** (-3) | Giữ lại Admin Dashboard + Orders + Analytics |

---

### Tasks Hài nhận thêm:

#### Task 2.9 — Admin Food CRUD (Chuyển từ 4.3)
**Tệp cần tạo:**
- `lib/views/admin/admin_food_list_screen.dart`
- `lib/views/admin/admin_food_form_screen.dart`

**Yêu cầu:**
- Danh sách tất cả món ăn (bao gồm hết hàng)
- Toggle on/off "Còn hàng / Hết hàng"
- Nút xóa món (dialog xác nhận)
- Nút "Thêm món mới" FAB
- Form: Tên, Danh mục (Dropdown), Giá, Mô tả, Toggle `isFeatured`
- Upload ảnh: `image_picker` → Firebase Storage → URL
- Preview ảnh trước khi lưu

**Commit:** `feat(admin): build food CRUD with image picker and Firebase Storage upload`

---

#### Task 2.10 — Category Management (Chuyển từ 4.4)
**Tệp cần tạo:** `lib/views/admin/admin_category_screen.dart`

**Yêu cầu:**
- Danh sách danh mục hiện có
- Thêm danh mục mới (tên + icon)
- Sửa tên danh mục
- Xóa danh mục (cảnh báo nếu còn món)
- Lưu vào Firestore `/categories`

**Commit:** `feat(admin): add category management screen with CRUD operations`

---

#### Task 2.11 — Promo Code Management (Chuyển từ 4.5)
**Tệp cần tạo:** `lib/views/admin/admin_promo_screen.dart`

**Yêu cầu:**
- Danh sách mã giảm giá đang có
- Mỗi promo: Code, Loại (%, fixed), Giá trị, Hết hạn, Trạng thái
- Toggle bật/tắt mã
- Form thêm mới: Code, Loại, Giá trị, Hết hạn
- Lưu vào Firestore `/promos`

**Commit:** `feat(admin): implement promo code management with percentage and fixed discount types`

---

### Ưu điểm Phương án 1:
✅ Hài hiểu rõ Food model (đang làm Menu)
✅ Tách biệt rõ: Hài = Food-related Admin, Quý = Order + Analytics
✅ Giảm Quý xuống 11 màn hình (vẫn đủ 4x scope)
✅ Tăng Hài lên 13 (vẫn cân bằng)

---

## 📦 PHƯƠNG ÁN 2: CHIA SẺ ORDER MANAGEMENT

### Chuyển từ Quý → An: **+2 màn hình**

**Lý do:** An đang làm Order/Tracking → Hiểu rõ Order flow nhất

| Task | Màn hình | Chuyển từ | Chuyển đến |
|------|----------|-----------|------------|
| 4.2 | Admin Orders Management | Quý | An |

**Kết quả sau chia:**

| Thành viên | Màn hình | Ghi chú |
|------------|----------|---------|
| **An** | **14** (+2) | Thêm Admin Orders |
| **Quý** | **12** (-2) | Giữ Dashboard + Food + Analytics |

---

### Tasks An nhận thêm:

#### Task 3.9 — Admin Orders Management (Chuyển từ 4.2)
**Tệp cần tạo:**
- `lib/views/admin/admin_orders_screen.dart`
- `lib/views/admin/admin_order_detail_screen.dart`

**Yêu cầu — Orders List:**
- `StreamBuilder` realtime từ Firestore
- Tab lọc: Tất cả / Chờ xác nhận / Đang làm / Sẵn sàng / Hoàn thành
- Badge số lượng trên tab "Chờ xác nhận"

**Yêu cầu — Order Detail (Admin):**
- Xem chi tiết: Thông tin người đặt, danh sách món, giờ lấy
- **Nút cập nhật trạng thái nhanh:** Xác nhận → Đang làm → Sẵn sàng
- Sau khi cập nhật `ready` → trigger FCM notification

**Commit:** `feat(admin): implement realtime order management with status updates and FCM trigger`

---

### Ưu điểm Phương án 2:
✅ An hiểu rõ Order model (đang làm Order flow)
✅ FCM trigger liên quan đến Order (An đang làm Tracking)
✅ Giảm Quý xuống 12 màn hình

**Nhược điểm:**
⚠️ An sẽ lên 14 màn hình (nặng hơn)
⚠️ Ít giảm tải hơn so với Phương án 1

---

## 📦 PHƯƠNG ÁN 3: KẾT HỢP (Tối ưu nhất)

### Chuyển từ Quý:
- **→ Hài:** Task 4.3, 4.4, 4.5 (**+3 màn hình**)
- **→ An:** Task 4.2 (**+2 màn hình**)

**Kết quả:**

| Thành viên | Màn hình | Tasks |
|------------|----------|-------|
| **Khánh** | 12 | ✅ Hoàn thành |
| **Hài** | **13** (+3) | Menu + Review + Food CRUD + Category + Promo |
| **An** | **14** (+2) | Cart + Order + Voucher + Admin Orders |
| **Quý** | **9** (-5) | Admin Dashboard + Analytics + Broadcast + Export |

---

### Tasks Quý giữ lại (9 màn hình):

| # | Màn hình | Độ khó | Ghi chú |
|---|----------|--------|---------|
| 4.1 | Admin Navigation + Dashboard | 🟠 Khó | Stats cards, Quick actions |
| 4.6 | Customer Management | 🟠 Khó | User list + Order history |
| 4.7 | Revenue Analytics (fl_chart) | 🔴 Rất khó | Charts, Top foods |
| 4.8 | Broadcast Notification | 🟠 Khó | FCM broadcast |
| 4.9 | Export Revenue Report | 🟡 Trung bình | CSV export |

**Tổng:** 5 tasks chính (9 màn hình) — Giảm từ 14 → 9 ✅

---

## 🆕 ĐỀ XUẤT THÊM TASKS (Tăng Scope)

Nếu muốn tăng scope thêm (để vẫn đạt 3.5-4x), có thể thêm:

### Tasks Mới cho Hài (Module 2):

#### Task 2.12 — Food Statistics Widget
**Màn hình:** Thêm vào Food Detail
- Hiển thị: Số lần được đặt tuần này, Xu hướng tăng/giảm
- Dùng `OrderViewModel` query orders

#### Task 2.13 — Popular Foods Ranking
**Màn hình:** `lib/views/student/popular_foods_screen.dart`
- Top 10 món ăn được đặt nhiều nhất
- Sort: Tuần này / Tháng này / Tất cả thời gian
- Dùng `fl_chart` mini bar chart

---

### Tasks Mới cho An (Module 3):

#### Task 3.10 — Order Statistics Dashboard
**Màn hình:** Thêm vào Order History
- Cards: Tổng đơn, Tổng chi tiêu, Đơn trung bình
- Biểu đồ mini: Số đơn theo tuần (7 ngày)

#### Task 3.11 — Favorite Payment Method
**Màn hình:** Thêm vào Profile
- Thống kê phương thức thanh toán ưa thích
- Pie chart: Tiền mặt vs Ví điện tử

---

### Tasks Mới cho Quý (Module 4):

#### Task 4.10 — Admin Activity Log
**Màn hình:** `lib/views/admin/admin_activity_log_screen.dart`
- Lịch sử các action Admin đã làm (thêm món, cập nhật trạng thái, gửi broadcast)
- Log vào Firestore collection `/admin_logs`
- Hiển thị: Action, Target, Timestamp, Admin name

#### Task 4.11 — Peak Hours Heatmap
**Màn hình:** Thêm vào Analytics Dashboard
- Heatmap: Giờ nào đông nhất trong tuần (dùng `fl_chart` heatmap)
- Data: Query orders group by hour + weekday

---

## 📋 BẢNG SO SÁNH 3 PHƯƠNG ÁN

| Tiêu chí | Phương án 1 | Phương án 2 | Phương án 3 (Kết hợp) |
|----------|-------------|-------------|----------------------|
| **Hài** | 13 (+3) | 10 | 13 (+3) |
| **An** | 12 | 14 (+2) | 14 (+2) |
| **Quý** | 11 (-3) | 12 (-2) | **9 (-5)** ✅ |
| **Cân bằng** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Logic phù hợp** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Khuyến nghị** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## ✅ KHUYẾN NGHỊ CUỐI CÙNG

### 🎯 **Chọn Phương án 3 (Kết hợp)**

**Lý do:**
1. ✅ Giảm Quý xuống **9 màn hình** (từ 14 → 9)
2. ✅ Phân bổ logic nhất:
   - Hài = Food-related (Menu + CRUD + Category + Promo)
   - An = Order-related (Cart + Order + Admin Orders)
   - Quý = Admin Core (Dashboard + Analytics + Broadcast)
3. ✅ Workload cân bằng:
   - Hài: 13 màn hình (trung bình)
   - An: 14 màn hình (khó)
   - Quý: 9 màn hình (rất khó nhưng ít hơn)
4. ✅ Vẫn đạt **48 màn hình** tổng (không giảm scope)

---

## 📝 CẬP NHẬT IMPLEMENTATION PLAN

Sau khi chọn Phương án 3, cần update:

### Module 2 — Hài (13 màn hình)

**Thêm:**
- Task 2.9: Admin Food CRUD (từ 4.3)
- Task 2.10: Category Management (từ 4.4)
- Task 2.11: Promo Code Management (từ 4.5)

**Files cần tạo thêm:**
- `lib/views/admin/admin_food_list_screen.dart`
- `lib/views/admin/admin_food_form_screen.dart`
- `lib/views/admin/admin_category_screen.dart`
- `lib/views/admin/admin_promo_screen.dart`

---

### Module 3 — An (14 màn hình)

**Thêm:**
- Task 3.9: Admin Orders Management (từ 4.2)

**Files cần tạo thêm:**
- `lib/views/admin/admin_orders_screen.dart`
- `lib/views/admin/admin_order_detail_screen.dart`

---

### Module 4 — Quý (9 màn hình)

**Giữ lại:**
- Task 4.1: Admin Navigation + Dashboard
- Task 4.6: Customer Management
- Task 4.7: Revenue Analytics
- Task 4.8: Broadcast Notification
- Task 4.9: Export Revenue Report

**Files cần tạo:**
- `lib/views/admin/admin_main_navigation.dart`
- `lib/views/admin/admin_dashboard_screen.dart`
- `lib/views/admin/admin_customer_screen.dart`
- `lib/views/admin/admin_stats_screen.dart`
- `lib/views/admin/admin_broadcast_screen.dart`

---

## 🚀 HÀNH ĐỘNG TIẾP THEO

1. **Khánh (Nhóm trưởng):** Review và approve Phương án 3
2. **Update `implementation_plan.md`:**
   - Di chuyển Task 4.2 → 3.9 (An)
   - Di chuyển Task 4.3, 4.4, 4.5 → 2.9, 2.10, 2.11 (Hài)
   - Cập nhật số màn hình từng module
3. **Thông báo team** về phân công mới
4. **Bắt đầu coding** theo plan mới

---

## 💡 LƯU Ý QUAN TRỌNG

### Về Admin Screens:
- Tất cả Admin screens đều nằm trong `lib/views/admin/`
- Quý vẫn là owner chính của folder này
- Hài và An chỉ được edit các files được phân công (2.9-2.11 và 3.9)
- **KHÔNG được edit files của nhau** trong folder admin

### Về File Ownership:
Cập nhật `team-rules.md`:

| Thành viên | Thư mục sở hữu (Admin) |
|------------|------------------------|
| **Hài** | `admin_food_list_screen.dart`, `admin_food_form_screen.dart`, `admin_category_screen.dart`, `admin_promo_screen.dart` |
| **An** | `admin_orders_screen.dart`, `admin_order_detail_screen.dart` |
| **Quý** | Tất cả files admin còn lại + `admin_viewmodel.dart` |

---

*Đề xuất bởi Claude Code — Workload Rebalancing Mode*