-- Create database
CREATE DATABASE IF NOT EXISTS carentadb;
USE carentadb;

-- -----------------------
-- Admin Table (new)
-- -----------------------
CREATE TABLE `admintbl` (
  `adminid` INT(11) NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `bcrypt` VARCHAR(255) NOT NULL,
  `first_name` VARCHAR(50) DEFAULT NULL,
  `last_name` VARCHAR(50) DEFAULT NULL,
  `role` ENUM('admin','manager') NOT NULL DEFAULT 'manager',
  `status` ENUM('active','inactive','banned','pending') DEFAULT 'active',
  `phone_number` VARCHAR(20) DEFAULT NULL,
  `profile_picture` VARCHAR(255) DEFAULT NULL,
  `last_login` DATETIME DEFAULT NULL,
  `last_ip_address` VARCHAR(45) DEFAULT NULL,
  `login_attempts` INT(11) DEFAULT 0,
  `two_factor_enabled` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`adminid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Default Superadmin
INSERT INTO `admintbl` (
    username, email, bcrypt, first_name, last_name, role, status, phone_number
) VALUES (
    'superadmin',
    'superadmin@example.com',
    '$2y$10$QpaDkt/XAAN40tj3Qowmke9A9U9VZM5lL3RdvO8IaDqrqlqcqX79a', -- password: Admin@123
    'Super',
    'Admin',
    'admin',
    'active',
    '09171234567'
);

-- -----------------------
-- User Table (original)
-- -----------------------
CREATE TABLE `usertbl` (
  `userid` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `bcrypt` varchar(255) NOT NULL,
  `first_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) DEFAULT NULL,
  `gender` enum('Male','Female','Other') DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `profile_picture` varchar(255) DEFAULT NULL,
  `street_address` varchar(100) DEFAULT NULL,
  `city` varchar(50) DEFAULT NULL,
  `state` varchar(50) DEFAULT NULL,
  `postal_code` varchar(10) DEFAULT NULL,
  `country` varchar(50) DEFAULT NULL,
  `role` enum('user','guest') DEFAULT 'user',
  `status` enum('active','inactive','banned','pending') DEFAULT 'active',
  `is_verified` tinyint(1) DEFAULT 0,
  `language` varchar(10) DEFAULT 'en',
  `timezone` varchar(50) DEFAULT 'UTC',
  `dark_mode` tinyint(1) DEFAULT 0,
  `last_login` datetime DEFAULT NULL,
  `last_ip_address` varchar(45) DEFAULT NULL,
  `login_attempts` int(11) DEFAULT 0,
  `two_factor_enabled` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`userid`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------
-- Car Table (original)
-- -----------------------
CREATE TABLE `cartbl` (
  `carid` int(11) NOT NULL AUTO_INCREMENT,
  `year` text NOT NULL,
  `manufacturer` text NOT NULL,
  `model` text NOT NULL,
  `type` text NOT NULL,
  `license_plate` text NOT NULL,
  `color` text NOT NULL,
  `transmission` text NOT NULL,
  `fueltype` text NOT NULL,
  `milage` text NOT NULL,
  `seatingcap` text NOT NULL,
  `status` text NOT NULL,
  `createdAt` text DEFAULT current_timestamp(),
  `withDriver` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`carid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------
-- Improved Media Table
-- -----------------------
CREATE TABLE `mediatbl` (
  `mediaid` INT(11) NOT NULL AUTO_INCREMENT,
  `carid` INT(11) DEFAULT NULL,
  `uploaded_by` INT(11) DEFAULT NULL,
  `media_type` ENUM('image','video') NOT NULL,
  `title` VARCHAR(150) DEFAULT NULL,
  `description` TEXT DEFAULT NULL,
  `media_url` VARCHAR(255) NOT NULL,
  `thumbnail_url` VARCHAR(255) DEFAULT NULL,
  `mime_type` VARCHAR(50) DEFAULT NULL,
  `file_size` BIGINT DEFAULT NULL,
  `duration_seconds` INT DEFAULT NULL,
  `tags` VARCHAR(255) DEFAULT NULL,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`mediaid`),
  KEY `carid` (`carid`),
  KEY `uploaded_by` (`uploaded_by`),
  CONSTRAINT `mediatbl_ibfk_1` FOREIGN KEY (`carid`) REFERENCES `cartbl` (`carid`),
  CONSTRAINT `mediatbl_ibfk_2` FOREIGN KEY (`uploaded_by`) REFERENCES `admintbl` (`adminid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------
-- Improved Price Table
-- -----------------------
CREATE TABLE `pricetbl` (
  `priceid` INT(11) NOT NULL AUTO_INCREMENT,
  `carid` INT(11) NOT NULL,
  `currency` CHAR(3) DEFAULT 'PHP',
  `hourly_rate` DECIMAL(10,2) DEFAULT NULL,
  `daily_rate` DECIMAL(10,2) DEFAULT NULL,
  `weekly_rate` DECIMAL(10,2) DEFAULT NULL,
  `monthly_rate` DECIMAL(10,2) DEFAULT NULL,
  `seasonal` TINYINT(1) DEFAULT 0,
  `promo_code` VARCHAR(50) DEFAULT NULL,
  `discount_percent` DECIMAL(5,2) DEFAULT NULL,
  `valid_from` DATE DEFAULT NULL,
  `valid_to` DATE DEFAULT NULL,
  `set_by_admin` INT(11) DEFAULT NULL,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`priceid`),
  KEY `carid` (`carid`),
  KEY `set_by_admin` (`set_by_admin`),
  CONSTRAINT `pricetbl_ibfk_1` FOREIGN KEY (`carid`) REFERENCES `cartbl` (`carid`),
  CONSTRAINT `pricetbl_ibfk_2` FOREIGN KEY (`set_by_admin`) REFERENCES `admintbl` (`adminid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------
-- Improved Payment Table
-- -----------------------
CREATE TABLE `paymenttbl` (
  `paymentid` INT(11) NOT NULL AUTO_INCREMENT,
  `rentalid` INT(11) NOT NULL,
  `userid` INT(11) DEFAULT NULL,
  `processed_by_admin` INT(11) DEFAULT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `currency` CHAR(3) DEFAULT 'PHP',
  `payment_method` ENUM('GCash','PayMaya','Credit Card','Debit Card','Bank Transfer','Cash') DEFAULT 'Cash',
  `payment_status` ENUM('pending','completed','failed','refunded','disputed') DEFAULT 'pending',
  `payment_type` ENUM('full','partial','refund') DEFAULT 'full',
  `transaction_id` VARCHAR(100) DEFAULT NULL,
  `gateway_fee` DECIMAL(10,2) DEFAULT NULL,
  `net_amount` DECIMAL(10,2) GENERATED ALWAYS AS (`amount` - IFNULL(`gateway_fee`,0)) STORED,
  `remarks` TEXT DEFAULT NULL,
  `receipt_url` VARCHAR(255) DEFAULT NULL,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`paymentid`),
  KEY `rentalid` (`rentalid`),
  KEY `userid` (`userid`),
  KEY `processed_by_admin` (`processed_by_admin`),
  CONSTRAINT `paymenttbl_ibfk_1` FOREIGN KEY (`rentalid`) REFERENCES `rentaltbl` (`rentalid`),
  CONSTRAINT `paymenttbl_ibfk_2` FOREIGN KEY (`userid`) REFERENCES `usertbl` (`userid`),
  CONSTRAINT `paymenttbl_ibfk_3` FOREIGN KEY (`processed_by_admin`) REFERENCES `admintbl` (`adminid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------
-- Improved Feedback Table
-- -----------------------
CREATE TABLE `feedbacktbl` (
  `feedbackid` INT(11) NOT NULL AUTO_INCREMENT,
  `userid` INT(11) NOT NULL,
  `carid` INT(11) DEFAULT NULL,
  `ownerid` INT(11) DEFAULT NULL,
  `rating` INT(11) NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
  `title` VARCHAR(100) DEFAULT NULL,
  `comment` TEXT DEFAULT NULL,
  `media_url` VARCHAR(255) DEFAULT NULL,
  `status` ENUM('visible','hidden','flagged','pending') DEFAULT 'visible',
  `approved_by` INT(11) DEFAULT NULL,
  `admin_reply` TEXT DEFAULT NULL,
  `reply_date` DATETIME DEFAULT NULL,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`feedbackid`),
  KEY `userid` (`userid`),
  KEY `carid` (`carid`),
  KEY `ownerid` (`ownerid`),
  KEY `approved_by` (`approved_by`),
  CONSTRAINT `feedbacktbl_ibfk_1` FOREIGN KEY (`userid`) REFERENCES `usertbl` (`userid`),
  CONSTRAINT `feedbacktbl_ibfk_2` FOREIGN KEY (`carid`) REFERENCES `cartbl` (`carid`),
  CONSTRAINT `feedbacktbl_ibfk_3` FOREIGN KEY (`ownerid`) REFERENCES `usertbl` (`userid`),
  CONSTRAINT `feedbacktbl_ibfk_4` FOREIGN KEY (`approved_by`) REFERENCES `admintbl` (`adminid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------
-- Improved Rental Table
-- -----------------------
CREATE TABLE `rentaltbl` (
  `rentalid` INT(11) NOT NULL AUTO_INCREMENT,
  `carid` INT(11) NOT NULL,
  `userid` INT(11) NOT NULL,
  `ownerid` INT(11) DEFAULT NULL,
  `approved_by` INT(11) DEFAULT NULL,
  `rental_type` ENUM('self-drive','with-driver') DEFAULT 'self-drive',
  `start_date` DATE NOT NULL,
  `start_time` TIME DEFAULT NULL,
  `end_date` DATE NOT NULL,
  `end_time` TIME DEFAULT NULL,
  `pickup_location` VARCHAR(150) DEFAULT NULL,
  `dropoff_location` VARCHAR(150) DEFAULT NULL,
  `daily_rate` DECIMAL(10,2) DEFAULT NULL,
  `total_days` INT DEFAULT NULL,
  `total_amount` DECIMAL(10,2) DEFAULT NULL,
  `security_deposit` DECIMAL(10,2) DEFAULT 0.00,
  `mileage_limit` INT DEFAULT NULL,
  `overage_fee_per_km` DECIMAL(10,2) DEFAULT NULL,
  `status` ENUM('pending','confirmed','ongoing','completed','cancelled') DEFAULT 'pending',
  `cancellation_reason` TEXT DEFAULT NULL,
  `cancelled_by` ENUM('user','admin','system') DEFAULT NULL,
  `admin_notes` TEXT DEFAULT NULL,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`rentalid`),
  KEY `carid` (`carid`),
  KEY `userid` (`userid`),
  KEY `ownerid` (`ownerid`),
  KEY `approved_by` (`approved_by`),
  CONSTRAINT `rentaltbl_ibfk_1` FOREIGN KEY (`carid`) REFERENCES `cartbl` (`carid`),
  CONSTRAINT `rentaltbl_ibfk_2` FOREIGN KEY (`userid`) REFERENCES `usertbl` (`userid`),
  CONSTRAINT `rentaltbl_ibfk_3` FOREIGN KEY (`ownerid`) REFERENCES `usertbl` (`userid`),
  CONSTRAINT `rentaltbl_ibfk_4` FOREIGN KEY (`approved_by`) REFERENCES `admintbl` (`adminid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
