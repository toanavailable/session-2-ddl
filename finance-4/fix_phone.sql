-- =====================================================
-- Khủng hoảng nâng cấp dữ liệu Số Điện Thoại
-- Bảng USERS (~2 triệu bản ghi): đổi Phone từ INT sang VARCHAR(15)
-- Giải pháp chọn: ALTER TABLE ... MODIFY (giải pháp 1), MySQL 8.0
-- =====================================================

-- Bước 0 (chuẩn bị): sao lưu bảng trước khi thay đổi cấu trúc
--   mysqldump -u root -p shop_db USERS > users_backup.sql

-- -----------------------------------------------------
-- CÂU LỆNH DDL ĐƯỢC CHỌN
-- ALGORITHM=COPY : đổi INT -> VARCHAR bắt buộc phải dựng lại bảng
-- LOCK=SHARED    : trong lúc chạy, ứng dụng vẫn ĐỌC được (đăng nhập bình thường),
--                  chỉ các lệnh GHI phải chờ. Nếu MySQL không đáp ứng được
--                  mức khóa này, lệnh báo lỗi ngay thay vì âm thầm khóa toàn bộ bảng.
-- Chạy vào giờ thấp điểm.
-- -----------------------------------------------------
ALTER TABLE USERS
    MODIFY COLUMN Phone VARCHAR(15),
    ALGORITHM = COPY,
    LOCK = SHARED;

-- -----------------------------------------------------
-- Sau DDL: khôi phục số 0 đầu đã bị INT cắt mất (DML)
-- Số di động Việt Nam có 10 chữ số, bắt đầu bằng 0.
-- Sau khi đổi kiểu, '0981234567' đang được lưu thành '981234567' (9 chữ số).
-- Cập nhật theo lô 10.000 dòng để không khóa bảng lâu; lặp lại đến khi 0 dòng bị ảnh hưởng.
-- -----------------------------------------------------
UPDATE USERS
SET Phone = CONCAT('0', Phone)
WHERE CHAR_LENGTH(Phone) = 9
  AND Phone NOT LIKE '0%'
LIMIT 10000;

-- Kiểm tra lại
SHOW CREATE TABLE USERS;

SELECT COUNT(*) AS SoDongChuaCoSo0
FROM USERS
WHERE Phone NOT LIKE '0%';
