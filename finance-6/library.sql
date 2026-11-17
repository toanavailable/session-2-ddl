-- =====================================================
-- Bài tập tổng hợp: Khởi tạo cấu trúc bảng với DDL và Ràng buộc
-- MySQL 8.0.16+ (DEFAULT (CURRENT_DATE) cần 8.0.13+, CHECK cần 8.0.16+)
-- =====================================================

CREATE DATABASE IF NOT EXISTS library_db;
USE library_db;

-- Xóa bảng cũ (nếu có): bảng con trước, bảng cha sau
DROP TABLE IF EXISTS BORROW_BOOKS;
DROP TABLE IF EXISTS BOOK;

-- -----------------------------------------------------
-- Thao tác 1: Tạo bảng BOOK với ràng buộc chặt chẽ
-- -----------------------------------------------------
CREATE TABLE BOOK (
    MaSach  CHAR(5)        PRIMARY KEY,
    TenSach VARCHAR(200)   NOT NULL,
    SoLuong INT            NOT NULL DEFAULT 0,
    GiaThue DECIMAL(10, 2) NOT NULL DEFAULT 5000,
    CONSTRAINT chk_book_soluong CHECK (SoLuong >= 0)
);

-- -----------------------------------------------------
-- Thao tác 2: Cơi nới - thêm cột NgayNhap
-- -----------------------------------------------------
ALTER TABLE BOOK
ADD NgayNhap DATE;

-- -----------------------------------------------------
-- Thao tác 3: Tạo bảng BORROW_BOOKS với khóa ngoại
-- -----------------------------------------------------
CREATE TABLE BORROW_BOOKS (
    MaMuon  INT AUTO_INCREMENT PRIMARY KEY,
    MaSach  CHAR(5) NOT NULL,
    NgayMuon DATE   NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_borrow_book
        FOREIGN KEY (MaSach) REFERENCES BOOK (MaSach)
);

-- =====================================================
-- Kiểm thử
-- =====================================================
INSERT INTO BOOK (MaSach, TenSach, SoLuong, NgayNhap) VALUES
    ('S0001', 'Lập trình C cơ bản', 10, '2026-10-01'),   -- GiaThue tự = 5000
    ('S0002', 'Cơ sở dữ liệu MySQL', 5, '2026-11-01');

INSERT INTO BOOK (MaSach, TenSach, SoLuong, GiaThue) VALUES
    ('S0003', 'Cấu trúc dữ liệu và giải thuật', 3, 8000.50);

INSERT INTO BORROW_BOOKS (MaSach) VALUES ('S0001');      -- NgayMuon tự = ngày hiện tại

SELECT * FROM BOOK;
SELECT * FROM BORROW_BOOKS;

-- Các lệnh dưới đây PHẢI bị từ chối:
-- INSERT INTO BOOK (MaSach, TenSach, SoLuong) VALUES ('S0004', 'Sách lỗi', -2);   -- vi phạm CHECK (SoLuong >= 0)
-- INSERT INTO BOOK (MaSach, TenSach, SoLuong) VALUES ('S0005', NULL, 1);          -- vi phạm NOT NULL (TenSach)
-- INSERT INTO BOOK (MaSach, TenSach, SoLuong) VALUES ('S0001', 'Trùng mã', 1);    -- vi phạm PRIMARY KEY
-- INSERT INTO BORROW_BOOKS (MaSach) VALUES ('S9999');                             -- vi phạm FOREIGN KEY
