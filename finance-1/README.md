# Sự cố "Thất thoát tài chính" và "Tràn bộ nhớ"

Phân tích lỗi kiểu dữ liệu trong bảng `PRODUCTS` của một trang thương mại điện tử và viết lại câu lệnh `CREATE TABLE` cho chuẩn xác.

## 1. Bối cảnh

Hệ thống gặp hai vấn đề:

1. **Sai lệch tiền bạc:** tổng tiền mỗi đơn hàng lệch vài đồng lẻ, cuối tháng thất thoát hàng triệu đồng.
2. **Lãng phí tài nguyên:** bộ nhớ máy chủ đầy nhanh bất thường dù tên sản phẩm rất ngắn.

Hai triệu chứng này tương ứng với đoạn mã tạo bảng dùng sai kiểu dữ liệu như sau:

```sql
CREATE TABLE PRODUCTS (
    ID INT PRIMARY KEY,
    ProductName CHAR(255),
    Price FLOAT,
    Description TEXT
);
```

> Lưu ý: ảnh đoạn mã trên hệ thống bài tập đang hiển thị `ProductName VARCHAR(255)` và `Price DECIMAL(18, 2)`. Đây đã là kiểu dữ liệu đúng nên không gây ra hai sự cố trên. Phần phân tích dưới đây dựa trên phiên bản lỗi (`CHAR(255)` và `FLOAT`), vì chỉ phiên bản này mới gây ra đúng các triệu chứng được mô tả.

## 2. Phân tích lỗi

### Lỗi 1 – `Price FLOAT` gây thất thoát tài chính

- `FLOAT` là kiểu **dấu phẩy động**. Nó lưu số dưới dạng nhị phân gần đúng, nên nhiều số thập phân không được biểu diễn chính xác. Ví dụ, `0.1 + 0.2` không bằng đúng `0.3`.
- Mỗi lần cộng hay nhân giá tiền, sai số nhỏ lại xuất hiện. Hàng nghìn đơn hàng mỗi ngày làm các sai số này cộng dồn lại, nên kế toán thấy lệch vài đồng lẻ ở mỗi đơn và hàng triệu đồng vào cuối tháng.
- `FLOAT` chỉ có độ chính xác khoảng 7 chữ số. Các giá trị lớn, ví dụ `123456789.99`, còn bị làm tròn mất cả phần lẻ.

**Cách sửa:** dùng `DECIMAL(18, 2)`. Đây là kiểu **dấu phẩy cố định**, lưu chính xác tuyệt đối từng chữ số: 16 chữ số phần nguyên và 2 chữ số phần thập phân. Đây là kiểu chuẩn cho dữ liệu tiền tệ.

### Lỗi 2 – `ProductName CHAR(255)` gây lãng phí bộ nhớ

- `CHAR(n)` có **độ dài cố định**. Mọi giá trị đều chiếm đủ n ký tự, phần thiếu được đệm bằng khoảng trắng.
- Tên sản phẩm ngắn như `"Áo thun"` (7 ký tự) vẫn chiếm đủ 255 ký tự, tức lãng phí hơn 97% dung lượng. Với bảng mã `utf8mb4`, mỗi ký tự còn có thể tốn tới 4 byte, nên mỗi dòng tốn tới 1.020 byte chỉ cho cột tên.
- Với hàng triệu sản phẩm, phần khoảng trắng vô ích này khiến dữ liệu và chỉ mục phình to, làm bộ nhớ đầy nhanh.

**Cách sửa:** dùng `VARCHAR(100)`. `VARCHAR` có **độ dài thay đổi**, chỉ lưu đúng số ký tự thực tế cộng thêm 1 byte để ghi độ dài. Tên sản phẩm hiếm khi dài quá 100 ký tự. Giới hạn nhỏ hơn 255 cũng giúp giảm bộ nhớ khi MySQL tạo bảng tạm để sắp xếp hay nhóm dữ liệu, vì bảng tạm cấp phát theo độ dài tối đa.

### Cải tiến thêm về ràng buộc

| Cột | Bổ sung | Lý do |
|---|---|---|
| `ID` | `AUTO_INCREMENT` | Tự sinh mã sản phẩm, tránh trùng khóa chính khi thêm mới |
| `ProductName` | `NOT NULL` | Sản phẩm bắt buộc phải có tên |
| `Price` | `NOT NULL`, `CHECK (Price >= 0)` | Sản phẩm phải có giá, và giá không được âm |
| `Description` | giữ `TEXT` | Mô tả có thể dài, `TEXT` lưu tới 65.535 byte |

## 3. Câu lệnh CREATE TABLE đã sửa

```sql
CREATE TABLE PRODUCTS (
    ID          INT AUTO_INCREMENT PRIMARY KEY,
    ProductName VARCHAR(100)   NOT NULL,
    Price       DECIMAL(18, 2) NOT NULL CHECK (Price >= 0),
    Description TEXT
);
```

## 4. Kết luận

- Dữ liệu **tiền tệ** luôn dùng `DECIMAL`, không bao giờ dùng `FLOAT` hay `DOUBLE`.
- Chuỗi có **độ dài thay đổi** như tên hay mô tả ngắn thì dùng `VARCHAR`. Chỉ dùng `CHAR` khi độ dài luôn cố định, ví dụ mã vùng hay mã quốc gia.
