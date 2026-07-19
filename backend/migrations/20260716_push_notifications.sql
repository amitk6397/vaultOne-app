CREATE TABLE IF NOT EXISTS user_device_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(512) NOT NULL,
    platform VARCHAR(20) NOT NULL DEFAULT 'android',
    device_id VARCHAR(160) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_seen_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_user_device_token (token),
    KEY ix_user_device_tokens_user_id (user_id),
    KEY ix_user_device_tokens_is_active (is_active),
    CONSTRAINT fk_device_token_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS push_notification_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(160) NOT NULL,
    body TEXT NOT NULL,
    target_type VARCHAR(20) NOT NULL,
    target_user_id INT NULL,
    data JSON NOT NULL,
    success_count INT NOT NULL DEFAULT 0,
    failure_count INT NOT NULL DEFAULT 0,
    created_by_admin_id INT NULL,
    event_type VARCHAR(60) NOT NULL DEFAULT 'manual',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY ix_push_notification_logs_target_type (target_type),
    KEY ix_push_notification_logs_target_user_id (target_user_id),
    KEY ix_push_notification_logs_created_at (created_at),
    CONSTRAINT fk_push_log_user FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_push_log_admin FOREIGN KEY (created_by_admin_id) REFERENCES admins(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS user_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(160) NOT NULL,
    body TEXT NOT NULL,
    data JSON NOT NULL,
    event_type VARCHAR(60) NOT NULL DEFAULT 'manual',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY ix_user_notifications_user_id (user_id),
    KEY ix_user_notifications_is_read (is_read),
    KEY ix_user_notifications_created_at (created_at),
    CONSTRAINT fk_user_notification_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
