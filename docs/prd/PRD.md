# PRODUCT REQUIREMENTS DOCUMENT (PRD)
**Product Name:** Zairyu Mate
**Version:** 1.0 (MVP)
**Status:** Planning
**Platform:** iOS (iPhone/iPad)

---

## 1. GIỚI THIỆU (Introduction)

### 1.1. Vấn đề (Problem)
*   Thủ tục xin visa/vĩnh trú tại Nhật phức tạp, đòi hỏi điền nhiều form mẫu lặp đi lặp lại.
*   Người dùng thường quên ngày hết hạn visa hoặc ngày cần chuẩn bị giấy tờ.
*   Các giải pháp Web hiện tại (như FormVisa) tốt nhưng bất tiện trên mobile: không tận dụng được phần cứng (NFC, Camera) và quy trình in ấn từ điện thoại còn nhiều bước.

### 1.2. Giải pháp (Solution)
Xây dựng một ứng dụng iOS Native đóng vai trò là **"Ví hồ sơ Visa & Trợ lý ảo"**. Ứng dụng tận dụng tối đa sức mạnh phần cứng iPhone (NFC, FaceID, Local Notification) để tự động hóa nhập liệu và nhắc nhở, đồng thời đồng bộ dữ liệu an toàn qua iCloud cá nhân của người dùng.

### 1.3. Giá trị cốt lõi (USP - Unique Selling Points)
1.  **Zero-Typing:** Quét thẻ Zairyu bằng NFC để điền form (Web không làm được).
2.  **Zero-PII Server:** Không lưu dữ liệu người dùng lên server riêng. Dữ liệu chỉ nằm trên máy và iCloud của khách.
3.  **Local Scheduler:** Nhắc lịch chuẩn bị hồ sơ ngay cả khi không có mạng.

---

## 2. ĐỐI TƯỢNG NGƯỜI DÙNG (User Personas)

*   **Persona A (Gijinkoku):** Kỹ sư IT, bận rộn, ghét thủ tục giấy tờ, thường dùng iPhone đời mới. Cần gia hạn visa nhanh gọn.
*   **Persona B (Eijuu Applicant):** Đang tích lũy điểm HSP hoặc chờ đủ 10 năm. Cần một lộ trình (Timeline) rõ ràng để không bỏ lỡ "thời điểm vàng" nộp hồ sơ.

---

## 3. YÊU CẦU CHỨC NĂNG (Functional Requirements)

### 3.1. Module Nhập liệu & Hồ sơ (Input & Profile)
*   **FR-01: Quét thẻ Zairyu (NFC):**
    *   Sử dụng `CoreNFC` để đọc chip IC trên thẻ Zairyu.
    *   Tự động trích xuất: Họ tên, Ngày sinh, Quốc tịch, Địa chỉ, Số thẻ, Ngày hết hạn, Loại visa.
    *   *Yêu cầu:* Cần nhập mã số thẻ (Card ID) để mở khóa chip (theo quy định của Nyukan).
*   **FR-02: OCR Scanner:**
    *   Sử dụng `Vision Framework` để scan Hộ chiếu (Passport) -> Lấy số hộ chiếu, ngày hết hạn.
*   **FR-03: Profile Management:**
    *   Lưu trữ nhiều profile (Ví dụ: Bản thân + Vợ + Con).
    *   Dữ liệu được lưu trong `Core Data` (Local DB).

### 3.2. Module Điền Form (Form Engine)
*   **FR-04: Auto-Fill PDF:**
    *   Mapping dữ liệu từ Profile vào các mẫu PDF chuẩn của Bộ Tư pháp Nhật (MOJ).
    *   Hỗ trợ các loại đơn:
        *   Gia hạn (Extension of Period of Stay).
        *   Đổi tư cách (Change of Status of Residence).
        *   Vĩnh trú (Permanent Residence).
*   **FR-05: Smart Logic:**
    *   Tự động tích vào các ô Checkbox dựa trên logic (VD: Nếu chọn "Kỹ sư" -> Tự check vào ô "Engineer/Specialist in Humanities...").

### 3.3. Module Lịch trình (Smart Scheduler)
*   **FR-06: Visa Tracker Dashboard:**
    *   Hiển thị đồng hồ đếm ngược (Countdown) tới ngày hết hạn Visa ngay màn hình chính.
*   **FR-07: Timeline Generator:**
    *   Tự động tạo to-do list dựa trên ngày hết hạn.
    *   *Ví dụ:* 3 tháng trước -> Nhắc đi xin giấy thuế; 1 tháng trước -> Nhắc điền form.
*   **FR-08: Local Notifications:**
    *   Gửi thông báo đẩy (Push Notification) nhắc lịch. Hoạt động offline, không cần server.

### 3.4. Module Xuất & In ấn (Output & Print) - *Quan trọng*
*   **FR-09: PDF Preview & Export:**
    *   Xem trước file PDF đã điền.
    *   Cho phép chỉnh sửa thủ công các trường (nếu NFC đọc sai hoặc thiếu).
*   **FR-10: In ấn thông minh (Native Share):**
    *   Nút **"In tại 7-Eleven"**: Tự động mở Share Sheet, ưu tiên gợi ý app *netprint* (nếu đã cài). Nếu chưa cài, hiển thị hướng dẫn tải app.
    *   Nút **"Gửi qua Email"**: Tự động đính kèm PDF vào trình soạn thảo mail (Mail Composer) để người dùng tự gửi hoặc gửi cho dịch vụ in.
    *   Nút **"Lưu vào Tệp" (Save to Files)**.

### 3.5. Module Đồng bộ & Bảo mật (Sync & Security)
*   **FR-11: iCloud Sync:**
    *   Sử dụng `CloudKit` để đồng bộ dữ liệu giữa iPhone và iPad của người dùng.
    *   Đảm bảo người dùng đổi điện thoại không mất dữ liệu.
*   **FR-12: Biometric Lock:**
    *   Yêu cầu FaceID/TouchID khi mở app để bảo vệ thông tin nhạy cảm.

---

## 4. YÊU CẦU PHI CHỨC NĂNG (Non-Functional Requirements)

*   **NFR-01: Privacy (Zero-PII):** App tuyệt đối không gửi bất kỳ dữ liệu cá nhân nào (Tên, tuổi, số thẻ...) về server của Developer (ngoại trừ logs crash ẩn danh).
*   **NFR-02: Offline First:** App phải hoạt động được 100% tính năng cơ bản khi không có internet (trừ việc tải mẫu form mới).
*   **NFR-03: Performance:** Thời gian generate PDF dưới 2 giây.

---

## 5. THIẾT KẾ UX/UI (User Experience)

### 5.1. Luồng chính (Key Flow)
1.  **Home:** Dashboard hiển thị thẻ Zairyu ảo + Đếm ngược ngày hết hạn.
2.  **Action:** Nút "Gia hạn ngay" (Renew Now).
3.  **Input Method:** Popup hỏi "Scan NFC" hay "Nhập tay".
4.  **Verification:** Màn hình review thông tin đã scan.
5.  **Finish:** Màn hình kết quả PDF -> Nút "In ấn" (Share Sheet).

### 5.2. Ngôn ngữ
*   Tiếng Việt (Mặc định), Tiếng Nhật, Tiếng Anh.

---

## 6. CHIẾN LƯỢC KIẾM TIỀN (Monetization Strategy)

Sử dụng mô hình **Freemium + In-App Purchase (IAP)**.

*   **Gói Free (Starter):**
    *   Nhập liệu thủ công (Manual Input).
    *   Tạo lịch trình cơ bản.
    *   Xuất PDF có Watermark mờ.
*   **Gói Pro (One-time Purchase hoặc Subscription nhỏ):**
    *   Mở khóa tính năng **NFC Scan & OCR** (Key selling point).
    *   Đồng bộ **iCloud**.
    *   Xuất PDF sạch (No watermark).
    *   Mở khóa form Vĩnh trú (Eijuu).

---

## 7. CÔNG NGHỆ (Tech Stack)

*   **Language:** Swift 5+
*   **Framework:** SwiftUI (cho giao diện hiện đại, nhanh).
*   **Database:** Core Data + CloudKit Mirroring.
*   **Hardware APIs:** CoreNFC, Vision (OCR), LocalAuthentication (FaceID).
*   **PDF Engine:** PDFKit (Native iOS) hoặc thư viện `TPPDF`.

---

## 8. ROADMAP (Lộ trình phát triển)

*   **Phase 1 (MVP - 4 tuần):**
    *   Nhập liệu thủ công.
    *   Điền form Gia hạn visa (Extension).
    *   Xuất PDF & Share to Files.
    *   Local DB (chưa có CloudKit).
*   **Phase 2 (Tech - 4 tuần):**
    *   Tích hợp NFC Reader (Zairyu Card).
    *   Tích hợp iCloud Sync.
    *   Tích hợp In-App Purchase.
*   **Phase 3 (Expansion - 4 tuần):**
    *   Thêm form Vĩnh trú & Tính điểm HSP.
    *   Tính năng Scheduler & Notification.
    *   Release lên App Store.
