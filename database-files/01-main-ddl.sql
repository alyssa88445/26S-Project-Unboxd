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
    street_address VARCHAR(255),
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
    order_total FLOAT (6,2) NULL,
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

-- user_session
INSERT INTO user_session (session_id, pages_viewed, login_time, logout_time, user_id) 
VALUES
(1, 34, '2026-01-04 09:48:31', '2026-01-26 07:42:48', 2),
(3, 87, '2025-11-03 10:08:22', '2025-11-16 20:10:46', 4),
(5, 23, '2026-01-10 18:59:52', '2025-05-24 12:18:12', 6),
(7, 70, '2026-01-26 01:42:44', '2026-03-16 10:19:26', 8),
(9, 39, '2025-08-27 00:14:39', '2025-08-30 00:44:46', 10),
(11, 59, '2025-06-23 22:38:42', '2026-03-29 11:53:06', 12),
(13, 58, '2026-03-23 03:07:00', '2026-04-03 13:26:59', 14),
(15, 11, '2025-12-14 22:43:47', '2025-09-30 10:08:46', 16),
(17, 96, '2025-12-09 02:19:28', '2025-10-16 08:05:30', 18),
(19, 62, '2025-06-10 17:25:06', '2026-03-02 17:47:33', 20),
(21, 87, '2026-03-19 19:47:18', '2025-07-13 00:27:17', 22),
(23, 54, '2025-08-26 23:42:27', '2025-07-06 21:47:42', 24),
(25, 67, '2025-05-21 18:33:59', '2025-11-15 17:26:48', 26),
(27, 56, '2025-08-29 14:04:07', '2025-06-05 23:06:13', 28),
(29, 47, '2025-10-10 08:55:09', '2025-05-20 10:13:04', 30),
(31, 85, '2025-09-11 16:57:15', '2025-08-26 11:11:09', 32),
(33, 41, '2026-04-06 16:42:36', '2026-02-13 11:07:07', 34),
(35, 62, '2025-09-11 21:16:37', '2025-10-31 22:25:04', 36),
(37, 81, '2025-08-31 21:58:14', '2025-10-23 09:00:20', 38),
(39, 11, '2025-12-24 10:37:06', '2025-09-08 15:35:51', 40),
(41, 55, '2025-04-24 23:54:40', '2025-09-11 02:08:03', 42),
(43, 7, '2025-12-17 11:42:13', '2025-12-06 00:54:11', 44),
(45, 58, '2025-04-28 01:24:06', '2025-08-08 23:45:52', 46),
(47, 63, '2026-03-06 11:14:38', '2025-09-26 20:40:54', 48),
(49, 27, '2026-01-21 14:15:22', '2025-10-26 13:54:58', 50),
(51, 7, '2025-07-18 13:25:54', '2025-10-21 06:10:02', 52),
(53, 38, '2025-07-09 12:55:30', '2026-02-24 11:45:12', 54),
(55, 45, '2026-01-15 13:16:30', '2025-05-10 14:42:16', 56),
(57, 78, '2025-05-25 18:40:02', '2025-08-28 00:27:14', 58),
(59, 59, '2025-08-17 01:55:50', '2025-10-04 23:34:19', 60),
(61, 36, '2025-11-21 09:13:48', '2025-04-27 19:11:57', 62),
(63, 80, '2025-06-13 12:53:30', '2025-10-01 13:17:42', 64),
(65, 54, '2025-12-21 07:45:24', '2026-01-27 03:32:26', 66),
(67, 12, '2026-01-02 09:25:39', '2026-02-04 19:03:25', 68),
(69, 92, '2025-06-16 20:30:19', '2025-07-31 11:48:51', 70);

-- user_activity
INSERT INTO user_activity (activity_id, activity_type, search_term, created_at, user_id, listing_id) 
VALUES
(71, 'purchase', 'small batch', '2025-05-30 20:22:43', 2, 72),
(73, 'purchase', 'series', '2026-03-28 12:35:13', 4, 74),
(75, 'view', NULL, '2025-07-08 14:17:04', 6, 76),
(77, 'purchase', 'wood', '2025-07-16 09:18:29', 8, 78),
(79, 'purchase', NULL, '2025-06-16 00:28:30', 10, 80),
(81, 'search', 'woman artist', '2025-08-27 18:43:33', 12, 82),
(83, 'view', 'fairytale', '2025-05-30 08:21:18', 14, 84),
(85, 'view', 'sculpted', '2026-02-03 00:13:07', 16, 86),
(87, 'view', 'mythology', '2025-08-27 04:58:38', 18, 88),
(89, 'search', 'witchy', '2025-07-09 22:12:40', 20, NULL),
(90, 'like', 'wave 2', '2025-08-07 14:15:42', 22, 91),
(92, 'like', 'Austin', '2025-09-27 06:38:44', 24, 93),
(94, 'like', 'retro', '2025-04-22 02:26:45', 26, 95),
(96, 'purchase', 'glazed', '2026-01-13 18:22:42', 28, 97),
(98, 'purchase', 'strange', '2025-06-12 09:01:39', 30, 99),
(100, 'like', NULL, '2025-11-25 17:12:40', 32, 101),
(102, 'like', NULL, '2025-10-08 08:48:55', 34, 103),
(104, 'like', 'tiny', '2025-12-28 10:37:26', 36, 105),
(106, 'like', 'limited edition', '2025-11-25 04:49:50', 38, 107),
(108, 'view', 'tide pool', '2025-06-22 04:40:02', 40, 109),
(110, 'view', 'mystery', '2025-06-10 11:55:51', 42, 111),
(112, 'like', 'witchy', '2025-04-17 13:04:42', 44, 113),
(114, 'like', 'paper', '2025-11-15 18:00:34', 46, 115),
(116, 'view', 'punk', '2025-06-25 04:08:45', 48, 117),
(118, 'search', 'tide pool', '2025-05-21 14:07:06', 50, 119),
(120, 'purchase', 'dreamlike', '2025-04-24 22:05:48', 52, 121),
(122, 'search', 'city', '2025-07-08 16:16:44', 54, 123),
(124, 'like', 'skull', '2025-11-08 09:47:06', 56, 125),
(126, 'view', 'industrial', '2025-10-22 16:03:57', 58, 127),
(128, 'like', NULL, '2025-09-16 21:29:42', 60, NULL),
(129, 'like', 'local art', '2026-03-13 15:55:57', 62, 130),
(131, 'like', 'witchy', '2025-06-07 17:15:23', 64, 132),
(133, 'search', 'secondhand', '2026-02-14 08:17:31', 66, 134),
(135, 'search', 'rare', '2025-07-22 06:53:52', 68, 136),
(137, 'purchase', 'mythology', '2025-05-27 21:12:36', 70, 138);

-- likes
INSERT INTO likes (user_id, listing_id, liked_at) 
VALUES
(2, 72, '2025-10-28 01:11:54'),
(4, 74, '2025-07-24 00:04:49'),
(6, 76, '2026-01-31 19:30:43'),
(8, 78, '2026-01-21 21:26:43'),
(10, 80, '2025-09-05 01:08:54'),
(12, 82, '2025-06-01 05:21:17'),
(14, 84, '2026-02-22 17:44:57'),
(16, 86, '2026-02-07 04:52:18'),
(18, 88, '2025-11-08 04:01:50'),
(20, 139, '2025-09-26 19:33:44'),
(22, 91, '2025-09-15 05:35:08'),
(24, 93, '2025-12-23 12:54:48'),
(26, 95, '2025-10-10 22:23:12'),
(28, 97, '2026-01-27 11:50:59'),
(30, 99, '2025-09-06 20:01:40'),
(32, 101, '2025-07-02 10:43:48'),
(34, 103, '2025-06-05 22:05:18'),
(36, 105, '2025-04-30 01:57:49'),
(38, 107, '2025-06-23 12:39:13'),
(40, 109, '2025-08-18 01:57:58'),
(42, 111, '2026-02-04 23:10:23'),
(44, 113, '2026-03-16 23:25:37'),
(46, 115, '2025-07-19 04:54:10'),
(48, 117, '2025-08-28 14:55:15'),
(50, 119, '2025-12-27 02:46:18'),
(52, 121, '2025-07-20 22:46:51'),
(54, 123, '2025-05-03 12:14:37'),
(56, 125, '2025-09-12 12:29:29'),
(58, 127, '2026-03-20 17:22:37'),
(60, 140, '2025-12-30 06:38:47'),
(62, 130, '2026-01-02 13:16:53'),
(64, 132, '2025-10-21 21:57:46'),
(66, 134, '2025-08-21 05:00:43'),
(68, 136, '2025-06-12 05:11:08'),
(70, 138, '2025-05-07 17:57:04'),
(141, 142, '2026-01-06 15:52:46'),
(143, 144, '2026-02-20 15:32:38'),
(145, 146, '2025-10-24 01:58:42'),
(147, 148, '2026-04-03 03:12:38'),
(149, 150, '2025-12-12 00:22:17'),
(151, 152, '2025-12-07 10:40:46'),
(153, 154, '2025-08-28 13:37:05'),
(155, 156, '2025-11-14 01:55:43'),
(157, 158, '2025-07-02 15:47:56'),
(159, 160, '2025-10-21 06:53:20'),
(161, 162, '2025-05-23 13:57:27'),
(163, 164, '2025-09-04 21:37:02'),
(165, 166, '2025-10-03 14:05:45'),
(167, 168, '2025-08-22 01:54:15'),
(169, 170, '2025-06-26 20:41:51'),
(171, 172, '2025-09-21 17:59:04'),
(173, 174, '2025-07-06 13:50:13'),
(175, 176, '2026-01-02 05:03:51'),
(177, 178, '2025-12-07 12:49:54'),
(179, 180, '2026-04-13 23:45:52'),
(181, 182, '2025-08-11 20:24:48'),
(183, 184, '2025-12-22 18:27:20'),
(185, 186, '2025-11-12 00:14:49'),
(187, 188, '2025-06-27 15:17:36'),
(189, 190, '2025-10-24 05:45:29'),
(191, 192, '2025-07-20 23:51:35'),
(193, 194, '2026-01-15 00:29:09'),
(195, 196, '2026-04-11 21:08:04'),
(197, 198, '2026-03-24 05:12:42'),
(199, 200, '2026-03-15 16:15:47'),
(201, 202, '2025-08-24 02:39:18'),
(203, 204, '2026-03-24 23:21:03'),
(205, 206, '2026-01-03 06:29:30'),
(207, 208, '2025-09-08 01:51:08'),
(209, 210, '2026-03-20 17:53:15'),
(211, 212, '2025-05-17 17:03:21'),
(213, 214, '2026-03-21 03:14:04'),
(215, 216, '2025-09-28 09:14:14'),
(217, 218, '2026-01-15 20:49:23'),
(219, 220, '2025-05-26 09:24:50'),
(221, 222, '2025-06-30 09:29:58'),
(223, 224, '2025-05-30 04:30:08'),
(225, 226, '2026-03-18 16:49:02'),
(227, 228, '2025-11-02 09:24:30'),
(229, 230, '2025-11-27 18:56:53'),
(231, 232, '2025-05-25 05:14:32'),
(233, 234, '2026-04-02 08:45:08'),
(235, 236, '2026-02-14 20:42:15'),
(237, 238, '2025-05-19 04:29:32'),
(239, 240, '2025-12-29 11:01:36'),
(241, 242, '2026-03-04 02:20:09'),
(243, 244, '2025-12-20 21:15:44'),
(245, 246, '2026-01-22 05:03:04'),
(247, 248, '2025-12-06 06:09:19'),
(249, 250, '2025-08-10 17:46:59'),
(251, 252, '2025-11-16 06:10:58'),
(253, 254, '2026-02-04 18:16:20'),
(255, 256, '2025-04-19 04:42:01'),
(257, 258, '2025-12-17 17:12:20'),
(259, 260, '2025-08-29 05:32:52'),
(261, 262, '2025-08-30 16:57:38'),
(263, 264, '2025-05-24 17:26:56'),
(265, 266, '2025-08-20 12:23:21'),
(267, 268, '2026-01-11 20:56:50'),
(269, 270, '2025-10-30 23:47:35'),
(271, 272, '2025-10-26 21:22:34'),
(273, 274, '2026-01-28 05:53:38'),
(275, 276, '2026-01-27 12:12:22'),
(277, 278, '2026-02-12 15:40:15'),
(279, 280, '2025-05-29 22:59:14'),
(281, 282, '2025-11-27 21:51:11'),
(283, 284, '2026-02-25 19:07:20'),
(285, 286, '2026-03-13 00:13:19'),
(287, 288, '2026-02-13 12:08:22'),
(289, 290, '2025-12-12 18:32:27'),
(291, 292, '2025-12-14 16:38:46'),
(293, 294, '2026-04-09 20:59:30'),
(295, 296, '2025-08-22 03:46:51'),
(297, 298, '2025-09-22 06:59:55'),
(299, 300, '2025-08-21 10:29:48'),
(301, 302, '2025-07-21 19:36:12'),
(303, 304, '2025-06-10 08:08:37'),
(305, 306, '2026-02-14 23:46:22'),
(307, 308, '2025-06-14 17:42:04'),
(309, 310, '2026-01-19 23:35:37'),
(311, 312, '2025-08-22 03:07:26'),
(313, 314, '2025-06-20 02:32:30'),
(315, 316, '2025-08-12 23:42:01'),
(317, 318, '2025-12-24 11:24:02'),
(319, 320, '2026-01-29 10:50:54');

-- listing_moderation
INSERT INTO listing_moderation (moderation_id, reason, action, reviewed_at, listing_id, reviewed_by) 
VALUES
(321, 'Approved upon submission', 'approved', '2025-04-19 02:01:09', 72, 322),
(323, 'Approved upon submission', 'approved', '2025-06-03 02:59:40', 74, 324),
(325, 'Flagged for external link in bio', 'flagged', '2026-04-13 09:38:00', 76, 326),
(327, 'Approved upon submission', 'approved', '2026-01-26 18:52:09', 78, 328),
(329, 'Rejected for inappropriate content', 'rejected', '2025-07-31 16:13:39', 80, 330),
(331, 'Approved upon submission', 'approved', '2026-02-09 06:35:41', 82, 332),
(333, 'Approved upon submission', 'approved', '2026-03-22 00:03:52', 84, 334),
(335, 'Flagged for suspected spam', 'flagged', '2025-12-24 06:21:08', 86, 336),
(337, 'Approved upon submission', 'approved', '2026-04-10 00:44:03', 88, 338),
(339, 'Approved upon submission', 'approved', '2025-07-31 03:59:38', 139, 340),
(341, 'Rejected for duplicate account', 'rejected', '2025-04-27 00:34:39', 91, 342),
(343, 'Approved upon submission', 'approved', '2025-07-06 14:11:03', 93, 344),
(345, 'Flagged for unverifiable location', 'flagged', '2026-03-08 10:37:20', 95, 346),
(347, 'Approved upon submission', 'approved', '2025-12-27 08:37:02', 97, 348),
(349, 'Approved upon submission', 'approved', '2026-03-23 12:24:55', 99, 350),
(351, 'Approved upon submission', 'approved', '2025-09-08 19:31:00', 101, 352),
(353, 'Rejected for misleading description', 'rejected', '2025-07-30 03:05:26', 103, 354),
(355, 'Flagged for unusual purchase pattern', 'flagged', '2026-02-14 01:47:19', 105, 356),
(357, 'Approved upon submission', 'approved', '2026-04-08 17:44:27', 107, 358),
(359, 'Approved upon submission', 'approved', '2026-03-04 06:09:15', 109, 360),
(361, NULL, 'approved', '2025-09-26 01:33:20', 111, 362),
(363, 'Flagged for multiple reports from sellers', 'flagged', '2026-01-04 05:30:07', 113, 364),
(365, NULL, 'rejected', '2025-12-10 07:52:59', 115, 366),
(367, 'Approved upon submission', 'approved', '2025-09-12 02:45:10', 117, 368),
(369, 'Approved upon submission', 'approved', '2025-07-07 17:10:48', 119, 370),
(371, 'Approved upon submission', 'approved', '2025-04-24 10:09:26', 121, 372),
(373, 'Flagged for suspicious payment method', 'flagged', '2025-11-12 15:26:15', 123, 374),
(375, 'Approved upon submission', 'approved', '2025-07-16 18:54:52', 125, 376),
(377, 'Rejected for counterfeit listing', 'rejected', '2025-07-12 07:18:16', 127, 378),
(379, 'Approved upon submission', 'approved', '2025-12-30 16:13:47', 140, 380),
(381, 'Approved upon submission', 'approved', '2025-04-18 23:07:31', 130, 382),
(383, 'Approved upon submission', 'approved', '2025-04-21 00:46:18', 132, 384),
(385, 'Flagged for incomplete profile', 'flagged', '2025-10-04 08:33:29', 134, 386),
(387, 'Approved upon submission', 'approved', '2025-05-07 15:08:15', 136, 388),
(389, 'Approved upon submission', 'approved', '2025-04-16 02:54:24', 138, 390);

-- artist_application
INSERT INTO artist_application (application_id, status, portfolio_link, submitted_at, reviewed_at, artist_id, reviewer_id) 
VALUES
(391, 'pending', 'portfolio.com/01KP6KSYNVJ3Q4QDA1YGZGRENS', '2025-10-08 00:00:00', '2025-05-06 00:00:00', 392, 322),
(393, 'pending', 'portfolio.com/01KP6KSYNZRG05F7DEEJZD0WTH', '2025-08-20 00:00:00', '2025-06-19 00:00:00', 394, 324),
(395, 'rejected', 'portfolio.com/01KP6KSYNZTRP9J138X8HFG45F', '2025-04-27 00:00:00', '2025-04-18 00:00:00', 396, 326),
(397, 'rejected', 'portfolio.com/01KP6KSYP0FHVSVAK3B7WG3EN4', '2026-03-30 00:00:00', NULL, 398, 328),
(399, 'rejected', 'portfolio.com/01KP6KSYP02WQD1N08VP1B2EM9', '2025-07-30 00:00:00', '2025-07-26 00:00:00', 400, 330),
(401, 'approved', 'portfolio.com/01KP6KSYP1ZPVEK8K6EWRPH1J0', '2026-01-04 00:00:00', '2025-09-28 00:00:00', 402, 332),
(403, 'pending', 'portfolio.com/01KP6KSYP12DV2XXSXNVZK8YAS', '2025-11-24 00:00:00', '2025-05-15 00:00:00', 404, 334),
(405, 'rejected', 'portfolio.com/01KP6KSYP22NJ0BWJHJT7M03E6', '2025-05-26 00:00:00', '2025-09-08 00:00:00', 406, 336),
(407, 'rejected', 'portfolio.com/01KP6KSYP2W8R20BZJM76ABKER', '2025-09-30 00:00:00', '2025-09-04 00:00:00', 408, NULL),
(409, 'pending', 'portfolio.com/01KP6KSYP35DGCYGMTQ0BY3GXP', '2025-07-26 00:00:00', '2025-07-13 00:00:00', 410, 340),
(411, 'rejected', 'portfolio.com/01KP6KSYP3YK3VF0DCX7D22WAX', '2025-08-29 00:00:00', '2025-04-30 00:00:00', 412, 342),
(413, 'approved', 'portfolio.com/01KP6KSYP48FYBAJ63RZ2ZYB8Y', '2025-11-09 00:00:00', '2025-09-12 00:00:00', 414, 344),
(415, 'approved', 'portfolio.com/01KP6KSYP4QKSJ59Z55R6Y94MH', '2026-02-15 00:00:00', '2025-07-06 00:00:00', 416, 346),
(417, 'approved', 'portfolio.com/01KP6KSYP5JHBWSXTY7V74CD8R', '2025-08-05 00:00:00', '2025-06-10 00:00:00', 418, 348),
(419, 'rejected', 'portfolio.com/01KP6KSYP51BST43XYMCDHGW67', '2025-04-14 00:00:00', '2025-08-24 00:00:00', 420, NULL),
(421, 'rejected', 'portfolio.com/01KP6KSYP606AXQDXVFNQVV88B', '2025-04-16 00:00:00', '2026-02-05 00:00:00', 422, 352),
(423, 'rejected', 'portfolio.com/01KP6KSYP6YNACW0WPEZEVBFH7', '2025-10-24 00:00:00', '2025-12-15 00:00:00', 424, 354),
(425, 'rejected', 'portfolio.com/01KP6KSYP7P39ZCX7YT0VDXSSJ', '2026-03-13 00:00:00', '2025-07-24 00:00:00', 426, 356),
(427, 'pending', 'portfolio.com/01KP6KSYP74QMW55E5VVVPZJHE', '2025-06-30 00:00:00', '2025-07-10 00:00:00', 428, 358),
(429, 'rejected', 'portfolio.com/01KP6KSYP8F7S8CYBNY7EH8A46', '2025-07-03 00:00:00', '2026-03-01 00:00:00', 430, 360),
(431, 'rejected', 'portfolio.com/01KP6KSYP885S0MRNFEKKTZK2E', '2025-08-29 00:00:00', '2025-07-09 00:00:00', 432, 362),
(433, 'rejected', 'portfolio.com/01KP6KSYP9JE3NHY9PW27XTDBT', '2025-04-29 00:00:00', '2025-08-30 00:00:00', 434, 364),
(435, 'approved', 'portfolio.com/01KP6KSYP9Q8X0H46KQTHQYBTQ', '2025-10-06 00:00:00', NULL, 436, 366),
(437, 'pending', 'portfolio.com/01KP6KSYPA2KQ3KW6T738JPHVH', '2025-10-11 00:00:00', '2026-03-22 00:00:00', 438, 368),
(439, 'rejected', 'portfolio.com/01KP6KSYPA47VS99S17M1XBSHG', '2025-11-05 00:00:00', '2026-02-14 00:00:00', 440, 370),
(441, 'pending', 'portfolio.com/01KP6KSYPBMM9QD32T5Z25BGGX', '2025-11-01 00:00:00', '2025-11-12 00:00:00', 442, 372),
(443, 'pending', 'portfolio.com/01KP6KSYPBBEVMNZ32T5DNVKNM', '2026-03-11 00:00:00', '2025-05-31 00:00:00', 444, 374),
(445, 'rejected', 'portfolio.com/01KP6KSYPCBJX9HJF9VCBST0WC', '2025-04-22 00:00:00', '2025-09-19 00:00:00', 446, 376),
(447, 'approved', 'portfolio.com/01KP6KSYPCQ6K4N9J75NN3HP8W', '2025-08-11 00:00:00', '2025-10-21 00:00:00', 448, 378),
(449, 'pending', 'portfolio.com/01KP6KSYPDKBQY27BYDSVCEFEK', '2025-10-19 00:00:00', '2026-01-25 00:00:00', 450, 380),
(451, 'pending', 'portfolio.com/01KP6KSYPDJGS11B1YVJVCYCM0', '2025-10-10 00:00:00', '2026-02-04 00:00:00', 452, 382),
(453, 'approved', 'portfolio.com/01KP6KSYPEKPRG63QA6TTVK0KR', '2025-12-29 00:00:00', '2025-07-20 00:00:00', 454, 384),
(455, 'pending', 'portfolio.com/01KP6KSYPE7X8XM5QND5V3KEV2', '2026-01-26 00:00:00', '2025-05-19 00:00:00', 456, 386),
(457, 'approved', 'portfolio.com/01KP6KSYPFKWNVVRQQ3KRPGXBW', '2025-12-16 00:00:00', '2025-09-15 00:00:00', 458, 388),
(459, 'rejected', 'portfolio.com/01KP6KSYPFBDVMAR9G8HD86B3X', '2026-03-01 00:00:00', '2025-07-20 00:00:00', 460, 390);

-- fraud_report
INSERT INTO fraud_report (report_id, reason, status, created_at, resolved_at, order_id, reviewer_id) 
VALUES
(2, 'Suspicious purchase volume', 'open', '2025-05-22 18:16:11', NULL, 2, 322),
(4, 'Possible duplicate account', 'investigating', '2026-03-01 07:28:00', NULL, 4, 324),
(6, 'Unusual login location', 'resolved', '2025-04-28 20:03:47', '2025-05-03 11:22:09', 6, 326),
(8, 'Mismatched billing address', 'dismissed', '2025-08-01 22:33:04', NULL, 8, 328),
(10, 'Chargeback after delivery', 'open', '2025-12-11 06:39:46', NULL, 10, 330),
(12, 'Possible duplicate account', 'resolved', '2026-04-02 11:32:28', '2026-04-04 15:32:28', 12, 332),
(14, 'Suspicious purchase volume', 'investigating', '2025-04-25 17:44:06', NULL, 14, 334),
(16, 'Multiple failed payment attempts', 'open', '2025-09-09 21:34:31', NULL, 16, 336),
(18, 'Flagged shipping address', 'dismissed', '2025-04-28 11:01:39', NULL, 18, 338),
(20, 'Chargeback after delivery', 'resolved', '2026-02-03 08:56:08', '2026-02-05 09:56:08', 20, 340),
(22, 'Suspicious purchase volume', 'open', '2025-05-12 00:40:04', NULL, 22, 342),
(24, 'Possible duplicate account', 'investigating', '2025-07-04 12:56:23', NULL, 24, 344),
(26, 'Unusual login location', 'open', '2026-01-27 05:44:52', NULL, 26, 346),
(28, 'Mismatched billing address', 'resolved', '2025-12-15 09:43:13', '2025-12-16 11:43:13', 28, 348),
(30, 'Flagged shipping address', 'dismissed', '2026-03-05 02:11:58', NULL, 30, 350),
(32, 'Suspicious purchase volume', 'open', '2026-04-13 03:35:59', NULL, 32, 352),
(34, 'Multiple failed payment attempts', 'investigating', '2026-03-02 22:06:32', NULL, 34, 354),
(36, 'Chargeback after delivery', 'resolved', '2025-04-26 12:54:03', '2025-08-15 04:32:33', 36, 356),
(38, 'Possible duplicate account', 'open', '2025-10-01 03:27:29', NULL, 38, 358),
(40, 'Flagged shipping address', 'dismissed', '2026-03-02 15:02:12', NULL, 40, 360),
(42, 'Mismatched billing address', 'resolved', '2025-04-21 14:01:28', '2026-04-11 11:55:00', 42, 362),
(44, 'Suspicious purchase volume', 'open', '2026-03-04 13:17:57', NULL, 44, 364),
(46, 'Unusual login location', 'investigating', '2025-07-29 09:08:43', NULL, 46, 366),
(48, 'Multiple failed payment attempts', 'dismissed', '2025-12-02 22:45:32', NULL, 48, 368),
(50, 'Possible duplicate account', 'open', '2025-07-18 12:09:38', NULL, 50, 370),
(52, 'Chargeback after delivery', 'resolved', '2025-09-19 02:22:24', '2025-09-20 01:22:24', 52, 372),
(54, 'Suspicious purchase volume', 'open', '2025-11-22 21:45:05', NULL, 54, 374),
(56, 'Unusual login location', 'investigating', '2025-10-25 19:09:36', NULL, 56, 376),
(58, 'Mismatched billing address', 'resolved', '2026-04-06 21:02:00', '2026-04-08 03:02:00', 58, 378),
(60, 'Flagged shipping address', 'dismissed', '2025-11-07 06:51:45', NULL, 60, 380),
(62, 'Multiple failed payment attempts', 'open', '2025-09-26 08:42:58', NULL, 62, 382),
(64, 'Suspicious purchase volume', 'open', '2025-09-02 22:43:30', NULL, 64, 384),
(66, 'Possible duplicate account', 'investigating', '2025-09-12 00:07:26', NULL, 66, 386),
(68, 'Chargeback after delivery', 'resolved', '2025-11-09 09:17:52', '2026-02-14 18:55:25', 68, 388),
(70, 'Unusual login location', 'open', '2026-01-08 01:01:59', NULL, 70, 390);

-- system_metric
INSERT INTO system_metric (metric_id, metric_type, value, recorded_at) 
VALUES
(461, 'gc_pause_time', 6.02, '2026-02-23 12:07:17'),
(462, 'api_call_volume', 47.09, '2025-11-27 09:26:43'),
(463, 'network_latency', 35.02, '2025-10-04 18:43:40'),
(464, 'response_time', 32.56, '2025-04-18 11:13:00'),
(465, 'request_count', 73.68, '2025-11-13 10:53:05'),
(466, 'session_count', 86.42, '2025-11-22 17:44:21'),
(467, 'packet_loss', 17.24, '2025-11-03 12:55:11'),
(468, 'uptime', 15.15, '2025-04-21 04:37:12'),
(469, 'error_rate', 99.13, '2026-02-25 18:32:55'),
(470, 'load_average', 74.42, '2025-10-18 19:35:46'),
(471, 'swap_usage', 68.84, '2025-09-27 21:06:14'),
(472, 'disk_io', 29.21, '2025-05-01 12:53:50'),
(473, 'swap_usage', 1.1, '2025-08-16 21:52:44'),
(474, 'request_count', 19.54, '2025-06-10 22:44:50'),
(475, 'packet_loss', 93.54, '2025-10-22 16:12:56'),
(476, 'network_latency', 67.19, '2025-09-04 05:46:01'),
(477, 'load_average', 73.87, '2026-03-17 14:02:43'),
(478, 'queue_depth', 9.55, '2025-05-10 14:00:37'),
(479, 'memory_usage', 65.49, '2026-01-09 07:14:56'),
(480, 'cache_hit_rate', 33.29, '2025-09-07 10:21:13'),
(481, 'gc_pause_time', 60.87, '2025-12-29 06:12:32'),
(482, 'error_rate', 1.17, '2025-12-17 04:35:36'),
(483, 'network_latency', 94.31, '2025-10-10 08:57:34'),
(484, 'request_count', 61.06, '2026-01-02 00:56:08'),
(485, 'gc_pause_time', 58.81, '2025-09-21 10:51:54'),
(486, 'bandwidth_usage', 70.42, '2025-04-20 10:27:21'),
(487, 'gc_pause_time', 29.93, '2025-06-19 07:59:38'),
(488, 'cpu_usage', 80, '2025-11-03 13:42:29'),
(489, 'disk_io', 59.22, '2025-06-07 07:14:53'),
(490, 'heap_usage', 65.98, '2025-05-14 04:30:43'),
(491, 'db_query_time', 94.94, '2025-10-22 01:50:34'),
(492, 'response_time', 28.23, '2025-06-17 15:36:38'),
(493, 'packet_loss', 56.03, '2025-05-01 22:35:43'),
(494, 'swap_usage', 93.92, '2025-12-16 07:54:50'),
(495, 'session_count', 42.03, '2025-06-25 21:24:27');

-- system_alert
INSERT INTO system_alert (alert_id, alert_type, severity, status, message, created_at, resolved_at) 
VALUES
(496, 'High CPU Usage', 'low', 'open', 'CPU usage exceeded 90% threshold', '2025-05-25 06:48:43', NULL),
(497, 'API Timeout', 'low', 'investigating', 'API response time exceeded 5s', '2025-05-27 07:28:56', NULL),
(498, 'Memory Spike', 'low', 'resolved', 'Memory usage at 95%', '2025-11-22 08:32:01', '2025-11-22 23:32:01'),
(499, 'Disk I/O Overload', 'critical', 'open', 'Disk I/O wait time above 80ms', '2025-10-06 19:11:40', NULL),
(500, 'Packet Loss Detected', 'critical', 'resolved', 'Packet loss rate above 3%', '2025-06-12 19:46:47', '2025-06-12 23:46:47'),
(501, 'High Error Rate', 'low', 'investigating', 'Error rate exceeded 10% in last 5 minutes', '2026-01-25 22:24:41', NULL),
(502, 'Slow Database Query', 'medium', 'open', 'Database query response time above 2s', '2025-11-27 01:02:38', NULL),
(503, 'Cache Miss Surge', 'high', 'resolved', 'Cache miss rate exceeded 40%', '2025-10-15 16:43:44', '2025-10-17 04:43:44'),
(504, 'Network Latency Spike', 'low', 'open', 'Network latency above 300ms', '2025-10-06 09:50:49', NULL),
(505, 'Thread Pool Exhaustion', 'medium', 'investigating', 'Thread pool at 98% capacity', '2026-02-19 14:09:47', NULL),
(506, 'Heap Overflow Warning', 'medium', 'resolved', 'Heap usage at 92% of max allocation', '2026-01-20 15:27:05', '2026-01-21 23:27:05'),
(507, 'GC Pause Overrun', 'low', 'open', 'GC pause duration exceeded 500ms', '2026-04-06 14:05:31', NULL),
(508, 'Bandwidth Saturation', 'medium', 'investigating', 'Bandwidth utilization at 95%', '2025-12-31 22:46:10', NULL),
(509, 'Queue Depth Critical', 'medium', 'resolved', 'Queue depth exceeded 1000 messages', '2025-05-17 07:53:56', '2025-05-18 12:53:56'),
(510, 'Swap Usage High', 'high', 'open', 'Swap usage above 70%', '2025-11-22 12:18:40', NULL),
(511, 'Session Limit Approaching', 'low', 'resolved', 'Active sessions at 90% of limit', '2026-02-22 17:52:45', '2026-02-23 11:52:45'),
(512, 'Load Average Spike', 'high', 'open', 'Load average exceeded 4x CPU count', '2026-04-13 18:47:40', NULL),
(513, 'API Call Volume Surge', 'medium', 'investigating', 'API call volume up 300% from baseline', '2025-04-23 04:54:17', NULL),
(514, 'Uptime Anomaly', 'medium', 'open', 'Service uptime anomaly detected', '2025-09-05 23:51:13', NULL),
(515, 'Request Rate Spike', 'high', 'resolved', 'Incoming request rate spiked 250% above normal', '2025-04-14 10:08:16', '2025-04-15 00:08:16'),
(516, 'High CPU Usage', 'high', 'investigating', 'CPU usage exceeded 90% threshold', '2025-07-08 04:03:44', NULL),
(517, 'Disk I/O Overload', 'low', 'open', 'Disk I/O wait time above 80ms', '2026-03-10 18:25:25', NULL),
(518, 'Memory Spike', 'medium', 'resolved', 'Memory usage at 95%', '2025-07-07 08:04:13', '2025-07-10 06:04:13'),
(519, 'API Timeout', 'low', 'open', 'API response time exceeded 5s', '2025-08-05 13:16:28', NULL),
(520, 'Error Rate Critical', 'critical', 'investigating', 'Error rate exceeded 15% in last 5 minutes', '2025-08-07 16:03:22', NULL),
(521, 'Response Time Degraded', 'medium', 'resolved', NULL, '2026-03-15 06:56:30', '2026-03-15 18:56:30'),
(522, 'Packet Loss Detected', 'critical', 'open', 'Packet loss rate above 3%', '2026-03-20 11:12:26', NULL),
(523, 'Heap Overflow Warning', 'critical', 'investigating', 'Heap usage at 92% of max allocation', '2025-05-21 01:33:31', NULL),
(524, 'Cache Miss Surge', 'critical', 'open', 'Cache miss rate exceeded 40%', '2025-09-23 19:36:38', NULL),
(525, 'Network Latency Spike', 'low', 'resolved', 'Network latency above 300ms', '2025-07-14 09:04:27', '2025-07-16 16:04:27'),
(526, 'Thread Pool Exhaustion', 'low', 'open', 'Thread pool at 98% capacity', '2026-03-04 18:32:09', NULL),
(527, 'Slow Database Query', 'low', 'resolved', 'Database query response time above 2s', '2025-04-14 05:40:57', '2025-04-14 10:40:57'),
(528, 'Load Average Spike', 'high', 'investigating', 'Load average exceeded 4x CPU count', '2025-06-22 03:16:04', NULL),
(529, 'API Call Volume Surge', 'critical', 'open', 'API call volume up 300% from baseline', '2026-03-15 23:21:35', NULL),
(530, 'Swap Usage High', 'low', 'resolved', 'Swap usage above 70%', '2025-12-06 16:31:08', '2025-12-06 20:31:08');

-- platform_metrics
INSERT INTO platform_metrics (metric_id, active_users, churned_users, conversions, retained_users, user_rate, conversion_rate, retention_rate, turnover_rate, recorded_at) 
VALUES
<<<<<<< Updated upstream
(531, 782, 4198, 5190, 4911, 0.1813, 0.3182, 0.7768, 0.3214, '2025-08-25 23:28:35'),
(532, 483, 107, 5915, 1911, 0.6811, 0.4075, 0.3808, 0.7308, '2025-10-06 03:53:39'),
(533, 4955, 8066, 6491, 9920, 0.4227, 0.285, 0.3279, 0.9821, '2025-06-02 07:31:28'),
(534, 1927, 4283, 1179, 594, 0.0353, 0.6346, 0.1826, 0.9382, '2025-05-04 07:17:01'),
(535, 4487, 9108, 5360, 7278, 0.5294, 0.6443, 0.4352, 0.341, '2026-02-07 10:58:44'),
(536, 5988, 6319, 4758, 2826, 0.853, 0.6096, 0.691, 0.6517, '2025-06-25 13:31:18'),
(537, 1387, 4104, 8394, 8220, 0.4597, 0.1775, 0.2303, 0.0286, '2026-03-01 08:46:53'),
(538, 4464, 6143, 4561, 7055, 0.3461, 0.7766, 0.547, 0.1328, '2025-11-24 23:09:48'),
(539, 5593, 8850, 2431, 5176, 0.1693, 0.2624, 0.225, 0.8218, '2026-01-04 16:48:16'),
(540, 7220, 7913, 2535, 3201, 0.2985, 0.6311, 0.984, 0.757, '2025-07-09 04:57:42'),
(541, 1239, 8791, 295, 6916, 0.8365, 0.4844, 0.976, 0.0112, '2025-06-10 23:38:00'),
(542, 4316, 9818, 4093, 7208, 0.8217, 0.4428, 0.0355, 0.911, '2025-07-30 06:06:38'),
(543, 5355, 5134, 1332, 6774, 0.6873, 0.545, 0.3314, 0.6163, '2025-06-05 17:46:02'),
(544, 8504, 6237, 2532, 7687, 0.3454, 0.7807, 0.1071, 0.3413, '2025-10-13 07:02:00'),
(545, 9397, 4968, 8787, 712, 0.6447, 0.8195, 0.947, 0.1403, '2025-11-30 11:37:17'),
(546, 3248, 4408, 2162, 8590, 0.5393, 0.6921, 0.6923, 0.6599, '2026-03-04 15:29:55'),
(547, 1103, 8215, 4685, 3092, 0.2536, 0.176, 0.7845, 0.1246, '2025-09-18 06:34:57'),
(548, 5449, 4346, 4225, 8842, 0.383, 0.1018, 0.2827, 0.8089, '2026-03-13 21:15:54'),
(549, 8093, 6497, 9603, 3399, 0.6136, 0.4775, 0.6911, 0.065, '2025-07-07 10:20:58'),
(550, 8145, 179, 7189, 6868, 0.1394, 0.9604, 0.3009, 0.7093, '2025-05-04 11:01:06'),
(551, 9659, 5266, 3051, 6449, 0.8291, 0.1583, 0.3501, 0.1319, '2025-10-24 02:47:01'),
(552, 4524, 654, 9408, 8033, 0.8933, 0.1983, 0.7594, 0.6755, '2025-09-28 07:38:03'),
(553, 625, 7545, 5933, 9086, 0.7136, 0.436, 0.3898, 0.177, '2025-04-18 13:27:29'),
(554, 6703, 4576, 8343, 5846, 0.3815, 0.3436, 0.6942, 0.5674, '2026-03-23 08:52:49'),
(555, 8603, 7872, 4476, 4804, 0.9761, 0.7191, 0.529, 0.8058, '2026-03-06 11:41:17'),
(556, 346, 7428, 230, 3003, 0.4162, 0.3392, 0.5567, 0.3472, '2025-11-26 03:20:40'),
(557, 845, 2442, 5364, 7686, 0.4772, 0.9363, 0.388, 0.3693, '2025-12-23 01:06:29'),
(558, 6450, 7760, 8428, 9172, 0.3438, 0.6711, 0.6711, 0.9528, '2026-04-02 01:45:08'),
(559, 4791, 6445, 7579, 8358, 0.8655, 0.4492, 0.8208, 0.5097, '2025-08-03 07:34:16'),
(560, 2597, 2455, 6693, 8478, 0.1535, 0.5589, 0.7441, 0.2476, '2025-07-02 13:01:56'),
(561, 7643, 6486, 1847, 9955, 0.3795, 0.0368, 0.6538, 0.243, '2025-08-10 16:13:04'),
(562, 9762, 4918, 8672, 139, 0.2856, 0.037, 0.9519, 0.2527, '2025-08-29 03:34:59'),
(563, 4142, 5170, 2066, 4685, 0.8128, 0.5068, 0.894, 0.375, '2025-09-21 23:59:09'),
(564, 2584, 2116, 1038, 9647, 0.1103, 0.4556, 0.44, 0.0152, '2026-04-09 09:58:34'),
(565, 8444, 7448, 9752, 9999, 0.7629, 0.7407, 0.7093, 0.7843, '2025-05-02 16:15:57');
=======
  ('01KP6KW51T94QNBXCZ6G16Q3SF', 782, 4198, 5190, 4911, 0.1813, 0.3182, 0.7768, 0.3214, '2025-08-25 23:28:35'),
  ('01KP6KW51VKX0S4ZCWN37WHX4T', 483, 107, 5915, 1911, 0.6811, 0.4075, 0.3808, 0.7308, '2025-10-06 03:53:39'),
  ('01KP6KW51W9EPZJRHEXH3ZSG5S', 4955, 8066, 6491, 9920, 0.4227, 0.285, 0.3279, 0.9821, '2025-06-02 07:31:28'),
  ('01KP6KW51WPYNNGGDTFRHBJ744', 1927, 4283, 1179, 594, 0.0353, 0.6346, 0.1826, 0.9382, '2025-05-04 07:17:01'),
  ('01KP6KW51X6KQ3K3BBB59MBT8A', 4487, 9108, 5360, 7278, 0.5294, 0.6443, 0.4352, 0.341, '2026-02-07 10:58:44'),
  ('01KP6KW51X9XDSG9VAP4BBC01D', 5988, 6319, 4758, 2826, 0.853, 0.6096, 0.691, 0.6517, '2025-06-25 13:31:18'),
  ('01KP6KW51YKJFTNHS6A2F55VY1', 1387, 4104, 8394, 8220, 0.4597, 0.1775, 0.2303, 0.0286, '2026-03-01 08:46:53'),
  ('01KP6KW51ZSTYVQRZF3CXNXZ1V', 4464, 6143, 4561, 7055, 0.3461, 0.7766, 0.547, 0.1328, '2025-11-24 23:09:48'),
  ('01KP6KW51ZZ40N5TQB9QCDX40B', 5593, 8850, 2431, 5176, 0.1693, 0.2624, 0.225, 0.8218, '2026-01-04 16:48:16'),
  ('01KP6KW520821ATJVR4DNQWT9J', 7220, 7913, 2535, 3201, 0.2985, 0.6311, 0.984, 0.757, '2025-07-09 04:57:42'),
  ('01KP6KW520JT8RHXQ836WJBXBP', 1239, 8791, 295, 6916, 0.8365, 0.4844, 0.976, 0.0112, '2025-06-10 23:38:00'),
  ('01KP6KW521RRH3NAZ4ZZJ1H3XR', 4316, 9818, 4093, 7208, 0.8217, 0.4428, 0.0355, 0.911, '2025-07-30 06:06:38'),
  ('01KP6KW521GYDCEV40DZK9HP7C', 5355, 5134, 1332, 6774, 0.6873, 0.545, 0.3314, 0.6163, '2025-06-05 17:46:02'),
  ('01KP6KW5226PXTTRBSJTBAG32C', 8504, 6237, 2532, 7687, 0.3454, 0.7807, 0.1071, 0.3413, '2025-10-13 07:02:00'),
  ('01KP6KW523BRFWXXQQH7JAJA50', 9397, 4968, 8787, 712, 0.6447, 0.8195, 0.947, 0.1403, '2025-11-30 11:37:17'),
  ('01KP6KW523X7N6MBHQGPD3T0A5', 3248, 4408, 2162, 8590, 0.5393, 0.6921, 0.6923, 0.6599, '2026-03-04 15:29:55'),
  ('01KP6KW524Y2TJ17701FZXF575', 1103, 8215, 4685, 3092, 0.2536, 0.176, 0.7845, 0.1246, '2025-09-18 06:34:57'),
  ('01KP6KW5241DKFR93XETCRERQ8', 5449, 4346, 4225, 8842, 0.383, 0.1018, 0.2827, 0.8089, '2026-03-13 21:15:54'),
  ('01KP6KW525BJY605G5QQE15SZA', 8093, 6497, 9603, 3399, 0.6136, 0.4775, 0.6911, 0.065, '2025-07-07 10:20:58'),
  ('01KP6KW526S5AY57PZN0PMKZXE', 8145, 179, 7189, 6868, 0.1394, 0.9604, 0.3009, 0.7093, '2025-05-04 11:01:06'),
  ('01KP6KW526H4ZFNCXFS8YKG2X9', 9659, 5266, 3051, 6449, 0.8291, 0.1583, 0.3501, 0.1319, '2025-10-24 02:47:01'),
  ('01KP6KW527FNJMKZJEQDVPAJVC', 4524, 654, 9408, 8033, 0.8933, 0.1983, 0.7594, 0.6755, '2025-09-28 07:38:03'),
  ('01KP6KW527YMTF2YNR11ED1ZE2', 625, 7545, 5933, 9086, 0.7136, 0.436, 0.3898, 0.177, '2025-04-18 13:27:29'),
  ('01KP6KW528520PJNVNDD30XXHZ', 6703, 4576, 8343, 5846, 0.3815, 0.3436, 0.6942, 0.5674, '2026-03-23 08:52:49'),
  ('01KP6KW528XJFZ7HMXWV4JZB86', 8603, 7872, 4476, 4804, 0.9761, 0.7191, 0.529, 0.8058, '2026-03-06 11:41:17'),
  ('01KP6KW529ZZNPHKGSB9VFEZRP', 346, 7428, 230, 3003, 0.4162, 0.3392, 0.5567, 0.3472, '2025-11-26 03:20:40'),
  ('01KP6KW52AW56VNQPV1XEZ0A91', 845, 2442, 5364, 7686, 0.4772, 0.9363, 0.388, 0.3693, '2025-12-23 01:06:29'),
  ('01KP6KW52AE42MZV77ZAP9T9CM', 6450, 7760, 8428, 9172, 0.3438, 0.6711, 0.6711, 0.9528, '2026-04-02 01:45:08'),
  ('01KP6KW52BQGQDJ3CPSENM9DEP', 4791, 6445, 7579, 8358, 0.8655, 0.4492, 0.8208, 0.5097, '2025-08-03 07:34:16'),
  ('01KP6KW52B9SD95BE3XZM89MZE', 2597, 2455, 6693, 8478, 0.1535, 0.5589, 0.7441, 0.2476, '2025-07-02 13:01:56'),
  ('01KP6KW52CNTVM1P841C8GYNX4', 7643, 6486, 1847, 9955, 0.3795, 0.0368, 0.6538, 0.243, '2025-08-10 16:13:04'),
  ('01KP6KW52DJFXZKAY28YR41ZBK', 9762, 4918, 8672, 139, 0.2856, 0.037, 0.9519, 0.2527, '2025-08-29 03:34:59'),
  ('01KP6KW52D57ZMKSS5PGA7R2VG', 4142, 5170, 2066, 4685, 0.8128, 0.5068, 0.894, 0.375, '2025-09-21 23:59:09'),
  ('01KP6KW52E1N1VTC0J9JXPR0EG', 2584, 2116, 1038, 9647, 0.1103, 0.4556, 0.44, 0.0152, '2026-04-09 09:58:34'),
  ('01KP6KW52EMYQ4S7QP2GR65NGJ', 8444, 7448, 9752, 9999, 0.7629, 0.7407, 0.7093, 0.7843, '2025-05-02 16:15:57');


-- user
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (1, 'gtarry0', 'Goddard', 'Tarry', '318-516-5691', 'Male', '03558 Loomis Hill', 'Monroe', 'Louisiana', 'user', '1935-07-25', '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (2, 'gsinderson1', 'Gal', 'Sinderson', '502-287-1193', 'Male', '3435 Green Terrace', 'Louisville', 'Kentucky', 'user', null, '2026-04-13 11:16:13', 'https://robohash.org/recusandaedistinctioimpedit.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (3, 'mhandford2', 'Michelle', 'Handford', '623-740-6731', 'Female', '00540 Grasskamp Pass', 'Phoenix', 'Arizona', 'user', null, '2026-04-13 11:16:13', 'https://robohash.org/eaquevoluptatemdeserunt.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (4, 'edanels3', 'Evita', 'Danels', '317-399-6065', 'Female', '8103 Buell Plaza', 'Indianapolis', 'Indiana', 'user', '1940-12-12', '2026-04-13 11:16:13', 'https://robohash.org/isteautomnis.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (5, 'kglencrosche4', 'Kenny', 'Glencrosche', '786-778-4049', 'Male', '94314 David Pass', 'Miami', 'Florida', 'user', '1987-11-03', '2026-04-13 11:16:13', 'https://robohash.org/nihilodiout.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (6, 'rjamieson5', 'Rosalynd', 'Jamieson', null, 'Female', '59 Monterey Hill', 'Waterbury', 'Connecticut', 'user', '2007-10-07', '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (7, 'sfishenden6', 'Shalna', 'Fishenden', '718-965-9307', null, '556 Starling Pass', 'Brooklyn', 'New York', 'user', '1947-05-31', '2026-04-13 11:16:13', 'https://robohash.org/velveritatisaut.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (8, 'mamner7', 'Maryl', 'Amner', '714-691-9339', 'Female', '74 Katie Court', 'Orange', 'California', 'user', '2002-12-28', '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (9, 'mshilton8', 'Mair', 'Shilton', '248-350-1014', 'Female', '7097 Starling Park', 'Troy', 'Michigan', 'user', '1973-12-13', '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (10, 'dpriscott9', 'Danny', 'Priscott', '702-342-6740', 'Male', '44 Merry Crossing', 'Las Vegas', 'Nevada', 'user', '1982-11-15', '2026-04-13 11:16:13', 'https://robohash.org/etiuremolestiae.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (11, 'sbarnshawa', 'Sadye', 'Barnshaw', '303-228-8486', 'Female', '73611 Bartillon Circle', 'Denver', 'Colorado', 'user', '1958-12-18', '2026-04-13 11:16:13', 'https://robohash.org/idautet.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (12, 'rmcgairlb', 'Rees', 'McGairl', '916-548-8759', 'Male', '16 Vidon Way', 'Sacramento', 'California', 'user', '1968-07-22', '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (13, 'pmewburnc', 'Papageno', 'Mewburn', null, 'Male', '3 Brown Court', 'Alexandria', 'Virginia', 'user', '1960-02-10', '2026-04-13 11:16:13', 'https://robohash.org/quodautemculpa.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (14, 'wboucherd', 'Wright', 'Boucher', '801-923-9632', null, '99 Oak Center', 'Salt Lake City', 'Utah', 'user', '1954-04-22', '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (15, 'lfursee', 'Lucilia', 'Furse', null, 'Female', '18 Monument Alley', 'Minneapolis', 'Minnesota', 'user', '1962-09-05', '2026-04-13 11:16:13', 'https://robohash.org/providentoccaecatisit.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (16, 'tmcgilvrayf', 'Tammara', 'McGilvray', '505-269-4307', 'Female', '44 Harper Plaza', 'Albuquerque', 'New Mexico', 'user', '1931-08-18', '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (17, 'eromerilg', 'Elfrieda', 'Romeril', '915-179-7839', 'Female', '25812 Butterfield Way', 'El Paso', 'Texas', 'user', '1946-06-13', '2026-04-13 11:16:13', 'https://robohash.org/consequaturasperioresnihil.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (18, 'ldyetth', 'Lewes', 'Dyett', '404-122-2106', 'Male', '5769 Melrose Drive', 'Atlanta', 'Georgia', 'user', '1965-11-15', '2026-04-13 11:16:13', 'https://robohash.org/hicuterror.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (19, 'ahustleri', 'Adria', 'Hustler', '360-271-4023', 'Non-binary', '49 Pine View Street', 'Vancouver', 'Washington', 'user', '2006-02-24', '2026-04-13 11:16:13', 'https://robohash.org/voluptatemetdolor.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (20, 'dbinningj', 'Dun', 'Binning', '717-744-9895', 'Male', '68 Dapin Lane', 'Harrisburg', 'Pennsylvania', 'user', null, '2026-04-13 11:16:13', 'https://robohash.org/laborumimpeditomnis.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (21, 'kheadleyk', 'Karena', 'Headley', '520-528-3706', 'Female', '403 Trailsway Terrace', 'Tucson', 'Arizona', 'user', null, '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (22, 'clogsdalel', 'Catarina', 'Logsdale', '202-564-3878', 'Female', '1 Rowland Point', 'Washington', 'District of Columbia', 'user', '1937-03-20', '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (23, 'kdeenym', 'Kurt', 'Deeny', null, 'Male', '853 Graedel Hill', 'Jacksonville', 'Florida', 'user', '1935-03-25', '2026-04-13 11:16:13', 'https://robohash.org/consecteturvelsint.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (24, 'xivanyushkinn', 'Ximenez', 'Ivanyushkin', '214-806-0140', null, '37 Superior Parkway', 'Dallas', 'Texas', 'user', '1977-01-18', '2026-04-13 11:16:13', 'https://robohash.org/etdoloribusconsequatur.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (25, 'edollardo', 'Enrika', 'Dollard', '205-170-9929', 'Female', '69650 Knutson Trail', 'Birmingham', 'Alabama', 'user', '1999-09-29', '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (26, 'cpauluschp', 'Cloris', 'Paulusch', null, 'Female', '5488 Mockingbird Alley', 'Pittsburgh', 'Pennsylvania', 'user', '1965-09-03', '2026-04-13 11:16:13', 'https://robohash.org/cumquoautem.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (27, 'nklimpkeq', 'Natty', 'Klimpke', '361-857-3691', null, '807 Blackbird Road', 'Corpus Christi', 'Texas', 'user', '1972-04-09', '2026-04-13 11:16:13', 'https://robohash.org/adconsequaturvoluptatum.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (28, 'lavelingr', 'Luce', 'Aveling', null, 'Male', '3 Lerdahl Circle', 'Columbus', 'Ohio', 'user', '1942-08-17', '2026-04-13 11:16:13', 'https://robohash.org/rerumrecusandaeeveniet.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (29, 'pfinderss', 'Pasquale', 'Finders', '954-813-9501', null, '949 Parkside Way', 'Orlando', 'Florida', 'user', '1991-11-09', '2026-04-13 11:16:13', 'https://robohash.org/quodundeveniam.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (30, 'ccrownshawt', 'Ches', 'Crownshaw', '804-351-0054', 'Male', '165 Merchant Center', 'Richmond', 'Virginia', 'user', '1932-12-27', '2026-04-13 11:16:13', 'https://robohash.org/quismolestiaerecusandae.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (31, 'roilleru', 'Ruby', 'Oiller', '757-996-7003', 'Female', '8171 Lukken Court', 'Norfolk', 'Virginia', 'user', '1959-07-06', '2026-04-13 11:16:13', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (32, 'jbluev', 'Judie', 'Blue', '386-623-2411', 'Genderqueer', '68110 Esker Junction', 'Daytona Beach', 'Florida', 'user', '1945-05-04', '2026-04-13 11:16:13', 'https://robohash.org/quidemsolutaaccusantium.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (33, 'vcrombleholmew', 'Vaughan', 'Crombleholme', '415-666-9076', null, '144 Declaration Trail', 'San Francisco', 'California', 'user', '1951-09-07', '2026-04-13 11:16:13', 'https://robohash.org/idquasexplicabo.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (34, 'aleeburnex', 'Aymer', 'Leeburne', '212-240-8259', 'Male', '790 Russell Center', 'New York City', 'New York', 'user', '1992-01-07', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (35, 'sdanilovy', 'Stevy', 'Danilov', '281-402-6655', 'Male', '75424 Dorton Way', 'Houston', 'Texas', 'user', '1951-03-25', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (36, 'gblabeyz', 'Gardiner', 'Blabey', '704-465-4285', null, '8 Luster Junction', 'Charlotte', 'North Carolina', 'user', '1950-11-18', '2026-04-13 11:16:14', 'https://robohash.org/utquiat.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (37, 'gharsum10', 'Gratiana', 'Harsum', '951-867-9728', 'Female', '841 Duke Alley', 'Corona', 'California', 'user', '1972-08-21', '2026-04-13 11:16:14', 'https://robohash.org/necessitatibusetporro.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (38, 'jlicquorish11', 'Jacqueline', 'Licquorish', '801-967-0092', 'Agender', '8561 Tomscot Park', 'Salt Lake City', 'Utah', 'user', '1951-02-01', '2026-04-13 11:16:14', 'https://robohash.org/velsedhic.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (39, 'fmapledorum12', 'Felic', 'Mapledorum', null, 'Male', '086 Mifflin Way', 'Minneapolis', 'Minnesota', 'user', '1990-02-06', '2026-04-13 11:16:14', 'https://robohash.org/suntplaceatet.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (40, 'nguyton13', 'Neill', 'Guyton', '405-854-3499', 'Male', '269 Elmside Center', 'Oklahoma City', 'Oklahoma', 'user', '1998-03-01', '2026-04-13 11:16:14', 'https://robohash.org/atquequiaut.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (41, 'mmintoff14', 'Mariellen', 'Mintoff', '719-274-6396', 'Genderqueer', '41 Bunting Junction', 'Colorado Springs', 'Colorado', 'user', '1985-04-18', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (42, 'qcregan15', 'Quintana', 'Cregan', '704-520-1370', 'Female', '712 Cascade Center', 'Charlotte', 'North Carolina', 'user', '1961-08-26', '2026-04-13 11:16:14', 'https://robohash.org/utiurehic.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (43, 'cbenmore16', 'Calida', 'Benmore', '239-256-5125', 'Female', '57864 Magdeline Center', 'Cape Coral', 'Florida', 'user', '1958-12-28', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (44, 'bmcorkil17', 'Boycey', 'McOrkil', '303-665-7759', null, '1 Melody Parkway', 'Littleton', 'Colorado', 'user', '1941-10-09', '2026-04-13 11:16:14', 'https://robohash.org/animieligendiautem.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (45, 'jhorburgh18', 'Juli', 'Horburgh', '636-395-4948', null, '6524 Meadow Ridge Alley', 'Saint Louis', 'Missouri', 'user', '2000-04-21', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (46, 'ghicklingbottom19', 'Giselle', 'Hicklingbottom', '239-672-1490', 'Female', '1 Alpine Street', 'Naples', 'Florida', 'user', '2004-03-07', '2026-04-13 11:16:14', 'https://robohash.org/laboresintnatus.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (47, 'acurness1a', 'Alyda', 'Curness', '320-999-0773', 'Female', '01402 Rusk Court', 'Saint Cloud', 'Minnesota', 'user', '1945-06-24', '2026-04-13 11:16:14', 'https://robohash.org/utconsequaturporro.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (48, 'rlines1b', 'Roddy', 'Lines', null, 'Male', '67 Maryland Plaza', 'Omaha', 'Nebraska', 'user', '1958-07-29', '2026-04-13 11:16:14', 'https://robohash.org/etipsasimilique.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (49, 'iwookey1c', 'Ida', 'Wookey', '712-692-8848', 'Female', '40238 Hoepker Street', 'Sioux City', 'Iowa', 'user', '2004-04-18', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (50, 'atallyn1d', 'Andi', 'Tallyn', '408-282-3414', 'Female', '7 Tennyson Junction', 'San Jose', 'California', 'user', '1960-12-03', '2026-04-13 11:16:14', 'https://robohash.org/etestaccusantium.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (51, 'hputtock1e', 'Hartley', 'Puttock', '352-574-3907', 'Male', '4182 Lakewood Center', 'Ocala', 'Florida', 'user', '1930-11-19', '2026-04-13 11:16:14', 'https://robohash.org/rerumlaboriosamfacere.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (52, 'dcoldman1f', 'Dana', 'Coldman', null, 'Female', '3381 Morning Hill', 'Jacksonville', 'Florida', 'user', '1997-08-15', '2026-04-13 11:16:14', 'https://robohash.org/aspernaturvelmolestiae.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (53, 'eovize1g', 'Elwin', 'Ovize', '757-805-8809', 'Male', '9 Hoard Place', 'Newport News', 'Virginia', 'user', '1942-03-21', '2026-04-13 11:16:14', 'https://robohash.org/recusandaeenimerror.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (54, 'ldunkley1h', 'Lura', 'Dunkley', '515-723-5289', 'Female', '04 Fisk Drive', 'Des Moines', 'Iowa', 'user', '1936-11-18', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (55, 'nolennane1i', 'Nadiya', 'O''Lennane', '904-931-0965', 'Female', '2164 Buell Junction', 'Jacksonville', 'Florida', 'user', '1999-06-17', '2026-04-13 11:16:14', 'https://robohash.org/solutaculpasunt.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (56, 'styndall1j', 'Sherwynd', 'Tyndall', '502-209-6791', 'Male', '7 Arrowood Circle', 'Louisville', 'Kentucky', 'user', '1957-06-29', '2026-04-13 11:16:14', 'https://robohash.org/quiaperiamquae.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (57, 'hrigmand1k', 'Hasty', 'Rigmand', '717-354-7477', 'Male', '2557 Briar Crest Place', 'Harrisburg', 'Pennsylvania', 'user', '1973-10-11', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (58, 'wgosker1l', 'Willie', 'Gosker', '918-477-2956', 'Genderqueer', '29687 Kropf Junction', 'Tulsa', 'Oklahoma', 'user', '2005-10-18', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (59, 'cjoslow1m', 'Cart', 'Joslow', null, null, '4919 Menomonie Hill', 'Flint', 'Michigan', 'user', '1977-10-12', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (60, 'mbyles1n', 'Miller', 'Byles', null, 'Male', '6803 Lakeland Junction', 'Cleveland', 'Ohio', 'user', '1979-03-18', '2026-04-13 11:16:14', 'https://robohash.org/ullameaquebeatae.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (61, 'fneubigin1o', 'Faun', 'Neubigin', '231-322-6185', 'Female', '30 Roth Terrace', 'Muskegon', 'Michigan', 'user', null, '2026-04-13 11:16:14', 'https://robohash.org/velitanimiet.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (62, 'aizen1p', 'Antonia', 'Izen', '212-583-1550', null, '0721 Hansons Hill', 'New York City', 'New York', 'user', '1949-05-15', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (63, 'dtremolieres1q', 'Daniella', 'Tremolieres', '772-188-3330', 'Female', '9734 Charing Cross Circle', 'Vero Beach', 'Florida', 'user', '1943-04-15', '2026-04-13 11:16:14', 'https://robohash.org/quocumquequod.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (64, 'bgilford1r', 'Bethina', 'Gilford', null, 'Bigender', '2350 Rigney Crossing', 'Los Angeles', 'California', 'user', '1999-07-17', '2026-04-13 11:16:14', 'https://robohash.org/estlaudantiumsed.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (65, 'jsuch1s', 'Jamaal', 'Such', null, 'Bigender', '6110 Bonner Center', 'Washington', 'District of Columbia', 'user', '1971-03-29', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (66, 'vquilty1t', 'Vaughn', 'Quilty', null, 'Male', '72 5th Point', 'Atlanta', 'Georgia', 'user', '1939-06-23', '2026-04-13 11:16:14', 'https://robohash.org/quipossimusvoluptate.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (67, 'econford1u', 'Erda', 'Conford', null, null, '2 Lunder Park', 'Northridge', 'California', 'user', '1969-03-08', '2026-04-13 11:16:14', 'https://robohash.org/exfugaquas.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (68, 'nlewens1v', 'Norrie', 'Lewens', '915-263-1303', 'Male', '46 Shasta Way', 'El Paso', 'Texas', 'user', '2003-01-31', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (69, 'bmichel1w', 'Bernadene', 'Michel', null, 'Female', '70 Huxley Crossing', 'Pittsburgh', 'Pennsylvania', 'user', '2003-06-24', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (70, 'vgorthy1x', 'Vera', 'Gorthy', null, 'Female', '9628 Buell Alley', 'Washington', 'District of Columbia', 'user', null, '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (71, 'mroscamp1y', 'Murray', 'Roscamp', null, 'Male', '45 Springs Street', 'Salt Lake City', 'Utah', 'user', '1983-08-28', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (72, 'ablasik1z', 'Abbye', 'Blasik', null, 'Female', '43 Brickson Park Parkway', 'Shawnee Mission', 'Kansas', 'user', '1971-11-22', '2026-04-13 11:16:14', 'https://robohash.org/cumquequodomnis.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (73, 'dhuntriss20', 'Dianna', 'Huntriss', '212-250-1161', 'Female', '958 Messerschmidt Road', 'New York City', 'New York', 'user', '1970-12-03', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (74, 'jbickell21', 'Jyoti', 'Bickell', '503-597-6298', null, '49379 Spenser Alley', 'Portland', 'Oregon', 'user', null, '2026-04-13 11:16:14', 'https://robohash.org/reiciendisvoluptasiste.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (75, 'lodonohue22', 'Lindsay', 'O''Donohue', '912-822-0484', null, '72 Autumn Leaf Crossing', 'Savannah', 'Georgia', 'user', '1969-04-16', '2026-04-13 11:16:14', 'https://robohash.org/earummagnamaspernatur.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (76, 'jsolloway23', 'Jany', 'Solloway', '202-679-7660', null, '40377 Novick Place', 'Washington', 'District of Columbia', 'user', '1948-01-19', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (77, 'bgearing24', 'Bobbette', 'Gearing', '920-393-2620', 'Female', '7 Lunder Alley', 'Appleton', 'Wisconsin', 'user', null, '2026-04-13 11:16:14', 'https://robohash.org/ipsaprovidentmaiores.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (78, 'tplaister25', 'Thorsten', 'Plaister', null, 'Male', '742 Johnson Terrace', 'Seattle', 'Washington', 'user', null, '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (79, 'jciobutaro26', 'Julia', 'Ciobutaro', '570-773-1991', 'Female', '8693 Melby Place', 'Scranton', 'Pennsylvania', 'user', '1982-10-04', '2026-04-13 11:16:14', 'https://robohash.org/architectoeaqueperspiciatis.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (80, 'carnaldi27', 'Cleopatra', 'Arnaldi', '801-546-7510', 'Female', '516 Maywood Pass', 'Salt Lake City', 'Utah', 'user', '2005-10-12', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (81, 'gdunbabin28', 'Gaspard', 'Dunbabin', '858-872-6885', 'Male', '0 Anderson Crossing', 'San Diego', 'California', 'user', '1987-12-02', '2026-04-13 11:16:14', 'https://robohash.org/beataeeoslaborum.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (82, 'apachta29', 'Ansley', 'Pachta', '801-489-6718', 'Female', '37238 Elgar Court', 'Salt Lake City', 'Utah', 'user', null, '2026-04-13 11:16:14', 'https://robohash.org/autematvel.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (83, 'jconahy2a', 'Joellen', 'Conahy', null, 'Female', '941 Nancy Lane', 'Columbus', 'Mississippi', 'user', '1930-06-17', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (84, 'ctaberer2b', 'Christabel', 'Taberer', '502-423-2124', 'Female', '55 Lukken Junction', 'Louisville', 'Kentucky', 'user', '2004-08-15', '2026-04-13 11:16:14', 'https://robohash.org/expeditaestmaxime.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (85, 'chrus2c', 'Carlen', 'Hrus', null, null, '55 Caliangt Crossing', 'Metairie', 'Louisiana', 'user', '1951-09-08', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (86, 'cwyness2d', 'Curran', 'Wyness', '914-663-3752', 'Male', '8 Darwin Center', 'Yonkers', 'New York', 'user', '2003-06-29', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (87, 'qantoniak2e', 'Quintina', 'Antoniak', null, null, '1 Kinsman Avenue', 'Washington', 'District of Columbia', 'user', '1976-12-31', '2026-04-13 11:16:14', null);
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (88, 'jshetliff2f', 'Josy', 'Shetliff', '407-910-4932', null, '1049 Mosinee Court', 'Orlando', 'Florida', 'user', '1937-03-31', '2026-04-13 11:16:14', 'https://robohash.org/inquidemvoluptate.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (89, 'hmundee2g', 'Helen', 'Mundee', '646-702-9901', null, '875 Warbler Lane', 'New York City', 'New York', 'user', '1997-02-12', '2026-04-13 11:16:14', 'https://robohash.org/sunteiuslibero.png?size=50x50&set=set1');
insert into user (user_id, username, first_name, last_name, phone, gender, street_address, city, state, role, dob, created_at, photo_link) values (90, 'ebenka2h', 'Eachelle', 'Benka', null, 'Female', '3 Haas Circle', 'Lake Worth', 'Florida', 'user', null, '2026-04-13 11:16:14', 'https://robohash.org/autquiomnis.png?size=50x50&set=set1');

-- user_email
insert into user_email (email_id, user_id, email, is_primary) values (1, 30, 'wcord0@huffingtonpost.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (2, 84, 'kchild1@amazon.co.uk', false);
insert into user_email (email_id, user_id, email, is_primary) values (3, 59, 'varnason2@surveymonkey.com', true);
insert into user_email (email_id, user_id, email, is_primary) values (4, 33, 'stellenbroker3@com.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (5, 24, 'rmoth4@cisco.com', true);
insert into user_email (email_id, user_id, email, is_primary) values (6, 19, 'cmuxworthy5@slate.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (7, 34, 'fkinde6@constantcontact.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (8, 20, 'akopman7@shutterfly.com', true);
insert into user_email (email_id, user_id, email, is_primary) values (9, 58, 'adaynter8@symantec.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (10, 42, 'edowley9@blogspot.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (11, 22, 'mcollecotta@nsw.gov.au', true);
insert into user_email (email_id, user_id, email, is_primary) values (12, 58, 'ggomersallb@alibaba.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (13, 32, 'gmalyjc@umn.edu', true);
insert into user_email (email_id, user_id, email, is_primary) values (14, 46, 'dparslowd@google.co.jp', true);
insert into user_email (email_id, user_id, email, is_primary) values (15, 23, 'hpanthere@arizona.edu', false);
insert into user_email (email_id, user_id, email, is_primary) values (16, 63, 'mseagoodf@stanford.edu', false);
insert into user_email (email_id, user_id, email, is_primary) values (17, 60, 'ssingletong@nature.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (18, 19, 'zkiebesh@hao123.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (19, 10, 'tparishi@marriott.com', true);
insert into user_email (email_id, user_id, email, is_primary) values (20, 54, 'fallredj@google.co.jp', true);
insert into user_email (email_id, user_id, email, is_primary) values (21, 63, 'giscowitzk@rambler.ru', true);
insert into user_email (email_id, user_id, email, is_primary) values (22, 83, 'enonil@irs.gov', true);
insert into user_email (email_id, user_id, email, is_primary) values (23, 4, 'dcollingridgem@shutterfly.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (24, 60, 'bculleyn@businessinsider.com', true);
insert into user_email (email_id, user_id, email, is_primary) values (25, 60, 'slabbeo@apple.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (26, 39, 'sthorndalep@macromedia.com', false);
insert into user_email (email_id, user_id, email, is_primary) values (27, 46, 'ncogginq@lycos.com', true);
insert into user_email (email_id, user_id, email, is_primary) values (28, 19, 'abrearleyr@umn.edu', true);
insert into user_email (email_id, user_id, email, is_primary) values (29, 6, 'hlimbs@earthlink.net', false);
insert into user_email (email_id, user_id, email, is_primary) values (30, 80, 'lyouellt@bigcartel.com', true);
insert into user_email (email_id, user_id, email, is_primary) values (31, 73, 'aperesu@php.net', true);
insert into user_email (email_id, user_id, email, is_primary) values (32, 44, 'ecleifev@digg.com', true);
insert into user_email (email_id, user_id, email, is_primary) values (33, 60, 'icaulfieldw@arstechnica.com', true);
insert into user_email (email_id, user_id, email, is_primary) values (34, 40, 'magerskowx@delicious.com', true);
insert into user_email (email_id, user_id, email, is_primary) values (35, 37, 'wdicksony@drupal.org', false);

-- artist
insert into artist (artist_id, is_verified) values (1, false);
insert into artist (artist_id, is_verified) values (2, true);
insert into artist (artist_id, is_verified) values (3, true);
insert into artist (artist_id, is_verified) values (4, false);
insert into artist (artist_id, is_verified) values (5, true);
insert into artist (artist_id, is_verified) values (6, true);
insert into artist (artist_id, is_verified) values (7, true);
insert into artist (artist_id, is_verified) values (8, true);
insert into artist (artist_id, is_verified) values (9, true);
insert into artist (artist_id, is_verified) values (10, false);
insert into artist (artist_id, is_verified) values (11, true);
insert into artist (artist_id, is_verified) values (12, false);
insert into artist (artist_id, is_verified) values (13, true);
insert into artist (artist_id, is_verified) values (14, false);
insert into artist (artist_id, is_verified) values (15, false);
insert into artist (artist_id, is_verified) values (16, true);
insert into artist (artist_id, is_verified) values (17, true);
insert into artist (artist_id, is_verified) values (18, true);
insert into artist (artist_id, is_verified) values (19, true);
insert into artist (artist_id, is_verified) values (20, false);
insert into artist (artist_id, is_verified) values (21, true);
insert into artist (artist_id, is_verified) values (22, true);
insert into artist (artist_id, is_verified) values (23, true);
insert into artist (artist_id, is_verified) values (24, true);
insert into artist (artist_id, is_verified) values (25, false);
insert into artist (artist_id, is_verified) values (26, true);
insert into artist (artist_id, is_verified) values (27, false);
insert into artist (artist_id, is_verified) values (28, true);
insert into artist (artist_id, is_verified) values (29, false);
insert into artist (artist_id, is_verified) values (30, false);
insert into artist (artist_id, is_verified) values (31, true);
insert into artist (artist_id, is_verified) values (32, true);
insert into artist (artist_id, is_verified) values (33, true);
insert into artist (artist_id, is_verified) values (34, false);
insert into artist (artist_id, is_verified) values (35, false);
insert into artist (artist_id, is_verified) values (36, false);
insert into artist (artist_id, is_verified) values (37, true);
insert into artist (artist_id, is_verified) values (38, false);
insert into artist (artist_id, is_verified) values (39, false);
insert into artist (artist_id, is_verified) values (40, true);
insert into artist (artist_id, is_verified) values (41, true);
insert into artist (artist_id, is_verified) values (42, true);
insert into artist (artist_id, is_verified) values (43, true);
insert into artist (artist_id, is_verified) values (44, false);
insert into artist (artist_id, is_verified) values (45, true);
insert into artist (artist_id, is_verified) values (46, true);
insert into artist (artist_id, is_verified) values (47, true);
insert into artist (artist_id, is_verified) values (48, true);
insert into artist (artist_id, is_verified) values (49, false);
insert into artist (artist_id, is_verified) values (50, false);
insert into artist (artist_id, is_verified) values (51, false);
insert into artist (artist_id, is_verified) values (52, true);
insert into artist (artist_id, is_verified) values (53, true);
insert into artist (artist_id, is_verified) values (54, true);
insert into artist (artist_id, is_verified) values (55, true);
insert into artist (artist_id, is_verified) values (56, true);
insert into artist (artist_id, is_verified) values (57, true);
insert into artist (artist_id, is_verified) values (58, false);
insert into artist (artist_id, is_verified) values (59, false);
insert into artist (artist_id, is_verified) values (60, false);

-- admin
insert into admin (admin_id, first_name, last_name, role) values (1, 'Marie-ann', 'Welch', 'systems');
insert into admin (admin_id, first_name, last_name, role) values (2, 'Bevvy', 'Creane', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (3, 'Tate', 'Legion', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (4, 'Kingsley', 'Ross', 'manager');
insert into admin (admin_id, first_name, last_name, role) values (5, 'Laure', 'Dunlop', 'systems');
insert into admin (admin_id, first_name, last_name, role) values (6, 'Lena', 'Burkman', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (7, 'Susanne', 'Dwire', 'manager');
insert into admin (admin_id, first_name, last_name, role) values (8, 'Peggy', 'Sawkin', 'manager');
insert into admin (admin_id, first_name, last_name, role) values (9, 'Osgood', 'Jaycox', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (10, 'Shelton', 'Orht', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (11, 'Pamella', 'Gowdridge', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (12, 'Petra', 'Pinnocke', 'manager');
insert into admin (admin_id, first_name, last_name, role) values (13, 'Lark', 'Findlow', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (14, 'Konstantin', 'Thundercliffe', 'systems');
insert into admin (admin_id, first_name, last_name, role) values (15, 'Demetri', 'Winser', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (16, 'Even', 'Gorman', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (17, 'Simone', 'Deners', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (18, 'Horatio', 'Saye', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (19, 'Sharai', 'Mannix', 'manager');
insert into admin (admin_id, first_name, last_name, role) values (20, 'Oby', 'Heselwood', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (21, 'Nessy', 'Greenroyd', 'systems');
insert into admin (admin_id, first_name, last_name, role) values (22, 'Gelya', 'Doni', 'manager');
insert into admin (admin_id, first_name, last_name, role) values (23, 'Stefanie', 'Abercrombie', 'systems');
insert into admin (admin_id, first_name, last_name, role) values (24, 'Leanor', 'Hendin', 'systems');
insert into admin (admin_id, first_name, last_name, role) values (25, 'Idelle', 'Bolus', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (26, 'Cristal', 'Scogings', 'manager');
insert into admin (admin_id, first_name, last_name, role) values (27, 'Blinny', 'Colin', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (28, 'Teodorico', 'Vallis', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (29, 'Julianna', 'Foot', 'systems');
insert into admin (admin_id, first_name, last_name, role) values (30, 'Tyson', 'Mathivat', 'manager');
insert into admin (admin_id, first_name, last_name, role) values (31, 'Kass', 'Shillito', 'manager');
insert into admin (admin_id, first_name, last_name, role) values (32, 'Clementius', 'Wrench', 'performance');
insert into admin (admin_id, first_name, last_name, role) values (33, 'Niki', 'Hackford', 'systems');
insert into admin (admin_id, first_name, last_name, role) values (34, 'Winifred', 'Gehrtz', 'systems');
insert into admin (admin_id, first_name, last_name, role) values (35, 'Patty', 'Rugieri', 'manager');

-- admin_email
insert into admin_email (email_id, admin_id, email, is_primary) values (1, 30, 'pgreste0@fastcompany.com', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (2, 1, 'wgreenwell1@shop-pro.jp', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (3, 31, 'adoey2@ox.ac.uk', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (4, 26, 'gmclernon3@quantcast.com', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (5, 7, 'estorror4@auda.org.au', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (6, 12, 'pwhittier5@sourceforge.net', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (7, 17, 'kmapplethorpe6@wikia.com', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (8, 28, 'dpalfreeman7@hao123.com', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (9, 19, 'eridger8@ezinearticles.com', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (10, 4, 'tchalk9@google.com.hk', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (11, 10, 'bjelfa@aol.com', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (12, 21, 'araybouldb@comcast.net', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (13, 7, 'gstirmanc@ameblo.jp', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (14, 22, 'jblundelld@pinterest.com', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (15, 22, 'dcornforde@hp.com', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (16, 28, 'syellopf@123-reg.co.uk', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (17, 5, 'gbrittg@wikimedia.org', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (18, 11, 'ppieh@yahoo.com', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (19, 15, 'cburli@cdc.gov', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (20, 5, 'dalbistonj@shop-pro.jp', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (21, 19, 'iloneyk@xinhuanet.com', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (22, 2, 'jscholzl@state.gov', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (23, 31, 'ggarettm@netvibes.com', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (24, 26, 'clawlyn@seesaa.net', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (25, 26, 'cbaseggioo@hc360.com', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (26, 2, 'kbustp@gravatar.com', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (27, 22, 'dmannq@canalblog.com', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (28, 19, 'bcassimerr@mediafire.com', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (29, 2, 'cmacsporrans@illinois.edu', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (30, 20, 'pbrodestt@cargocollective.com', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (31, 13, 'ckaesu@amazon.co.uk', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (32, 21, 'cchengv@yolasite.com', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (33, 31, 'astariesw@typepad.com', true);
insert into admin_email (email_id, admin_id, email, is_primary) values (34, 4, 'stregianx@free.fr', false);
insert into admin_email (email_id, admin_id, email, is_primary) values (35, 6, 'jdudneyy@drupal.org', false);

-- artist_status
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (1, 15, 60, '2026-04-14 17:45:41', 'under review');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (2, 34, 26, '2026-04-14 17:45:41', 'under review');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (3, 12, 58, '2026-04-14 17:45:41', 'banned');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (4, 29, 37, '2026-04-14 17:45:41', 'banned');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (5, 24, 50, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (6, 28, 12, '2026-04-14 17:45:41', 'banned');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (7, 21, 52, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (8, 24, 53, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (9, 28, 25, '2026-04-14 17:45:41', 'resolved');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (10, 22, 36, '2026-04-14 17:45:41', 'resolved');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (11, 28, 31, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (12, 18, 32, '2026-04-14 17:45:41', 'banned');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (13, 26, 46, '2026-04-14 17:45:41', 'under review');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (14, 17, 33, '2026-04-14 17:45:41', 'banned');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (15, 18, 27, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (16, 29, 14, '2026-04-14 17:45:41', 'banned');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (17, 18, 51, '2026-04-14 17:45:41', 'under review');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (18, 3, 59, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (19, 4, 22, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (20, 11, 57, '2026-04-14 17:45:41', 'resolved');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (21, 34, 27, '2026-04-14 17:45:41', 'resolved');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (22, 30, 21, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (23, 33, 2, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (24, 33, 32, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (25, 32, 32, '2026-04-14 17:45:41', 'resolved');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (26, 6, 34, '2026-04-14 17:45:41', 'banned');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (27, 31, 51, '2026-04-14 17:45:41', 'resolved');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (28, 13, 52, '2026-04-14 17:45:41', 'resolved');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (29, 16, 3, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (30, 24, 12, '2026-04-14 17:45:41', 'under review');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (31, 16, 12, '2026-04-14 17:45:41', 'under review');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (32, 21, 45, '2026-04-14 17:45:41', 'verified');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (33, 13, 3, '2026-04-14 17:45:41', 'banned');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (34, 35, 4, '2026-04-14 17:45:41', 'under review');
insert into artist_status (status_id, reviewer_id, artist_id, created_at, status) values (35, 27, 27, '2026-04-14 17:45:41', 'banned');

-- category
insert into category (category_id, name) values (1, 'Folklore');
insert into category (category_id, name) values (2, 'Retro Nostalgia');
insert into category (category_id, name) values (3, 'Sneakers');
insert into category (category_id, name) values (4, 'Medieval Fantasy');
insert into category (category_id, name) values (5, 'Zodiac Signs');
insert into category (category_id, name) values (6, 'Architecture');
insert into category (category_id, name) values (7, 'Mascot Characters');
insert into category (category_id, name) values (8, 'Music & Bands');
insert into category (category_id, name) values (9, 'Botany');
insert into category (category_id, name) values (10, 'Historical Figures');
insert into category (category_id, name) values (11, 'Video Games');
insert into category (category_id, name) values (12, 'Beverages');
insert into category (category_id, name) values (13, 'Designer Toys');
insert into category (category_id, name) values (14, 'Kawaii');
insert into category (category_id, name) values (15, 'Superheroes');
insert into category (category_id, name) values (16, 'Anime');
insert into category (category_id, name) values (17, 'European Architecture');
insert into category (category_id, name) values (18, 'Urban Vinyl');
insert into category (category_id, name) values (19, 'Space Exploration');
insert into category (category_id, name) values (20, 'Asian Architecture');
insert into category (category_id, name) values (21, 'School Mascot Characters');
insert into category (category_id, name) values (22, '2000s Nostalgia');
insert into category (category_id, name) values (23, 'Steampunk');
insert into category (category_id, name) values (24, 'Sci-Fi');
insert into category (category_id, name) values (25, 'Horror');
insert into category (category_id, name) values (26, 'Cats');
insert into category (category_id, name) values (27, 'Miscellaneous');
insert into category (category_id, name) values (28, 'Food');
insert into category (category_id, name) values (29, 'Dogs');
insert into category (category_id, name) values (30, 'Pin-Up');
insert into category (category_id, name) values (31, 'Ocean Life');
insert into category (category_id, name) values (32, 'Space');
insert into category (category_id, name) values (33, 'Classic Board Games');
insert into category (category_id, name) values (34, '90s Nostalgia');
insert into category (category_id, name) values (35, '50s Nostalgia');

-- item
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (1, 'Super Villains', 'In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus.', 'S', 'http://dummyimage.com/196x100.png/ff4444/ffffff', 14, 7);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (2, 'Circus Circus', null, 'L', 'http://dummyimage.com/170x100.png/cc0000/ffffff', 34, 15);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (3, 'Enchanted Forest', 'Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat.', 'L', 'http://dummyimage.com/148x100.png/cc0000/ffffff', 34, 2);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (4, 'Artistic Masterpieces', null, 'M', 'http://dummyimage.com/235x100.png/5fa2dd/ffffff', 6, 18);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (5, 'Cyberpunk City', 'In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus.', 'L', 'http://dummyimage.com/225x100.png/5fa2dd/ffffff', 3, 25);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (6, 'Mythical Creatures', 'Duis bibendum. Morbi non quam nec dui luctus rutrum. Nulla tellus.', 'M', 'http://dummyimage.com/240x100.png/dddddd/000000', 58, 4);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (7, 'Tech Gadgets', 'Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum.', 'S', 'http://dummyimage.com/191x100.png/dddddd/000000', 6, 24);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (8, 'Foodie Fun', 'Phasellus in felis. Donec semper sapien a libero. Nam dui.', 'M', 'http://dummyimage.com/204x100.png/dddddd/000000', 53, 1);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (9, 'Zombie Apocalypse', 'Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus.', 'S', 'http://dummyimage.com/241x100.png/cc0000/ffffff', 48, 8);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (10, 'Ancient Egypt', 'Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque.', 'L', 'http://dummyimage.com/189x100.png/cc0000/ffffff', 22, 24);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (11, 'Pirate Adventure', 'Suspendisse potenti. In eleifend quam a odio. In hac habitasse platea dictumst.', 'S', 'http://dummyimage.com/216x100.png/ff4444/ffffff', 19, 35);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (12, 'Magic Potions', 'Pellentesque at nulla. Suspendisse potenti. Cras in purus eu magna vulputate luctus.', 'M', 'http://dummyimage.com/120x100.png/dddddd/000000', 58, 3);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (13, 'Dinosaur Discovery', 'In congue. Etiam justo. Etiam pretium iaculis justo.', 'M', 'http://dummyimage.com/134x100.png/cc0000/ffffff', 35, 14);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (14, 'Wild West Saloon', 'Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus.', 'L', 'http://dummyimage.com/129x100.png/cc0000/ffffff', 52, 10);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (15, 'Dinosaur Discovery', 'Maecenas ut massa quis augue luctus tincidunt. Nulla mollis molestie lorem. Quisque ut erat.', 'L', 'http://dummyimage.com/168x100.png/dddddd/000000', 31, 33);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (16, 'Ancient Egypt', 'Integer ac leo. Pellentesque ultrices mattis odio. Donec vitae nisi.', 'S', 'http://dummyimage.com/151x100.png/cc0000/ffffff', 11, 1);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (17, 'Robot Revolution', 'Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis.', 'S', 'http://dummyimage.com/250x100.png/5fa2dd/ffffff', 5, 23);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (18, 'Medieval Knights', 'Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero.', 'S', 'http://dummyimage.com/158x100.png/dddddd/000000', 47, 32);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (19, 'Haunted Mansion', 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin risus. Praesent lectus.', 'M', 'http://dummyimage.com/120x100.png/5fa2dd/ffffff', 29, 11);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (20, 'Time Travelers', 'Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum.', 'L', 'http://dummyimage.com/122x100.png/dddddd/000000', 6, 35);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (21, 'Tech Gadgets', 'Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros.', 'S', 'http://dummyimage.com/159x100.png/ff4444/ffffff', 41, 30);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (22, 'Pirate''s Cove', 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin risus. Praesent lectus.', 'S', 'http://dummyimage.com/250x100.png/cc0000/ffffff', 36, 1);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (23, 'Fairy Tale Castle', 'Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem.', 'M', 'http://dummyimage.com/168x100.png/dddddd/000000', 46, 22);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (24, 'Musical Melodies', 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin risus. Praesent lectus.', 'M', 'http://dummyimage.com/173x100.png/ff4444/ffffff', 26, 21);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (25, 'Pirate Adventure', 'Curabitur gravida nisi at nibh. In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem.', 'M', 'http://dummyimage.com/101x100.png/ff4444/ffffff', 32, 25);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (26, 'Steampunk Workshop', 'Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.', 'M', 'http://dummyimage.com/124x100.png/ff4444/ffffff', 10, 20);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (27, 'Magical Unicorn', 'Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem.', 'L', 'http://dummyimage.com/182x100.png/dddddd/000000', 12, 11);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (28, 'Fairy Tale Castle', 'Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius.', 'S', 'http://dummyimage.com/231x100.png/cc0000/ffffff', 25, 22);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (29, 'Pirate''s Cove', 'Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus.', 'S', 'http://dummyimage.com/106x100.png/5fa2dd/ffffff', 9, 11);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (30, 'Circus Circus', 'Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem.', 'M', 'http://dummyimage.com/211x100.png/cc0000/ffffff', 45, 25);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (31, 'Tech Gadgets', null, 'M', 'http://dummyimage.com/201x100.png/cc0000/ffffff', 4, 34);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (32, 'Toy Box Treasures', 'Nullam sit amet turpis elementum ligula vehicula consequat. Morbi a ipsum. Integer a nibh.', 'S', 'http://dummyimage.com/173x100.png/5fa2dd/ffffff', 57, 4);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (33, 'Pirate Adventure', 'In congue. Etiam justo. Etiam pretium iaculis justo.', 'L', 'http://dummyimage.com/159x100.png/ff4444/ffffff', 50, 25);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (34, 'Jurassic Dino World', 'Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis. Ut at dolor quis odio consequat varius.', 'L', 'http://dummyimage.com/140x100.png/ff4444/ffffff', 59, 26);
insert into item (item_id, name, description, size, image_link, artist_id, category_id) values (35, 'Mythical Creatures', 'Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem.', 'S', 'http://dummyimage.com/218x100.png/cc0000/ffffff', 38, 19);

-- variants
insert into variants (item_id, name, pull_rate) values (20, 'Green large fairy', 0.38);
insert into variants (item_id, name, pull_rate) values (28, 'Blue medium dragon', 0.51);
insert into variants (item_id, name, pull_rate) values (10, 'Yellow extra large mermaid', 0.19);
insert into variants (item_id, name, pull_rate) values (18, 'Purple tiny gnome', 0.31);
insert into variants (item_id, name, pull_rate) values (32, 'Red large fairy', 0.27);
insert into variants (item_id, name, pull_rate) values (35, 'Blue extra large mermaid', 0.11);
insert into variants (item_id, name, pull_rate) values (1, 'Purple large fairy', 0.27);
insert into variants (item_id, name, pull_rate) values (6, 'Yellow large fairy', 0.45);
insert into variants (item_id, name, pull_rate) values (22, 'Red large fairy', 0.71);
insert into variants (item_id, name, pull_rate) values (31, 'Red small unicorn', 0.74);
insert into variants (item_id, name, pull_rate) values (21, 'Green medium dragon', 0.03);
insert into variants (item_id, name, pull_rate) values (9, 'Blue large fairy', 0.08);
insert into variants (item_id, name, pull_rate) values (23, 'Orange large fairy', 0.12);
insert into variants (item_id, name, pull_rate) values (32, 'Pink large fairy', 0.86);
insert into variants (item_id, name, pull_rate) values (6, 'Blue small unicorn', 0.38);
insert into variants (item_id, name, pull_rate) values (33, 'Yellow extra large mermaid', 0.61);
insert into variants (item_id, name, pull_rate) values (32, 'Yellow small unicorn', 0.78);
insert into variants (item_id, name, pull_rate) values (11, 'Purple extra large mermaid', 0.07);
insert into variants (item_id, name, pull_rate) values (26, 'Green extra large mermaid', 0.26);
insert into variants (item_id, name, pull_rate) values (6, 'Red large fairy', 0.82);
insert into variants (item_id, name, pull_rate) values (27, 'Purple tiny gnome', 0.98);
insert into variants (item_id, name, pull_rate) values (9, 'Teal large fairy', 0.67);
insert into variants (item_id, name, pull_rate) values (34, 'Silver large fairy', 0.86);
insert into variants (item_id, name, pull_rate) values (11, 'Purple medium dragon', 0.1);
insert into variants (item_id, name, pull_rate) values (35, 'Pink extra large mermaid', 0.11);
insert into variants (item_id, name, pull_rate) values (2, 'Blue extra large mermaid', 0.36);
insert into variants (item_id, name, pull_rate) values (20, 'Red medium dragon', 0.53);
insert into variants (item_id, name, pull_rate) values (35, 'Green tiny gnome', 0.47);
insert into variants (item_id, name, pull_rate) values (4, 'Purple tiny gnome', 0.97);
insert into variants (item_id, name, pull_rate) values (23, 'Orange tiny gnome', 0.83);
insert into variants (item_id, name, pull_rate) values (15, 'Red extra large mermaid', 0.78);
insert into variants (item_id, name, pull_rate) values (35, 'Teal extra large mermaid', 0.96);
insert into variants (item_id, name, pull_rate) values (13, 'Yellow extra large mermaid', 0.95);
insert into variants (item_id, name, pull_rate) values (25, 'Green small unicorn', 0.45);
insert into variants (item_id, name, pull_rate) values (22, 'Blue tiny gnome', 0.74);
insert into variants (item_id, name, pull_rate) values (4, 'Yellow medium dragon', 0.67);
insert into variants (item_id, name, pull_rate) values (9, 'Pink extra large mermaid', 0.16);
insert into variants (item_id, name, pull_rate) values (14, 'Red tiny gnome', 0.74);
insert into variants (item_id, name, pull_rate) values (30, 'Blue medium dragon', 0.89);
insert into variants (item_id, name, pull_rate) values (7, 'Teal large fairy', 0.4);
insert into variants (item_id, name, pull_rate) values (26, 'Orange large fairy', 0.23);
insert into variants (item_id, name, pull_rate) values (32, 'Silver tiny gnome', 0.31);
insert into variants (item_id, name, pull_rate) values (25, 'Blue small unicorn', 0.51);
insert into variants (item_id, name, pull_rate) values (3, 'Green extra large mermaid', 0.3);
insert into variants (item_id, name, pull_rate) values (17, 'Purple small unicorn', 0.94);
insert into variants (item_id, name, pull_rate) values (6, 'Green medium dragon', 0.92);
insert into variants (item_id, name, pull_rate) values (31, 'Orange extra large mermaid', 0.07);
insert into variants (item_id, name, pull_rate) values (31, 'Teal large fairy', 0.82);
insert into variants (item_id, name, pull_rate) values (31, 'Pink large fairy', 0.9);
insert into variants (item_id, name, pull_rate) values (30, 'Orange tiny gnome', 0.98);
insert into variants (item_id, name, pull_rate) values (28, 'Silver large fairy', 0.34);
insert into variants (item_id, name, pull_rate) values (10, 'Red small unicorn', 0.31);
insert into variants (item_id, name, pull_rate) values (27, 'Yellow small unicorn', 0.91);
insert into variants (item_id, name, pull_rate) values (5, 'Blue small unicorn', 0.78);
insert into variants (item_id, name, pull_rate) values (12, 'Orange large fairy', 0.69);
insert into variants (item_id, name, pull_rate) values (13, 'Green small unicorn', 0.7);
insert into variants (item_id, name, pull_rate) values (32, 'Pink tiny gnome', 0.03);
insert into variants (item_id, name, pull_rate) values (17, 'Teal extra large mermaid', 0.96);
insert into variants (item_id, name, pull_rate) values (4, 'Silver medium dragon', 0.03);
insert into variants (item_id, name, pull_rate) values (15, 'Purple extra large mermaid', 0.65);

-- listing
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (1, 'Sci-Fi Robot Model', 9, 342.03, 'active', '2026-04-13 12:17:37', 35, 25);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (2, 'Vintage Porcelain Doll', 46, 93.06, 'active', '2026-04-13 12:17:37', 3, 28);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (3, 'Miniature Samurai Warrior Figurine', 99, 767.45, 'active', '2026-04-13 12:17:37', 25, 52);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (4, 'Gothic Gargoyle Figurine', 25, 997.82, 'pending', '2026-04-13 12:17:37', 17, 4);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (5, 'Sci-Fi Robot Model', 87, 296.86, 'active', '2026-04-13 12:17:37', 4, 39);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (6, 'Animal Sculpture Collection', 92, 687.89, 'active', '2026-04-13 12:17:37', 3, 28);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (7, 'Fairy Garden Figurine Set', 12, 16.22, 'active', '2026-04-13 12:17:37', 32, 30);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (8, 'Fairy Garden Figurine Set', 122, 769.14, 'active', '2026-04-13 12:17:37', 18, 1);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (9, 'Superhero Action Figure', 86, 60.92, 'pending', '2026-04-13 12:17:37', 10, 54);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (10, 'Animal Sculpture Collection', 28, 122.64, 'active', '2026-04-13 12:17:37', 31, 27);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (11, 'Mythical Creature Statue', 35, 863.77, 'rejected', '2026-04-13 12:17:37', 32, 30);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (12, 'Sci-Fi Robot Model', 81, 818.32, 'pending', '2026-04-13 12:17:37', 17, 4);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (13, 'Animal Sculpture Collection', 14, 330.98, 'flagged', '2026-04-13 12:17:37', 25, 52);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (14, 'Fairy Garden Figurine Set', 46, 202.98, 'pending', '2026-04-13 12:17:37', 3, 28);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (15, 'Miniature Samurai Warrior Figurine', 34, 701.83, 'archive', '2026-04-13 12:17:37', 29, 44);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (16, 'Gothic Gargoyle Figurine', 115, 37.41, 'archive', '2026-04-13 12:17:37', 28, 58);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (17, 'Vintage Porcelain Doll', 40, 914.38, 'rejected', '2026-04-13 12:17:37', 28, 58);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (18, 'Gothic Gargoyle Figurine', 96, 327.56, 'archive', '2026-04-13 12:17:37', 7, 40);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (19, 'Mystical Dragon Figurine', 74, 454.41, 'active', '2026-04-13 12:17:37', 16, 45);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (20, 'Gothic Gargoyle Figurine', 57, 226.8, 'active', '2026-04-13 12:17:37', 13, 37);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (21, 'Animal Sculpture Collection', 14, 61.31, 'active', '2026-04-13 12:17:37', 17, 4);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (22, 'Animal Sculpture Collection', 52, 979.34, 'rejected', '2026-04-13 12:17:37', 25, 52);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (23, 'Mythical Creature Statue', 1, 925.04, 'pending', '2026-04-13 12:17:37', 3, 28);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (24, 'Mystical Dragon Figurine', 29, 625.39, 'archive', '2026-04-13 12:17:37', 29, 44);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (25, 'Sci-Fi Robot Model', 107, 495.65, 'active', '2026-04-13 12:17:37', 19, 45);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (26, 'Miniature Samurai Warrior Figurine', 43, 885.94, 'flagged', '2026-04-13 12:17:37', 34, 6);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (27, 'Animal Sculpture Collection', 58, 818.54, 'active', '2026-04-13 12:17:37', 8, 16);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (28, 'Mystical Dragon Figurine', 139, 248.39, 'archive', '2026-04-13 12:17:37', 31, 27);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (29, 'Medieval Knight Bust', 116, 171.49, 'active', '2026-04-13 12:17:37', 22, 31);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (30, 'Miniature Samurai Warrior Figurine', 99, 862.36, 'archive', '2026-04-13 12:17:37', 29, 44);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (31, 'Mythical Creature Statue', 71, 351.78, 'active', '2026-04-13 12:17:37', 30, 43);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (32, 'Gothic Gargoyle Figurine', 149, 268.87, 'pending', '2026-04-13 12:17:37', 7, 40);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (33, 'Superhero Action Figure', 125, 47.46, 'active', '2026-04-13 12:17:37', 7, 40);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (34, 'Miniature Samurai Warrior Figurine', 142, 202.36, 'pending', '2026-04-13 12:17:37', 30, 43);
insert into listing (listing_id, title, quantity, price, status, post_time, item_id, artist_id) values (35, 'Fairy Garden Figurine Set', 23, 601.9, 'archive', '2026-04-13 12:17:37', 26, 8);

-- order
insert into `order` (order_id, order_time, status, buyer_id) values (1, '2026-04-14 17:55:51', 'purchased', 70);
insert into `order` (order_id, order_time, status, buyer_id) values (2, '2026-04-14 17:55:51', 'in cart', 86);
insert into `order` (order_id, order_time, status, buyer_id) values (3, '2026-04-14 17:55:51', 'purchased', 8);
insert into `order` (order_id, order_time, status, buyer_id) values (4, '2026-04-14 17:55:51', 'in cart', 77);
insert into `order` (order_id, order_time, status, buyer_id) values (5, '2026-04-14 17:55:51', 'in cart', 51);
insert into `order` (order_id, order_time, status, buyer_id) values (6, '2026-04-14 17:55:51', 'in cart', 20);
insert into `order` (order_id, order_time, status, buyer_id) values (7, '2026-04-14 17:55:51', 'purchased', 66);
insert into `order` (order_id, order_time, status, buyer_id) values (8, '2026-04-14 17:55:51', 'in cart', 78);
insert into `order` (order_id, order_time, status, buyer_id) values (9, '2026-04-14 17:55:51', 'purchased', 61);
insert into `order` (order_id, order_time, status, buyer_id) values (10, '2026-04-14 17:55:51', 'processing', 6);
insert into `order` (order_id, order_time, status, buyer_id) values (11, '2026-04-14 17:55:51', 'shipped', 40);
insert into `order` (order_id, order_time, status, buyer_id) values (12, '2026-04-14 17:55:51', 'processing', 45);
insert into `order` (order_id, order_time, status, buyer_id) values (13, '2026-04-14 17:55:51', 'in cart', 5);
insert into `order` (order_id, order_time, status, buyer_id) values (14, '2026-04-14 17:55:51', 'purchased', 29);
insert into `order` (order_id, order_time, status, buyer_id) values (15, '2026-04-14 17:55:51', 'shipped', 42);
insert into `order` (order_id, order_time, status, buyer_id) values (16, '2026-04-14 17:55:51', 'in cart', 34);
insert into `order` (order_id, order_time, status, buyer_id) values (17, '2026-04-14 17:55:51', 'purchased', 5);
insert into `order` (order_id, order_time, status, buyer_id) values (18, '2026-04-14 17:55:51', 'shipped', 62);
insert into `order` (order_id, order_time, status, buyer_id) values (19, '2026-04-14 17:55:51', 'shipped', 11);
insert into `order` (order_id, order_time, status, buyer_id) values (20, '2026-04-14 17:55:51', 'in cart', 85);
insert into `order` (order_id, order_time, status, buyer_id) values (21, '2026-04-14 17:55:51', 'purchased', 14);
insert into `order` (order_id, order_time, status, buyer_id) values (22, '2026-04-14 17:55:51', 'purchased', 90);
insert into `order` (order_id, order_time, status, buyer_id) values (23, '2026-04-14 17:55:51', 'in cart', 70);
insert into `order` (order_id, order_time, status, buyer_id) values (24, '2026-04-14 17:55:51', 'purchased', 72);
insert into `order` (order_id, order_time, status, buyer_id) values (25, '2026-04-14 17:55:51', 'in cart', 77);
insert into `order` (order_id, order_time, status, buyer_id) values (26, '2026-04-14 17:55:51', 'in cart', 41);
insert into `order` (order_id, order_time, status, buyer_id) values (27, '2026-04-14 17:55:51', 'processing', 42);
insert into `order` (order_id, order_time, status, buyer_id) values (28, '2026-04-14 17:55:51', 'processing', 5);
insert into `order` (order_id, order_time, status, buyer_id) values (29, '2026-04-14 17:55:51', 'shipped', 14);
insert into `order` (order_id, order_time, status, buyer_id) values (30, '2026-04-14 17:55:51', 'in cart', 53);
insert into `order` (order_id, order_time, status, buyer_id) values (31, '2026-04-14 17:55:51', 'in cart', 61);
insert into `order` (order_id, order_time, status, buyer_id) values (32, '2026-04-14 17:55:51', 'purchased', 12);
insert into `order` (order_id, order_time, status, buyer_id) values (33, '2026-04-14 17:55:51', 'shipped', 3);
insert into `order` (order_id, order_time, status, buyer_id) values (34, '2026-04-14 17:55:51', 'purchased', 9);
insert into `order` (order_id, order_time, status, buyer_id) values (35, '2026-04-14 17:55:51', 'processing', 68);

-- order_items
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (1, 2, 60.65, 31, 7);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (2, 9, 63.29, 33, 20);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (3, 5, 19.66, 25, 25);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (4, 1, 79.75, 11, 2);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (5, 8, 1.42, 1, 26);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (6, 10, 84.39, 5, 30);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (7, 5, 37.02, 33, 21);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (8, 7, 63.28, 15, 33);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (9, 6, 5.95, 2, 35);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (10, 9, 95.78, 13, 23);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (11, 5, 51.11, 20, 3);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (12, 10, 87.33, 29, 5);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (13, 10, 47.43, 8, 3);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (14, 3, 99.15, 27, 29);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (15, 10, 8.96, 7, 18);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (16, 6, 75.54, 19, 26);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (17, 1, 2.53, 23, 21);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (18, 5, 27.89, 3, 9);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (19, 5, 79.36, 19, 5);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (20, 7, 58.57, 12, 24);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (21, 4, 84.42, 13, 11);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (22, 8, 46.89, 25, 24);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (23, 3, 26.43, 18, 10);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (24, 8, 11.61, 24, 25);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (25, 7, 19.06, 18, 29);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (26, 3, 29.27, 33, 17);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (27, 5, 32.81, 30, 7);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (28, 9, 47.03, 15, 19);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (29, 3, 79.78, 28, 25);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (30, 10, 73.8, 10, 17);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (31, 8, 7.76, 32, 3);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (32, 6, 50.16, 17, 24);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (33, 1, 88.37, 6, 17);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (34, 5, 26.54, 3, 31);
insert into order_items (order_item_id, quantity, price_at_purchase, order_id, listing_id) values (35, 3, 69.47, 26, 4);
>>>>>>> Stashed changes
