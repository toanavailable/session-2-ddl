-- Bảng PRODUCTS đã sửa: lưu tiền chính xác và tiết kiệm bộ nhớ
CREATE TABLE PRODUCTS (
    ID          INT AUTO_INCREMENT PRIMARY KEY,
    ProductName VARCHAR(100)   NOT NULL,
    Price       DECIMAL(18, 2) NOT NULL CHECK (Price >= 0),
    Description TEXT
);
