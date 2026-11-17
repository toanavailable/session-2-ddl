-- =====================================================
-- Thực hành: Hiệu chỉnh cấu trúc bảng với DDL (ALTER TABLE)
-- Dựa trên bảng Persons - hobbies của bài trước
-- =====================================================

CREATE DATABASE IF NOT EXISTS person_hobby_db;
USE person_hobby_db;

-- Xóa bảng cũ (nếu có): bảng con trước, bảng cha sau
DROP TABLE IF EXISTS hobbies;
DROP TABLE IF EXISTS Persons;

-- 1. Tạo bảng cha Persons (từ bài trước)
CREATE TABLE Persons (
    personId  INT          NOT NULL,
    lastName  VARCHAR(255) NOT NULL,
    firstName VARCHAR(255) NOT NULL,
    email     VARCHAR(100) UNIQUE,
    address   VARCHAR(255),
    city      VARCHAR(255),
    PRIMARY KEY (personId)
);

-- 2. Tạo bảng con hobbies (từ bài trước)
CREATE TABLE hobbies (
    id       INT          NOT NULL,
    name     VARCHAR(100) NOT NULL,
    personId INT          NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT chk_hobbies_name CHECK (CHAR_LENGTH(name) > 4),
    CONSTRAINT fk_hobbies_persons FOREIGN KEY (personId) REFERENCES Persons (personId)
);

-- 3. Hiệu chỉnh cấu trúc bảng Persons
-- 3.1 Thêm cột phone (chuỗi, giữ được số 0 đầu và dấu +)
ALTER TABLE Persons
ADD phone VARCHAR(15);

-- 3.2 Xóa cột city
ALTER TABLE Persons
DROP COLUMN city;

-- 4. Kiểm tra cấu trúc sau khi hiệu chỉnh
DESCRIBE Persons;
