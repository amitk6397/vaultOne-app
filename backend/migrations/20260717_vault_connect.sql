-- Vault Connect: one-to-one secure messaging schema.
-- Application writes all DATETIME values in UTC.
CREATE TABLE conversations (
    id CHAR(36) PRIMARY KEY,
    type ENUM('direct') NOT NULL DEFAULT 'direct',
    direct_key VARCHAR(80) NOT NULL,
    last_message_id CHAR(36) NULL,
    last_message_at DATETIME(6) NULL,
    disappearing_duration_seconds INT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE KEY uq_conversations_direct_key (direct_key),
    KEY ix_conversations_last_message_at (last_message_at)
) ENGINE=InnoDB;

CREATE TABLE conversation_members (
    id CHAR(36) PRIMARY KEY,
    conversation_id CHAR(36) NOT NULL,
    user_id INT NOT NULL,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    is_muted BOOLEAN NOT NULL DEFAULT FALSE,
    cleared_before DATETIME(6) NULL,
    joined_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uq_conversation_member (conversation_id, user_id),
    KEY ix_conversation_members_user_archived (user_id, is_archived),
    CONSTRAINT fk_connect_member_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    CONSTRAINT fk_connect_member_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE messages (
    id CHAR(36) PRIMARY KEY,
    client_message_id VARCHAR(80) NOT NULL,
    conversation_id CHAR(36) NOT NULL,
    sender_user_id INT NOT NULL,
    message_type ENUM('text','image','video','document','deleted') NOT NULL,
    content TEXT NULL,
    reply_to_message_id CHAR(36) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at DATETIME(6) NULL,
    expires_at DATETIME(6) NULL,
    UNIQUE KEY uq_message_client_retry (sender_user_id, client_message_id),
    KEY ix_messages_conversation_created (conversation_id, created_at, id),
    KEY ix_messages_expires_at (expires_at),
    CONSTRAINT fk_connect_message_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    CONSTRAINT fk_connect_message_sender FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_connect_message_reply FOREIGN KEY (reply_to_message_id) REFERENCES messages(id) ON DELETE SET NULL
) ENGINE=InnoDB;

ALTER TABLE conversations
    ADD CONSTRAINT fk_connect_last_message FOREIGN KEY (last_message_id) REFERENCES messages(id) ON DELETE SET NULL;

CREATE TABLE message_receipts (
    id CHAR(36) PRIMARY KEY,
    message_id CHAR(36) NOT NULL,
    user_id INT NOT NULL,
    delivered_at DATETIME(6) NULL,
    read_at DATETIME(6) NULL,
    UNIQUE KEY uq_message_receipt_user (message_id, user_id),
    KEY ix_message_receipts_user (user_id),
    CONSTRAINT fk_connect_receipt_message FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    CONSTRAINT fk_connect_receipt_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE message_attachments (
    id CHAR(36) PRIMARY KEY,
    message_id CHAR(36) NULL,
    owner_user_id INT NOT NULL,
    conversation_id CHAR(36) NOT NULL,
    storage_key VARCHAR(700) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(160) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(20) NOT NULL,
    checksum CHAR(64) NULL,
    upload_status ENUM('pending','uploading','complete','failed','cancelled') NOT NULL DEFAULT 'pending',
    expires_at DATETIME(6) NULL,
    deleted_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uq_message_attachment_storage_key (storage_key),
    KEY ix_message_attachments_message (message_id),
    KEY ix_message_attachments_owner (owner_user_id),
    KEY ix_message_attachments_conversation (conversation_id),
    KEY ix_message_attachments_expires (expires_at),
    KEY ix_message_attachments_status (upload_status),
    CONSTRAINT fk_connect_attachment_message FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    CONSTRAINT fk_connect_attachment_owner FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_connect_attachment_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE message_user_states (
    id CHAR(36) PRIMARY KEY,
    message_id CHAR(36) NOT NULL,
    user_id INT NOT NULL,
    is_deleted_for_user BOOLEAN NOT NULL DEFAULT TRUE,
    deleted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uq_message_user_state (message_id, user_id),
    CONSTRAINT fk_connect_state_message FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    CONSTRAINT fk_connect_state_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE user_blocks (
    id CHAR(36) PRIMARY KEY,
    blocker_user_id INT NOT NULL,
    blocked_user_id INT NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uq_user_block_pair (blocker_user_id, blocked_user_id),
    KEY ix_user_blocks_blocked (blocked_user_id),
    CONSTRAINT fk_connect_block_blocker FOREIGN KEY (blocker_user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_connect_block_blocked FOREIGN KEY (blocked_user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT ck_connect_not_self_block CHECK (blocker_user_id <> blocked_user_id)
) ENGINE=InnoDB;

CREATE TABLE user_reports (
    id CHAR(36) PRIMARY KEY,
    reporter_user_id INT NOT NULL,
    reported_user_id INT NOT NULL,
    conversation_id CHAR(36) NULL,
    message_id CHAR(36) NULL,
    attachment_id CHAR(36) NULL,
    category VARCHAR(40) NOT NULL,
    description TEXT NOT NULL,
    evidence JSON NOT NULL,
    status ENUM('pending','reviewing','resolved','dismissed') NOT NULL DEFAULT 'pending',
    admin_notes TEXT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    KEY ix_user_reports_status_created (status, created_at),
    KEY ix_user_reports_reporter (reporter_user_id),
    KEY ix_user_reports_reported (reported_user_id),
    CONSTRAINT fk_connect_report_reporter FOREIGN KEY (reporter_user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_connect_report_reported FOREIGN KEY (reported_user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_connect_report_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE SET NULL,
    CONSTRAINT fk_connect_report_message FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE SET NULL,
    CONSTRAINT fk_connect_report_attachment FOREIGN KEY (attachment_id) REFERENCES message_attachments(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE vault_connect_config (
    id INT PRIMARY KEY,
    image_limit_bytes BIGINT NOT NULL DEFAULT 20971520,
    video_limit_bytes BIGINT NOT NULL DEFAULT 209715200,
    document_limit_bytes BIGINT NOT NULL DEFAULT 52428800,
    contact_batch_limit INT NOT NULL DEFAULT 500,
    message_rate_limit INT NOT NULL DEFAULT 60,
    delete_for_everyone_seconds INT NOT NULL DEFAULT 86400,
    allowed_extensions JSON NOT NULL,
    disappearing_durations JSON NOT NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB;

INSERT INTO vault_connect_config (
    id, allowed_extensions, disappearing_durations
) VALUES (
    1,
    JSON_ARRAY('jpg','jpeg','png','gif','webp','heic','mp4','mov','m4v','webm','3gp','pdf','doc','docx','xls','xlsx','ppt','pptx','txt','csv','zip'),
    JSON_ARRAY(0,3600,86400,604800,2592000)
);

CREATE TABLE vault_connect_user_access (
    user_id INT PRIMARY KEY,
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    suspended_until DATETIME(6) NULL,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_connect_access_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE vault_connect_audit_logs (
    id CHAR(36) PRIMARY KEY,
    user_id INT NULL,
    event_type VARCHAR(60) NOT NULL,
    metadata_json JSON NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    KEY ix_connect_audit_event_created (event_type, created_at),
    KEY ix_connect_audit_user (user_id),
    CONSTRAINT fk_connect_audit_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
