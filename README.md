# Hiệu chỉnh cấu trúc bảng với DDL

Dùng lệnh `ALTER TABLE` để thay đổi cấu trúc bảng `Persons` (đã tạo ở bài trước) theo yêu cầu mới, không cần xóa bảng và tạo lại.

## Thêm cột phone

```sql
ALTER TABLE Persons
ADD phone VARCHAR(15);
```

- Cột dùng `VARCHAR(15)` thay vì `INT`, vì số điện thoại là chuỗi định danh. Kiểu chuỗi giữ được số 0 ở đầu (`0912345678`) và dấu `+` của mã quốc gia (`+84912345678`). Kiểu `INT` sẽ cắt mất số 0 ở đầu.
- Độ dài 15 đủ cho số điện thoại quốc tế (tối đa 15 chữ số theo chuẩn E.164).
- Các dòng đã có trong bảng sẽ nhận `phone = NULL`.

## Xóa cột city

```sql
ALTER TABLE Persons
DROP COLUMN city;
```

- `DROP COLUMN` xóa cột cùng **toàn bộ dữ liệu** trong cột đó, và không thể khôi phục. Nếu dữ liệu còn giá trị, nên sao lưu trước khi chạy.
- Cột `city` không có khóa hay ràng buộc nào liên quan, nên xóa được trực tiếp. Bảng `hobbies` không bị ảnh hưởng, vì khóa ngoại chỉ tham chiếu tới `personId`.

## Cấu trúc bảng Persons sau khi hiệu chỉnh

| Cột | Kiểu dữ liệu | Ràng buộc |
|---|---|---|
| `personId` | `INT` | `NOT NULL`, `PRIMARY KEY` |
| `lastName` | `VARCHAR(255)` | `NOT NULL` |
| `firstName` | `VARCHAR(255)` | `NOT NULL` |
| `email` | `VARCHAR(100)` | `UNIQUE` |
| `address` | `VARCHAR(255)` | – |
| `phone` | `VARCHAR(15)` | – (cột mới) |

Kiểm tra lại bằng lệnh `DESCRIBE Persons;`.

## Self-Check

| Tiêu chí | Đạt |
|---|---|
| Từ khóa hệ thống viết hoa (`CREATE`, `TABLE`, `ALTER`, `ADD`, `DROP`) | ✅ |
| Mỗi câu lệnh kết thúc bằng `;` | ✅ |
| Tạo bảng cha `Persons` trước bảng con `hobbies` | ✅ |

## Script SQL hoàn chỉnh

```sql
CREATE DATABASE IF NOT EXISTS person_hobby_db;
USE person_hobby_db;

DROP TABLE IF EXISTS hobbies;
DROP TABLE IF EXISTS Persons;

CREATE TABLE Persons (
    personId  INT          NOT NULL,
    lastName  VARCHAR(255) NOT NULL,
    firstName VARCHAR(255) NOT NULL,
    email     VARCHAR(100) UNIQUE,
    address   VARCHAR(255),
    city      VARCHAR(255),
    PRIMARY KEY (personId)
);

CREATE TABLE hobbies (
    id       INT          NOT NULL,
    name     VARCHAR(100) NOT NULL,
    personId INT          NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT chk_hobbies_name CHECK (CHAR_LENGTH(name) > 4),
    CONSTRAINT fk_hobbies_persons FOREIGN KEY (personId) REFERENCES Persons (personId)
);

ALTER TABLE Persons
ADD phone VARCHAR(15);

ALTER TABLE Persons
DROP COLUMN city;

DESCRIBE Persons;
```
