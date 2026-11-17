-- =====================================================
-- Module "Ví Điện Tử ShopeePay Mini" - Database Schema Script
-- MySQL 8.0.16+ (CHECK constraint được thực thi từ 8.0.16)
-- Đủ 6 "Anh bảo vệ": PRIMARY KEY, FOREIGN KEY, NOT NULL, UNIQUE, CHECK, DEFAULT
-- =====================================================

CREATE DATABASE IF NOT EXISTS shopeepay_mini;
USE shopeepay_mini;

-- Xóa theo thứ tự ngược: bảng con trước, bảng cha sau
DROP TABLE IF EXISTS WALLET_TRANSACTIONS;
DROP TABLE IF EXISTS WALLETS;
DROP TABLE IF EXISTS CUSTOMERS;

-- -----------------------------------------------------
-- 1. CUSTOMERS - khách hàng (bảng cha)
-- -----------------------------------------------------
CREATE TABLE CUSTOMERS (
    CustomerID INT AUTO_INCREMENT,
    FullName   VARCHAR(100) NOT NULL,
    Email      VARCHAR(100) NOT NULL,
    Phone      VARCHAR(15)  NOT NULL,
    CreatedAt  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customers       PRIMARY KEY (CustomerID),
    CONSTRAINT uq_customers_email UNIQUE (Email),
    CONSTRAINT uq_customers_phone UNIQUE (Phone),
    CONSTRAINT chk_customers_email CHECK (Email LIKE '%_@_%._%'),
    CONSTRAINT chk_customers_phone CHECK (Phone REGEXP '^[+]?[0-9]{9,14}$')
);

-- -----------------------------------------------------
-- 2. WALLETS - ví điện tử (mỗi khách hàng tối đa 1 ví)
-- -----------------------------------------------------
CREATE TABLE WALLETS (
    WalletID   INT AUTO_INCREMENT,
    CustomerID INT            NOT NULL,
    Balance    DECIMAL(18, 2) NOT NULL DEFAULT 0,
    Currency   CHAR(3)        NOT NULL DEFAULT 'VND',
    Status     VARCHAR(10)    NOT NULL DEFAULT 'ACTIVE',
    CreatedAt  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_wallets          PRIMARY KEY (WalletID),
    CONSTRAINT uq_wallets_customer UNIQUE (CustomerID),              -- 1 khách hàng = tối đa 1 ví
    CONSTRAINT chk_wallets_balance CHECK (Balance >= 0),             -- không bao giờ âm tiền
    CONSTRAINT chk_wallets_currency CHECK (Currency = 'VND'),
    CONSTRAINT chk_wallets_status  CHECK (Status IN ('ACTIVE', 'LOCKED', 'CLOSED')),
    CONSTRAINT fk_wallets_customers
        FOREIGN KEY (CustomerID) REFERENCES CUSTOMERS (CustomerID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- 3. WALLET_TRANSACTIONS - lịch sử biến động số dư
-- -----------------------------------------------------
CREATE TABLE WALLET_TRANSACTIONS (
    TransactionID   BIGINT AUTO_INCREMENT,
    TransactionCode VARCHAR(36)    NOT NULL,                         -- mã giao dịch do ứng dụng sinh (chống trùng lặp)
    WalletID        INT            NOT NULL,
    Type            VARCHAR(10)    NOT NULL,                         -- DEPOSIT / WITHDRAW / PAYMENT
    Amount          DECIMAL(18, 2) NOT NULL,
    BalanceAfter    DECIMAL(18, 2) NULL,                             -- số dư sau giao dịch (để đối soát)
    Status          VARCHAR(10)    NOT NULL DEFAULT 'PENDING',       -- PENDING / SUCCESS / FAILED
    Description     VARCHAR(255)   NULL,
    CreatedAt       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_wallet_transactions PRIMARY KEY (TransactionID),
    CONSTRAINT uq_transactions_code   UNIQUE (TransactionCode),
    CONSTRAINT chk_transactions_type   CHECK (Type IN ('DEPOSIT', 'WITHDRAW', 'PAYMENT')),
    CONSTRAINT chk_transactions_amount CHECK (Amount > 0 AND Amount <= 100000000),
    CONSTRAINT chk_transactions_status CHECK (Status IN ('PENDING', 'SUCCESS', 'FAILED')),
    CONSTRAINT chk_transactions_balance_after
        CHECK (BalanceAfter IS NULL OR BalanceAfter >= 0),
    CONSTRAINT chk_transactions_success_has_balance
        CHECK (Status <> 'SUCCESS' OR BalanceAfter IS NOT NULL),
    CONSTRAINT fk_transactions_wallets
        FOREIGN KEY (WalletID) REFERENCES WALLETS (WalletID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =====================================================
-- DỮ LIỆU MẪU
-- =====================================================
INSERT INTO CUSTOMERS (FullName, Email, Phone) VALUES
    ('Nguyễn Văn An', 'an.nguyen@gmail.com', '0912345678'),
    ('Trần Thị Bình', 'binh.tran@gmail.com', '0987654321');

INSERT INTO WALLETS (CustomerID) VALUES (1), (2);   -- Balance tự = 0, Status tự = 'ACTIVE'

-- Nạp 500.000đ vào ví 1 (giao dịch nguyên tử: cập nhật số dư + ghi lịch sử)
START TRANSACTION;
UPDATE WALLETS SET Balance = Balance + 500000 WHERE WalletID = 1 AND Status = 'ACTIVE';
INSERT INTO WALLET_TRANSACTIONS (TransactionCode, WalletID, Type, Amount, BalanceAfter, Status, Description)
VALUES ('TXN-20261116-0001', 1, 'DEPOSIT', 500000, 500000, 'SUCCESS', 'Nạp tiền từ ngân hàng');
COMMIT;

-- Thanh toán 120.000đ từ ví 1
START TRANSACTION;
UPDATE WALLETS SET Balance = Balance - 120000 WHERE WalletID = 1 AND Status = 'ACTIVE';
INSERT INTO WALLET_TRANSACTIONS (TransactionCode, WalletID, Type, Amount, BalanceAfter, Status, Description)
VALUES ('TXN-20261116-0002', 1, 'PAYMENT', 120000, 380000, 'SUCCESS', 'Thanh toán đơn hàng #1001');
COMMIT;

SELECT * FROM WALLETS;
SELECT * FROM WALLET_TRANSACTIONS;

-- =====================================================
-- KIỂM THỬ KỊCH BẢN RỦI RO: mỗi lệnh dưới đây PHẢI bị từ chối
-- =====================================================
-- R1. Thanh toán vượt số dư (ví 2 đang có 0đ)      -> CHECK chk_wallets_balance
-- UPDATE WALLETS SET Balance = Balance - 50000 WHERE WalletID = 2;

-- R2. Nhập số tiền âm hoặc bằng 0                   -> CHECK chk_transactions_amount
-- INSERT INTO WALLET_TRANSACTIONS (TransactionCode, WalletID, Type, Amount) VALUES ('TXN-R2', 1, 'WITHDRAW', -200000);

-- R3. Tạo ví thứ hai cho cùng một khách hàng        -> UNIQUE uq_wallets_customer
-- INSERT INTO WALLETS (CustomerID) VALUES (1);

-- R4. Gửi lại cùng một giao dịch (bấm "Thanh toán" 2 lần) -> UNIQUE uq_transactions_code
-- INSERT INTO WALLET_TRANSACTIONS (TransactionCode, WalletID, Type, Amount) VALUES ('TXN-20261116-0002', 1, 'PAYMENT', 120000);

-- R5. Giao dịch cho ví không tồn tại                -> FOREIGN KEY fk_transactions_wallets
-- INSERT INTO WALLET_TRANSACTIONS (TransactionCode, WalletID, Type, Amount) VALUES ('TXN-R5', 999, 'DEPOSIT', 100000);

-- R6. Tạo ví cho khách hàng không tồn tại           -> FOREIGN KEY fk_wallets_customers
-- INSERT INTO WALLETS (CustomerID) VALUES (999);

-- R7. Loại giao dịch hoặc trạng thái không hợp lệ   -> CHECK chk_transactions_type / chk_transactions_status
-- INSERT INTO WALLET_TRANSACTIONS (TransactionCode, WalletID, Type, Amount) VALUES ('TXN-R7', 1, 'HACK', 100000);

-- R8. Thiếu thông tin bắt buộc (không có số tiền)   -> NOT NULL
-- INSERT INTO WALLET_TRANSACTIONS (TransactionCode, WalletID, Type) VALUES ('TXN-R8', 1, 'DEPOSIT');

-- R9. Xóa ví / khách hàng đang có lịch sử giao dịch -> FOREIGN KEY ON DELETE RESTRICT
-- DELETE FROM WALLETS WHERE WalletID = 1;
