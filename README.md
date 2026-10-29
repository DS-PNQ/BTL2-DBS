# BTL2 – Hệ thống quản lý đặt phòng du lịch (tham khảo Booking.com)

Hiện thực BTL2 trên **MySQL 8.0.16+** dựa trên lược đồ quan hệ của BTL1, kèm ứng dụng web Node.js kết nối trực tiếp CSDL.

## Cấu trúc

| File | Nội dung | Mục đề bài |
|---|---|---|
| `sql/1_schema.sql` | 36 bảng, khóa chính/ngoại, CHECK, generated column | 1.1 |
| `sql/2_triggers.sql` | Trigger cho ràng buộc ngữ nghĩa không viết được bằng CHECK, trigger 2.2.1 và 2.2.2 | 1.1, 2.2 |
| `sql/3_routines.sql` | Thủ tục thêm/sửa/xóa `BOOKING`, 2 thủ tục truy vấn, 2 hàm | 2.1, 2.3, 2.4 |
| `sql/4_data.sql` | Dữ liệu mẫu, mọi bảng ≥ 5 dòng | 1.2 |
| `sql/5_demo.sql` | Câu lệnh minh họa khi báo cáo, có ghi kết quả mong đợi | 2.x |
| `app/` | Ứng dụng web (Express + mysql2) | 3.1, 3.2, 3.3 |

## Cách chạy

```bash
mysql -uroot -p --default-character-set=utf8mb4 < sql/1_schema.sql
mysql -uroot -p --default-character-set=utf8mb4 < sql/2_triggers.sql
mysql -uroot -p --default-character-set=utf8mb4 < sql/3_routines.sql
mysql -uroot -p --default-character-set=utf8mb4 < sql/4_data.sql
mysql -uroot -p --force -t booking_db < sql/5_demo.sql   # tùy chọn, sẽ sửa dữ liệu
```

Có thể mở từng file trong MySQL Workbench và chạy theo thứ tự trên. Muốn đưa dữ liệu về ban đầu thì chạy lại 1 → 4.

Ứng dụng (cần Node.js 18+):

```bash
cd app
npm install
DB_PASSWORD=matkhau npm start      # Windows PowerShell: $env:DB_PASSWORD="matkhau"; npm start
```

Mở http://localhost:3000. Biến môi trường: `DB_HOST` (localhost), `DB_PORT` (3306), `DB_USER` (root), `DB_PASSWORD` (rỗng), `DB_NAME` (booking_db), `PORT` (3000).

Ứng dụng có 2 tab:
- **Đơn đặt phòng** (3.1 + 3.2): danh sách lấy từ `sp_search_bookings` (tìm theo từ khóa, thành phố, trạng thái, khoảng ngày); bấm tiêu đề cột để sắp xếp; nút *Đặt phòng mới* / *Sửa* / *Xóa* gọi `sp_insert_booking`, `sp_update_booking`, `sp_delete_booking`. Form kiểm tra dữ liệu ở trình duyệt, lỗi nghiệp vụ hiện đúng thông báo của CSDL. Khi chọn trạng thái *Đã hủy*, form gọi `fn_refund_amount` để xem trước tiền hoàn và phí hủy.
- **Thống kê** (3.3): doanh thu theo cơ sở (`sp_revenue_by_accommodation`) và công suất phòng (`fn_occupancy_rate`).

## Lỗi phát hiện trong BTL1 và cách sửa

| # | Lỗi trong BTL1 | Sửa trong BTL2 |
|---|---|---|
| 1 | **RB11** nói về hai đơn dùng chung một *phòng thực tế* (ROOM), nhưng lược đồ không có liên kết BOOKING → ROOM (đơn chỉ gắn với ROOM_TYPE qua BOOKING_ROOM_TYPE) nên không kiểm tra được. Điều kiện chỉ so từng cặp đơn, bỏ qua `RESERVED_QUANTITY`. | Kiểm tra theo **hạng phòng, từng đêm**: tổng số phòng đã đặt (đơn chưa hủy) ≤ số ROOM của hạng đó (`sp_check_availability`, trigger 2.2.1). |
| 2 | **RB12**: Bảng 1 ghi thực thể là `BOOKING, ROOM` nhưng nội dung dùng ROOM_TYPE; công thức so tổng khách với sức chứa **một** hạng phòng, sai khi đơn đặt nhiều phòng hoặc nhiều hạng. | Tổng khách ≤ Σ(sức chứa × số phòng đặt), đồng thời người lớn ≤ Σ(ADULTS × số phòng). |
| 3 | **RB13** cấm `PENDING → CANCELLED`: đơn chưa thanh toán không thể hủy, mâu thuẫn với mô tả I.1.3 (Chờ thanh toán / Đã hủy). | Cho phép thêm `PENDING → CANCELLED`. |
| 4 | `BOOKING_VOUCHER` có khóa `(BOOKING_ID, VOUCHER_CODE)` → một đơn áp được nhiều voucher, trái với “mỗi đơn tối đa một mã”. Voucher có trạng thái `USED` nhưng lại mô tả N:1 “một mã áp cho nhiều đơn” (mâu thuẫn). Không ràng buộc voucher phải do chính khách được cấp sử dụng. | Khóa chính `BOOKING_ID`, `VOUCHER_CODE` UNIQUE (dùng một lần); trigger kiểm tra chủ voucher, tự chuyển `USED` khi áp và trả lại `ACTIVE` khi gỡ. |
| 5 | Các mối liên kết **1:1** ánh xạ thiếu UNIQUE: `REVIEW.BOOKING_ID`, `PAYMENT.BOOKING_ID` (thanh toán thành công), `CANCELLATION` có khóa `(BOOKING_ID, CANCELLATION_ID)` cho phép nhiều lần hủy một đơn. | Thêm UNIQUE; với PAYMENT dùng cột sinh `PAID_BOOKING_ID` + UNIQUE để chỉ giới hạn giao dịch SUCCESS/REFUNDED (giao dịch FAILED vẫn được nhiều). |
| 6 | `WISHLIST` dùng khóa thay thế `WISHLIST_ID` nên mất ràng buộc “mỗi cặp khách – cơ sở chỉ xuất hiện một lần”. | UNIQUE `(USER_ID, ACCOMMODATION_ID)`. |
| 7 | `GENIUS_LEVEL` được mô tả là thuộc tính của GUEST nhưng không có trong lược đồ GUEST. Các thuộc tính dẫn xuất `TOTAL_NIGHTS`, `TOTAL_AMOUNT`, `OVERALL_SCORE` cũng không xuất hiện. | Thêm `GENIUS_LEVEL` (trigger), `TOTAL_NIGHTS`/`OVERALL_SCORE` (generated column), `TOTAL_AMOUNT` (trigger 2.2.2). `AVERAGE_RATING` tính khi truy vấn. |
| 8 | Công thức `TOTAL_AMOUNT` có “thuế và phí dịch vụ” và gói giá (ăn sáng, hủy miễn phí) nhưng BOOKING_ROOM_TYPE không ghi khách chọn gói nào → không tính được tiền hoàn, không biết đơn có ăn sáng. | Thêm `BOOKING_ROOM_TYPE.ROOM_RATE_ID` (FK tới ROOM_RATE); thuế + phí cố định 10%. |
| 9 | Không đảm bảo hạng phòng trong BOOKING_ROOM_TYPE thuộc **đúng cơ sở** của đơn (BOOKING.ACCOMMODATION_ID có thể khác). | FK kép `(BOOKING_ID, ACCOMMODATION_ID) → BOOKING`. |
| 10 | Chuyên biệt hóa **rời nhau** (USER → GUEST/HOST/ADMIN, ACCOMMODATION → 4 loại hình, PHOTO thuộc cơ sở *hoặc* hạng phòng) không được thể hiện: một USER_ID có thể nằm ở cả GUEST và HOST. | Cột phân loại (`USER_TYPE`, `ACC_TYPE`, `PHOTO_TYPE`) + FK kép từ lớp con, kiểm tra bằng CHECK, không cần trigger. |
| 11 | `REFER` cho phép người dùng tự giới thiệu chính mình. | CHECK `REFERRED_USER_ID <> REFERRER_ID`. |
| 12 | `WALLET_TRANSACTION(USER_ID, TRANSACTION_HISTORY)` lưu lịch sử là một chuỗi, không có số tiền/thời điểm nên không “theo dõi biến động” được. | `(USER_ID, TRANSACTION_TIME, AMOUNT, DESCRIPTION)`. |
| 13 | Thiếu các ràng buộc ngầm định trong mô tả: thẻ thanh toán phải của chính khách đặt đơn và còn hạn; thanh toán `CARD` phải có số thẻ; chỉ chủ cơ sở mới phản hồi đánh giá về cơ sở mình. | CHECK `CK_PAY_CARD` + trigger trên PAYMENT, RESPONSE. |

Còn để ngỏ (không ảnh hưởng yêu cầu BTL2): tin nhắn chưa ràng buộc người gửi phải là khách hoặc chủ cơ sở của đơn; `AVAILABILITY_STATUS` của ROOM chỉ là trạng thái hiện tại nên không dùng để tính phòng trống theo ngày.

## Hiện thực 13 ràng buộc ngữ nghĩa

| RB | Cách hiện thực |
|---|---|
| RB01 check-out > check-in | CHECK `RB01_CHECKOUT_AFTER_CHECKIN` |
| RB02 ngày đặt ≤ check-in | CHECK `RB02_BOOKED_BEFORE_CHECKIN` |
| RB03 ≥ 1 người lớn | CHECK `RB03_MIN_ONE_ADULT` |
| RB04 sao 1–5 | CHECK `RB04_STAR` |
| RB05 điểm 1–10 | CHECK `RB05_SCORE_RANGE` |
| RB06 số đêm | Generated column `BOOKING.TOTAL_NIGHTS` |
| RB07 điểm tổng thể | Generated column `REVIEW.OVERALL_SCORE` |
| RB08 đánh giá sau lưu trú | `trg_review_bi/bu` → `sp_check_review` |
| RB09 hiệu lực voucher | `trg_bv_check_bi` → `sp_check_voucher` |
| RB10 bảo toàn tài chính khi hủy | `trg_cancellation_bi/bu` → `sp_check_cancellation` |
| RB11 không đặt vượt phòng (đã sửa) | Trigger 2.2.1 (xem dưới) |
| RB12 sức chứa (đã sửa) | `trg_brt_capacity_ai/au/ad`, `trg_booking_capacity_bu` → `sp_check_capacity` |
| RB13 chuỗi trạng thái (đã sửa) | `trg_booking_status_bu` |

## Phần 2 – danh sách để phân công trình bày

| Mục | Đối tượng | Ghi chú |
|---|---|---|
| 2.1 | `sp_insert_booking` | Kiểm tra khách là GUEST, đủ 18 tuổi, cơ sở/hạng phòng/gói giá hợp lệ và đang hiệu lực, ngày (RB01, RB02, ≤ 30 đêm), số khách (RB03, RB12), đơn trùng; sinh mã đơn và PIN. |
| 2.1 | `sp_update_booking` | NULL = giữ nguyên; chỉ đổi ngày/số khách khi đơn còn mở và chưa tới ngày nhận phòng; chuyển trạng thái theo RB13; hủy đơn tự ghi CANCELLATION với tiền hoàn từ `fn_refund_amount`. |
| 2.1 | `sp_delete_booking` | Chỉ xóa đơn nháp chưa phát sinh thanh toán (giải phóng phòng bị giữ ảo); từ chối đơn COMPLETED (lịch sử), CONFIRMED (phải hủy), đơn có thanh toán (đối soát). |
| 2.2.1 | `trg_brt_availability_ai/au`, `trg_booking_availability_au`, `trg_room_availability_au/ad` | Không đặt vượt số phòng. DML gây vi phạm: thêm/sửa BOOKING_ROOM_TYPE, đổi ngày BOOKING, xóa/chuyển ROOM. |
| 2.2.2 | `trg_booking_total_bi/bu`, `trg_brt_total_ai/au/ad`, `trg_bv_total_ai/ad` (+ `fn_calc_total`) | `TOTAL_AMOUNT = (Σ giá × số phòng × TOTAL_NIGHTS − giảm giá) × 1.1`; giảm giá = voucher, nếu không có thì theo `GENIUS_LEVEL` (10/12/15%). `TOTAL_NIGHTS` (generated column) và `GENIUS_LEVEL` (`trg_booking_genius_au`) được tính trước. |
| 2.3 | `sp_search_bookings` | BOOKING ⋈ USER ⋈ ACCOMMODATION, WHERE theo từ khóa/thành phố/trạng thái/khoảng ngày, ORDER BY. |
| 2.3 | `sp_revenue_by_accommodation` | ACCOMMODATION ⋈ BOOKING ⟕ REVIEW, COUNT/SUM/AVG, WHERE, GROUP BY, HAVING doanh thu tối thiểu, ORDER BY. |
| 2.4 | `fn_refund_amount(booking, ngày hủy)` | Con trỏ duyệt từng hạng phòng của đơn; IF theo gói hủy miễn phí và số ngày trước khi nhận phòng (≥3: 100%, 1–2: 50%, 0: 0%). |
| 2.4 | `fn_occupancy_rate(cơ sở, từ, đến)` | Con trỏ duyệt các đơn CONFIRMED/COMPLETED giao với khoảng, cộng phần đêm nằm trong khoảng; = đêm-phòng bán / (số phòng × số ngày) × 100. |
