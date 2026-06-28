-- ============================================================
--  lr_properties - database schema
--  Run once in your database (works with oxmysql).
-- ============================================================

CREATE TABLE IF NOT EXISTS `lr_properties` (
    `id`            INT             NOT NULL AUTO_INCREMENT,
    `label`         VARCHAR(64)     NOT NULL,
    `type`          VARCHAR(16)     NOT NULL DEFAULT 'house',   -- house | business
    `owner`         VARCHAR(64)     DEFAULT NULL,               -- owner identifier (license/citizenid)
    `owner_name`    VARCHAR(64)     DEFAULT NULL,
    `tenure`        VARCHAR(16)     DEFAULT NULL,               -- buy | rent
    `rent_due`      BIGINT          DEFAULT NULL,               -- unix ts of next rent charge
    `tax_due`       BIGINT          DEFAULT NULL,               -- unix ts of next tax charge
    `door`          TEXT            NOT NULL,                   -- json {x,y,z,h}
    `interior`      TEXT            NOT NULL,                   -- json interior definition (see interiors.lua)
    `exit`          TEXT            DEFAULT NULL,               -- json {x,y,z} per-property interior exit (overrides config)
    `price`         INT             NOT NULL DEFAULT 0,
    `rent_price`    INT             NOT NULL DEFAULT 0,
    `locked`        TINYINT(1)      NOT NULL DEFAULT 1,
    `for_sale`      TINYINT(1)      NOT NULL DEFAULT 0,
    `entry_fee`     INT             NOT NULL DEFAULT 0,         -- business: charged per entry
    `safe_balance`  INT             NOT NULL DEFAULT 0,         -- business cash box
    `created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lr_property_objects` (
    `id`            INT             NOT NULL AUTO_INCREMENT,
    `property_id`   INT             NOT NULL,
    `model`         VARCHAR(64)     NOT NULL,
    `pos`           TEXT            NOT NULL,                   -- json {x,y,z}
    `rot`           TEXT            NOT NULL,                   -- json {x,y,z}
    PRIMARY KEY (`id`),
    KEY `property_id` (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lr_property_keys` (
    `id`            INT             NOT NULL AUTO_INCREMENT,
    `property_id`   INT             NOT NULL,
    `identifier`    VARCHAR(64)     NOT NULL,
    `holder_name`   VARCHAR(64)     DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `prop_ident` (`property_id`, `identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lr_property_employees` (
    `id`            INT             NOT NULL AUTO_INCREMENT,
    `property_id`   INT             NOT NULL,
    `identifier`    VARCHAR(64)     NOT NULL,
    `name`          VARCHAR(64)     DEFAULT NULL,
    `grade`         INT             NOT NULL DEFAULT 0,         -- 0 employee, higher = more rights
    `salary`        INT             NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `prop_ident` (`property_id`, `identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lr_realtors` (
    `identifier`    VARCHAR(64)     NOT NULL,
    `name`          VARCHAR(64)     DEFAULT NULL,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- tracks who is currently INSIDE which property, so a player who logs out
-- inside a home spawns back inside it on reconnect.
CREATE TABLE IF NOT EXISTS `lr_inside` (
    `identifier`    VARCHAR(64)     NOT NULL,
    `property_id`   INT             NOT NULL,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- placeable in-world access points (storage / wardrobe / safe markers)
CREATE TABLE IF NOT EXISTS `lr_access_points` (
    `id`            INT             NOT NULL AUTO_INCREMENT,
    `property_id`   INT             NOT NULL,
    `type`          VARCHAR(16)     NOT NULL,   -- storage | wardrobe | safe
    `pos`           TEXT            NOT NULL,   -- json {x,y,z}
    PRIMARY KEY (`id`),
    KEY `property_id` (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
--  Zaten kurulu bir veritabanın varsa, sadece şu satırı çalıştır:
--  ALTER TABLE `lr_properties` ADD COLUMN `exit` TEXT DEFAULT NULL AFTER `interior`;
-- ------------------------------------------------------------
