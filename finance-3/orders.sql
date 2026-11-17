-- =====================================================
-- Kiến trúc quan hệ Khách Hàng - Đơn Hàng (1 - N)
-- MySQL 8.0.16+ (DEFAULT (CURRENT_DATE) cần 8.0.13+, CHECK cần 8.0.16+)
-- =====================================================

CREATE DATABASE IF NOT EXISTS shop_db;
USE shop_db;

-- Xóa bảng cũ (nếu có) theo thứ tự NGƯỢC: bảng con trước, bảng cha sau
DROP TABLE IF EXISTS ORDERS;
DROP TABLE IF EXISTS CUSTOMERS;

-- 1. Tạo bảng CHA trước: CUSTOMERS
CREATE TABLE CUSTOMERS (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    FullName   VARCHAR(100) NOT NULL,
    Email      VARCHAR(100) NOT NULL UNIQUE,
    Phone      VARCHAR(15)  UNIQUE,
    CreatedAt  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tạo bảng CON sau: ORDERS (tham chiếu CUSTOMERS)
CREATE TABLE ORDERS (
    OrderID     INT AUTO_INCREMENT PRIMARY KEY,
    OrderDate   DATE           NOT NULL DEFAULT (CURRENT_DATE),
    TotalAmount DECIMAL(18, 2) NOT NULL DEFAULT 0,
    CustomerID  INT            NOT NULL,
    CONSTRAINT chk_orders_total CHECK (TotalAmount >= 0),
    CONSTRAINT fk_orders_customers
        FOREIGN KEY (CustomerID) REFERENCES CUSTOMERS (CustomerID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- 3. Dữ liệu mẫu: thêm khách hàng trước, đơn hàng sau
INSERT INTO CUSTOMERS (FullName, Email, Phone) VALUES
    ('Nguyễn Văn An', 'an.nguyen@gmail.com', '0912345678'),
    ('Trần Thị Bình', 'binh.tran@gmail.com', '0987654321');

INSERT INTO ORDERS (OrderDate, TotalAmount, CustomerID) VALUES
    ('2026-11-10', 1250000.00, 1),
    ('2026-11-12',  499000.50, 1);

-- Không nhập OrderDate -> tự động lấy ngày hiện tại
INSERT INTO ORDERS (TotalAmount, CustomerID) VALUES (320000.00, 2);

SELECT * FROM ORDERS;

-- 4. Kiểm thử toàn vẹn dữ liệu: các lệnh dưới đây phải bị từ chối
-- INSERT INTO ORDERS (TotalAmount, CustomerID) VALUES (100000, 999);  -- lỗi khóa ngoại: khách hàng 999 không tồn tại
-- INSERT INTO ORDERS (TotalAmount, CustomerID) VALUES (100000, NULL); -- lỗi NOT NULL: đơn hàng phải có khách hàng
-- INSERT INTO ORDERS (TotalAmount, CustomerID) VALUES (-50000, 1);    -- lỗi CHECK: tổng tiền âm
-- DELETE FROM CUSTOMERS WHERE CustomerID = 1;                          -- lỗi RESTRICT: khách hàng còn đơn hàng
