CREATE TABLE IF NOT EXISTS account_deletion_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    user_name VARCHAR(120) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    reason_code VARCHAR(60) NOT NULL,
    reason_text TEXT NULL,
    status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    admin_note TEXT NULL,
    reviewed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX ix_account_deletion_requests_user_id (user_id),
    INDEX ix_account_deletion_requests_status (status),
    INDEX ix_account_deletion_requests_created_at (created_at),
    CONSTRAINT fk_account_deletion_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE SET NULL
);
