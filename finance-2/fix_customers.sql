-- =====================================================
-- Vá lỗ hổng "Khách hàng ảo" cho bảng CUSTOMERS
-- Không dùng DROP TABLE, chỉ dùng ALTER TABLE
-- Yêu cầu MySQL 8.0.16+ (CHECK mới được thực thi)
-- =====================================================

-- Bước 1: Lưu lại dữ liệu rác trước khi dọn (để đối soát nếu cần)
CREATE TABLE CUSTOMERS_INVALID AS
SELECT * FROM CUSTOMERS
WHERE Email IS NULL OR TRIM(Email) = ''
   OR FullName IS NULL
   OR Age < 0;

-- Bước 2: Dọn dữ liệu sai để ALTER TABLE không bị lỗi
-- 2.1 Tuổi âm: không biết tuổi thật -> đặt về NULL
UPDATE CUSTOMERS SET Age = NULL WHERE Age < 0;

-- 2.2 Khách hàng không có email / không có tên: dữ liệu rác -> xóa
DELETE FROM CUSTOMERS
WHERE Email IS NULL OR TRIM(Email) = '' OR FullName IS NULL;

-- 2.3 Kiểm tra email trùng trước khi thêm UNIQUE (kết quả phải rỗng)
SELECT Email, COUNT(*) AS SoLan
FROM CUSTOMERS
GROUP BY Email
HAVING COUNT(*) > 1;

-- Bước 3: Vá cấu trúc bảng bằng ALTER TABLE
ALTER TABLE CUSTOMERS
    MODIFY FullName VARCHAR(100) NOT NULL,
    MODIFY Email    VARCHAR(100) NOT NULL,
    ADD CONSTRAINT uq_customers_email  UNIQUE (Email),
    ADD CONSTRAINT chk_customers_email CHECK (Email LIKE '%_@_%._%'),
    ADD CONSTRAINT chk_customers_age   CHECK (Age BETWEEN 0 AND 150);

-- Bước 4 (mở rộng): thêm ngày sinh để chạy chiến dịch email sinh nhật
ALTER TABLE CUSTOMERS
    ADD DateOfBirth DATE;

-- Kiểm tra lại cấu trúc bảng
SHOW CREATE TABLE CUSTOMERS;

-- Thử nghiệm: các lệnh dưới đây phải bị từ chối
-- INSERT INTO CUSTOMERS (CustomerID, FullName, Email, Age) VALUES (100, 'Test', NULL, 20);          -- lỗi NOT NULL
-- INSERT INTO CUSTOMERS (CustomerID, FullName, Email, Age) VALUES (101, 'Test', 'abc', 20);         -- lỗi CHECK email
-- INSERT INTO CUSTOMERS (CustomerID, FullName, Email, Age) VALUES (102, 'Test', 'a@b.com', -5);     -- lỗi CHECK tuổi
