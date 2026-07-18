# 📋 Hợp Đồng Dữ Liệu Dùng Chung (Firestore Schema)

> **Dự án:** Canteen App (PRM393 - Nhóm 4)  
> **Các bên liên quan:** Hài (Module 2), An (Module 3), Quý (Module 4)  
> **Trạng thái:** ĐÃ KHÓA  

Tài liệu này định nghĩa cấu trúc dữ liệu Firestore chuẩn và kiểu dữ liệu tương ứng trong Dart. Tất cả các thành viên phải tuân thủ nghiêm ngặt để đảm bảo khả năng tích hợp hệ thống.

---

##  Quy Ước Chung
1.  **Quy tắc đặt tên:** camelCase (ví dụ: `userId`, `finalTotal`).
2.  **Mã định danh (ID):** Tất cả là `String` (Firestore Document ID).
3.  **Tiền tệ:** Kiểu `double` (để nhất quán với `FoodModel` hiện có), hiển thị VNĐ bằng cách làm tròn ở UI.
4.  **Thời gian:** Firestore sử dụng `Timestamp`, Dart sử dụng `DateTime`. Khi ghi mới, sử dụng `FieldValue.serverTimestamp()`.

---

## 🍱 1. Collection: `/foods` (Món ăn)
Được tạo/sửa bởi Admin (Module 4) và đọc bởi Student (Module 1, 2, 3).

### Cấu trúc JSON mẫu:
```json
{
  "name": "Cơm tấm sườn bì chả",
  "description": "Cơm tấm dẻo, sườn nướng mật ong...",
  "price": 35000.0,
  "category": "Cơm",
  "imageUrl": "https://images.unsplash.com/...",
  "available": true,
  "avgRating": 4.8,
  "totalReviews": 12,
  "createdAt": "Timestamp"
}
```

### Bàn giao cho Hài (Module 2):
Khi Hài gọi logic thêm món vào giỏ từ UI, hãy truyền đối tượng `FoodModel` có chứa đầy đủ:
*   `id` (String)
*   `name` (String)
*   `imageUrl` (String)
*   `price` (double)
*   `available` (bool)

---

## 🎟️ 2. Collection: `/promos` (Voucher giảm giá)
Được tạo bởi Admin (Module 4) và đọc bởi Student (Module 3).

### Cấu trúc JSON mẫu:
```json
{
  "code": "FPT10",
  "description": "Giảm 10% tối đa 20k cho đơn từ 50k",
  "discountType": "percentage",
  "discountValue": 10.0,
  "minimumOrderAmount": 50000.0,
  "maximumDiscount": 20000.0,
  "startAt": "Timestamp",
  "expiresAt": "Timestamp",
  "isActive": true,
  "usageLimit": 100,
  "usedCount": 5
}
```

### Bàn giao cho Quý (Module 4):
Quý khi viết trang Admin CRUD Voucher phải tuân thủ đúng tên trường:
*   `discountType`: Chỉ nhận `'percentage'` hoặc `'fixed'`.
*   `discountValue`: Số phần trăm (ví dụ: `10.0` tương ứng 10%) hoặc số tiền cố định (ví dụ: `20000.0`).
*   `expiresAt` và `isActive` để kiểm soát hiệu lực.

---

## 🛒 3. Collection: `/orders` (Đơn hàng)
Được tạo bởi Student (Module 3) và cập nhật bởi Admin (Module 4).

### Cấu trúc JSON mẫu:
```json
{
  "displayCode": "CF-260716-4F2A",
  "userId": "firebase-user-uid",
  "userName": "Nguyễn Văn An",
  "userEmail": "annv@fpt.edu.vn",
  "items": [
    {
      "foodId": "food-doc-id-001",
      "foodName": "Cơm tấm sườn bì chả",
      "imageUrl": "https://...",
      "unitPrice": 35000.0,
      "quantity": 2,
      "lineTotal": 70000.0
    }
  ],
  "subtotal": 70000.0,
  "discountAmount": 7000.0,
  "finalTotal": 63000.0,
  "promoId": "promo-doc-id-fpt10",
  "promoCode": "FPT10",
  "pickupAt": "Timestamp",
  "paymentMethod": "cash",
  "paymentStatus": "unpaid",
  "status": "pending",
  "counterNumber": null,
  "cancelReason": null,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  "statusTimestamps": {
    "pending": "Timestamp"
  }
}
```

### Quy tắc cập nhật trạng thái đơn hàng:
1.  **Quy trình trạng thái:** `pending` (Chờ xác nhận) $\rightarrow$ `confirmed` (Đã xác nhận) $\rightarrow$ `preparing` (Đang làm) $\rightarrow$ `ready` (Sẵn sàng lấy) $\rightarrow$ `completed` (Đã nhận đồ).
2.  **Hủy đơn:** `cancelled` (Chỉ Student được hủy khi đơn đang ở trạng thái `pending`).
3.  **Bàn giao cho Quý (Module 4):**
    *   Khi thay đổi trạng thái đơn, bắt buộc phải cập nhật trường `status` bằng chuỗi giá trị tương ứng trong Enum.
    *   Bắt buộc phải cập nhật Map `statusTimestamps` bằng cách thêm entry dạng `{"trạng_thái_mới": FieldValue.serverTimestamp()}` để hỗ trợ Student tracking thời gian chính xác từng bước.
