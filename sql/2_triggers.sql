-- =====================================================================
-- Ràng buộc ngữ nghĩa không viết được bằng CHECK (1.1) + Trigger phần 2.2
--   2.2.1  Ràng buộc nghiệp vụ: không đặt vượt số phòng (RB11 đã sửa)
--   2.2.2  Thuộc tính dẫn xuất: BOOKING.TOTAL_AMOUNT
-- Các RB còn lại đã nằm trong 1_schema.sql:
--   RB01, RB02, RB03, RB04, RB05 = CHECK;  RB06, RB07 = generated column
-- =====================================================================
USE booking_db;
DELIMITER $$

-- ---------------------------------------------------------------------
-- 2.2.1  RB11 (đã sửa): với mỗi đêm, tổng số phòng đã đặt (đơn chưa hủy)
-- của một hạng phòng không vượt quá số phòng thực tế của hạng đó.
-- DML có thể vi phạm:
--   INSERT/UPDATE BOOKING_ROOM_TYPE  (thêm phòng / tăng số lượng / đổi hạng)
--   UPDATE BOOKING                   (đổi ngày nhận/trả phòng)
--   DELETE/UPDATE ROOM               (bớt phòng thực tế của hạng phòng)
--   (BOOKING CANCELLED -> trạng thái khác đã bị RB13 chặn)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_check_availability(IN p_acc INT, IN p_room VARCHAR(50), IN p_from DATE, IN p_to DATE)
BEGIN
  DECLARE v_rooms INT;
  DECLARE v_night DATE;
  DECLARE v_used INT;
  DECLARE v_msg VARCHAR(128);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_night = NULL;

  SET v_rooms = (SELECT COUNT(*) FROM ROOM WHERE ACCOMMODATION_ID = p_acc AND ROOM_NAME = p_room);
  -- sinh từng đêm trong [p_from, p_to), tìm đêm đầu tiên bị đặt vượt
  WITH RECURSIVE NIGHTS (D) AS (
    SELECT p_from
    UNION ALL
    SELECT D + INTERVAL 1 DAY FROM NIGHTS WHERE D + INTERVAL 1 DAY < p_to
  )
  SELECT n.D, SUM(brt.RESERVED_QUANTITY) INTO v_night, v_used
  FROM NIGHTS n
  JOIN BOOKING b ON n.D >= b.CHECK_IN_DATE AND n.D < b.CHECK_OUT_DATE AND b.STATUS <> 'CANCELLED'
  JOIN BOOKING_ROOM_TYPE brt ON brt.BOOKING_ID = b.BOOKING_ID
                            AND brt.ACCOMMODATION_ID = p_acc AND brt.ROOM_NAME = p_room
  GROUP BY n.D
  HAVING SUM(brt.RESERVED_QUANTITY) > v_rooms
  ORDER BY n.D
  LIMIT 1;

  IF v_night IS NOT NULL THEN
    SET v_msg = CONCAT('Hết phòng (RB11): hạng "', p_room, '" có ', v_rooms, ' phòng nhưng đêm ',
                       DATE_FORMAT(v_night, '%d/%m/%Y'), ' đã bị đặt ', v_used, ' phòng');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
END$$

CREATE TRIGGER trg_brt_availability_ai AFTER INSERT ON BOOKING_ROOM_TYPE FOR EACH ROW
BEGIN
  DECLARE v_in, v_out DATE;
  DECLARE v_status VARCHAR(10);
  SELECT CHECK_IN_DATE, CHECK_OUT_DATE, STATUS INTO v_in, v_out, v_status
  FROM BOOKING WHERE BOOKING_ID = NEW.BOOKING_ID;
  IF v_status <> 'CANCELLED' THEN
    CALL sp_check_availability(NEW.ACCOMMODATION_ID, NEW.ROOM_NAME, v_in, v_out);
  END IF;
END$$

CREATE TRIGGER trg_brt_availability_au AFTER UPDATE ON BOOKING_ROOM_TYPE FOR EACH ROW
BEGIN
  DECLARE v_in, v_out DATE;
  DECLARE v_status VARCHAR(10);
  SELECT CHECK_IN_DATE, CHECK_OUT_DATE, STATUS INTO v_in, v_out, v_status
  FROM BOOKING WHERE BOOKING_ID = NEW.BOOKING_ID;
  IF v_status <> 'CANCELLED' THEN
    CALL sp_check_availability(NEW.ACCOMMODATION_ID, NEW.ROOM_NAME, v_in, v_out);
  END IF;
END$$

CREATE TRIGGER trg_booking_availability_au AFTER UPDATE ON BOOKING FOR EACH ROW
BEGIN
  DECLARE v_done INT DEFAULT 0;
  DECLARE v_room VARCHAR(50);
  DECLARE cur_rooms CURSOR FOR SELECT ROOM_NAME FROM BOOKING_ROOM_TYPE WHERE BOOKING_ID = NEW.BOOKING_ID;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  IF NEW.STATUS <> 'CANCELLED'
     AND (NEW.CHECK_IN_DATE <> OLD.CHECK_IN_DATE OR NEW.CHECK_OUT_DATE <> OLD.CHECK_OUT_DATE) THEN
    OPEN cur_rooms;
    room_loop: LOOP
      FETCH cur_rooms INTO v_room;
      IF v_done = 1 THEN LEAVE room_loop; END IF;
      CALL sp_check_availability(NEW.ACCOMMODATION_ID, v_room, NEW.CHECK_IN_DATE, NEW.CHECK_OUT_DATE);
    END LOOP;
    CLOSE cur_rooms;
  END IF;
END$$

CREATE TRIGGER trg_room_availability_ad AFTER DELETE ON ROOM FOR EACH ROW
BEGIN
  DECLARE v_last DATE;
  SET v_last = (SELECT MAX(b.CHECK_OUT_DATE)
                FROM BOOKING b JOIN BOOKING_ROOM_TYPE brt ON brt.BOOKING_ID = b.BOOKING_ID
                WHERE brt.ACCOMMODATION_ID = OLD.ACCOMMODATION_ID AND brt.ROOM_NAME = OLD.ROOM_NAME
                  AND b.STATUS IN ('PENDING', 'CONFIRMED'));
  IF v_last > CURDATE() THEN
    CALL sp_check_availability(OLD.ACCOMMODATION_ID, OLD.ROOM_NAME, CURDATE(), v_last);
  END IF;
END$$

CREATE TRIGGER trg_room_availability_au AFTER UPDATE ON ROOM FOR EACH ROW
BEGIN
  DECLARE v_last DATE;
  IF NEW.ACCOMMODATION_ID <> OLD.ACCOMMODATION_ID OR NEW.ROOM_NAME <> OLD.ROOM_NAME THEN
    SET v_last = (SELECT MAX(b.CHECK_OUT_DATE)
                  FROM BOOKING b JOIN BOOKING_ROOM_TYPE brt ON brt.BOOKING_ID = b.BOOKING_ID
                  WHERE brt.ACCOMMODATION_ID = OLD.ACCOMMODATION_ID AND brt.ROOM_NAME = OLD.ROOM_NAME
                    AND b.STATUS IN ('PENDING', 'CONFIRMED'));
    IF v_last > CURDATE() THEN
      CALL sp_check_availability(OLD.ACCOMMODATION_ID, OLD.ROOM_NAME, CURDATE(), v_last);
    END IF;
  END IF;
END$$

-- ---------------------------------------------------------------------
-- 2.2.2  Thuộc tính dẫn xuất BOOKING.TOTAL_AMOUNT
--   TOTAL_AMOUNT = (Σ giá phòng lúc đặt × số phòng × TOTAL_NIGHTS - giảm giá) × 1.1 (VAT + phí 10%)
--   giảm giá = giá trị voucher nếu đơn có áp voucher, ngược lại = % theo GUEST.GENIUS_LEVEL
--   (1: 10%, 2: 12%, 3: 15%)
-- Phụ thuộc 2 thuộc tính dẫn xuất khác, được tính trước:
--   TOTAL_NIGHTS  : generated column (DBMS tính khi ghi dòng BOOKING)
--   GENIUS_LEVEL  : trigger trg_booking_genius_au (cập nhật khi đơn chuyển COMPLETED)
-- DML làm thay đổi giá trị:
--   INSERT/UPDATE/DELETE BOOKING_ROOM_TYPE  (giá, số phòng)
--   INSERT/DELETE BOOKING_VOUCHER           (áp / gỡ voucher; UPDATE bị chặn)
--   UPDATE BOOKING.CHECK_IN_DATE/CHECK_OUT_DATE (đổi số đêm)
--   INSERT BOOKING                          (đơn mới chưa có phòng -> 0)
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_calc_total(p_booking_id INT, p_nights INT, p_user_id INT) RETURNS DECIMAL(15, 2)
READS SQL DATA
BEGIN
  DECLARE v_subtotal DECIMAL(15, 2);
  DECLARE v_discount DECIMAL(15, 2);
  DECLARE v_level TINYINT;

  SET v_subtotal = p_nights * (SELECT IFNULL(SUM(ROOM_PRICE_AT_BOOKING * RESERVED_QUANTITY), 0)
                               FROM BOOKING_ROOM_TYPE WHERE BOOKING_ID = p_booking_id);
  SET v_discount = (SELECT v.DISCOUNT_VALUE
                    FROM BOOKING_VOUCHER bv JOIN VOUCHER v ON v.VOUCHER_CODE = bv.VOUCHER_CODE
                    WHERE bv.BOOKING_ID = p_booking_id);
  IF v_discount IS NULL THEN
    SET v_level = (SELECT GENIUS_LEVEL FROM GUEST WHERE USER_ID = p_user_id);
    SET v_discount = v_subtotal * CASE v_level WHEN 3 THEN 0.15 WHEN 2 THEN 0.12 ELSE 0.10 END;
  END IF;
  RETURN ROUND(GREATEST(v_subtotal - v_discount, 0) * 1.10, 2);
END$$

CREATE TRIGGER trg_booking_total_bi BEFORE INSERT ON BOOKING FOR EACH ROW
  SET NEW.TOTAL_AMOUNT = 0$$

CREATE TRIGGER trg_booking_total_bu BEFORE UPDATE ON BOOKING FOR EACH ROW
BEGIN
  IF NEW.CHECK_IN_DATE <> OLD.CHECK_IN_DATE OR NEW.CHECK_OUT_DATE <> OLD.CHECK_OUT_DATE THEN
    SET NEW.TOTAL_AMOUNT = fn_calc_total(NEW.BOOKING_ID, DATEDIFF(NEW.CHECK_OUT_DATE, NEW.CHECK_IN_DATE), NEW.USER_ID);
  END IF;
END$$

CREATE TRIGGER trg_brt_total_ai AFTER INSERT ON BOOKING_ROOM_TYPE FOR EACH ROW
  UPDATE BOOKING SET TOTAL_AMOUNT = fn_calc_total(BOOKING_ID, TOTAL_NIGHTS, USER_ID)
  WHERE BOOKING_ID = NEW.BOOKING_ID$$

CREATE TRIGGER trg_brt_total_au AFTER UPDATE ON BOOKING_ROOM_TYPE FOR EACH ROW
  UPDATE BOOKING SET TOTAL_AMOUNT = fn_calc_total(BOOKING_ID, TOTAL_NIGHTS, USER_ID)
  WHERE BOOKING_ID IN (NEW.BOOKING_ID, OLD.BOOKING_ID)$$

CREATE TRIGGER trg_brt_total_ad AFTER DELETE ON BOOKING_ROOM_TYPE FOR EACH ROW
  UPDATE BOOKING SET TOTAL_AMOUNT = fn_calc_total(BOOKING_ID, TOTAL_NIGHTS, USER_ID)
  WHERE BOOKING_ID = OLD.BOOKING_ID$$

CREATE TRIGGER trg_bv_total_ai AFTER INSERT ON BOOKING_VOUCHER FOR EACH ROW
  UPDATE BOOKING SET TOTAL_AMOUNT = fn_calc_total(BOOKING_ID, TOTAL_NIGHTS, USER_ID)
  WHERE BOOKING_ID = NEW.BOOKING_ID$$

CREATE TRIGGER trg_bv_total_ad AFTER DELETE ON BOOKING_VOUCHER FOR EACH ROW
  UPDATE BOOKING SET TOTAL_AMOUNT = fn_calc_total(BOOKING_ID, TOTAL_NIGHTS, USER_ID)
  WHERE BOOKING_ID = OLD.BOOKING_ID$$

-- GENIUS_LEVEL (dẫn xuất từ số đơn COMPLETED trong 2 năm): 0-4 -> 1, 5-14 -> 2, >=15 -> 3
CREATE TRIGGER trg_booking_genius_au AFTER UPDATE ON BOOKING FOR EACH ROW
BEGIN
  DECLARE v_completed INT;
  IF NEW.STATUS = 'COMPLETED' AND OLD.STATUS <> 'COMPLETED' THEN
    SET v_completed = (SELECT COUNT(*) FROM BOOKING
                       WHERE USER_ID = NEW.USER_ID AND STATUS = 'COMPLETED'
                         AND CHECK_OUT_DATE >= CURDATE() - INTERVAL 2 YEAR);
    UPDATE GUEST
    SET GENIUS_LEVEL = CASE WHEN v_completed >= 15 THEN 3 WHEN v_completed >= 5 THEN 2 ELSE 1 END
    WHERE USER_ID = NEW.USER_ID;
  END IF;
END$$

-- ---------------------------------------------------------------------
-- RB12 (đã sửa): tổng khách <= tổng sức chứa (sức chứa hạng phòng × số phòng đặt)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_check_capacity(IN p_booking_id INT, IN p_adults INT, IN p_children INT)
BEGIN
  DECLARE v_max_adults, v_max_guests INT;
  DECLARE v_msg VARCHAR(128);
  SELECT SUM(rt.ADULTS * brt.RESERVED_QUANTITY), SUM((rt.ADULTS + rt.CHILDREN) * brt.RESERVED_QUANTITY)
    INTO v_max_adults, v_max_guests
  FROM BOOKING_ROOM_TYPE brt
  JOIN ROOM_TYPE rt ON rt.ACCOMMODATION_ID = brt.ACCOMMODATION_ID AND rt.ROOM_NAME = brt.ROOM_NAME
  WHERE brt.BOOKING_ID = p_booking_id;

  IF v_max_guests IS NOT NULL AND (p_adults > v_max_adults OR p_adults + p_children > v_max_guests) THEN
    SET v_msg = CONCAT('Vượt sức chứa (RB12): ', p_adults, ' người lớn + ', p_children,
                       ' trẻ em, phòng đã đặt chứa tối đa ', v_max_adults, ' người lớn / ', v_max_guests, ' khách');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
END$$

CREATE TRIGGER trg_brt_capacity_ai AFTER INSERT ON BOOKING_ROOM_TYPE FOR EACH ROW
BEGIN
  DECLARE v_adults, v_children INT;
  SELECT ADULTS, CHILDREN INTO v_adults, v_children FROM BOOKING WHERE BOOKING_ID = NEW.BOOKING_ID;
  CALL sp_check_capacity(NEW.BOOKING_ID, v_adults, v_children);
END$$

CREATE TRIGGER trg_brt_capacity_au AFTER UPDATE ON BOOKING_ROOM_TYPE FOR EACH ROW
BEGIN
  DECLARE v_adults, v_children INT;
  SELECT ADULTS, CHILDREN INTO v_adults, v_children FROM BOOKING WHERE BOOKING_ID = NEW.BOOKING_ID;
  CALL sp_check_capacity(NEW.BOOKING_ID, v_adults, v_children);
END$$

CREATE TRIGGER trg_brt_capacity_ad AFTER DELETE ON BOOKING_ROOM_TYPE FOR EACH ROW
BEGIN
  DECLARE v_adults, v_children INT;
  SELECT ADULTS, CHILDREN INTO v_adults, v_children FROM BOOKING WHERE BOOKING_ID = OLD.BOOKING_ID;
  CALL sp_check_capacity(OLD.BOOKING_ID, v_adults, v_children);
END$$

CREATE TRIGGER trg_booking_capacity_bu BEFORE UPDATE ON BOOKING FOR EACH ROW
BEGIN
  IF NEW.ADULTS <> OLD.ADULTS OR NEW.CHILDREN <> OLD.CHILDREN THEN
    CALL sp_check_capacity(NEW.BOOKING_ID, NEW.ADULTS, NEW.CHILDREN);
  END IF;
END$$

-- ---------------------------------------------------------------------
-- RB13 (đã sửa): PENDING -> CONFIRMED -> COMPLETED | CANCELLED, và PENDING -> CANCELLED
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_booking_status_bu BEFORE UPDATE ON BOOKING FOR EACH ROW
BEGIN
  DECLARE v_msg VARCHAR(128);
  IF NEW.STATUS <> OLD.STATUS AND NOT (
       (OLD.STATUS = 'PENDING'   AND NEW.STATUS IN ('CONFIRMED', 'CANCELLED')) OR
       (OLD.STATUS = 'CONFIRMED' AND NEW.STATUS IN ('COMPLETED', 'CANCELLED'))) THEN
    SET v_msg = CONCAT('Không được chuyển trạng thái đơn từ ', OLD.STATUS, ' sang ', NEW.STATUS, ' (RB13)');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
END$$

-- ---------------------------------------------------------------------
-- RB08: chỉ đánh giá đơn COMPLETED, ngày đánh giá >= ngày trả phòng
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_check_review(IN p_booking_id INT, IN p_review_date DATE)
BEGIN
  DECLARE v_status VARCHAR(10);
  DECLARE v_out DATE;
  DECLARE v_msg VARCHAR(128);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_status = NULL;
  SELECT STATUS, CHECK_OUT_DATE INTO v_status, v_out FROM BOOKING WHERE BOOKING_ID = p_booking_id;
  IF v_status <> 'COMPLETED' THEN
    SET v_msg = CONCAT('Chỉ được đánh giá đơn đã hoàn thành (RB08); đơn ', p_booking_id, ' đang ', v_status);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF p_review_date < v_out THEN
    SET v_msg = CONCAT('Ngày đánh giá phải từ ngày trả phòng ', DATE_FORMAT(v_out, '%d/%m/%Y'), ' trở đi (RB08)');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
END$$

CREATE TRIGGER trg_review_bi BEFORE INSERT ON REVIEW FOR EACH ROW
  CALL sp_check_review(NEW.BOOKING_ID, NEW.REVIEW_DATE)$$

CREATE TRIGGER trg_review_bu BEFORE UPDATE ON REVIEW FOR EACH ROW
  CALL sp_check_review(NEW.BOOKING_ID, NEW.REVIEW_DATE)$$

-- ---------------------------------------------------------------------
-- RB09: voucher ACTIVE, chưa hết hạn tại ngày đặt; (bổ sung) đúng khách được cấp.
-- Voucher dùng 1 lần: áp vào đơn -> USED, gỡ khỏi đơn -> ACTIVE/EXPIRED.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_check_voucher(IN p_booking_id INT, IN p_code VARCHAR(20))
BEGIN
  DECLARE v_status VARCHAR(10);
  DECLARE v_expiry, v_booking_date DATE;
  DECLARE v_owner, v_guest INT;
  DECLARE v_msg VARCHAR(128);
  DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;

  SELECT STATUS, EXPIRY_DATE, USER_ID INTO v_status, v_expiry, v_owner FROM VOUCHER WHERE VOUCHER_CODE = p_code;
  SELECT BOOKING_DATE, USER_ID INTO v_booking_date, v_guest FROM BOOKING WHERE BOOKING_ID = p_booking_id;
  IF v_status IS NULL THEN
    SET v_msg = CONCAT('Voucher ', p_code, ' không tồn tại');
  ELSEIF v_owner <> v_guest THEN
    SET v_msg = CONCAT('Voucher ', p_code, ' được cấp cho khách khác, không áp dụng cho đơn này');
  ELSEIF v_status <> 'ACTIVE' THEN
    SET v_msg = CONCAT('Voucher ', p_code, ' đang ở trạng thái ', v_status, ', chỉ voucher ACTIVE mới dùng được (RB09)');
  ELSEIF v_booking_date > v_expiry THEN
    SET v_msg = CONCAT('Voucher ', p_code, ' hết hạn ngày ', DATE_FORMAT(v_expiry, '%d/%m/%Y'), ', trước ngày đặt (RB09)');
  END IF;
  IF v_msg IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
END$$

CREATE TRIGGER trg_bv_check_bi BEFORE INSERT ON BOOKING_VOUCHER FOR EACH ROW
  CALL sp_check_voucher(NEW.BOOKING_ID, NEW.VOUCHER_CODE)$$

CREATE TRIGGER trg_bv_block_bu BEFORE UPDATE ON BOOKING_VOUCHER FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không sửa voucher đã áp dụng; hãy gỡ voucher cũ rồi áp mã mới'$$

CREATE TRIGGER trg_bv_used_ai AFTER INSERT ON BOOKING_VOUCHER FOR EACH ROW
  UPDATE VOUCHER SET STATUS = 'USED' WHERE VOUCHER_CODE = NEW.VOUCHER_CODE$$

CREATE TRIGGER trg_bv_restore_ad AFTER DELETE ON BOOKING_VOUCHER FOR EACH ROW
  UPDATE VOUCHER SET STATUS = IF(EXPIRY_DATE < CURDATE(), 'EXPIRED', 'ACTIVE')
  WHERE VOUCHER_CODE = OLD.VOUCHER_CODE$$

-- ---------------------------------------------------------------------
-- RB10: phí hủy + tiền hoàn = số tiền đã thanh toán (chưa thanh toán -> cả hai = 0)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_check_cancellation(IN p_booking_id INT, IN p_fee DECIMAL(15, 2), IN p_refund DECIMAL(15, 2))
BEGIN
  DECLARE v_paid DECIMAL(15, 2);
  DECLARE v_msg VARCHAR(128);
  IF (SELECT STATUS FROM BOOKING WHERE BOOKING_ID = p_booking_id) <> 'CANCELLED' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ ghi nhận thông tin hủy cho đơn ở trạng thái CANCELLED';
  END IF;
  SET v_paid = IFNULL((SELECT AMOUNT FROM PAYMENT
                       WHERE BOOKING_ID = p_booking_id AND PAYMENT_STATUS IN ('SUCCESS', 'REFUNDED')), 0);
  IF p_fee + p_refund <> v_paid THEN
    SET v_msg = CONCAT('Phí hủy + tiền hoàn = ', p_fee + p_refund, ' phải bằng số tiền đã thanh toán ', v_paid, ' (RB10)');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
END$$

CREATE TRIGGER trg_cancellation_bi BEFORE INSERT ON CANCELLATION FOR EACH ROW
  CALL sp_check_cancellation(NEW.BOOKING_ID, NEW.CANCELLATION_FEE, NEW.REFUND_AMOUNT)$$

CREATE TRIGGER trg_cancellation_bu BEFORE UPDATE ON CANCELLATION FOR EACH ROW
  CALL sp_check_cancellation(NEW.BOOKING_ID, NEW.CANCELLATION_FEE, NEW.REFUND_AMOUNT)$$

-- ---------------------------------------------------------------------
-- Bổ sung: thẻ thanh toán phải của chính khách đặt đơn và còn hạn
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_check_payment(IN p_booking_id INT, IN p_card VARCHAR(19), IN p_date DATETIME)
BEGIN
  DECLARE v_owner INT;
  DECLARE v_expiry DATE;
  DECLARE v_msg VARCHAR(128);
  DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;
  IF p_card IS NOT NULL THEN
    SELECT USER_ID, EXPIRY_DATE INTO v_owner, v_expiry FROM PAYMENT_CARD WHERE CARD_NUMBER = p_card;
    IF v_owner <> (SELECT USER_ID FROM BOOKING WHERE BOOKING_ID = p_booking_id) THEN
      SET v_msg = CONCAT('Thẻ ****', RIGHT(p_card, 4), ' không thuộc khách hàng của đơn này');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
    IF v_expiry < DATE(p_date) THEN
      SET v_msg = CONCAT('Thẻ ****', RIGHT(p_card, 4), ' đã hết hạn ngày ', DATE_FORMAT(v_expiry, '%d/%m/%Y'));
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_payment_bi BEFORE INSERT ON PAYMENT FOR EACH ROW
  CALL sp_check_payment(NEW.BOOKING_ID, NEW.CARD_NUMBER, NEW.PAYMENT_DATE)$$

CREATE TRIGGER trg_payment_bu BEFORE UPDATE ON PAYMENT FOR EACH ROW
  CALL sp_check_payment(NEW.BOOKING_ID, NEW.CARD_NUMBER, NEW.PAYMENT_DATE)$$

-- ---------------------------------------------------------------------
-- Bổ sung: chỉ chủ cơ sở được phản hồi đánh giá về cơ sở của mình, sau ngày đánh giá
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_check_response(IN p_review_id INT, IN p_host_id INT, IN p_date DATE)
BEGIN
  DECLARE v_owner INT;
  DECLARE v_review_date DATE;
  DECLARE v_msg VARCHAR(128);
  DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;
  SELECT a.USER_ID, r.REVIEW_DATE INTO v_owner, v_review_date
  FROM REVIEW r
  JOIN BOOKING b ON b.BOOKING_ID = r.BOOKING_ID
  JOIN ACCOMMODATION a ON a.ACCOMMODATION_ID = b.ACCOMMODATION_ID
  WHERE r.REVIEW_ID = p_review_id;
  IF v_owner <> p_host_id THEN
    SET v_msg = CONCAT('Chỉ chủ cơ sở (USER_ID=', v_owner, ') mới được phản hồi đánh giá ', p_review_id);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF p_date < v_review_date THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày phản hồi không được trước ngày đánh giá';
  END IF;
END$$

CREATE TRIGGER trg_response_bi BEFORE INSERT ON RESPONSE FOR EACH ROW
  CALL sp_check_response(NEW.REVIEW_ID, NEW.USER_ID, NEW.RESPONSE_DATE)$$

CREATE TRIGGER trg_response_bu BEFORE UPDATE ON RESPONSE FOR EACH ROW
  CALL sp_check_response(NEW.REVIEW_ID, NEW.USER_ID, NEW.RESPONSE_DATE)$$

DELIMITER ;
