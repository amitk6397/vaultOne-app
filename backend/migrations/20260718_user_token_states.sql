-- JWT session generation used for immediate all-device token revocation.
-- Existing tokens implicitly use generation 0 and remain valid until revoked.
CREATE TABLE IF NOT EXISTS user_token_states (
    user_id INT NOT NULL,
    session_version INT NOT NULL DEFAULT 0,
    revoked_at DATETIME(6) NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (user_id),
    CONSTRAINT fk_user_token_states_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
