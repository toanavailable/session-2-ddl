# Khởi tạo cấu trúc bảng với DDL và Ràng buộc

Dùng nhóm lệnh DDL (`CREATE`, `ALTER`) để tạo cơ sở dữ liệu thư viện gồm hai bảng: `BOOK` lưu thông tin sách và `BORROW_BOOKS` lưu lịch sử mượn sách. Mỗi cột được chọn kiểu dữ liệu tối ưu và có ràng buộc để chặn lỗi nhập liệu.

## Thao tác 1: Tạo bảng BOOK

```sql
CREATE TABLE BOOK (
    MaSach  CHAR(5)        PRIMARY KEY,
    TenSach VARCHAR(200)   NOT NULL,
    SoLuong INT            NOT NULL DEFAULT 0,
    GiaThue DECIMAL(10, 2) NOT NULL DEFAULT 5000,
    CONSTRAINT chk_book_soluong CHECK (SoLuong >= 0)
);
```

| Cột | Kiểu dữ liệu | Ràng buộc | Lý do chọn |
|---|---|---|---|
| `MaSach` | `CHAR(5)` | `PRIMARY KEY` | Mã luôn đủ 5 ký tự, nên kiểu cố định không lãng phí và truy xuất nhanh |
| `TenSach` | `VARCHAR(200)` | `NOT NULL` | Tên sách dài ngắn khác nhau, `VARCHAR` chỉ tốn đúng độ dài thực |
| `SoLuong` | `INT` | `NOT NULL`, `DEFAULT 0`, `CHECK (SoLuong >= 0)` | Số nguyên, chặn số lượng âm |
| `GiaThue` | `DECIMAL(10, 2)` | `NOT NULL`, `DEFAULT 5000` | Tiền cần chính xác tuyệt đối, `FLOAT` sẽ gây sai số |

## Thao tác 2: Cơi nới – thêm cột NgayNhap

```sql
ALTER TABLE BOOK
ADD NgayNhap DATE;
```

Cột này dùng `DATE` vì chỉ cần lưu ngày, tháng, năm (dạng `YYYY-MM-DD`, 3 byte), không cần giờ phút như `DATETIME`. Các sách đã có trong bảng sẽ nhận `NgayNhap = NULL` cho đến khi được cập nhật.

## Thao tác 3: Tạo bảng BORROW_BOOKS với khóa ngoại

```sql
CREATE TABLE BORROW_BOOKS (
    MaMuon   INT AUTO_INCREMENT PRIMARY KEY,
    MaSach   CHAR(5) NOT NULL,
    NgayMuon DATE    NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_borrow_book
        FOREIGN KEY (MaSach) REFERENCES BOOK (MaSach)
);
```

| Cột | Kiểu dữ liệu | Ràng buộc | Lý do chọn |
|---|---|---|---|
| `MaMuon` | `INT` | `PRIMARY KEY`, `AUTO_INCREMENT` | Mã mượn tự tăng, không cần nhập tay |
| `MaSach` | `CHAR(5)` | `NOT NULL`, `FOREIGN KEY → BOOK(MaSach)` | Phải **cùng kiểu** với `BOOK.MaSach`. Chỉ mượn được sách có thật |
| `NgayMuon` | `DATE` | `NOT NULL`, `DEFAULT (CURRENT_DATE)` | Tự lấy ngày hiện tại nếu không nhập |

Bảng `BOOK` (bảng cha) phải được tạo **trước** `BORROW_BOOKS` (bảng con). Nếu làm ngược lại, MySQL sẽ báo lỗi khóa ngoại vì bảng được tham chiếu chưa tồn tại.

## Self-Check

| Tiêu chí | Đạt |
|---|---|
| `CHAR(5)` cho mã sách, `VARCHAR` cho tên sách | ✅ |
| `DECIMAL` cho giá thuê | ✅ |
| `DATE` cho các cột ngày tháng | ✅ |
| `PRIMARY KEY` cho `MaSach`, `MaMuon` | ✅ |
| `NOT NULL` cho thông tin bắt buộc | ✅ |
| `CHECK (SoLuong >= 0)` | ✅ |
| `DEFAULT` cho giá thuê và ngày mượn | ✅ |
| `ALTER TABLE ... ADD` để thêm cột | ✅ |
| `FOREIGN KEY (MaSach) REFERENCES BOOK(MaSach)` | ✅ |

## Script SQL hoàn chỉnh

```sql
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
```

> Lưu ý: `DEFAULT (CURRENT_DATE)` cho cột `DATE` cần MySQL **8.0.13+**, và `CHECK` được thực thi từ **8.0.16+**.
