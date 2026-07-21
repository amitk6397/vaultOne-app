CREATE TABLE IF NOT EXISTS pending_user_registrations (
    id INTEGER NOT NULL AUTO_INCREMENT,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_pending_user_registrations_email (email),
    UNIQUE KEY uq_pending_user_registrations_phone (phone),
    INDEX ix_pending_user_registrations_expires_at (expires_at)
);
