DROP DATABASE IF EXISTS `unbxd-orig`;
CREATE DATABASE `unbxd-orig`;
USE `unbxd-orig`;

CREATE TABLE `user` (
    user_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username    VARCHAR(100) NOT NULL UNIQUE,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    phone       VARCHAR(20),
    bio         VARCHAR(255),
    city        VARCHAR(100),
    state       VARCHAR(100),
    role        VARCHAR(50) NOT NULL DEFAULT 'user',
    gender      VARCHAR(20),
    dob         DATE,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    photo_link  TINYTEXT
);

CREATE TABLE user_email (
    email_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email       VARCHAR(255) NOT NULL UNIQUE,
    is_primary  TINYINT(1) NOT NULL DEFAULT 0,
    user_id     INT UNSIGNED NOT NULL,
    CONSTRAINT fk_email_user FOREIGN KEY (user_id) REFERENCES `user`(user_id) ON DELETE CASCADE
);

CREATE TABLE artist (
    artist_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    is_verified TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_artist_user FOREIGN KEY (artist_id) REFERENCES `user`(user_id) ON DELETE CASCADE
);

CREATE TABLE admin (
    admin_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role VARCHAR(50) NOT NULL
);

CREATE TABLE admin_email (
    email_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email       VARCHAR(255) NOT NULL UNIQUE,
    is_primary  TINYINT(1) NOT NULL DEFAULT 0,
    admin_id     INT UNSIGNED NOT NULL,
    CONSTRAINT fk_email_admin FOREIGN KEY (admin_id) REFERENCES admin(admin_id) ON DELETE CASCADE
);

CREATE TABLE artist_status (
    status_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    status enum('under review', 'verified', 'banned', 'resolved') NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    artist_id INT UNSIGNED NOT NULL,
    reviewer_id INT UNSIGNED NOT NULL,
    CONSTRAINT fk_artist_status_reviewer FOREIGN KEY (reviewer_id) REFERENCES admin(admin_id) ON DELETE RESTRICT,
    CONSTRAINT fk_artist_status_artist FOREIGN KEY (artist_id) REFERENCES artist(artist_id)
);

CREATE TABLE category (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE item (
    item_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    size        VARCHAR(50),
    image_link  VARCHAR(255),
    artist_id     INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED,
    CONSTRAINT fk_item_user FOREIGN KEY (artist_id) REFERENCES artist(artist_id) ON DELETE CASCADE,
    CONSTRAINT fk_item_category FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE SET NULL
);

CREATE TABLE variants (
    item_id     INT UNSIGNED NOT NULL,
    name        VARCHAR(75) NOT NULL,
    pull_rate   FLOAT(3,2) NOT NULL,
    PRIMARY KEY (item_id, name),
    CONSTRAINT fk_variant_item FOREIGN KEY (item_id) REFERENCES item(item_id) ON DELETE CASCADE
);

CREATE TABLE listing (
    listing_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(50) NOT NULL,
    quantity    INT NOT NULL DEFAULT 0,
    price       DECIMAL(6, 2) NOT NULL,
    status ENUM('pending', 'active', 'archive', 'approved', 'rejected', 'flagged') NOT NULL,
    listing_type    VARCHAR(255),
    post_time   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    item_id     INT UNSIGNED NOT NULL,
    artist_id   INT UNSIGNED NOT NULL,
    CONSTRAINT fk_listing_seller FOREIGN KEY (artist_id) REFERENCES artist(artist_id) ON DELETE CASCADE,
    CONSTRAINT fk_listing_item FOREIGN KEY (item_id) REFERENCES item(item_id) ON DELETE CASCADE
);

CREATE TABLE `order` (
    order_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_time  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('in cart', 'purchased', 'processing', 'shipped') NOT NULL,
    buyer_id    INT UNSIGNED NOT NULL,
    order_total FLOAT (6,2) NOT NULL,
    CONSTRAINT fk_order_user FOREIGN KEY (buyer_id) REFERENCES `user`(user_id) ON DELETE RESTRICT
);

CREATE TABLE order_items (
    order_item_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    quantity            INT NOT NULL,
    price_at_purchase   FLOAT(6, 2) NOT NULL,
    order_id            INT UNSIGNED NOT NULL,
    listing_id          INT UNSIGNED NOT NULL,
    CONSTRAINT fk_orderitems_order FOREIGN KEY (order_id) REFERENCES `order`(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_orderitems_listing FOREIGN KEY (listing_id) REFERENCES listing(listing_id) ON DELETE CASCADE
);

CREATE TABLE likes (
    user_id     INT UNSIGNED NOT NULL,
    listing_id  INT UNSIGNED NOT NULL,
    liked_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, listing_id),
    CONSTRAINT fk_likes_user    FOREIGN KEY (user_id)    REFERENCES `user`(user_id)       ON DELETE CASCADE,
    CONSTRAINT fk_likes_listing FOREIGN KEY (listing_id) REFERENCES listing(listing_id)   ON DELETE CASCADE
);

CREATE TABLE artist_application (
    application_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    status ENUM('pending', 'approved', 'rejected') NOT NULL,
    portfolio_link  VARCHAR(255) NOT NULL,
    submitted_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at DATETIME,
    artist_id INT UNSIGNED NOT NULL,
    reviewer_id INT UNSIGNED,
    CONSTRAINT fk_application_artist FOREIGN KEY (artist_id) REFERENCES artist(artist_id) ON DELETE CASCADE,
    CONSTRAINT fk_application_reviewer FOREIGN KEY (reviewer_id) REFERENCES admin(admin_id) ON DELETE RESTRICT
);

CREATE TABLE user_activity (
    activity_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    activity_type   ENUM('view', 'search', 'like', 'purchase') NOT NULL,
    search_term     VARCHAR(255) DEFAULT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id         INT UNSIGNED NOT NULL,
    listing_id      INT UNSIGNED DEFAULT NULL,
    CONSTRAINT fk_activity_user    FOREIGN KEY (user_id)    REFERENCES `user`(user_id)       ON DELETE CASCADE,
    CONSTRAINT fk_activity_listing FOREIGN KEY (listing_id) REFERENCES listing(listing_id)   ON DELETE SET NULL
);

CREATE TABLE listing_moderation (
    moderation_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reason          VARCHAR(255),
    action          ENUM('approved', 'rejected', 'flagged') NOT NULL,
    reviewed_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    listing_id      INT UNSIGNED NOT NULL,
    reviewed_by     INT UNSIGNED NOT NULL,
    CONSTRAINT fk_moderation_listing    FOREIGN KEY (listing_id)    REFERENCES listing(listing_id)  ON DELETE CASCADE,
    CONSTRAINT fk_moderation_reviewer   FOREIGN KEY (reviewed_by)   REFERENCES `admin`(admin_id)      ON DELETE RESTRICT
);

CREATE TABLE fraud_report (
    report_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reason      TEXT NOT NULL,
    status      ENUM('open', 'investigating', 'resolved', 'dismissed') NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME DEFAULT NULL,
    order_id    INT UNSIGNED NOT NULL,
    reviewer_id  INT UNSIGNED NOT NULL,
    CONSTRAINT fk_afraud_order FOREIGN KEY (order_id) REFERENCES `order`(order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_fraud_reviewer FOREIGN KEY (reviewer_id) REFERENCES admin(admin_id) ON DELETE RESTRICT
);

CREATE TABLE user_session (
    session_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pages_viewed    INT UNSIGNED NOT NULL DEFAULT 0,
    login_time      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    logout_time     DATETIME DEFAULT NULL,
    user_id         INT UNSIGNED NOT NULL,
    CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES `user`(user_id) ON DELETE CASCADE
);

CREATE TABLE system_metric (
    metric_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    metric_type     VARCHAR(50) NOT NULL,
    value           DECIMAL(10, 2) NOT NULL,
    recorded_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE system_alert (
    alert_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    alert_type      VARCHAR(100) NOT NULL,
    severity        ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    status          ENUM('open', 'investigating', 'resolved') NOT NULL DEFAULT 'open',
    message         VARCHAR (255),
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at     DATETIME DEFAULT NULL
);

CREATE TABLE platform_metrics (
    metric_id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    active_users        INT UNSIGNED NOT NULL DEFAULT 0,
    churned_users       INT UNSIGNED NOT NULL DEFAULT 0,
    conversions         INT UNSIGNED NOT NULL DEFAULT 0,
    retained_users      INT UNSIGNED NOT NULL DEFAULT 0,
    user_rate           DECIMAL(5, 4) NOT NULL DEFAULT 0,
    conversion_rate     DECIMAL(5, 4) NOT NULL DEFAULT 0,
    retention_rate      DECIMAL(5, 4) NOT NULL DEFAULT 0,
    turnover_rate       DECIMAL(5, 4) NOT NULL DEFAULT 0,
    recorded_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);