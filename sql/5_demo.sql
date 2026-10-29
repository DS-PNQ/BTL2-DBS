-- =====================================================================
-- Kịch bản minh họa khi báo cáo. Chạy sau 1 -> 4:
--   mysql --force -t -uroot -p booking_db < 5_demo.sql
-- (--force: chạy tiếp sau các câu cố ý báo lỗi). Script có sửa dữ liệu,
-- muốn làm lại thì chạy lại 1_schema -> 4_data.
-- Dòng "-- => ..." là kết quả mong đợi.
-- =====================================================================
USE booking_db;

-- ========================= 2.4 HÀM =========================
SELECT '2.4 fn_refund_amount' AS test;
-- Đơn 8: gói Standard hủy miễn phí, nhận phòng sau 10 ngày, đã thanh toán
SELECT b.TOTAL_AMOUNT,
       fn_refund_amount(8, CURDATE())                   AS huy_hom_nay,       -- => 100%
       fn_refund_amount(8, CURDATE() + INTERVAL 9 DAY)  AS huy_truoc_1_ngay,  -- => 50%
       fn_refund_amount(8, CURDATE() + INTERVAL 10 DAY) AS huy_ngay_nhan,     -- => 0
       fn_refund_amount(10, CURDATE())                  AS goi_khong_hoan,    -- => 0 (Villa không hoàn tiền)
       fn_refund_amount(12, CURDATE())                  AS chua_thanh_toan    -- => 0
FROM BOOKING b WHERE b.BOOKING_ID = 8;
SELECT fn_refund_amount(1, CURDATE());                    -- => lỗi: đơn COMPLETED không thể hủy
SELECT fn_refund_amount(8, CURDATE() + INTERVAL 20 DAY);  -- => lỗi: đã qua ngày nhận phòng
SELECT fn_refund_amount(999, CURDATE());                  -- => lỗi: không tìm thấy đơn

SELECT '2.4 fn_occupancy_rate' AS test;
SELECT fn_occupancy_rate(1, CURDATE() - INTERVAL 220 DAY, CURDATE() + INTERVAL 30 DAY) AS saigon_riverside,
       fn_occupancy_rate(6, CURDATE() - INTERVAL 150 DAY, CURDATE())                   AS phu_quoc_150_ngay,
       fn_occupancy_rate(6, CURDATE() + INTERVAL 15 DAY, CURDATE() + INTERVAL 18 DAY)  AS phu_quoc_villa_dot_toi;
SELECT fn_occupancy_rate(3, CURDATE(), CURDATE() + INTERVAL 7 DAY);  -- => lỗi: cơ sở chưa khai báo phòng
SELECT fn_occupancy_rate(1, CURDATE(), CURDATE() - INTERVAL 1 DAY);  -- => lỗi: ngày kết thúc phải sau ngày bắt đầu
SELECT fn_occupancy_rate(99, CURDATE(), CURDATE() + INTERVAL 1 DAY); -- => lỗi: cơ sở không tồn tại

-- ========================= 2.3 THỦ TỤC TRUY VẤN =========================
SELECT '2.3 sp_search_bookings' AS test;
CALL sp_search_bookings(NULL, 'Hồ Chí Minh', NULL, NULL, NULL);
CALL sp_search_bookings('An', NULL, 'COMPLETED', CURDATE() - INTERVAL 1 YEAR, CURDATE());
CALL sp_search_bookings(NULL, NULL, NULL, CURDATE(), CURDATE() - INTERVAL 1 DAY);  -- => lỗi khoảng ngày

SELECT '2.3 sp_revenue_by_accommodation' AS test;
CALL sp_revenue_by_accommodation(NULL, NULL, NULL, 0);
CALL sp_revenue_by_accommodation(NULL, CURDATE() - INTERVAL 1 YEAR, CURDATE(), 5000000);  -- HAVING lọc cơ sở < 5tr
CALL sp_revenue_by_accommodation('Hồ Chí Minh', NULL, NULL, -1);                          -- => lỗi doanh thu âm

-- ========================= 2.1 THÊM =========================
SELECT '2.1 sp_insert_booking' AS test;
CALL sp_insert_booking(4, 1, 'Deluxe', 3, 1, CURDATE() + INTERVAL 3 DAY, CURDATE() + INTERVAL 5 DAY, 2, 1, '14:00', 'Phòng yên tĩnh', @new_id);
SELECT BOOKING_ID, BOOKING_CODE, STATUS, TOTAL_NIGHTS, TOTAL_AMOUNT FROM BOOKING WHERE BOOKING_ID = @new_id;  -- => 2 đêm, 1.4tr×2×0.9×1.1
CALL sp_insert_booking(7,  1, 'Deluxe',   3,  1, CURDATE() + INTERVAL 3 DAY,  CURDATE() + INTERVAL 5 DAY,  2, 0, NULL, NULL, @x);  -- => chủ cơ sở không phải GUEST
CALL sp_insert_booking(17, 1, 'Deluxe',   3,  1, CURDATE() + INTERVAL 3 DAY,  CURDATE() + INTERVAL 5 DAY,  2, 0, NULL, NULL, @x);  -- => khách chưa đủ 18 tuổi
CALL sp_insert_booking(3,  1, 'Deluxe',   3,  1, CURDATE() - INTERVAL 1 DAY,  CURDATE() + INTERVAL 1 DAY,  2, 0, NULL, NULL, @x);  -- => RB02 ngày nhận phòng đã qua
CALL sp_insert_booking(3,  1, 'Deluxe',   3,  1, CURDATE() + INTERVAL 5 DAY,  CURDATE() + INTERVAL 5 DAY,  2, 0, NULL, NULL, @x);  -- => RB01
CALL sp_insert_booking(3,  1, 'Deluxe',   3,  1, CURDATE() + INTERVAL 5 DAY,  CURDATE() + INTERVAL 6 DAY,  0, 2, NULL, NULL, @x);  -- => RB03
CALL sp_insert_booking(3,  1, 'Standard', 1,  1, CURDATE() + INTERVAL 5 DAY,  CURDATE() + INTERVAL 6 DAY,  3, 0, NULL, NULL, @x);  -- => RB12 vượt sức chứa
CALL sp_insert_booking(3,  1, 'Standard', 12, 1, CURDATE() + INTERVAL 5 DAY,  CURDATE() + INTERVAL 6 DAY,  2, 0, NULL, NULL, @x);  -- => gói giá chưa hiệu lực
CALL sp_insert_booking(3,  1, 'Deluxe',   1,  1, CURDATE() + INTERVAL 5 DAY,  CURDATE() + INTERVAL 6 DAY,  2, 0, NULL, NULL, @x);  -- => gói giá không thuộc hạng phòng
CALL sp_insert_booking(5,  1, 'Standard', 1,  1, CURDATE() + INTERVAL 11 DAY, CURDATE() + INTERVAL 12 DAY, 2, 0, NULL, NULL, @x);  -- => RB11 hết phòng (trigger)
CALL sp_insert_booking(2,  1, 'Deluxe',   3,  1, CURDATE() + INTERVAL 12 DAY, CURDATE() + INTERVAL 14 DAY, 2, 0, NULL, NULL, @x);  -- => trùng đơn BK00000008

-- ========================= 2.2.1 TRIGGER RB11 =========================
SELECT '2.2.1 trigger phòng trống (RB11)' AS test;
-- Standard có 3 phòng; đêm +11: đơn 8 đặt 2 + đơn 12 đặt 1 = 3 (đầy)
UPDATE BOOKING_ROOM_TYPE SET RESERVED_QUANTITY = 3 WHERE BOOKING_ID = 8;           -- => lỗi hết phòng
DELETE FROM ROOM WHERE ACCOMMODATION_ID = 1 AND ROOM_NAME = 'Standard' AND ROOM_NUMBER = '103';  -- => lỗi hết phòng
CALL sp_insert_booking(4, 1, 'Standard', 1, 1, CURDATE() + INTERVAL 13 DAY, CURDATE() + INTERVAL 15 DAY, 2, 0, NULL, NULL, @k);  -- OK: đơn 8 trả phòng +13
CALL sp_update_booking(@k, CURDATE() + INTERVAL 10 DAY, CURDATE() + INTERVAL 12 DAY, NULL, NULL, NULL, NULL, NULL, NULL);       -- => lỗi hết phòng đêm +11

-- ========================= 2.2.2 TRIGGER TOTAL_AMOUNT =========================
SELECT '2.2.2 trigger TOTAL_AMOUNT' AS test;
SELECT BOOKING_ID, TOTAL_NIGHTS, TOTAL_AMOUNT FROM BOOKING WHERE BOOKING_ID = 12;   -- 900k × 1 đêm × 0.9 × 1.1 = 891.000
INSERT INTO BOOKING_VOUCHER VALUES (12, 'V-CUONG-01');                              -- áp voucher 150k
SELECT BOOKING_ID, TOTAL_AMOUNT FROM BOOKING WHERE BOOKING_ID = 12;                  -- => (900k - 150k) × 1.1 = 825.000
CALL sp_update_booking(12, CURDATE() + INTERVAL 20 DAY, CURDATE() + INTERVAL 23 DAY, NULL, NULL, NULL, NULL, NULL, NULL);
SELECT BOOKING_ID, TOTAL_NIGHTS, TOTAL_AMOUNT FROM BOOKING WHERE BOOKING_ID = 12;    -- => 3 đêm: (2.7tr - 150k) × 1.1 = 2.805.000
DELETE FROM BOOKING_VOUCHER WHERE BOOKING_ID = 12;                                   -- gỡ voucher -> giảm Genius 10%
SELECT b.TOTAL_AMOUNT, v.STATUS FROM BOOKING b, VOUCHER v WHERE b.BOOKING_ID = 12 AND v.VOUCHER_CODE = 'V-CUONG-01';  -- => 2.673.000, ACTIVE

-- ========================= Ràng buộc ngữ nghĩa khác =========================
SELECT 'RB08 / RB09 / RB10 / RB13 / bổ sung' AS test;
INSERT INTO REVIEW (TITLE, CLEANLINESS, COMFORT, LOCATION, FACILITIES, STAFF, VALUE_FOR_MONEY, BOOKING_ID)
VALUES ('Chưa ở', 9, 9, 9, 9, 9, 9, 8);                                  -- => RB08 đơn chưa hoàn thành
INSERT INTO REVIEW (TITLE, CLEANLINESS, COMFORT, LOCATION, FACILITIES, STAFF, VALUE_FOR_MONEY, BOOKING_ID)
VALUES ('Điểm sai', 11, 9, 9, 9, 9, 9, 2);                               -- => RB05 (CHECK)
INSERT INTO BOOKING_VOUCHER VALUES (8, 'V-BINH-OLD');                    -- => RB09 voucher EXPIRED
INSERT INTO BOOKING_VOUCHER VALUES (12, 'V-AN-02');                      -- => voucher của khách khác
INSERT INTO CANCELLATION (BOOKING_ID, REFUND_AMOUNT, CANCELLATION_FEE) VALUES (8, 100, 0);  -- => chỉ cho đơn CANCELLED
UPDATE CANCELLATION SET REFUND_AMOUNT = 0 WHERE BOOKING_ID = 13;        -- => RB10 phí + hoàn ≠ đã trả
UPDATE BOOKING SET STATUS = 'PENDING' WHERE BOOKING_ID = 1;              -- => RB13
UPDATE BOOKING SET ADULTS = 5 WHERE BOOKING_ID = 8;                      -- => RB12 (trigger)
UPDATE RESPONSE SET USER_ID = 9 WHERE REVIEW_ID = 1;                     -- => chủ cơ sở khác không được phản hồi
INSERT INTO PAYMENT (TRANSACTION_CODE, PAYMENT_METHOD, AMOUNT, BOOKING_ID, CARD_NUMBER)
VALUES ('TXN-TEST', 'CARD', 100000, 12, '4111111111111111');              -- => thẻ không thuộc khách của đơn
INSERT INTO GUEST (USER_ID) VALUES (7);                                  -- => chủ cơ sở không thể đồng thời là GUEST (rời nhau)

-- ========================= 2.1 SỬA / XÓA =========================
SELECT '2.1 sp_update_booking' AS test;
CALL sp_update_booking(11, NULL, NULL, NULL, NULL, NULL, NULL, 'COMPLETED', NULL);  -- => RB13 PENDING -> COMPLETED
CALL sp_update_booking(1,  NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL);            -- => đơn đã hoàn thành
CALL sp_update_booking(8,  NULL, NULL, NULL, NULL, NULL, NULL, 'COMPLETED', NULL);  -- => chưa tới ngày trả phòng
CALL sp_update_booking(8,  CURDATE() + INTERVAL 10 DAY, CURDATE() + INTERVAL 9 DAY, NULL, NULL, NULL, NULL, NULL, NULL);  -- => RB01
CALL sp_update_booking(8,  NULL, NULL, NULL, NULL, '16:00', 'Cần thêm gối', 'CANCELLED', 'Thay đổi kế hoạch');           -- OK, hoàn 100%
SELECT b.STATUS, b.SPECIAL_REQUESTS, c.REFUND_AMOUNT, c.CANCELLATION_FEE, p.AMOUNT
FROM BOOKING b JOIN CANCELLATION c USING (BOOKING_ID) JOIN PAYMENT p USING (BOOKING_ID) WHERE b.BOOKING_ID = 8;

SELECT '2.1 sp_delete_booking' AS test;
CALL sp_delete_booking(1);    -- => COMPLETED: không xóa
CALL sp_delete_booking(9);    -- => CONFIRMED: hãy hủy
CALL sp_delete_booking(13);   -- => đã có thanh toán
CALL sp_delete_booking(11);   -- OK: PENDING, chỉ có giao dịch FAILED; voucher V-HAN-01 trả về ACTIVE
SELECT (SELECT COUNT(*) FROM BOOKING WHERE BOOKING_ID = 11) AS con_don_11,
       (SELECT STATUS FROM VOUCHER WHERE VOUCHER_CODE = 'V-HAN-01') AS voucher;
