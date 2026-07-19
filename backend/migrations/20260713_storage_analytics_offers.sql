-- Database-backed storage quotas, analytics and targeted in-app offers (MySQL 8+).
ALTER TABLE users ADD COLUMN storage_limit_bytes BIGINT NULL;

CREATE TABLE IF NOT EXISTS user_offers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL, plan_id INT NULL,
  title VARCHAR(160) NOT NULL, description TEXT NOT NULL,
  discount_percent INT NOT NULL DEFAULT 0, offer_price_paise INT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  starts_at DATETIME NOT NULL, expires_at DATETIME NOT NULL,
  created_by_admin_id INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_offer_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_offer_plan FOREIGN KEY (plan_id) REFERENCES subscription_plans(id),
  CONSTRAINT fk_offer_admin FOREIGN KEY (created_by_admin_id) REFERENCES admins(id),
  INDEX ix_offer_user (user_id), INDEX ix_offer_active (is_active), INDEX ix_offer_expiry (expires_at)
) ENGINE=InnoDB;
