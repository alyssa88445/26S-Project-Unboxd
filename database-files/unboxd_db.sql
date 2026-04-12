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

INSERT INTO `user` (user_id, username, first_name, last_name, phone, bio, city,
state, role, gender, dob, created_at, photo_link)
VALUES
(1, 'twilightsparks', 'Twilight', 'Sparkle', '5', 'Music is magical!',
'Portland', 'Oregon', 'user', 'female', '2001-11-07', '2026-03-15 14:30:00',
'https://example.com/photos/user1.jpg'),
(2, 'johnambrose', 'John', 'Ambrose', '6', 'Love is in the air.', 'New
York City', 'New York', 'user', 'male', '1999-03-02', '2022-02-14 11:20:00',
'https://example.com/photos/user2.jpg'),
(3, 'alitaplains02', 'Alita', 'Plains', '3', 'Horses.', 'Louisville',
'Kentucky', 'user', 'female', '2007-05-04', '2023-01-03 09:03:00',
'https://example.com/photos/user3.jpg');

INSERT INTO user_email (email, is_primary, user_id)
VALUES
('astra.coleman@email.com', 1, 1),
('astra.backup@email.com', 0, 1),
('marco.reyes@email.com', 1, 2),
('luna.park@email.com', 1, 3);

INSERT INTO artist (artist_id, is_verified)
VALUES
(1, 1),
(2, 0),
(3, 1);

INSERT INTO admin (first_name, last_name, role)
VALUES
('Jordan', 'Kim', 'systems_admin'),
('Sam', 'Torres', 'moderator'),
('Riley', 'Chen', 'support');

INSERT INTO admin_email (email, is_primary, admin_id)
VALUES
('jordan.kim@unbxd.com', 1, 1),
('sam.torres@unbxd.com', 1, 2),
('riley.chen@unbxd.com', 1, 3);

INSERT INTO artist_status (status, artist_id, reviewer_id)
VALUES
('verified', 1, 1),
('under review', 2, 2),
('verified', 3, 1);

INSERT INTO category (name)
VALUES
('Fantasy'),
('Indie'),
('Rock');

INSERT INTO item (name, description, size, image_link, artist_id, category_id)
VALUES
('Mystery Box Vol.1', 'Limited collectible box', 'S', 'https://example.com/img/mystery-box-1.jpg', 1, 1),
('Enchanted Series', 'Magical creature blind box', 'M', 'https://example.com/img/enchanted.jpg', 2, 1),
('Street Art Pack', 'Urban themed figurine set', 'S', 'https://example.com/img/street-art.jpg', 3, 3);

INSERT INTO variants (item_id, name, pull_rate)
VALUES
(1, 'Pink', 0.50),
(1, 'Gold', 0.10),
(2, 'Silver', 0.40);

INSERT INTO listing (title, quantity, price, status, listing_type, item_id, artist_id)
VALUES
('Mystery Box Vol.1 Drop', 50, 24.99, 'active', 'standard', 1, 1),
('Enchanted Series Launch', 30, 34.99, 'active', 'limited_edition', 2, 2),
('Street Art Auction', 20, 19.99, 'pending', 'auction', 3, 3);

INSERT INTO `order` (status, buyer_id, order_total)
VALUES
('purchased', 1, 24.99),
('shipped', 2, 69.98),
('in cart', 3, 19.99);

INSERT INTO order_items (quantity, price_at_purchase, order_id, listing_id)
VALUES
(1, 24.99, 1, 1),
(2, 34.99, 2, 2),
(1, 19.99, 3, 3);

INSERT INTO likes (user_id, listing_id)
VALUES
(1, 2),
(2, 1),
(3, 1);

INSERT INTO user_activity (activity_type, search_term, user_id, listing_id)
VALUES
('search', 'fairy figurine', 1, NULL),
('view', NULL, 2, 1),
('purchase', NULL, 3, 3);

INSERT INTO fraud_report (reason, status, order_id, reviewer_id)
VALUES
('Suspicious purchase volume', 'open', 1, 1),
('Possible duplicate account', 'investigating', 2, 2);

INSERT INTO user_session (pages_viewed, user_id)
VALUES
(5, 1),
(12, 2),
(3, 3);

INSERT INTO system_metric (metric_type, value)
VALUES
('cpu_usage', 45.20),
('memory_usage', 62.80),
('network_latency', 12.50);

INSERT INTO system_alert (alert_type, severity, status, message)
VALUES
('High CPU Usage', 'high', 'open', 'CPU usage exceeded 90% threshold'),
('API Timeout', 'medium', 'resolved', 'API response time exceeded 5s'),
('Memory Spike', 'critical', 'investigating', 'Memory usage at 95%');

INSERT INTO platform_metrics (active_users, churned_users, conversions, retained_users, user_rate, conversion_rate, retention_rate, turnover_rate)
VALUES
(1500, 200, 350, 1300, 0.0750, 0.2333, 0.8667, 0.1333),
(1620, 180, 410, 1440, 0.0800, 0.2531, 0.8889, 0.1111);

INSERT INTO artist_application (status, portfolio_link, artist_id, reviewer_id)
VALUES
('approved', 'https://example.com/portfolio/artist1', 1, 1),
('pending', 'https://example.com/portfolio/artist2', 2, NULL),
('rejected', 'https://example.com/portfolio/artist3', 3, 2);

INSERT INTO listing_moderation (reason, action, listing_id, reviewed_by) 
VALUES
('Approved after review', 'approved', 1, 1),
('Misleading description', 'flagged', 3, 2);
