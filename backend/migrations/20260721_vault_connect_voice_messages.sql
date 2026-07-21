ALTER TABLE messages
    MODIFY COLUMN message_type ENUM(
        'text', 'image', 'video', 'document', 'voice', 'deleted'
    ) NOT NULL;
