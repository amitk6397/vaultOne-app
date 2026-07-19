CREATE TABLE IF NOT EXISTS user_auth_events (
    id INTEGER NOT NULL AUTO_INCREMENT,
    user_id INTEGER NOT NULL,
    event_type ENUM('register', 'login', 'logout') NOT NULL,
    auth_method VARCHAR(30) NOT NULL DEFAULT 'password',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX ix_user_auth_events_user_id (user_id),
    INDEX ix_user_auth_events_event_type (event_type),
    INDEX ix_user_auth_events_created_at (created_at),
    CONSTRAINT fk_user_auth_events_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
);
