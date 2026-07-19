-- VaultOne UPI subscriptions (MySQL 8+). Back up the database before applying.
CREATE TABLE IF NOT EXISTS subscription_plans (
  id INT AUTO_INCREMENT PRIMARY KEY, code VARCHAR(60) NOT NULL UNIQUE,
  name VARCHAR(120) NOT NULL, description TEXT NOT NULL, storage_gb INT NOT NULL,
  price_paise INT NOT NULL, billing_days INT NOT NULL, features JSON NOT NULL,
  why_purchase JSON NOT NULL, is_premium BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE, sort_order INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX ix_subscription_plans_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment_settings (
  id INT AUTO_INCREMENT PRIMARY KEY, upi_id VARCHAR(160) NOT NULL,
  receiver_name VARCHAR(160) NOT NULL, qr_code_path VARCHAR(700), instructions TEXT NOT NULL,
  payments_enabled BOOLEAN NOT NULL DEFAULT FALSE, request_expiry_minutes INT NOT NULL DEFAULT 30,
  updated_by_admin_id INT, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_payment_settings_admin FOREIGN KEY (updated_by_admin_id) REFERENCES admins(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS subscription_payments (
  id INT AUTO_INCREMENT PRIMARY KEY, order_id VARCHAR(48) NOT NULL UNIQUE,
  user_id INT NOT NULL, plan_id INT NOT NULL,
  status ENUM('created','pending_verification','approved','rejected','expired') NOT NULL DEFAULT 'created',
  base_amount_paise INT NOT NULL, payable_amount_paise INT NOT NULL, paid_amount_paise INT,
  utr VARCHAR(64) UNIQUE, screenshot_path VARCHAR(700), rejection_reason TEXT,
  expires_at DATETIME NOT NULL, submitted_at DATETIME, reviewed_at DATETIME,
  reviewed_by_admin_id INT, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_payment_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_payment_plan FOREIGN KEY (plan_id) REFERENCES subscription_plans(id),
  CONSTRAINT fk_payment_admin FOREIGN KEY (reviewed_by_admin_id) REFERENCES admins(id),
  INDEX ix_payment_user (user_id), INDEX ix_payment_plan (plan_id), INDEX ix_payment_status (status),
  INDEX ix_payment_amount (payable_amount_paise), INDEX ix_payment_expiry (expires_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_subscriptions (
  id INT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, plan_id INT NOT NULL,
  payment_id INT NOT NULL UNIQUE,
  status ENUM('pending','active','expired','cancelled') NOT NULL DEFAULT 'active',
  storage_gb INT NOT NULL, starts_at DATETIME NOT NULL, expires_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_subscription_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_subscription_plan FOREIGN KEY (plan_id) REFERENCES subscription_plans(id),
  CONSTRAINT fk_subscription_payment FOREIGN KEY (payment_id) REFERENCES subscription_payments(id),
  INDEX ix_subscription_user (user_id), INDEX ix_subscription_status (status), INDEX ix_subscription_expiry (expires_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment_audit_logs (
  id INT AUTO_INCREMENT PRIMARY KEY, payment_id INT NOT NULL, admin_id INT NOT NULL,
  action VARCHAR(40) NOT NULL, details JSON NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_payment FOREIGN KEY (payment_id) REFERENCES subscription_payments(id),
  CONSTRAINT fk_audit_admin FOREIGN KEY (admin_id) REFERENCES admins(id),
  INDEX ix_audit_payment (payment_id), INDEX ix_audit_admin (admin_id)
) ENGINE=InnoDB;

INSERT IGNORE INTO subscription_plans
(code,name,description,storage_gb,price_paise,billing_days,features,why_purchase,is_premium,is_active,sort_order)
VALUES
('monthly-1','Monthly Starter','Flexible monthly secure storage',1,4900,30,JSON_ARRAY('1 GB secure cloud space','All vault essentials'),JSON_ARRAY('Flexible monthly access'),FALSE,TRUE,1),
('quarterly-3','Quarterly Plus','Three-month storage plan',3,9900,90,JSON_ARRAY('3 GB secure cloud space','Priority sync'),JSON_ARRAY('Lower per-GB price'),FALSE,TRUE,2),
('yearly-5','Yearly Pro','Annual storage for regular backups',5,14900,365,JSON_ARRAY('5 GB secure cloud space','Priority support'),JSON_ARRAY('Best for regular backups'),FALSE,TRUE,3),
('premium-10','Premium Yearly','Maximum VaultOne storage and benefits',10,24900,365,JSON_ARRAY('10 GB secure space','All plan features','Priority support'),JSON_ARRAY('Best value per GB'),TRUE,TRUE,4);

INSERT INTO payment_settings (upi_id,receiver_name,instructions,payments_enabled,request_expiry_minutes)
SELECT '', 'VaultOne', 'Pay the exact amount and submit your UTR and screenshot.', FALSE, 30
WHERE NOT EXISTS (SELECT 1 FROM payment_settings);
