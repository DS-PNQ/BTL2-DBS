-- =====================================================================
-- 1.2 Dữ liệu mẫu (>= 5 dòng mỗi bảng)
-- Ngày đặt phòng tính tương đối theo CURDATE() để demo đúng ở bất kỳ ngày nào.
-- Mọi dòng đi qua CHECK + trigger thật; trạng thái đơn chuyển bằng sp_update_booking.
-- =====================================================================
USE booking_db;

-- ---------------- Người dùng ----------------
INSERT INTO `USER` (USER_ID, USER_TYPE, EMAIL, PASSWORD, FULL_NAME, PHONE_NUMBER, PROFILE_IMAGE, CREATED_DATE, STREET_ADDRESS, WARD, DISTRICT, CITY) VALUES
(1,  'G', 'an.nguyen@gmail.com',     SHA2('An@12345', 256),    'Nguyễn Văn An',    '0901234567', 'https://img.example.com/u1.jpg',  '2023-01-15', '12 Lê Lợi',          'Bến Nghé',     'Quận 1',       'Hồ Chí Minh'),
(2,  'G', 'binh.tran@gmail.com',     SHA2('Binh@12345', 256),  'Trần Thị Bình',    '0912345678', NULL,                              '2023-03-02', '45 Hai Bà Trưng',    'Tràng Tiền',   'Hoàn Kiếm',    'Hà Nội'),
(3,  'G', 'cuong.le@gmail.com',      SHA2('Cuong@12345', 256), 'Lê Hoàng Cường',   '0923456789', NULL,                              '2023-06-20', '88 Nguyễn Văn Linh', 'Nam Dương',    'Hải Châu',     'Đà Nẵng'),
(4,  'G', 'dung.pham@yahoo.com',     SHA2('Dung@12345', 256),  'Phạm Thu Dung',    '0934567890', 'https://img.example.com/u4.jpg',  '2024-01-10', '3 Trần Phú',         'Lộc Thọ',      'Nha Trang',    'Khánh Hòa'),
(5,  'G', 'duc.vo@outlook.com',      SHA2('Duc@12345', 256),   'Võ Minh Đức',      '0945678901', NULL,                              '2024-04-05', '20 Võ Văn Tần',      'Võ Thị Sáu',   'Quận 3',       'Hồ Chí Minh'),
(6,  'G', 'han.dang@gmail.com',      SHA2('Han@12345', 256),   'Đặng Gia Hân',     '0956789012', NULL,                              '2024-08-18', '7 Phan Đình Phùng',  'Phường 1',     'Đà Lạt',       'Lâm Đồng'),
(7,  'H', 'huy.hoang@saigonhotel.vn', SHA2('Huy@12345', 256),  'Hoàng Quốc Huy',   '0967890123', NULL,                              '2022-05-01', '1 Tôn Đức Thắng',    'Bến Nghé',     'Quận 1',       'Hồ Chí Minh'),
(8,  'H', 'lan.bui@hanoiheritage.vn', SHA2('Lan@12345', 256),  'Bùi Thị Lan',      '0978901234', NULL,                              '2022-07-12', '22 Hàng Bạc',        'Hàng Bạc',     'Hoàn Kiếm',    'Hà Nội'),
(9,  'H', 'phong.ngo@pqresort.vn',   SHA2('Phong@12345', 256), 'Ngô Thanh Phong',  '0989012345', NULL,                              '2022-09-30', '99 Trần Hưng Đạo',   'Dương Đông',   'Phú Quốc',     'Kiên Giang'),
(10, 'H', 'anh.do@dalatstay.vn',     SHA2('Anh@12345', 256),   'Đỗ Mai Anh',       '0990123456', NULL,                              '2023-02-14', '5 Hoàng Hoa Thám',   'Phường 10',    'Đà Lạt',       'Lâm Đồng'),
(11, 'H', 'khoa.trinh@dnapart.vn',   SHA2('Khoa@12345', 256),  'Trịnh Văn Khoa',   '0381234567', NULL,                              '2023-05-25', '15 Võ Nguyên Giáp',  'Phước Mỹ',     'Sơn Trà',      'Đà Nẵng'),
(12, 'A', 'admin.root@booking.vn',   SHA2('Root@12345', 256),  'Phạm Nhật Quang',  '0392345678', NULL,                              '2022-01-01', '268 Lý Thường Kiệt', 'Phường 14',    'Quận 10',      'Hồ Chí Minh'),
(13, 'A', 'mod.kien@booking.vn',     SHA2('Kien@12345', 256),  'Lê Chí Kiên',      '0703456789', NULL,                              '2022-01-01', '268 Lý Thường Kiệt', 'Phường 14',    'Quận 10',      'Hồ Chí Minh'),
(14, 'A', 'support.khoa@booking.vn', SHA2('Khoa2@12345', 256), 'Phan Anh Khoa',    '0704567890', NULL,                              '2022-02-01', '268 Lý Thường Kiệt', 'Phường 14',    'Quận 10',      'Hồ Chí Minh'),
(15, 'A', 'finance.nguyen@booking.vn', SHA2('Nguyen@12345', 256), 'Lê Thị Nguyên', '0705678901', NULL,                              '2022-02-01', '268 Lý Thường Kiệt', 'Phường 14',    'Quận 10',      'Hồ Chí Minh'),
(16, 'A', 'content.quang@booking.vn', SHA2('Quang@12345', 256), 'Nguyễn Trọng Đăng Quang', '0706789012', NULL,                     '2022-03-01', '268 Lý Thường Kiệt', 'Phường 14',    'Quận 10',      'Hồ Chí Minh'),
(17, 'G', 'khang.ly@gmail.com',      SHA2('Khang@12345', 256), 'Lý Minh Khang',    '0707890123', NULL,                              '2025-06-01', '9 Nguyễn Trãi',      'Bến Thành',    'Quận 1',       'Hồ Chí Minh');

INSERT INTO GUEST (USER_ID, BIRTH_DATE, GENDER) VALUES
(1, '1995-04-12', 'M'), (2, '1998-09-23', 'F'), (3, '1990-01-30', 'M'), (4, '2000-12-05', 'F'),
(5, '1987-07-17', 'M'), (6, '2003-03-08', 'F'),
(17, CURDATE() - INTERVAL 16 YEAR, 'M');          -- khách chưa đủ 18 tuổi (demo validate)

INSERT INTO HOST (USER_ID, TAX_CODE, BUSINESS_NAME, BANK_ACCOUNT) VALUES
(7,  '0301234567',     'Công ty TNHH Saigon Hospitality',  '0071000123456'),
(8,  '0102345678',     'Công ty CP Hanoi Heritage Hotels', '1903456789012'),
(9,  '1701234567',     'Công ty CP Phu Quoc Resort',       '0201000456789'),
(10, '5801234567-001', 'Hộ kinh doanh Dalat Stay',         '060123456789'),
(11, '0401234567',     'Công ty TNHH Danang Apartments',   '0041000789123');

INSERT INTO ADMIN (USER_ID, ADMIN_ROLE) VALUES
(12, 'SUPER_ADMIN'), (13, 'MODERATOR'), (14, 'SUPPORT'), (15, 'FINANCE'), (16, 'CONTENT');

INSERT INTO REFER (REFERRED_USER_ID, REFERRER_ID) VALUES (2, 1), (3, 1), (4, 2), (5, 3), (6, 4);

INSERT INTO WALLET (USER_ID, BALANCE, LOYALTY_POINTS) VALUES
(1, 1250000, 820), (2, 300000, 240), (3, 0, 150), (4, 500000, 60), (5, 150000, 90), (6, 0, 10);

INSERT INTO WALLET_TRANSACTION (USER_ID, TRANSACTION_TIME, AMOUNT, DESCRIPTION) VALUES
(1, '2025-12-20 10:00:00',  1000000, 'Nạp tiền vào ví'),
(1, '2026-01-05 08:30:00',   250000, 'Hoàn tiền khuyến mãi Genius'),
(2, '2026-02-14 19:20:00',   300000, 'Thưởng giới thiệu bạn bè'),
(4, '2026-03-01 09:00:00',   600000, 'Nạp tiền vào ví'),
(4, '2026-03-10 15:45:00',  -100000, 'Thanh toán phí dịch vụ'),
(5, '2026-04-22 11:10:00',   150000, 'Thưởng giới thiệu bạn bè');

INSERT INTO COMPANION (USER_ID, COMPANION_NO, FULL_NAME, BIRTH_DATE, PHONE_NUMBER) VALUES
(1, 1, 'Nguyễn Thị Mai', '1996-02-20', '0909111222'),
(1, 2, 'Nguyễn Gia Bảo', '2019-08-01', NULL),
(2, 1, 'Trần Văn Nam',   '1997-11-11', '0919222333'),
(3, 1, 'Lê Thị Hoa',     '1992-05-05', '0929333444'),
(5, 1, 'Võ Thị Lan',     '1989-10-10', '0949555666');

INSERT INTO PAYMENT_CARD (CARD_NUMBER, CARDHOLDER_NAME, EXPIRY_DATE, CARD_TYPE, USER_ID) VALUES
('4111111111111111', 'NGUYEN VAN AN',  '2029-08-31', 'VISA',       1),
('5555555555554444', 'TRAN THI BINH',  '2028-05-31', 'MASTERCARD', 2),
('3530111333300000', 'LE HOANG CUONG', '2030-01-31', 'JCB',        3),
('4012888888881881', 'PHAM THU DUNG',  '2028-12-31', 'VISA',       4),
('5105105105105100', 'VO MINH DUC',    '2029-03-31', 'MASTERCARD', 5),
('378282246310005',  'DANG GIA HAN',   '2027-11-30', 'AMEX',       6);

INSERT INTO VOUCHER (VOUCHER_CODE, DISCOUNT_VALUE, APPLICABLE_CONDITIONS, EXPIRY_DATE, STATUS, USER_ID) VALUES
('V-AN-01',    200000, 'Đơn từ 1.000.000đ',         CURDATE() - INTERVAL 100 DAY, 'ACTIVE',  1),
('V-AN-02',    300000, 'Đơn từ 2.000.000đ',         CURDATE() + INTERVAL 90 DAY,  'ACTIVE',  1),
('V-BINH-01',  250000, 'Áp dụng mọi cơ sở',         CURDATE() + INTERVAL 30 DAY,  'ACTIVE',  2),
('V-BINH-OLD', 100000, 'Khuyến mãi hè',             CURDATE() - INTERVAL 10 DAY,  'EXPIRED', 2),
('V-CUONG-01', 150000, 'Thành viên mới',            CURDATE() + INTERVAL 60 DAY,  'ACTIVE',  3),
('V-DUNG-01',  400000, 'Đơn từ 3.000.000đ',         CURDATE() + INTERVAL 60 DAY,  'ACTIVE',  4),
('V-DUC-01',   500000, 'Resort 5 sao',              CURDATE() + INTERVAL 45 DAY,  'ACTIVE',  5),
('V-HAN-01',   100000, 'Căn hộ dịch vụ',            CURDATE() + INTERVAL 20 DAY,  'ACTIVE',  6);

-- ---------------- Cơ sở lưu trú ----------------
INSERT INTO ACCOMMODATION (ACCOMMODATION_ID, ACC_TYPE, NAME, DESCRIPTION, STAR_RATING, CHECK_IN_TIME, CHECK_OUT_TIME, CANCELLATION_POLICY, PET_POLICY, CHILD_POLICY, CONTACT_EMAIL, PHONE_NUMBER, STREET_ADDRESS, WARD, DISTRICT, CITY, LONGITUDE, LATITUDE, USER_ID) VALUES
(1,  'HOTEL',     'Saigon Riverside Hotel',        'Khách sạn ven sông Sài Gòn, gần phố đi bộ Nguyễn Huệ', 4, '14:00', '12:00', 'Tùy gói giá',              'Không nhận thú cưng', 'Trẻ dưới 6 tuổi miễn phí', 'booking@saigonriverside.vn', '02838220011', '19 Tôn Đức Thắng',   'Bến Nghé',   'Quận 1',      'Hồ Chí Minh', 106.706000, 10.776000, 7),
(2,  'HOTEL',     'Hanoi Old Quarter Hotel',       'Khách sạn trong lòng phố cổ',                         4, '14:00', '12:00', 'Hủy miễn phí trước 3 ngày', 'Không nhận thú cưng', 'Trẻ dưới 6 tuổi miễn phí', 'info@hanoioldquarter.vn',    '02439261234', '30 Hàng Bè',         'Hàng Bạc',   'Hoàn Kiếm',   'Hà Nội',      105.853000, 21.033000, 8),
(3,  'HOTEL',     'Hoan Kiem Boutique Hotel',      'Khách sạn boutique gần hồ Gươm',                      3, '14:00', '11:00', 'Không hoàn tiền',           'Nhận thú cưng nhỏ',   'Trẻ dưới 4 tuổi miễn phí', 'stay@hkboutique.vn',         '02439281111', '10 Lò Sũ',           'Lý Thái Tổ', 'Hoàn Kiếm',   'Hà Nội',      105.854000, 21.030000, 8),
(4,  'HOTEL',     'Ben Thanh Central Hotel',       'Khách sạn đối diện chợ Bến Thành',                    3, '13:00', '12:00', 'Hủy miễn phí trước 1 ngày', 'Không nhận thú cưng', 'Trẻ dưới 6 tuổi miễn phí', 'hello@benthanhcentral.vn',   '02838225566', '60 Lê Thánh Tôn',    'Bến Thành',  'Quận 1',      'Hồ Chí Minh', 106.698000, 10.772000, 7),
(5,  'HOTEL',     'Da Nang Beach Hotel',           'Khách sạn 5 sao mặt biển Mỹ Khê',                    5, '14:00', '12:00', 'Hủy miễn phí trước 7 ngày', 'Không nhận thú cưng', 'Trẻ dưới 12 tuổi miễn phí','rsvn@danangbeach.vn',        '02363955555', '200 Võ Nguyên Giáp', 'Phước Mỹ',   'Sơn Trà',     'Đà Nẵng',     108.247000, 16.063000, 11),
(6,  'RESORT',    'Phu Quoc Sunset Resort',        'Resort bãi Trường, ngắm hoàng hôn',                   5, '15:00', '12:00', 'Tùy gói giá',              'Nhận thú cưng',       'Trẻ dưới 12 tuổi miễn phí','resort@pqsunset.vn',         '02973888999', 'Bãi Trường',         'Dương Tơ',   'Phú Quốc',    'Kiên Giang',  103.960000, 10.140000, 9),
(7,  'RESORT',    'Nha Trang Bay Resort',          'Resort trên đảo Hòn Tre',                             5, '14:00', '12:00', 'Hủy miễn phí trước 7 ngày', 'Không nhận thú cưng', 'Trẻ dưới 12 tuổi miễn phí','rsvn@ntbay.vn',              '02583599999', 'Đảo Hòn Tre',        'Vĩnh Nguyên','Nha Trang',   'Khánh Hòa',   109.230000, 12.210000, 9),
(8,  'RESORT',    'Hoi An Riverside Resort',       'Resort ven sông Thu Bồn',                             4, '14:00', '12:00', 'Hủy miễn phí trước 3 ngày', 'Nhận thú cưng nhỏ',   'Trẻ dưới 6 tuổi miễn phí', 'info@hoianriverside.vn',     '02353864800', '175 Cửa Đại',        'Cẩm Châu',   'Hội An',      'Quảng Nam',   108.350000, 15.880000, 11),
(9,  'RESORT',    'Mui Ne Sand Resort',            'Resort đồi cát Mũi Né',                               4, '14:00', '12:00', 'Hủy miễn phí trước 3 ngày', 'Không nhận thú cưng', 'Trẻ dưới 6 tuổi miễn phí', 'book@muinesand.vn',          '02523847111', '54 Nguyễn Đình Chiểu','Hàm Tiến',  'Phan Thiết',  'Bình Thuận',  108.260000, 10.950000, 9),
(10, 'RESORT',    'Vung Tau Ocean Resort',         'Resort Bãi Sau',                                      4, '14:00', '12:00', 'Hủy miễn phí trước 1 ngày', 'Nhận thú cưng',       'Trẻ dưới 6 tuổi miễn phí', 'stay@vtocean.vn',            '02543526666', '8 Thùy Vân',         'Thắng Tam',  'Vũng Tàu',    'Bà Rịa - Vũng Tàu', 107.090000, 10.340000, 7),
(11, 'APARTMENT', 'Landmark 81 Skyview Apartment', 'Căn hộ tầng cao nhìn toàn thành phố',                 4, '14:00', '11:00', 'Hủy miễn phí trước 2 ngày', 'Không nhận thú cưng', 'Trẻ em ở miễn phí',         'skyview@l81apt.vn',          '0901888181',  '720A Điện Biên Phủ', 'Phường 22',  'Bình Thạnh',  'Hồ Chí Minh', 106.722000, 10.795000, 7),
(12, 'APARTMENT', 'My Khe Seaview Apartment',      'Căn hộ 2 phòng ngủ nhìn biển',                        3, '14:00', '12:00', 'Hủy miễn phí trước 3 ngày', 'Nhận thú cưng nhỏ',   'Trẻ em ở miễn phí',         'mykhe@dnapart.vn',           '0905123123',  '68 Hoàng Sa',        'Phước Mỹ',   'Sơn Trà',     'Đà Nẵng',     108.249000, 16.070000, 11),
(13, 'APARTMENT', 'West Lake Serviced Apartment',  'Căn hộ dịch vụ ven Hồ Tây',                           4, '14:00', '12:00', 'Hủy miễn phí trước 3 ngày', 'Không nhận thú cưng', 'Trẻ em ở miễn phí',         'westlake@hanoiheritage.vn',  '0904567567',  '51 Xuân Diệu',       'Quảng An',   'Tây Hồ',      'Hà Nội',      105.828000, 21.065000, 8),
(14, 'APARTMENT', 'Nha Trang Center Apartment',    'Căn hộ trung tâm, đi bộ ra biển 3 phút',              3, '14:00', '12:00', 'Không hoàn tiền',           'Không nhận thú cưng', 'Trẻ em ở miễn phí',         'ntcenter@dnapart.vn',        '0905678678',  '20 Trần Phú',        'Lộc Thọ',    'Nha Trang',   'Khánh Hòa',   109.196000, 12.243000, 11),
(15, 'APARTMENT', 'Thao Dien Garden Apartment',    'Căn hộ sân vườn khu Thảo Điền',                       4, '14:00', '12:00', 'Hủy miễn phí trước 2 ngày', 'Nhận thú cưng',       'Trẻ em ở miễn phí',         'thaodien@saigonhotel.vn',    '0908999888',  '12 Quốc Hương',      'Thảo Điền',  'Thủ Đức',     'Hồ Chí Minh', 106.733000, 10.803000, 7),
(16, 'HOMESTAY',  'Dalat Pine Hill Homestay',      'Homestay giữa đồi thông',                             3, '14:00', '11:00', 'Hủy miễn phí trước 3 ngày', 'Nhận thú cưng',       'Trẻ em ở miễn phí',         'pinehill@dalatstay.vn',      '0911222333',  '15 Đống Đa',         'Phường 3',   'Đà Lạt',      'Lâm Đồng',    108.430000, 11.940000, 10),
(17, 'HOMESTAY',  'Dalat Flower Garden Homestay',  'Homestay vườn hoa',                                   2, '14:00', '11:00', 'Không hoàn tiền',           'Nhận thú cưng',       'Trẻ em ở miễn phí',         'flower@dalatstay.vn',        '0911333444',  '3 Trần Hưng Đạo',    'Phường 10',  'Đà Lạt',      'Lâm Đồng',    108.450000, 11.935000, 10),
(18, 'HOMESTAY',  'Sapa Cloud Homestay',           'Homestay săn mây Sa Pa',                              3, '13:00', '11:00', 'Hủy miễn phí trước 3 ngày', 'Không nhận thú cưng', 'Trẻ em ở miễn phí',         'cloud@dalatstay.vn',         '0911444555',  'Bản Cát Cát',        'San Sả Hồ',  'Sa Pa',       'Lào Cai',     103.840000, 22.330000, 10),
(19, 'HOMESTAY',  'Hoi An Lantern Homestay',       'Homestay đèn lồng phố cổ',                            3, '14:00', '11:00', 'Hủy miễn phí trước 2 ngày', 'Không nhận thú cưng', 'Trẻ em ở miễn phí',         'lantern@dalatstay.vn',       '0911555666',  '40 Phan Châu Trinh', 'Minh An',    'Hội An',      'Quảng Nam',   108.330000, 15.877000, 10),
(20, 'HOMESTAY',  'Ha Giang Rock Homestay',        'Homestay nhà trình tường',                            2, '13:00', '11:00', 'Không hoàn tiền',           'Nhận thú cưng',       'Trẻ em ở miễn phí',         'rock@dalatstay.vn',          '0911666777',  'Thôn Lũng Cẩm',      'Sủng Là',    'Đồng Văn',    'Hà Giang',    105.280000, 23.230000, 10);

INSERT INTO HOTEL (ACCOMMODATION_ID, NUMBER_OF_FLOORS) VALUES (1, 15), (2, 8), (3, 6), (4, 10), (5, 25);
INSERT INTO HOTEL_FACILITIES (ACCOMMODATION_ID, COMMON_FACILITIES) VALUES
(1, 'Sân thượng rooftop'), (1, 'Phòng họp'), (2, 'Phòng chờ'), (3, 'Thư viện'), (4, 'Phòng giặt chung'), (5, 'Phòng hội nghị');
INSERT INTO RESORT (ACCOMMODATION_ID, PROPERTY_AREA) VALUES (6, 120000), (7, 250000), (8, 45000), (9, 60000), (10, 38000);
INSERT INTO APARTMENT (ACCOMMODATION_ID, NUMBER_OF_BEDROOMS) VALUES (11, 1), (12, 2), (13, 2), (14, 1), (15, 3);
INSERT INTO HOMESTAY (ACCOMMODATION_ID, HOUSE_TYPE, NUMBER_OF_RENTAL_ROOMS) VALUES
(16, 'Nhà gỗ', 6), (17, 'Biệt thự Pháp', 5), (18, 'Nhà sàn', 8), (19, 'Nhà cổ', 4), (20, 'Nhà trình tường', 5);

INSERT INTO AMENITY (AMENITY_NAME, AMENITY_GROUP) VALUES
('Wifi miễn phí', 'GENERAL'), ('Lễ tân 24/7', 'GENERAL'), ('Thang máy', 'GENERAL'),
('Hồ bơi ngoài trời', 'ENTERTAINMENT'), ('Phòng gym', 'ENTERTAINMENT'), ('Spa', 'ENTERTAINMENT'),
('Nhà hàng', 'FOOD'), ('Quầy bar', 'FOOD'), ('Đưa đón sân bay', 'SUPPORT'), ('Bãi đỗ xe riêng', 'SUPPORT');

INSERT INTO ACCOMMODATION_AMENITY (ACCOMMODATION_ID, AMENITY_NAME) VALUES
(1, 'Wifi miễn phí'), (1, 'Lễ tân 24/7'), (1, 'Thang máy'), (1, 'Hồ bơi ngoài trời'), (1, 'Nhà hàng'),
(2, 'Wifi miễn phí'), (2, 'Lễ tân 24/7'), (5, 'Spa'), (5, 'Phòng gym'),
(6, 'Hồ bơi ngoài trời'), (6, 'Spa'), (6, 'Đưa đón sân bay'), (6, 'Quầy bar'),
(11, 'Wifi miễn phí'), (11, 'Phòng gym'), (16, 'Wifi miễn phí'), (16, 'Bãi đỗ xe riêng');

INSERT INTO ROOM_TYPE (ACCOMMODATION_ID, ROOM_NAME, AREA, NUMBER_OF_BEDS, BED_TYPE, ADULTS, CHILDREN, `VIEW`) VALUES
(1,  'Standard',  25,  1, 'Queen',  2, 1, 'Thành phố'),
(1,  'Deluxe',    35,  1, 'King',   2, 2, 'Sông Sài Gòn'),
(2,  'Superior',  28,  2, 'Twin',   2, 1, 'Phố cổ'),
(2,  'Suite',     50,  1, 'King',   3, 2, 'Phố cổ'),
(6,  'Bungalow',  45,  1, 'King',   2, 2, 'Vườn'),
(6,  'Villa',     120, 3, 'King',   6, 3, 'Biển'),
(11, 'Studio',    40,  1, 'Queen',  2, 1, 'Thành phố'),
(12, '2-Bedroom', 75,  2, 'Queen',  4, 2, 'Biển'),
(16, 'Double',    20,  1, 'Double', 2, 0, 'Đồi thông'),
(17, 'Family',    35,  2, 'Double', 4, 2, 'Vườn hoa');

INSERT INTO ROOM_TYPE_AMENITIES (ACCOMMODATION_ID, ROOM_NAME, IN_ROOM_AMENITIES) VALUES
(1, 'Standard', 'Điều hòa'), (1, 'Standard', 'TV'), (1, 'Deluxe', 'Minibar'), (1, 'Deluxe', 'Bồn tắm'),
(2, 'Suite', 'Bàn làm việc'), (6, 'Villa', 'Hồ bơi riêng'), (11, 'Studio', 'Bếp'), (16, 'Double', 'Lò sưởi');

INSERT INTO ROOM (ACCOMMODATION_ID, ROOM_NAME, ROOM_NUMBER, AVAILABILITY_STATUS) VALUES
(1, 'Standard', '101', 'AVAILABLE'), (1, 'Standard', '102', 'OCCUPIED'), (1, 'Standard', '103', 'AVAILABLE'),
(1, 'Deluxe', '201', 'AVAILABLE'), (1, 'Deluxe', '202', 'MAINTENANCE'),
(2, 'Superior', '301', 'AVAILABLE'), (2, 'Superior', '302', 'AVAILABLE'), (2, 'Suite', '501', 'AVAILABLE'),
(6, 'Bungalow', 'B01', 'AVAILABLE'), (6, 'Bungalow', 'B02', 'AVAILABLE'), (6, 'Bungalow', 'B03', 'OCCUPIED'),
(6, 'Villa', 'V01', 'AVAILABLE'), (6, 'Villa', 'V02', 'AVAILABLE'),
(11, 'Studio', '35.01', 'AVAILABLE'), (11, 'Studio', '35.02', 'AVAILABLE'),
(12, '2-Bedroom', 'A12', 'AVAILABLE'), (16, 'Double', 'D1', 'AVAILABLE'), (16, 'Double', 'D2', 'AVAILABLE'),
(17, 'Family', 'F1', 'AVAILABLE');

INSERT INTO ROOM_RATE (ACCOMMODATION_ID, ROOM_NAME, ROOM_RATE_ID, UNIT_PRICE, FREE_CANCELLATION, EFFECTIVE_DATE, CHILD_PRICE, BREAKFAST_INCLUDED) VALUES
(1,  'Standard',  1,  900000,  TRUE,  CURDATE() - INTERVAL 400 DAY, 0,      TRUE),
(1,  'Standard',  2,  750000,  FALSE, CURDATE() - INTERVAL 400 DAY, 0,      FALSE),
(1,  'Deluxe',    3,  1400000, TRUE,  CURDATE() - INTERVAL 400 DAY, 150000, TRUE),
(2,  'Superior',  4,  1100000, TRUE,  CURDATE() - INTERVAL 400 DAY, 100000, TRUE),
(2,  'Suite',     5,  2500000, TRUE,  CURDATE() - INTERVAL 400 DAY, 200000, TRUE),
(6,  'Bungalow',  6,  2200000, TRUE,  CURDATE() - INTERVAL 400 DAY, 300000, TRUE),
(6,  'Villa',     7,  6500000, FALSE, CURDATE() - INTERVAL 400 DAY, 500000, TRUE),
(11, 'Studio',    8,  1300000, TRUE,  CURDATE() - INTERVAL 400 DAY, 0,      FALSE),
(12, '2-Bedroom', 9,  1800000, TRUE,  CURDATE() - INTERVAL 400 DAY, 0,      FALSE),
(16, 'Double',    10, 550000,  TRUE,  CURDATE() - INTERVAL 400 DAY, 0,      TRUE),
(17, 'Family',    11, 900000,  FALSE, CURDATE() - INTERVAL 400 DAY, 100000, TRUE),
(1,  'Standard',  12, 1000000, TRUE,  CURDATE() + INTERVAL 60 DAY,  0,      TRUE);   -- giá Tết, chưa hiệu lực

INSERT INTO PHOTO (PHOTO_ID, PHOTO_TYPE, URL, DESCRIPTION, UPLOAD_DATE) VALUES
(1,  'A', 'https://img.example.com/acc/1-facade.jpg',  'Mặt tiền khách sạn',     '2025-01-10'),
(2,  'A', 'https://img.example.com/acc/2-lobby.jpg',   'Sảnh lễ tân',            '2025-01-12'),
(3,  'A', 'https://img.example.com/acc/6-beach.jpg',   'Bãi biển riêng',         '2025-02-01'),
(4,  'A', 'https://img.example.com/acc/11-view.jpg',   'View tầng 45',           '2025-02-15'),
(5,  'A', 'https://img.example.com/acc/16-garden.jpg', 'Đồi thông sau nhà',      '2025-03-03'),
(6,  'R', 'https://img.example.com/rt/1-standard.jpg', 'Phòng Standard',         '2025-01-10'),
(7,  'R', 'https://img.example.com/rt/1-deluxe.jpg',   'Phòng Deluxe hướng sông','2025-01-10'),
(8,  'R', 'https://img.example.com/rt/2-suite.jpg',    'Suite phố cổ',           '2025-01-12'),
(9,  'R', 'https://img.example.com/rt/6-villa.jpg',    'Villa hồ bơi riêng',     '2025-02-01'),
(10, 'R', 'https://img.example.com/rt/16-double.jpg',  'Phòng đôi gỗ thông',     '2025-03-03');

INSERT INTO ACCOMMODATION_PHOTO (PHOTO_ID, ACCOMMODATION_ID) VALUES (1, 1), (2, 2), (3, 6), (4, 11), (5, 16);
INSERT INTO ROOM_TYPE_PHOTO (PHOTO_ID, ACCOMMODATION_ID, ROOM_NAME) VALUES
(6, 1, 'Standard'), (7, 1, 'Deluxe'), (8, 2, 'Suite'), (9, 6, 'Villa'), (10, 16, 'Double');

INSERT INTO WISHLIST (SAVED_DATE, USER_ID, ACCOMMODATION_ID) VALUES
('2026-01-02', 1, 5), ('2026-01-03', 1, 7), ('2026-02-10', 2, 6), ('2026-03-15', 3, 18), ('2026-04-01', 4, 1), ('2026-05-20', 6, 16);

-- ---------------- Đặt phòng ----------------
-- Tất cả tạo ở trạng thái PENDING rồi chuyển trạng thái qua sp_update_booking (đúng RB13)
INSERT INTO BOOKING (BOOKING_ID, ADULTS, CHILDREN, BOOKING_CODE, PIN_CODE, BOOKING_DATE, CHECK_IN_DATE, CHECK_OUT_DATE, ESTIMATED_ARRIVAL_TIME, SPECIAL_REQUESTS, USER_ID, ACCOMMODATION_ID) VALUES
(1,  2, 0, 'BK00000001', '1234', CURDATE() - INTERVAL 215 DAY, CURDATE() - INTERVAL 200 DAY, CURDATE() - INTERVAL 198 DAY, '15:00', 'Phòng tầng cao',          1, 1),
(2,  2, 0, 'BK00000002', '2345', CURDATE() - INTERVAL 180 DAY, CURDATE() - INTERVAL 170 DAY, CURDATE() - INTERVAL 167 DAY, '14:00', NULL,                      1, 2),
(3,  2, 1, 'BK00000003', '3456', CURDATE() - INTERVAL 160 DAY, CURDATE() - INTERVAL 140 DAY, CURDATE() - INTERVAL 137 DAY, '16:00', 'Thêm nôi cho bé',         1, 6),
(4,  2, 0, 'BK00000004', '4567', CURDATE() - INTERVAL 120 DAY, CURDATE() - INTERVAL 110 DAY, CURDATE() - INTERVAL 108 DAY, '20:00', NULL,                      1, 11),
(5,  2, 0, 'BK00000005', '5678', CURDATE() - INTERVAL 90 DAY,  CURDATE() - INTERVAL 80 DAY,  CURDATE() - INTERVAL 78 DAY,  '13:00', 'Không hút thuốc',         1, 16),
(6,  2, 1, 'BK00000006', '6789', CURDATE() - INTERVAL 75 DAY,  CURDATE() - INTERVAL 60 DAY,  CURDATE() - INTERVAL 57 DAY,  '14:30', NULL,                      2, 1),
(7,  4, 2, 'BK00000007', '7890', CURDATE() - INTERVAL 70 DAY,  CURDATE() - INTERVAL 50 DAY,  CURDATE() - INTERVAL 46 DAY,  '15:00', 'Trang trí sinh nhật',     3, 6),
(8,  4, 0, 'BK00000008', '8901', CURDATE() - INTERVAL 5 DAY,   CURDATE() + INTERVAL 10 DAY,  CURDATE() + INTERVAL 13 DAY,  '18:00', 'Hai phòng cạnh nhau',     2, 1),
(9,  2, 1, 'BK00000009', '9012', CURDATE() - INTERVAL 3 DAY,   CURDATE() + INTERVAL 20 DAY,  CURDATE() + INTERVAL 22 DAY,  '14:00', NULL,                      4, 2),
(10, 5, 1, 'BK00000010', '0123', CURDATE() - INTERVAL 10 DAY,  CURDATE() + INTERVAL 15 DAY,  CURDATE() + INTERVAL 18 DAY,  '15:30', 'Đón sân bay 14h',         5, 6),
(11, 2, 0, 'BK00000011', '1357', CURDATE() - INTERVAL 1 DAY,   CURDATE() + INTERVAL 5 DAY,   CURDATE() + INTERVAL 7 DAY,   '21:00', NULL,                      6, 11),
(12, 1, 0, 'BK00000012', '2468', CURDATE() - INTERVAL 2 DAY,   CURDATE() + INTERVAL 11 DAY,  CURDATE() + INTERVAL 12 DAY,  '23:00', 'Nhận phòng muộn',         3, 1),
(13, 2, 0, 'BK00000013', '3579', CURDATE() - INTERVAL 20 DAY,  CURDATE() + INTERVAL 30 DAY,  CURDATE() + INTERVAL 32 DAY,  NULL,    NULL,                      4, 1),
(14, 2, 0, 'BK00000014', '4680', CURDATE() - INTERVAL 15 DAY,  CURDATE() + INTERVAL 25 DAY,  CURDATE() + INTERVAL 27 DAY,  NULL,    NULL,                      5, 2),
(15, 2, 0, 'BK00000015', '5791', CURDATE() - INTERVAL 2 DAY,   CURDATE() + INTERVAL 40 DAY,  CURDATE() + INTERVAL 42 DAY,  NULL,    NULL,                      6, 16),
(16, 3, 1, 'BK00000016', '6802', CURDATE() - INTERVAL 12 DAY,  CURDATE() + INTERVAL 35 DAY,  CURDATE() + INTERVAL 38 DAY,  NULL,    NULL,                      2, 17),
(17, 3, 0, 'BK00000017', '7913', CURDATE() - INTERVAL 8 DAY,   CURDATE() + INTERVAL 45 DAY,  CURDATE() + INTERVAL 47 DAY,  NULL,    NULL,                      3, 12);

-- trigger: kiểm tra phòng trống, sức chứa và tính TOTAL_AMOUNT
INSERT INTO BOOKING_ROOM_TYPE (BOOKING_ID, ACCOMMODATION_ID, ROOM_NAME, ROOM_RATE_ID, ROOM_PRICE_AT_BOOKING, RESERVED_QUANTITY) VALUES
(1,  1,  'Standard',  1,  900000,  1),
(2,  2,  'Superior',  4,  1100000, 1),
(3,  6,  'Bungalow',  6,  2200000, 1),
(4,  11, 'Studio',    8,  1300000, 1),
(5,  16, 'Double',    10, 550000,  1),
(6,  1,  'Deluxe',    3,  1400000, 1),
(7,  6,  'Villa',     7,  6500000, 1),
(8,  1,  'Standard',  1,  900000,  2),
(9,  2,  'Suite',     5,  2500000, 1),
(10, 6,  'Villa',     7,  6500000, 1),
(11, 11, 'Studio',    8,  1300000, 1),
(12, 1,  'Standard',  1,  900000,  1),
(13, 1,  'Deluxe',    3,  1400000, 1),
(14, 2,  'Superior',  4,  1100000, 1),
(15, 16, 'Double',    10, 550000,  1),
(16, 17, 'Family',    11, 900000,  1),
(17, 12, '2-Bedroom', 9,  1800000, 1);

-- trigger: RB09, voucher -> USED, tính lại TOTAL_AMOUNT
INSERT INTO BOOKING_VOUCHER (BOOKING_ID, VOUCHER_CODE) VALUES
(2, 'V-AN-01'), (6, 'V-BINH-01'), (9, 'V-DUNG-01'), (10, 'V-DUC-01'), (11, 'V-HAN-01');

-- Xác nhận đơn
CALL sp_update_booking(1,  NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(2,  NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(3,  NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(4,  NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(5,  NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(6,  NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(7,  NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(8,  NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(9,  NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(10, NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(13, NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(14, NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(16, NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);
CALL sp_update_booking(17, NULL, NULL, NULL, NULL, NULL, NULL, 'CONFIRMED', NULL);

-- Thanh toán (số tiền = TOTAL_AMOUNT trigger đã tính)
INSERT INTO PAYMENT (TRANSACTION_CODE, PAYMENT_DATE, PAYMENT_METHOD, AMOUNT, PAYMENT_STATUS, BOOKING_ID, CARD_NUMBER)
SELECT CONCAT('TXN', LPAD(b.BOOKING_ID, 6, '0')), b.BOOKING_DATE + INTERVAL 1 DAY, p.METHOD, b.TOTAL_AMOUNT, 'SUCCESS', b.BOOKING_ID, p.CARD
FROM BOOKING b
JOIN (SELECT 1 AS ID, 'CARD' AS METHOD, '4111111111111111' AS CARD
      UNION ALL SELECT 2,  'CARD', '4111111111111111'
      UNION ALL SELECT 3,  'PAY_AT_PROPERTY', NULL
      UNION ALL SELECT 4,  'CARD', '4111111111111111'
      UNION ALL SELECT 5,  'PAY_AT_PROPERTY', NULL
      UNION ALL SELECT 6,  'CARD', '5555555555554444'
      UNION ALL SELECT 7,  'CARD', '3530111333300000'
      UNION ALL SELECT 8,  'CARD', '5555555555554444'
      UNION ALL SELECT 9,  'CARD', '4012888888881881'
      UNION ALL SELECT 10, 'CARD', '5105105105105100'
      UNION ALL SELECT 13, 'CARD', '4012888888881881'
      UNION ALL SELECT 14, 'CARD', '5105105105105100'
      UNION ALL SELECT 16, 'CARD', '5555555555554444'
      UNION ALL SELECT 17, 'CARD', '3530111333300000') p ON p.ID = b.BOOKING_ID;

INSERT INTO PAYMENT (TRANSACTION_CODE, PAYMENT_DATE, PAYMENT_METHOD, AMOUNT, PAYMENT_STATUS, BOOKING_ID, CARD_NUMBER) VALUES
('TXN000011-F', CURDATE() - INTERVAL 1 DAY, 'CARD', 1, 'FAILED', 11, '378282246310005');

-- Hoàn thành đơn đã lưu trú (trigger cập nhật GENIUS_LEVEL: khách 1 đủ 5 đơn -> cấp 2)
CALL sp_update_booking(1, NULL, NULL, NULL, NULL, NULL, NULL, 'COMPLETED', NULL);
CALL sp_update_booking(2, NULL, NULL, NULL, NULL, NULL, NULL, 'COMPLETED', NULL);
CALL sp_update_booking(3, NULL, NULL, NULL, NULL, NULL, NULL, 'COMPLETED', NULL);
CALL sp_update_booking(4, NULL, NULL, NULL, NULL, NULL, NULL, 'COMPLETED', NULL);
CALL sp_update_booking(5, NULL, NULL, NULL, NULL, NULL, NULL, 'COMPLETED', NULL);
CALL sp_update_booking(6, NULL, NULL, NULL, NULL, NULL, NULL, 'COMPLETED', NULL);
CALL sp_update_booking(7, NULL, NULL, NULL, NULL, NULL, NULL, 'COMPLETED', NULL);

-- Hủy đơn (thủ tục tự ghi CANCELLATION với tiền hoàn từ fn_refund_amount, thỏa RB10)
CALL sp_update_booking(13, NULL, NULL, NULL, NULL, NULL, NULL, 'CANCELLED', 'Đổi lịch công tác');
CALL sp_update_booking(14, NULL, NULL, NULL, NULL, NULL, NULL, 'CANCELLED', 'Tìm được chỗ ở khác');
CALL sp_update_booking(15, NULL, NULL, NULL, NULL, NULL, NULL, 'CANCELLED', 'Đặt nhầm ngày');
CALL sp_update_booking(16, NULL, NULL, NULL, NULL, NULL, NULL, 'CANCELLED', 'Gia đình có việc bận');
CALL sp_update_booking(17, NULL, NULL, NULL, NULL, NULL, NULL, 'CANCELLED', 'Chuyến bay bị hủy');
UPDATE CANCELLATION SET REFUND_STATUS = 'REFUNDED' WHERE BOOKING_ID = 14;
UPDATE PAYMENT SET PAYMENT_STATUS = 'REFUNDED' WHERE BOOKING_ID = 14;

-- ---------------- Đánh giá, phản hồi, tin nhắn ----------------
INSERT INTO REVIEW (REVIEW_ID, TITLE, POSITIVE_COMMENT, NEGATIVE_COMMENT, REVIEW_DATE, CLEANLINESS, COMFORT, LOCATION, FACILITIES, STAFF, VALUE_FOR_MONEY, BOOKING_ID) VALUES
(1, 'Vị trí tuyệt vời',        'Đi bộ ra phố đi bộ 5 phút, nhân viên nhiệt tình', 'Thang máy hơi chậm',      CURDATE() - INTERVAL 197 DAY, 9, 8, 10, 8, 9, 8, 1),
(2, 'Resort đẹp như mơ',       'Bãi biển riêng sạch, hoàng hôn rất đẹp',          'Đồ ăn hơi đắt',           CURDATE() - INTERVAL 135 DAY, 10, 9, 9, 9, 10, 7, 3),
(3, 'Homestay ấm cúng',        'Chủ nhà thân thiện, view đồi thông',              'Phòng tắm nhỏ',           CURDATE() - INTERVAL 77 DAY,  8, 8, 9, 7, 10, 9, 5),
(4, 'Phòng Deluxe rộng rãi',   'Bồn tắm view sông, bữa sáng ngon',                NULL,                      CURDATE() - INTERVAL 56 DAY,  9, 9, 10, 9, 9, 8, 6),
(5, 'Kỳ nghỉ gia đình đáng nhớ','Villa có hồ bơi riêng, trẻ con rất thích',       'Wifi yếu ở villa',        CURDATE() - INTERVAL 44 DAY,  9, 10, 8, 8, 9, 7, 7);

INSERT INTO REVIEW_PHOTOS (REVIEW_ID, PHOTO_URL) VALUES
(1, 'https://img.example.com/review/1a.jpg'), (2, 'https://img.example.com/review/2a.jpg'),
(2, 'https://img.example.com/review/2b.jpg'), (3, 'https://img.example.com/review/3a.jpg'),
(5, 'https://img.example.com/review/5a.jpg');

INSERT INTO RESPONSE (REVIEW_ID, RESPONSE_DATE, RESPONSE_CONTENT, USER_ID) VALUES
(1, CURDATE() - INTERVAL 196 DAY, 'Cảm ơn anh An, chúng tôi đang nâng cấp thang máy.',        7),
(2, CURDATE() - INTERVAL 134 DAY, 'Rất vui vì anh đã có kỳ nghỉ đáng nhớ tại resort!',         9),
(3, CURDATE() - INTERVAL 76 DAY,  'Cảm ơn anh, homestay sẽ cải tạo phòng tắm trong năm nay.', 10),
(4, CURDATE() - INTERVAL 55 DAY,  'Hẹn gặp lại chị Bình lần sau!',                            7),
(5, CURDATE() - INTERVAL 43 DAY,  'Chúng tôi đã lắp thêm bộ phát wifi cho khu villa.',        9);

INSERT INTO MESSAGE (MESSAGE_ID, CONTENT, SENT_TIME, IS_READ, ATTACHMENT_URL, SENDER_ID, BOOKING_ID) VALUES
(1,  'Cho tôi nhận phòng sớm lúc 11h được không?',      TIMESTAMP(CURDATE() - INTERVAL 4 DAY, '09:15:00'), TRUE,  NULL, 2,  8),
(2,  'Dạ được ạ, khách sạn sẽ chuẩn bị phòng trước.',  TIMESTAMP(CURDATE() - INTERVAL 4 DAY, '10:02:00'), TRUE,  NULL, 7,  8),
(3,  'Suite có view ra phố cổ không ạ?',               TIMESTAMP(CURDATE() - INTERVAL 2 DAY, '20:40:00'), TRUE,  NULL, 4,  9),
(4,  'Có ạ, phòng ở tầng 5 nhìn ra Hàng Bè.',          TIMESTAMP(CURDATE() - INTERVAL 2 DAY, '21:05:00'), FALSE, 'https://img.example.com/msg/suite.jpg', 8, 9),
(5,  'Resort có đưa đón ở sân bay Phú Quốc không?',    TIMESTAMP(CURDATE() - INTERVAL 9 DAY, '08:00:00'), TRUE,  NULL, 5,  10),
(6,  'Có xe đưa đón miễn phí cho khách villa ạ.',      TIMESTAMP(CURDATE() - INTERVAL 9 DAY, '08:30:00'), TRUE,  NULL, 9,  10),
(7,  'Tôi đến muộn khoảng 21h, có lễ tân không?',      TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '12:00:00'), TRUE,  NULL, 6,  11),
(8,  'Căn hộ dùng khóa số, mã sẽ gửi trước 1 ngày.',   TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '12:20:00'), FALSE, NULL, 7,  11),
(9,  'Có chỗ gửi xe máy không ạ?',                     TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '07:45:00'), TRUE,  NULL, 3,  12),
(10, 'Có hầm gửi xe miễn phí ạ.',                      TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '08:10:00'), FALSE, NULL, 7,  12);

INSERT INTO MESSAGE_REPLY (MESSAGE_ID, REPLIED_TO_MESSAGE_ID) VALUES (2, 1), (4, 3), (6, 5), (8, 7), (10, 9);
