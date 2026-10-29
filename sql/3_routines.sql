-- =====================================================================
-- 2.1  Thủ tục thêm / sửa / xóa trên bảng BOOKING
-- 2.3  Thủ tục truy vấn
-- 2.4  Hàm (IF/LOOP, con trỏ, truy vấn, kiểm tra tham số)
-- =====================================================================
USE booking_db;
DELIMITER $$

-- ---------------------------------------------------------------------
-- 2.4 Hàm 1: số tiền hoàn lại nếu hủy đơn vào ngày p_cancel_date
--   Duyệt (con trỏ) từng hạng phòng của đơn, theo gói giá đã chọn:
--     gói hủy miễn phí: hủy trước >= 3 ngày hoàn 100%, 1-2 ngày hoàn 50%, ngày nhận phòng 0%
--     gói không hoàn tiền: 0%
--   Tiền hoàn = số tiền đã thanh toán × (phần được hoàn / tổng giá trị phòng)
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_refund_amount(p_booking_id INT, p_cancel_date DATE) RETURNS DECIMAL(15, 2)
READS SQL DATA
BEGIN
  DECLARE v_status VARCHAR(10);
  DECLARE v_check_in DATE;
  DECLARE v_paid DECIMAL(15, 2);
  DECLARE v_days INT;
  DECLARE v_line DECIMAL(15, 2);
  DECLARE v_free BOOLEAN;
  DECLARE v_subtotal DECIMAL(15, 2) DEFAULT 0;
  DECLARE v_refundable DECIMAL(15, 2) DEFAULT 0;
  DECLARE v_done INT DEFAULT 0;
  DECLARE v_msg VARCHAR(128);
  DECLARE cur_lines CURSOR FOR
    SELECT brt.ROOM_PRICE_AT_BOOKING * brt.RESERVED_QUANTITY, rr.FREE_CANCELLATION
    FROM BOOKING_ROOM_TYPE brt
    JOIN ROOM_RATE rr ON rr.ACCOMMODATION_ID = brt.ACCOMMODATION_ID AND rr.ROOM_NAME = brt.ROOM_NAME
                     AND rr.ROOM_RATE_ID = brt.ROOM_RATE_ID
    WHERE brt.BOOKING_ID = p_booking_id;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  IF p_booking_id IS NULL OR p_cancel_date IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'fn_refund_amount: phải truyền mã đơn và ngày hủy';
  END IF;
  SELECT STATUS, CHECK_IN_DATE INTO v_status, v_check_in FROM BOOKING WHERE BOOKING_ID = p_booking_id;
  IF v_status IS NULL THEN
    SET v_msg = CONCAT('Không tìm thấy đơn đặt phòng ID=', p_booking_id);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF v_status NOT IN ('PENDING', 'CONFIRMED') THEN
    SET v_msg = CONCAT('Đơn đang ở trạng thái ', v_status, ', không thể hủy');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SET v_paid = IFNULL((SELECT AMOUNT FROM PAYMENT
                       WHERE BOOKING_ID = p_booking_id AND PAYMENT_STATUS = 'SUCCESS'), 0);
  IF v_paid = 0 THEN
    RETURN 0;                                  -- chưa thanh toán thì không có gì để hoàn
  END IF;
  SET v_days = DATEDIFF(v_check_in, p_cancel_date);
  IF v_days < 0 THEN
    SET v_msg = CONCAT('Đã qua ngày nhận phòng ', DATE_FORMAT(v_check_in, '%d/%m/%Y'), ', không thể hủy đơn');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SET v_done = 0;
  OPEN cur_lines;
  line_loop: LOOP
    FETCH cur_lines INTO v_line, v_free;
    IF v_done = 1 THEN LEAVE line_loop; END IF;
    SET v_subtotal = v_subtotal + v_line;
    IF v_free THEN
      IF v_days >= 3 THEN
        SET v_refundable = v_refundable + v_line;
      ELSEIF v_days >= 1 THEN
        SET v_refundable = v_refundable + v_line * 0.5;
      END IF;
    END IF;
  END LOOP;
  CLOSE cur_lines;

  IF v_subtotal = 0 THEN
    RETURN 0;
  END IF;
  RETURN ROUND(v_paid * v_refundable / v_subtotal, 2);
END$$

-- ---------------------------------------------------------------------
-- 2.4 Hàm 2: công suất phòng (%) của một cơ sở trong khoảng [p_from, p_to)
--   = số đêm-phòng đã bán (đơn CONFIRMED/COMPLETED) / (số phòng × số ngày) × 100
--   Duyệt (con trỏ) từng dòng đặt phòng, chỉ cộng phần đêm nằm trong khoảng thống kê.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_occupancy_rate(p_accommodation_id INT, p_from DATE, p_to DATE) RETURNS DECIMAL(5, 2)
READS SQL DATA
BEGIN
  DECLARE v_rooms INT;
  DECLARE v_days INT;
  DECLARE v_sold INT DEFAULT 0;
  DECLARE v_in, v_out DATE;
  DECLARE v_qty INT;
  DECLARE v_nights INT;
  DECLARE v_done INT DEFAULT 0;
  DECLARE v_msg VARCHAR(128);
  DECLARE cur_stays CURSOR FOR
    SELECT b.CHECK_IN_DATE, b.CHECK_OUT_DATE, brt.RESERVED_QUANTITY
    FROM BOOKING b JOIN BOOKING_ROOM_TYPE brt ON brt.BOOKING_ID = b.BOOKING_ID
    WHERE b.ACCOMMODATION_ID = p_accommodation_id
      AND b.STATUS IN ('CONFIRMED', 'COMPLETED')
      AND b.CHECK_IN_DATE < p_to AND b.CHECK_OUT_DATE > p_from;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  IF p_accommodation_id IS NULL
     OR NOT EXISTS (SELECT 1 FROM ACCOMMODATION WHERE ACCOMMODATION_ID = p_accommodation_id) THEN
    SET v_msg = CONCAT('Cơ sở lưu trú ID=', IFNULL(p_accommodation_id, 'NULL'), ' không tồn tại');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;
  IF p_from IS NULL OR p_to IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phải nhập đủ ngày bắt đầu và ngày kết thúc';
  END IF;
  IF p_to <= p_from THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày kết thúc phải sau ngày bắt đầu';
  END IF;
  SET v_days = DATEDIFF(p_to, p_from);
  IF v_days > 366 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khoảng thống kê tối đa 366 ngày';
  END IF;
  SET v_rooms = (SELECT COUNT(*) FROM ROOM WHERE ACCOMMODATION_ID = p_accommodation_id);
  IF v_rooms = 0 THEN
    SET v_msg = CONCAT('Cơ sở ID=', p_accommodation_id, ' chưa khai báo phòng nào');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  OPEN cur_stays;
  stay_loop: LOOP
    FETCH cur_stays INTO v_in, v_out, v_qty;
    IF v_done = 1 THEN LEAVE stay_loop; END IF;
    SET v_nights = DATEDIFF(LEAST(v_out, p_to), GREATEST(v_in, p_from));
    IF v_nights > 0 THEN
      SET v_sold = v_sold + v_nights * v_qty;
    END IF;
  END LOOP;
  CLOSE cur_stays;

  RETURN ROUND(100 * v_sold / (v_rooms * v_days), 2);
END$$

-- ---------------------------------------------------------------------
-- 2.1a Thêm đơn đặt phòng (kèm hạng phòng được chọn - đơn không phòng là vô nghĩa)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_insert_booking(
  IN p_user_id INT, IN p_accommodation_id INT, IN p_room_name VARCHAR(50), IN p_room_rate_id INT,
  IN p_quantity INT, IN p_check_in DATE, IN p_check_out DATE, IN p_adults INT, IN p_children INT,
  IN p_eta TIME, IN p_requests VARCHAR(500), OUT p_booking_id INT)
BEGIN
  DECLARE v_age INT;
  DECLARE v_max_adults, v_max_children INT;
  DECLARE v_price DECIMAL(15, 2);
  DECLARE v_effective DATE;
  DECLARE v_dup VARCHAR(20);
  DECLARE v_code VARCHAR(20);
  DECLARE v_msg VARCHAR(128);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

  SET p_children = IFNULL(p_children, 0);

  -- Khách hàng
  IF p_user_id IS NULL THEN
    SET v_msg = 'Vui lòng chọn khách hàng đặt phòng';
  ELSEIF NOT EXISTS (SELECT 1 FROM `USER` WHERE USER_ID = p_user_id) THEN
    SET v_msg = CONCAT('Người dùng ID=', p_user_id, ' không tồn tại');
  ELSEIF NOT EXISTS (SELECT 1 FROM GUEST WHERE USER_ID = p_user_id) THEN
    SET v_msg = CONCAT('Người dùng ID=', p_user_id, ' không phải khách hàng (GUEST), không được đặt phòng');
  END IF;
  IF v_msg IS NULL THEN
    SET v_age = TIMESTAMPDIFF(YEAR, (SELECT BIRTH_DATE FROM GUEST WHERE USER_ID = p_user_id), CURDATE());
    IF v_age < 18 THEN
      SET v_msg = CONCAT('Khách phải đủ 18 tuổi mới được đặt phòng (hiện ', v_age, ' tuổi)');
    END IF;
  END IF;

  -- Cơ sở, hạng phòng, gói giá
  IF v_msg IS NULL THEN
    SET v_max_adults   = (SELECT ADULTS   FROM ROOM_TYPE WHERE ACCOMMODATION_ID = p_accommodation_id AND ROOM_NAME = p_room_name);
    SET v_max_children = (SELECT CHILDREN FROM ROOM_TYPE WHERE ACCOMMODATION_ID = p_accommodation_id AND ROOM_NAME = p_room_name);
    SET v_price     = (SELECT UNIT_PRICE FROM ROOM_RATE WHERE ACCOMMODATION_ID = p_accommodation_id
                         AND ROOM_NAME = p_room_name AND ROOM_RATE_ID = p_room_rate_id);
    SET v_effective = (SELECT EFFECTIVE_DATE FROM ROOM_RATE WHERE ACCOMMODATION_ID = p_accommodation_id
                         AND ROOM_NAME = p_room_name AND ROOM_RATE_ID = p_room_rate_id);
    IF p_accommodation_id IS NULL
       OR NOT EXISTS (SELECT 1 FROM ACCOMMODATION WHERE ACCOMMODATION_ID = p_accommodation_id) THEN
      SET v_msg = CONCAT('Cơ sở lưu trú ID=', IFNULL(p_accommodation_id, 'NULL'), ' không tồn tại');
    ELSEIF v_max_adults IS NULL THEN
      SET v_msg = CONCAT('Cơ sở ID=', p_accommodation_id, ' không có hạng phòng "', IFNULL(p_room_name, ''), '"');
    ELSEIF v_price IS NULL THEN
      SET v_msg = CONCAT('Gói giá ID=', IFNULL(p_room_rate_id, 'NULL'), ' không thuộc hạng phòng "', p_room_name, '"');
    ELSEIF v_effective > CURDATE() THEN
      SET v_msg = CONCAT('Gói giá ID=', p_room_rate_id, ' chỉ áp dụng từ ngày ', DATE_FORMAT(v_effective, '%d/%m/%Y'));
    ELSEIF p_quantity IS NULL OR p_quantity NOT BETWEEN 1 AND 10 THEN
      SET v_msg = 'Số lượng phòng phải từ 1 đến 10';
    END IF;
  END IF;

  -- Ngày lưu trú
  IF v_msg IS NULL THEN
    IF p_check_in IS NULL OR p_check_out IS NULL THEN
      SET v_msg = 'Vui lòng nhập ngày nhận phòng và ngày trả phòng';
    ELSEIF p_check_in < CURDATE() THEN
      SET v_msg = CONCAT('Ngày nhận phòng ', DATE_FORMAT(p_check_in, '%d/%m/%Y'), ' đã qua; ngày đặt phải <= ngày nhận phòng (RB02)');
    ELSEIF p_check_in > CURDATE() + INTERVAL 1 YEAR THEN
      SET v_msg = 'Chỉ nhận đặt phòng trước tối đa 1 năm';
    ELSEIF p_check_out <= p_check_in THEN
      SET v_msg = 'Ngày trả phòng phải sau ngày nhận phòng ít nhất 1 ngày (RB01)';
    ELSEIF DATEDIFF(p_check_out, p_check_in) > 30 THEN
      SET v_msg = 'Mỗi đơn chỉ được lưu trú tối đa 30 đêm';
    END IF;
  END IF;

  -- Số khách
  IF v_msg IS NULL THEN
    IF p_adults IS NULL OR p_adults < 1 THEN
      SET v_msg = 'Đơn phải có ít nhất 1 người lớn (RB03)';
    ELSEIF p_children < 0 THEN
      SET v_msg = 'Số trẻ em không được âm';
    ELSEIF p_adults > v_max_adults * p_quantity
        OR p_adults + p_children > (v_max_adults + v_max_children) * p_quantity THEN
      SET v_msg = CONCAT(p_quantity, ' phòng "', p_room_name, '" chứa tối đa ', v_max_adults * p_quantity,
                         ' người lớn, ', (v_max_adults + v_max_children) * p_quantity, ' khách (RB12)');
    END IF;
  END IF;

  -- Trùng đơn
  IF v_msg IS NULL THEN
    SET v_dup = (SELECT BOOKING_CODE FROM BOOKING
                 WHERE USER_ID = p_user_id AND ACCOMMODATION_ID = p_accommodation_id
                   AND STATUS IN ('PENDING', 'CONFIRMED')
                   AND CHECK_IN_DATE < p_check_out AND CHECK_OUT_DATE > p_check_in
                 LIMIT 1);
    IF v_dup IS NOT NULL THEN
      SET v_msg = CONCAT('Khách đã có đơn ', v_dup, ' tại cơ sở này trùng thời gian lưu trú');
    END IF;
  END IF;

  IF v_msg IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  REPEAT
    SET v_code = CONCAT('BK', DATE_FORMAT(CURDATE(), '%y%m%d'), LPAD(FLOOR(RAND() * 10000), 4, '0'));
  UNTIL NOT EXISTS (SELECT 1 FROM BOOKING WHERE BOOKING_CODE = v_code) END REPEAT;

  START TRANSACTION;
  INSERT INTO BOOKING (STATUS, ADULTS, CHILDREN, BOOKING_CODE, PIN_CODE, BOOKING_DATE, CHECK_IN_DATE,
                       CHECK_OUT_DATE, ESTIMATED_ARRIVAL_TIME, SPECIAL_REQUESTS, USER_ID, ACCOMMODATION_ID)
  VALUES ('PENDING', p_adults, p_children, v_code, LPAD(FLOOR(RAND() * 10000), 4, '0'), CURDATE(), p_check_in,
          p_check_out, p_eta, NULLIF(TRIM(p_requests), ''), p_user_id, p_accommodation_id);
  SET p_booking_id = LAST_INSERT_ID();
  -- trigger kiểm tra phòng trống (RB11) và tính TOTAL_AMOUNT
  INSERT INTO BOOKING_ROOM_TYPE (BOOKING_ID, ACCOMMODATION_ID, ROOM_NAME, ROOM_RATE_ID, ROOM_PRICE_AT_BOOKING, RESERVED_QUANTITY)
  VALUES (p_booking_id, p_accommodation_id, p_room_name, p_room_rate_id, v_price, p_quantity);
  COMMIT;
END$$

-- ---------------------------------------------------------------------
-- 2.1b Sửa đơn: tham số NULL = giữ nguyên.
--   Đổi ngày / số khách: chỉ khi đơn còn mở và chưa tới ngày nhận phòng.
--   Đổi trạng thái theo RB13; hủy đơn -> tự ghi CANCELLATION với tiền hoàn từ fn_refund_amount.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_update_booking(
  IN p_booking_id INT, IN p_check_in DATE, IN p_check_out DATE, IN p_adults INT, IN p_children INT,
  IN p_eta TIME, IN p_requests VARCHAR(500), IN p_status VARCHAR(10), IN p_cancel_reason VARCHAR(255))
BEGIN
  DECLARE v_status VARCHAR(10);
  DECLARE v_in, v_out DATE;
  DECLARE v_adults, v_children INT;
  DECLARE v_paid DECIMAL(15, 2) DEFAULT 0;
  DECLARE v_refund DECIMAL(15, 2) DEFAULT 0;
  DECLARE v_msg VARCHAR(128);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;

  SELECT STATUS, CHECK_IN_DATE, CHECK_OUT_DATE, ADULTS, CHILDREN
    INTO v_status, v_in, v_out, v_adults, v_children
  FROM BOOKING WHERE BOOKING_ID = p_booking_id;

  IF v_status IS NULL THEN
    SET v_msg = CONCAT('Không tìm thấy đơn đặt phòng ID=', IFNULL(p_booking_id, 'NULL'));
  ELSEIF v_status IN ('COMPLETED', 'CANCELLED') THEN
    SET v_msg = CONCAT('Đơn đã ', IF(v_status = 'COMPLETED', 'hoàn thành', 'hủy'), ', không thể chỉnh sửa');
  END IF;
  IF v_msg IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  SET p_check_in  = IFNULL(p_check_in, v_in);
  SET p_check_out = IFNULL(p_check_out, v_out);
  SET p_adults    = IFNULL(p_adults, v_adults);
  SET p_children  = IFNULL(p_children, v_children);
  SET p_status    = IFNULL(NULLIF(p_status, ''), v_status);

  -- Đổi ngày / số khách
  IF p_check_in <> v_in OR p_check_out <> v_out OR p_adults <> v_adults OR p_children <> v_children THEN
    IF v_in <= CURDATE() THEN
      SET v_msg = 'Đã tới ngày nhận phòng, không được đổi ngày hoặc số khách';
    ELSEIF p_check_in < CURDATE() THEN
      SET v_msg = 'Ngày nhận phòng mới không được trước hôm nay';
    ELSEIF p_check_out <= p_check_in THEN
      SET v_msg = 'Ngày trả phòng phải sau ngày nhận phòng ít nhất 1 ngày (RB01)';
    ELSEIF DATEDIFF(p_check_out, p_check_in) > 30 THEN
      SET v_msg = 'Mỗi đơn chỉ được lưu trú tối đa 30 đêm';
    ELSEIF p_adults < 1 THEN
      SET v_msg = 'Đơn phải có ít nhất 1 người lớn (RB03)';
    ELSEIF p_children < 0 THEN
      SET v_msg = 'Số trẻ em không được âm';
    END IF;
  END IF;

  -- Đổi trạng thái
  IF v_msg IS NULL AND p_status <> v_status THEN
    IF p_status NOT IN ('PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED') THEN
      SET v_msg = CONCAT('Trạng thái "', p_status, '" không hợp lệ');
    ELSEIF NOT ((v_status = 'PENDING'   AND p_status IN ('CONFIRMED', 'CANCELLED')) OR
                (v_status = 'CONFIRMED' AND p_status IN ('COMPLETED', 'CANCELLED'))) THEN
      SET v_msg = CONCAT('Không được chuyển trạng thái từ ', v_status, ' sang ', p_status, ' (RB13)');
    ELSEIF p_status = 'COMPLETED' AND v_out > CURDATE() THEN
      SET v_msg = CONCAT('Chưa tới ngày trả phòng ', DATE_FORMAT(v_out, '%d/%m/%Y'), ', chưa thể hoàn thành đơn');
    ELSEIF p_status = 'CANCELLED' THEN
      SET v_paid = IFNULL((SELECT AMOUNT FROM PAYMENT
                           WHERE BOOKING_ID = p_booking_id AND PAYMENT_STATUS = 'SUCCESS'), 0);
      SET v_refund = fn_refund_amount(p_booking_id, CURDATE());   -- tự báo lỗi nếu đã quá hạn hủy
    END IF;
  END IF;

  IF v_msg IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  START TRANSACTION;
  -- trigger kiểm tra RB11 (đổi ngày), RB12 (đổi số khách), RB13 và tính lại TOTAL_AMOUNT
  UPDATE BOOKING
  SET CHECK_IN_DATE          = p_check_in,
      CHECK_OUT_DATE         = p_check_out,
      ADULTS                 = p_adults,
      CHILDREN               = p_children,
      ESTIMATED_ARRIVAL_TIME = IFNULL(p_eta, ESTIMATED_ARRIVAL_TIME),
      SPECIAL_REQUESTS       = IF(p_requests IS NULL, SPECIAL_REQUESTS, NULLIF(TRIM(p_requests), '')),
      STATUS                 = p_status
  WHERE BOOKING_ID = p_booking_id;

  IF p_status = 'CANCELLED' THEN
    INSERT INTO CANCELLATION (BOOKING_ID, CANCELLATION_DATE, REASON, REFUND_STATUS, REFUND_AMOUNT, CANCELLATION_FEE)
    VALUES (p_booking_id, CURDATE(), IFNULL(NULLIF(TRIM(p_cancel_reason), ''), 'Khách yêu cầu hủy'),
            IF(v_refund > 0, 'PENDING', 'NONE'), v_refund, v_paid - v_refund);
  END IF;
  COMMIT;
END$$

-- ---------------------------------------------------------------------
-- 2.1c Xóa đơn.
--   Mục đích: dọn đơn nháp/bỏ dở (PENDING chưa thanh toán) đang giữ chỗ ảo làm
--   khách khác không đặt được phòng, và đơn đã hủy mà không phát sinh tiền.
--   Không được xóa: đơn COMPLETED (lịch sử doanh thu, đánh giá, hạng Genius),
--   đơn CONFIRMED (phải hủy để ghi nhận phí/hoàn tiền), đơn đã có thanh toán (đối soát).
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_delete_booking(IN p_booking_id INT)
BEGIN
  DECLARE v_status VARCHAR(10);
  DECLARE v_code VARCHAR(20);
  DECLARE v_msg VARCHAR(128);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;

  SELECT STATUS, BOOKING_CODE INTO v_status, v_code FROM BOOKING WHERE BOOKING_ID = p_booking_id;

  IF v_status IS NULL THEN
    SET v_msg = CONCAT('Không tìm thấy đơn đặt phòng ID=', IFNULL(p_booking_id, 'NULL'));
  ELSEIF v_status = 'COMPLETED' THEN
    SET v_msg = CONCAT('Đơn ', v_code, ' đã hoàn thành: là dữ liệu lịch sử (doanh thu, đánh giá), không được xóa');
  ELSEIF v_status = 'CONFIRMED' THEN
    SET v_msg = CONCAT('Đơn ', v_code, ' đã xác nhận: hãy hủy đơn (CANCELLED) thay vì xóa');
  ELSEIF EXISTS (SELECT 1 FROM PAYMENT WHERE BOOKING_ID = p_booking_id
                   AND PAYMENT_STATUS IN ('SUCCESS', 'PROCESSING', 'REFUNDED')) THEN
    SET v_msg = CONCAT('Đơn ', v_code, ' đã phát sinh thanh toán, phải giữ lại để đối soát');
  END IF;
  IF v_msg IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
  END IF;

  START TRANSACTION;
  DELETE FROM BOOKING_VOUCHER WHERE BOOKING_ID = p_booking_id;   -- trigger trả voucher về ACTIVE
  DELETE FROM PAYMENT WHERE BOOKING_ID = p_booking_id;           -- chỉ còn giao dịch FAILED
  DELETE FROM BOOKING WHERE BOOKING_ID = p_booking_id;           -- CASCADE: phòng đặt, hủy, tin nhắn
  COMMIT;
END$$

-- ---------------------------------------------------------------------
-- 2.3a Tìm kiếm đơn đặt phòng (BOOKING, USER, ACCOMMODATION) - WHERE + ORDER BY
--   Tham số NULL/rỗng = bỏ qua điều kiện đó.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_search_bookings(
  IN p_keyword VARCHAR(100), IN p_city VARCHAR(50), IN p_status VARCHAR(10), IN p_from DATE, IN p_to DATE)
BEGIN
  IF p_from > p_to THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày bắt đầu tìm kiếm phải trước ngày kết thúc';
  END IF;

  SELECT b.BOOKING_ID, b.BOOKING_CODE, b.USER_ID, u.FULL_NAME AS GUEST_NAME, u.EMAIL,
         b.ACCOMMODATION_ID, a.NAME AS ACCOMMODATION_NAME, a.CITY,
         b.CHECK_IN_DATE, b.CHECK_OUT_DATE, b.TOTAL_NIGHTS, b.ADULTS, b.CHILDREN,
         b.ESTIMATED_ARRIVAL_TIME, b.SPECIAL_REQUESTS, b.STATUS, b.TOTAL_AMOUNT, b.BOOKING_DATE
  FROM BOOKING b
  JOIN `USER` u        ON u.USER_ID = b.USER_ID
  JOIN ACCOMMODATION a ON a.ACCOMMODATION_ID = b.ACCOMMODATION_ID
  WHERE (IFNULL(p_keyword, '') = ''
         OR u.FULL_NAME LIKE CONCAT('%', p_keyword, '%')
         OR u.EMAIL LIKE CONCAT('%', p_keyword, '%')
         OR b.BOOKING_CODE LIKE CONCAT('%', p_keyword, '%')
         OR a.NAME LIKE CONCAT('%', p_keyword, '%'))
    AND (IFNULL(p_city, '') = '' OR a.CITY = p_city)
    AND (IFNULL(p_status, '') = '' OR b.STATUS = p_status)
    AND (p_from IS NULL OR b.CHECK_IN_DATE >= p_from)
    AND (p_to IS NULL OR b.CHECK_IN_DATE <= p_to)
  ORDER BY b.CHECK_IN_DATE DESC, b.BOOKING_ID DESC;
END$$

-- ---------------------------------------------------------------------
-- 2.3b Doanh thu theo cơ sở (ACCOMMODATION, BOOKING, REVIEW)
--   aggregate + WHERE + GROUP BY + HAVING + ORDER BY
--   Chỉ tính đơn COMPLETED có ngày trả phòng trong khoảng; lọc cơ sở có doanh thu >= p_min_revenue.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_revenue_by_accommodation(
  IN p_city VARCHAR(50), IN p_from DATE, IN p_to DATE, IN p_min_revenue DECIMAL(15, 2))
BEGIN
  IF p_from > p_to THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày bắt đầu thống kê phải trước ngày kết thúc';
  END IF;
  IF p_min_revenue < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doanh thu tối thiểu không được âm';
  END IF;

  SELECT a.ACCOMMODATION_ID, a.NAME, a.ACC_TYPE, a.CITY, a.STAR_RATING,
         COUNT(b.BOOKING_ID)         AS COMPLETED_BOOKINGS,
         SUM(b.TOTAL_NIGHTS)         AS NIGHTS_SOLD,
         SUM(b.TOTAL_AMOUNT)         AS REVENUE,
         ROUND(AVG(b.TOTAL_AMOUNT), 2) AS AVG_BOOKING_VALUE,
         COUNT(r.REVIEW_ID)          AS REVIEWS,
         ROUND(AVG(r.OVERALL_SCORE), 2) AS AVERAGE_RATING
  FROM ACCOMMODATION a
  JOIN BOOKING b      ON b.ACCOMMODATION_ID = a.ACCOMMODATION_ID
  LEFT JOIN REVIEW r  ON r.BOOKING_ID = b.BOOKING_ID
  WHERE b.STATUS = 'COMPLETED'
    AND (IFNULL(p_city, '') = '' OR a.CITY = p_city)
    AND (p_from IS NULL OR b.CHECK_OUT_DATE >= p_from)
    AND (p_to IS NULL OR b.CHECK_OUT_DATE <= p_to)
  GROUP BY a.ACCOMMODATION_ID, a.NAME, a.ACC_TYPE, a.CITY, a.STAR_RATING
  HAVING SUM(b.TOTAL_AMOUNT) >= IFNULL(p_min_revenue, 0)
  ORDER BY REVENUE DESC, a.NAME;
END$$

DELIMITER ;
