# Khủng hoảng nâng cấp Dữ liệu Số Điện Thoại

Đánh giá sự đánh đổi (trade-off) khi chạy lệnh DDL trên hệ thống đang vận hành: đổi cột `Phone` của bảng `USERS` (khoảng 2 triệu bản ghi) từ `INT` sang `VARCHAR(15)`.

## 1. Hiện trạng và nguyên nhân

- Cột `Phone` đang có kiểu `INT`. Số 0 ở đầu không có giá trị toán học nên bị cắt bỏ: `0981234567` được lưu thành `981234567`.
- Khi khách hàng đăng nhập bằng số điện thoại có số 0 đầu, hệ thống so sánh với dữ liệu đã mất số 0, nên báo sai thông tin đăng nhập.
- Số điện thoại là **chuỗi định danh**, không dùng để tính toán, nên phải lưu bằng kiểu chuỗi `VARCHAR(15)`. Kiểu này giữ được số 0, dấu `+84` và đủ dài cho số quốc tế.

> Lưu ý quan trọng: đổi kiểu dữ liệu **không tự khôi phục** số 0 đã mất. `INT 981234567` chỉ được chuyển thành chuỗi `'981234567'`. Vì vậy sau khi đổi kiểu, vẫn cần một bước cập nhật dữ liệu để thêm lại số 0.

## 2. Hai giải pháp DDL

### Giải pháp 1 – Đổi kiểu trực tiếp bằng `ALTER TABLE ... MODIFY`

```sql
ALTER TABLE USERS
    MODIFY COLUMN Phone VARCHAR(15),
    ALGORITHM = COPY,
    LOCK = SHARED;
```

MySQL tạo một bảng tạm với cấu trúc mới, chép toàn bộ 2 triệu dòng sang (chuyển `INT` thành chuỗi), rồi tráo bảng mới vào thay bảng cũ. Đổi `INT` sang `VARCHAR` là thay đổi kiểu dữ liệu thật sự, nên MySQL **bắt buộc dựng lại bảng** (`ALGORITHM=COPY`) chứ không sửa tại chỗ được. Trong lúc chép, bảng chỉ cho phép đọc và các lệnh ghi phải chờ.

### Giải pháp 2 – Thêm cột mới, chuyển dữ liệu rồi tráo cột (Expand – Migrate – Contract)

```sql
-- (1) Expand: thêm cột mới, gần như tức thì, không khóa bảng
ALTER TABLE USERS ADD COLUMN Phone_new VARCHAR(15), ALGORITHM = INSTANT;

-- (2) Migrate: chép dữ liệu theo lô, thêm lại số 0; ứng dụng ghi song song vào cả 2 cột
UPDATE USERS SET Phone_new = CONCAT('0', Phone)
WHERE Phone_new IS NULL LIMIT 10000;   -- lặp lại đến khi hết

-- (3) Contract: sau khi ứng dụng chuyển sang đọc cột mới thì xóa cột cũ và đổi tên
ALTER TABLE USERS DROP COLUMN Phone;
ALTER TABLE USERS RENAME COLUMN Phone_new TO Phone;
```

Cột mới được thêm bằng `ALGORITHM=INSTANT` (MySQL 8.0.12+) nên chỉ sửa metadata, không chép dữ liệu. Dữ liệu được chuyển dần theo lô, và ứng dụng được cập nhật qua nhiều lần triển khai để đọc và ghi cột mới. Cách làm tương tự có thể tự động hóa bằng công cụ online schema change như `pt-online-schema-change` hoặc `gh-ost`.

## 3. So sánh và lựa chọn

| Tiêu chí | Giải pháp 1: `MODIFY` trực tiếp | Giải pháp 2: Thêm cột mới + tráo cột |
|---|---|---|
| Số câu lệnh DDL | 1 câu, nguyên tử (thành công hết hoặc không thay đổi gì) | Nhiều câu, chia nhiều giai đoạn |
| Khóa bảng | Khóa ghi (`LOCK=SHARED`) trong lúc chép, vẫn cho phép đọc | Gần như không khóa (`INSTANT`, cập nhật theo lô) |
| Thời gian ảnh hưởng | Với 2 triệu dòng, thường từ vài chục giây đến vài phút | Gần như bằng 0, nhưng toàn bộ quá trình kéo dài lâu hơn |
| Đăng nhập (đọc) | Vẫn hoạt động bình thường | Vẫn hoạt động bình thường |
| Đăng ký / cập nhật (ghi) | Phải chờ đến khi lệnh chạy xong | Hoạt động bình thường |
| Dung lượng đĩa tạm | Cần thêm khoảng bằng kích thước bảng để chép | Thêm 1 cột, tăng dần |
| Sửa code ứng dụng | Không đổi tên cột, nên code giữ nguyên | Phải sửa code nhiều lần (ghi 2 cột, đổi cột đọc, dọn dẹp) |
| Độ phức tạp / rủi ro thao tác | Thấp, dễ kiểm soát | Cao, dễ sót bước và lệch dữ liệu giữa 2 cột |
| Phù hợp khi | Bảng vừa (vài triệu dòng), chấp nhận chặn ghi ngắn vào giờ thấp điểm | Bảng rất lớn (hàng trăm triệu dòng) hoặc không chấp nhận gián đoạn ghi |

### Chốt giải pháp: Giải pháp 1

Lý do chọn:

1. **Quy mô 2 triệu dòng là vừa phải.** Việc dựng lại bảng thường chỉ mất từ vài chục giây đến vài phút. Nếu chạy vào giờ thấp điểm, thời gian chặn ghi là chấp nhận được.
2. **Không làm sập ứng dụng.** `LOCK=SHARED` cho phép đọc trong suốt quá trình, nên chức năng **đăng nhập** (nỗi đau chính của khách hàng) vẫn chạy. Cột giữ nguyên tên `Phone`, nên code ứng dụng không bị lỗi "Unknown column".
3. **Dứt điểm trong một câu lệnh nguyên tử.** Nếu có sự cố giữa chừng, MySQL hủy bảng tạm và bảng gốc còn nguyên vẹn. Không có trạng thái "nửa vời" hai cột như giải pháp 2.
4. **An toàn nhờ khai báo rõ `ALGORITHM` và `LOCK`.** Nếu MySQL không đáp ứng được mức khóa đã yêu cầu, lệnh báo lỗi ngay thay vì âm thầm khóa cả việc đọc.

Giải pháp 2 là lựa chọn đúng khi bảng lên tới hàng trăm triệu dòng hoặc hệ thống không được phép dừng ghi dù chỉ một phút. Với bài toán hiện tại, độ phức tạp của nó lớn hơn lợi ích mang lại.

## 4. Thực thi

### Câu lệnh DDL được chọn

```sql
ALTER TABLE USERS
    MODIFY COLUMN Phone VARCHAR(15),
    ALGORITHM = COPY,
    LOCK = SHARED;
```

### Quy trình chạy an toàn

1. **Sao lưu** bảng trước khi chạy: `mysqldump -u root -p shop_db USERS > users_backup.sql`.
2. **Chạy thử** trên bản sao dữ liệu ở môi trường staging để đo thời gian thực tế.
3. **Chạy lệnh DDL vào giờ thấp điểm** và báo trước cho các bộ phận liên quan.
4. **Khôi phục số 0 đầu** (lệnh DML, cập nhật theo lô để không khóa bảng lâu):

```sql
UPDATE USERS
SET Phone = CONCAT('0', Phone)
WHERE CHAR_LENGTH(Phone) = 9
  AND Phone NOT LIKE '0%'
LIMIT 10000;   -- lặp lại đến khi không còn dòng nào bị ảnh hưởng
```

5. **Kiểm tra** lại cấu trúc và dữ liệu:

```sql
SHOW CREATE TABLE USERS;
SELECT COUNT(*) FROM USERS WHERE Phone NOT LIKE '0%';
```

6. **Cập nhật ứng dụng** để truyền số điện thoại dạng **chuỗi** (`WHERE Phone = '0981234567'`). Nếu vẫn truyền dạng số, MySQL phải ép kiểu từng dòng và không dùng được chỉ mục, khiến đăng nhập chậm.
