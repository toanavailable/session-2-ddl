-- =====================================================
-- Thực hành: Khởi tạo cấu trúc bảng với DDL (Persons - hobbies)
-- MySQL 8.0.16+ (CHECK được thực thi từ 8.0.16)
-- =====================================================

CREATE DATABASE IF NOT EXISTS person_hobby_db;
USE person_hobby_db;

-- Xóa bảng cũ (nếu có): bảng con trước, bảng cha sau
DROP TABLE IF EXISTS hobbies;
DROP TABLE IF EXISTS Persons;

-- Thao tác 1: Tạo bảng cha Persons
CREATE TABLE Persons (
    personId  INT          NOT NULL,
    lastName  VARCHAR(255) NOT NULL,
    firstName VARCHAR(255) NOT NULL,
    email     VARCHAR(100) UNIQUE,
    address   VARCHAR(255),
    city      VARCHAR(255),
    PRIMARY KEY (personId)
);

-- Thao tác 2: Tạo bảng con hobbies (1 Person - N hobbies)
CREATE TABLE hobbies (
    id       INT          NOT NULL,
    name     VARCHAR(100) NOT NULL,
    personId INT          NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT chk_hobbies_name CHECK (CHAR_LENGTH(name) > 4),
    CONSTRAINT fk_hobbies_persons FOREIGN KEY (personId) REFERENCES Persons (personId)
);

-- =====================================================
-- Kiểm thử
-- =====================================================
INSERT INTO Persons (personId, lastName, firstName, email, address, city) VALUES
    (1, 'Nguyễn', 'An',   'an.nguyen@gmail.com', '12 Lê Lợi', 'Hà Nội'),
    (2, 'Trần',   'Bình', 'binh.tran@gmail.com', NULL, 'Đà Nẵng');

INSERT INTO hobbies (id, name, personId) VALUES
    (1, 'Đọc sách', 1),
    (2, 'Bơi lội', 1),
    (3, 'Chơi guitar', 2);

SELECT p.firstName, p.lastName, h.name AS hobby
FROM Persons p
JOIN hobbies h ON h.personId = p.personId;

-- Các lệnh dưới đây PHẢI bị từ chối:
-- INSERT INTO Persons (personId, lastName, firstName, email) VALUES (3, 'Lê', 'Cường', 'an.nguyen@gmail.com'); -- vi phạm UNIQUE email
-- INSERT INTO hobbies (id, name, personId) VALUES (4, 'Golf', 1);       -- vi phạm CHECK: tên chỉ 4 ký tự
-- INSERT INTO hobbies (id, name, personId) VALUES (5, 'Du lịch', 99);   -- vi phạm FOREIGN KEY: person 99 không tồn tại
-- INSERT INTO Persons (personId, lastName, firstName) VALUES (4, NULL, 'Dũng'); -- vi phạm NOT NULL
