# Vá lỗ hổng "Khách hàng ảo"

Phân tích các ràng buộc còn thiếu trong bảng `CUSTOMERS` và vá lỗi bằng `ALTER TABLE`, không xóa bảng tạo lại.

## 1. Bối cảnh

Bộ phận Marketing chạy chiến dịch gửi email chúc mừng sinh nhật, nhưng hệ thống gửi email bị crash liên tục. Có hai nguyên nhân: nhiều khách hàng không có email (dữ liệu rác), và có khách hàng nhập tuổi là -5.

Bảng hiện tại:

```sql
CREATE TABLE CUSTOMERS (
    CustomerID INT PRIMARY KEY,
    FullName VARCHAR(100),
    Email VARCHAR(100), -- Allows NULL
    Age INT             -- No control over negative values
);
```

## 2. Phân tích các ràng buộc còn thiếu

| Cột | Ràng buộc thiếu | Hậu quả hiện tại | Cách vá |
|---|---|---|---|
| `Email` | `NOT NULL` | Khách hàng không có email vẫn được lưu. Hệ thống gửi mail gặp giá trị NULL nên bị crash | `MODIFY Email VARCHAR(100) NOT NULL` |
| `Email` | `UNIQUE` | Một email có thể đăng ký nhiều tài khoản ("khách hàng ảo"), khiến một người nhận nhiều email trùng | `ADD CONSTRAINT ... UNIQUE (Email)` |
| `Email` | `CHECK` định dạng | Chuỗi rỗng hoặc chuỗi như `"abc"` vẫn lọt qua `NOT NULL` | `CHECK (Email LIKE '%_@_%._%')` |
| `Age` | `CHECK` | Kiểu `INT` chấp nhận cả số âm, nên tuổi -5 vẫn được lưu | `CHECK (Age BETWEEN 0 AND 150)` |
| `FullName` | `NOT NULL` | Có thể có khách hàng không tên, email chúc mừng thiếu lời xưng hô | `MODIFY FullName VARCHAR(100) NOT NULL` |

**Vì sao cần ràng buộc ở tầng CSDL?** Kiểm tra dữ liệu ở giao diện hay ở code ứng dụng có thể bị bỏ qua, ví dụ khi nhập dữ liệu trực tiếp, import file, hoặc khi có ứng dụng khác ghi vào cùng bảng. Ràng buộc trong CSDL là lớp bảo vệ cuối cùng. Dữ liệu sai bị chặn ngay khi `INSERT`/`UPDATE`, nên không còn rác lọt vào bảng.

**Thiếu sót về nghiệp vụ:** chiến dịch gửi email *sinh nhật* nhưng bảng chỉ có `Age`, không có ngày sinh. Tuổi còn thay đổi theo từng năm nên không biết khi nào cần gửi email. Vì vậy cần bổ sung cột `DateOfBirth DATE`.

## 3. Vá lỗi bằng ALTER TABLE

Bảng đang có sẵn dữ liệu rác, nên nếu thêm `NOT NULL`/`CHECK` ngay thì MySQL sẽ báo lỗi. Phải **dọn dữ liệu trước**, sau đó mới vá cấu trúc bảng.

### Bước 1 – Sao lưu dữ liệu rác để đối soát

```sql
CREATE TABLE CUSTOMERS_INVALID AS
SELECT * FROM CUSTOMERS
WHERE Email IS NULL OR TRIM(Email) = ''
   OR FullName IS NULL
   OR Age < 0;
```

### Bước 2 – Dọn dữ liệu sai

```sql
-- Tuổi âm: không biết tuổi thật nên đặt về NULL
UPDATE CUSTOMERS SET Age = NULL WHERE Age < 0;

-- Khách hàng không có email hoặc không có tên: xóa
DELETE FROM CUSTOMERS
WHERE Email IS NULL OR TRIM(Email) = '' OR FullName IS NULL;

-- Kiểm tra email trùng trước khi thêm UNIQUE (kết quả phải rỗng)
SELECT Email, COUNT(*) AS SoLan
FROM CUSTOMERS
GROUP BY Email
HAVING COUNT(*) > 1;
```

### Bước 3 – Thêm ràng buộc

```sql
ALTER TABLE CUSTOMERS
    MODIFY FullName VARCHAR(100) NOT NULL,
    MODIFY Email    VARCHAR(100) NOT NULL,
    ADD CONSTRAINT uq_customers_email  UNIQUE (Email),
    ADD CONSTRAINT chk_customers_email CHECK (Email LIKE '%_@_%._%'),
    ADD CONSTRAINT chk_customers_age   CHECK (Age BETWEEN 0 AND 150);
```

### Bước 4 – Bổ sung ngày sinh cho chiến dịch sinh nhật

```sql
ALTER TABLE CUSTOMERS
    ADD DateOfBirth DATE;
```

## 4. Kiểm thử

Sau khi vá, các lệnh sau đều bị MySQL từ chối:

```sql
INSERT INTO CUSTOMERS (CustomerID, FullName, Email, Age) VALUES (100, 'Test', NULL, 20);       -- vi phạm NOT NULL
INSERT INTO CUSTOMERS (CustomerID, FullName, Email, Age) VALUES (101, 'Test', 'abc', 20);      -- vi phạm CHECK email
INSERT INTO CUSTOMERS (CustomerID, FullName, Email, Age) VALUES (102, 'Test', 'a@b.com', -5);  -- vi phạm CHECK tuổi
```

> Lưu ý: ràng buộc `CHECK` chỉ được MySQL thực thi từ phiên bản **8.0.16** trở lên. Các phiên bản cũ hơn chấp nhận cú pháp nhưng bỏ qua điều kiện.

## 5. Kết luận

- Cột bắt buộc cho nghiệp vụ, như email trong chiến dịch email, phải có `NOT NULL`.
- Cột dùng để liên hệ hoặc định danh, như email, nên có `UNIQUE` để tránh tài khoản ảo.
- Cột số có miền giá trị hợp lệ, như tuổi, phải có `CHECK`.
- Khi sửa bảng đang chạy, dùng `ALTER TABLE` và dọn dữ liệu cũ trước, không `DROP TABLE` vì sẽ mất toàn bộ dữ liệu khách hàng.
