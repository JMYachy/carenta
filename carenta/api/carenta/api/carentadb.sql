-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 03, 2025 at 09:34 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `carentadb`
--

-- --------------------------------------------------------

--
-- Table structure for table `admintbl`
--

CREATE TABLE `admintbl` (
  `adminid` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `bcrypt` varchar(255) NOT NULL,
  `first_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) DEFAULT NULL,
  `role` enum('admin','manager') NOT NULL DEFAULT 'manager',
  `status` enum('active','inactive','banned','pending') DEFAULT 'active',
  `phone_number` varchar(20) DEFAULT NULL,
  `profile_picture` varchar(255) DEFAULT NULL,
  `last_login` datetime DEFAULT NULL,
  `last_ip_address` varchar(45) DEFAULT NULL,
  `login_attempts` int(11) DEFAULT 0,
  `two_factor_enabled` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admintbl`
--

INSERT INTO `admintbl` (`adminid`, `username`, `email`, `bcrypt`, `first_name`, `last_name`, `role`, `status`, `phone_number`, `profile_picture`, `last_login`, `last_ip_address`, `login_attempts`, `two_factor_enabled`, `created_at`, `updated_at`) VALUES
(1, 'superadmin', 'superadmin@example.com', '$2y$10$Tkyy7U94rAGwvX5fwNjhFeKWZNgRF7eXIxbB11t7LODI/jk6roEOa', 'Super', 'Admin', 'admin', 'active', '09171234567', 'http://10.0.2.2/carenta/uploads/avatars/admin_1_1755924229.jpg', '2025-09-30 15:02:12', '127.0.0.1', 0, 1, '2025-08-15 01:42:39', '2025-09-30 07:02:12');

-- --------------------------------------------------------

--
-- Table structure for table `cartbl`
--

CREATE TABLE `cartbl` (
  `carid` int(11) NOT NULL,
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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `withDriver` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cartbl`
--

INSERT INTO `cartbl` (`carid`, `year`, `manufacturer`, `model`, `type`, `license_plate`, `color`, `transmission`, `fueltype`, `milage`, `seatingcap`, `status`, `created_at`, `updated_at`, `withDriver`) VALUES
(8, '2019', 'Mitsubishi', 'Montero Sport', 'SUV', 'ABC123', 'White', 'Automatic', 'Diesel', '35000', '7', 'available', '2025-09-28 17:03:34', '2025-09-28 21:05:50', 'Yes'),
(9, '2021', 'Honda', 'Civic', 'Sedan', 'ABC987', 'Black', 'Automatic', 'Gasoline', '12000', '5', 'available', '2025-09-28 17:04:58', '2025-09-28 21:05:50', 'No');

-- --------------------------------------------------------

--
-- Table structure for table `car_schedule`
--

CREATE TABLE `car_schedule` (
  `schedule_id` int(11) NOT NULL,
  `carid` int(11) NOT NULL,
  `available_day` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `is_available` tinyint(1) DEFAULT 1,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `car_schedule`
--

INSERT INTO `car_schedule` (`schedule_id`, `carid`, `available_day`, `start_time`, `end_time`, `is_available`, `notes`, `created_at`, `updated_at`) VALUES
(1, 8, 'Monday', '09:00:00', '17:00:00', 1, 'Weekday availability', '2025-09-28 21:39:00', '2025-09-28 21:39:00'),
(2, 8, 'Tuesday', '09:00:00', '17:00:00', 1, 'Weekday availability', '2025-09-28 21:39:00', '2025-09-28 21:39:00'),
(3, 8, 'Wednesday', '09:00:00', '17:00:00', 1, 'Weekday availability', '2025-09-28 21:39:00', '2025-09-28 21:39:00'),
(4, 8, 'Thursday', '09:00:00', '17:00:00', 1, 'Weekday availability', '2025-09-28 21:39:00', '2025-09-28 21:39:00'),
(5, 8, 'Friday', '09:00:00', '17:00:00', 1, 'Weekday availability', '2025-09-28 21:39:00', '2025-09-28 21:39:00'),
(6, 8, 'Saturday', '10:00:00', '14:00:00', 1, 'Half-day weekend', '2025-09-28 21:39:00', '2025-09-28 21:39:00'),
(7, 8, 'Sunday', '00:00:00', '00:00:00', 0, 'Closed', '2025-09-28 21:39:00', '2025-09-28 21:39:00'),
(8, 8, 'Monday', '09:00:00', '17:00:00', 1, 'Weekday availability', '2025-09-28 21:39:08', '2025-09-28 21:39:08'),
(9, 8, 'Tuesday', '09:00:00', '17:00:00', 1, 'Weekday availability', '2025-09-28 21:39:08', '2025-09-28 21:39:08'),
(10, 8, 'Wednesday', '09:00:00', '17:00:00', 1, 'Weekday availability', '2025-09-28 21:39:08', '2025-09-28 21:39:08'),
(11, 8, 'Thursday', '09:00:00', '17:00:00', 1, 'Weekday availability', '2025-09-28 21:39:08', '2025-09-28 21:39:08'),
(12, 8, 'Friday', '09:00:00', '17:00:00', 1, 'Weekday availability', '2025-09-28 21:39:08', '2025-09-28 21:39:08'),
(13, 8, 'Saturday', '10:00:00', '14:00:00', 1, 'Half-day weekend', '2025-09-28 21:39:08', '2025-09-28 21:39:08'),
(14, 8, 'Sunday', '00:00:00', '00:00:00', 0, 'Closed', '2025-09-28 21:39:08', '2025-09-28 21:39:08');

-- --------------------------------------------------------

--
-- Table structure for table `favoritecarstbl`
--

CREATE TABLE `favoritecarstbl` (
  `favoriteid` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `carid` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `feedbacktbl`
--

CREATE TABLE `feedbacktbl` (
  `feedbackid` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `carid` int(11) DEFAULT NULL,
  `ownerid` int(11) DEFAULT NULL,
  `rating` int(11) NOT NULL CHECK (`rating` between 1 and 5),
  `title` varchar(100) DEFAULT NULL,
  `comment` text DEFAULT NULL,
  `media_url` varchar(255) DEFAULT NULL,
  `status` enum('visible','hidden','flagged','pending') DEFAULT 'visible',
  `approved_by` int(11) DEFAULT NULL,
  `admin_reply` text DEFAULT NULL,
  `reply_date` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mediatbl`
--

CREATE TABLE `mediatbl` (
  `mediaid` int(11) NOT NULL,
  `carid` int(11) DEFAULT NULL,
  `uploaded_by` int(11) DEFAULT NULL,
  `media_type` enum('image','video') NOT NULL,
  `title` varchar(150) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `media_url` varchar(255) NOT NULL,
  `thumbnail_url` varchar(255) DEFAULT NULL,
  `mime_type` varchar(50) DEFAULT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  `duration_seconds` int(11) DEFAULT NULL,
  `tags` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `mediatbl`
--

INSERT INTO `mediatbl` (`mediaid`, `carid`, `uploaded_by`, `media_type`, `title`, `description`, `media_url`, `thumbnail_url`, `mime_type`, `file_size`, `duration_seconds`, `tags`, `created_at`, `updated_at`) VALUES
(6, 8, NULL, 'image', NULL, NULL, 'uploads/images/img_68d96a663c3b77.83690413.jpg', NULL, 'image/jpeg', 41401, NULL, NULL, '2025-09-28 17:03:34', '2025-09-28 17:03:34'),
(7, 8, NULL, 'image', NULL, NULL, 'uploads/images/img_68d96a663cb610.72027903.jpg', NULL, 'image/jpeg', 35642, NULL, NULL, '2025-09-28 17:03:34', '2025-09-28 17:03:34'),
(8, 9, NULL, 'image', NULL, NULL, 'uploads/images/img_68d96aba7f51c2.77637322.jpg', NULL, 'image/jpeg', 9688, NULL, NULL, '2025-09-28 17:04:58', '2025-09-28 17:04:58'),
(9, 9, NULL, 'image', NULL, NULL, 'uploads/images/img_68d96aba7fb2d9.10487218.jpg', NULL, 'image/jpeg', 10248, NULL, NULL, '2025-09-28 17:04:58', '2025-09-28 17:04:58');

-- --------------------------------------------------------

--
-- Table structure for table `paymenttbl`
--

CREATE TABLE `paymenttbl` (
  `paymentid` int(11) NOT NULL,
  `rentalid` int(11) NOT NULL,
  `userid` int(11) DEFAULT NULL,
  `processed_by_admin` int(11) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` char(3) DEFAULT 'PHP',
  `payment_method` enum('GCash','PayMaya','Credit Card','Debit Card','Bank Transfer','Cash') DEFAULT 'Cash',
  `payment_status` enum('pending','completed','failed','refunded','disputed') DEFAULT 'pending',
  `payment_type` enum('full','partial','refund') DEFAULT 'full',
  `transaction_id` varchar(100) DEFAULT NULL,
  `gateway_fee` decimal(10,2) DEFAULT NULL,
  `net_amount` decimal(10,2) GENERATED ALWAYS AS (`amount` - ifnull(`gateway_fee`,0)) STORED,
  `remarks` text DEFAULT NULL,
  `receipt_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `paymenttbl`
--

INSERT INTO `paymenttbl` (`paymentid`, `rentalid`, `userid`, `processed_by_admin`, `amount`, `currency`, `payment_method`, `payment_status`, `payment_type`, `transaction_id`, `gateway_fee`, `remarks`, `receipt_url`, `created_at`, `updated_at`) VALUES
(1, 14, 5, 1, 12000.00, 'PHP', 'GCash', 'completed', 'full', NULL, NULL, NULL, NULL, '2025-09-29 06:37:00', '2025-09-29 06:37:00');

-- --------------------------------------------------------

--
-- Table structure for table `pricetbl`
--

CREATE TABLE `pricetbl` (
  `priceid` int(11) NOT NULL,
  `carid` int(11) NOT NULL,
  `currency` char(3) DEFAULT 'PHP',
  `hourly_rate` decimal(10,2) DEFAULT NULL,
  `daily_rate` decimal(10,2) DEFAULT NULL,
  `weekly_rate` decimal(10,2) DEFAULT NULL,
  `monthly_rate` decimal(10,2) DEFAULT NULL,
  `seasonal` tinyint(1) DEFAULT 0,
  `promo_code` varchar(50) DEFAULT NULL,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `valid_from` date DEFAULT NULL,
  `valid_to` date DEFAULT NULL,
  `set_by_admin` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pricetbl`
--

INSERT INTO `pricetbl` (`priceid`, `carid`, `currency`, `hourly_rate`, `daily_rate`, `weekly_rate`, `monthly_rate`, `seasonal`, `promo_code`, `discount_percent`, `valid_from`, `valid_to`, `set_by_admin`, `created_at`, `updated_at`) VALUES
(6, 8, 'PHP', NULL, 4000.00, 10000.00, 15000.00, 0, 'NEWCAR', 20.00, NULL, NULL, NULL, '2025-09-28 17:03:34', '2025-09-28 17:03:34'),
(7, 9, 'PHP', NULL, 4000.00, 10000.00, 15000.00, 0, 'CAR', 10.00, NULL, NULL, NULL, '2025-09-28 17:04:58', '2025-09-28 17:04:58');

-- --------------------------------------------------------

--
-- Table structure for table `rentaltbl`
--

CREATE TABLE `rentaltbl` (
  `rentalid` int(11) NOT NULL,
  `carid` int(11) NOT NULL,
  `userid` int(11) NOT NULL,
  `ownerid` int(11) DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `rental_type` enum('self-drive','with-driver') DEFAULT 'self-drive',
  `start_date` date NOT NULL,
  `start_time` time DEFAULT NULL,
  `end_date` date NOT NULL,
  `end_time` time DEFAULT NULL,
  `pickup_location` varchar(150) DEFAULT NULL,
  `dropoff_location` varchar(150) DEFAULT NULL,
  `daily_rate` decimal(10,2) DEFAULT NULL,
  `total_days` int(11) DEFAULT NULL,
  `total_amount` decimal(10,2) DEFAULT NULL,
  `security_deposit` decimal(10,2) DEFAULT 0.00,
  `mileage_limit` int(11) DEFAULT NULL,
  `overage_fee_per_km` decimal(10,2) DEFAULT NULL,
  `status` enum('pending','confirmed','ongoing','completed','cancelled') DEFAULT 'pending',
  `cancellation_reason` text DEFAULT NULL,
  `cancelled_by` enum('user','admin','system') DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `admin_notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rentaltbl`
--

INSERT INTO `rentaltbl` (`rentalid`, `carid`, `userid`, `ownerid`, `approved_by`, `rental_type`, `start_date`, `start_time`, `end_date`, `end_time`, `pickup_location`, `dropoff_location`, `daily_rate`, `total_days`, `total_amount`, `security_deposit`, `mileage_limit`, `overage_fee_per_km`, `status`, `cancellation_reason`, `cancelled_by`, `cancelled_at`, `admin_notes`, `created_at`, `updated_at`) VALUES
(11, 9, 5, NULL, 1, 'self-drive', '2025-10-01', '08:30:00', '2025-10-03', '00:00:22', 'gensan', 'davao', NULL, NULL, 12000.00, 0.00, NULL, NULL, 'cancelled', 'The Car is under  Maintenance', 'admin', '2025-09-29 05:58:01', NULL, '2025-09-28 22:05:46', '2025-09-29 06:54:30'),
(12, 9, 5, NULL, 1, 'self-drive', '2025-09-29', '06:30:00', '2025-10-01', '00:00:06', 'gensan', 'davao', NULL, NULL, 12000.00, 0.00, NULL, NULL, 'ongoing', NULL, NULL, NULL, NULL, '2025-09-29 06:30:41', '2025-09-29 06:31:49'),
(14, 8, 5, NULL, 1, 'self-drive', '2025-09-25', '09:00:00', '2025-09-27', '18:00:00', 'General Santos City', 'Davao City', 4000.00, 3, 12000.00, 0.00, NULL, NULL, 'completed', NULL, NULL, NULL, NULL, '2025-09-29 06:37:00', '2025-09-29 06:37:00'),
(15, 9, 6, NULL, 1, 'self-drive', '2025-10-03', '04:42:00', '2025-10-05', '00:00:04', 'Gensan', 'Davao', NULL, NULL, 12000.00, 0.00, NULL, NULL, 'cancelled', 'in-maintenance', 'admin', NULL, NULL, '2025-09-30 04:42:57', '2025-09-30 07:01:54');

-- --------------------------------------------------------

--
-- Table structure for table `usertbl`
--

CREATE TABLE `usertbl` (
  `userid` int(11) NOT NULL,
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
  `role` enum('admin','Mananger','user','guest') DEFAULT 'user',
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `usertbl`
--

INSERT INTO `usertbl` (`userid`, `username`, `email`, `bcrypt`, `first_name`, `last_name`, `gender`, `birthdate`, `phone_number`, `profile_picture`, `street_address`, `city`, `state`, `postal_code`, `country`, `role`, `status`, `is_verified`, `language`, `timezone`, `dark_mode`, `last_login`, `last_ip_address`, `login_attempts`, `two_factor_enabled`, `created_at`, `updated_at`) VALUES
(5, 'john', 'john@gmail.com', '$2y$10$A5L9JN9VXkY4vurLXKXMROOk2l4s0sAmIRTyFu.x4gZdLLwE0StZe', 'John Marc', 'Goite', 'Male', '2001-11-01', '09275267118', NULL, 'Banate', 'Malungon', 'Sarangani', '9503', 'Philippines', 'user', 'active', 0, 'en', 'UTC', 0, '2025-09-29 15:21:24', '127.0.0.1', 0, 0, '2025-09-28 16:47:15', '2025-09-29 07:21:24'),
(6, 'francis', 'francis@gmail.com', '$2y$10$GCupXShyWzCxqRJG/zeJGOjh1cAdVs9MgVbcl/DoT1..fFB/6WoMe', 'francis Lorenzo', 'Cagaoan', 'Male', '2004-09-30', '09700923983', NULL, 'Gensan', 'Gensan', 'South Cotabato', '9500', 'Philippines', 'user', 'active', 0, 'en', 'UTC', 0, '2025-09-30 14:59:08', '127.0.0.1', 0, 0, '2025-09-30 04:41:40', '2025-09-30 06:59:08');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admintbl`
--
ALTER TABLE `admintbl`
  ADD PRIMARY KEY (`adminid`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `cartbl`
--
ALTER TABLE `cartbl`
  ADD PRIMARY KEY (`carid`);

--
-- Indexes for table `car_schedule`
--
ALTER TABLE `car_schedule`
  ADD PRIMARY KEY (`schedule_id`),
  ADD KEY `carid` (`carid`);

--
-- Indexes for table `favoritecarstbl`
--
ALTER TABLE `favoritecarstbl`
  ADD PRIMARY KEY (`favoriteid`),
  ADD UNIQUE KEY `uniq_user_car` (`userid`,`carid`),
  ADD KEY `idx_user` (`userid`),
  ADD KEY `idx_car` (`carid`);

--
-- Indexes for table `feedbacktbl`
--
ALTER TABLE `feedbacktbl`
  ADD PRIMARY KEY (`feedbackid`),
  ADD KEY `userid` (`userid`),
  ADD KEY `carid` (`carid`),
  ADD KEY `ownerid` (`ownerid`),
  ADD KEY `approved_by` (`approved_by`);

--
-- Indexes for table `mediatbl`
--
ALTER TABLE `mediatbl`
  ADD PRIMARY KEY (`mediaid`),
  ADD KEY `carid` (`carid`),
  ADD KEY `uploaded_by` (`uploaded_by`);

--
-- Indexes for table `paymenttbl`
--
ALTER TABLE `paymenttbl`
  ADD PRIMARY KEY (`paymentid`),
  ADD KEY `rentalid` (`rentalid`),
  ADD KEY `userid` (`userid`),
  ADD KEY `processed_by_admin` (`processed_by_admin`);

--
-- Indexes for table `pricetbl`
--
ALTER TABLE `pricetbl`
  ADD PRIMARY KEY (`priceid`),
  ADD KEY `carid` (`carid`),
  ADD KEY `set_by_admin` (`set_by_admin`);

--
-- Indexes for table `rentaltbl`
--
ALTER TABLE `rentaltbl`
  ADD PRIMARY KEY (`rentalid`),
  ADD KEY `carid` (`carid`),
  ADD KEY `userid` (`userid`),
  ADD KEY `ownerid` (`ownerid`),
  ADD KEY `approved_by` (`approved_by`);

--
-- Indexes for table `usertbl`
--
ALTER TABLE `usertbl`
  ADD PRIMARY KEY (`userid`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `phone_number` (`phone_number`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admintbl`
--
ALTER TABLE `admintbl`
  MODIFY `adminid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `cartbl`
--
ALTER TABLE `cartbl`
  MODIFY `carid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `car_schedule`
--
ALTER TABLE `car_schedule`
  MODIFY `schedule_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `favoritecarstbl`
--
ALTER TABLE `favoritecarstbl`
  MODIFY `favoriteid` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `feedbacktbl`
--
ALTER TABLE `feedbacktbl`
  MODIFY `feedbackid` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mediatbl`
--
ALTER TABLE `mediatbl`
  MODIFY `mediaid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `paymenttbl`
--
ALTER TABLE `paymenttbl`
  MODIFY `paymentid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `pricetbl`
--
ALTER TABLE `pricetbl`
  MODIFY `priceid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `rentaltbl`
--
ALTER TABLE `rentaltbl`
  MODIFY `rentalid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `usertbl`
--
ALTER TABLE `usertbl`
  MODIFY `userid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `car_schedule`
--
ALTER TABLE `car_schedule`
  ADD CONSTRAINT `car_schedule_ibfk_1` FOREIGN KEY (`carid`) REFERENCES `cartbl` (`carid`) ON DELETE CASCADE;

--
-- Constraints for table `favoritecarstbl`
--
ALTER TABLE `favoritecarstbl`
  ADD CONSTRAINT `favoritecarstbl_car_fk` FOREIGN KEY (`carid`) REFERENCES `cartbl` (`carid`) ON DELETE CASCADE,
  ADD CONSTRAINT `favoritecarstbl_user_fk` FOREIGN KEY (`userid`) REFERENCES `usertbl` (`userid`) ON DELETE CASCADE;

--
-- Constraints for table `feedbacktbl`
--
ALTER TABLE `feedbacktbl`
  ADD CONSTRAINT `feedbacktbl_ibfk_1` FOREIGN KEY (`userid`) REFERENCES `usertbl` (`userid`),
  ADD CONSTRAINT `feedbacktbl_ibfk_2` FOREIGN KEY (`carid`) REFERENCES `cartbl` (`carid`),
  ADD CONSTRAINT `feedbacktbl_ibfk_3` FOREIGN KEY (`ownerid`) REFERENCES `usertbl` (`userid`),
  ADD CONSTRAINT `feedbacktbl_ibfk_4` FOREIGN KEY (`approved_by`) REFERENCES `admintbl` (`adminid`);

--
-- Constraints for table `mediatbl`
--
ALTER TABLE `mediatbl`
  ADD CONSTRAINT `mediatbl_ibfk_1` FOREIGN KEY (`carid`) REFERENCES `cartbl` (`carid`),
  ADD CONSTRAINT `mediatbl_ibfk_2` FOREIGN KEY (`uploaded_by`) REFERENCES `usertbl` (`userid`);

--
-- Constraints for table `paymenttbl`
--
ALTER TABLE `paymenttbl`
  ADD CONSTRAINT `paymenttbl_ibfk_1` FOREIGN KEY (`rentalid`) REFERENCES `rentaltbl` (`rentalid`),
  ADD CONSTRAINT `paymenttbl_ibfk_2` FOREIGN KEY (`userid`) REFERENCES `usertbl` (`userid`),
  ADD CONSTRAINT `paymenttbl_ibfk_3` FOREIGN KEY (`processed_by_admin`) REFERENCES `admintbl` (`adminid`);

--
-- Constraints for table `pricetbl`
--
ALTER TABLE `pricetbl`
  ADD CONSTRAINT `pricetbl_ibfk_1` FOREIGN KEY (`carid`) REFERENCES `cartbl` (`carid`),
  ADD CONSTRAINT `pricetbl_ibfk_2` FOREIGN KEY (`set_by_admin`) REFERENCES `admintbl` (`adminid`);

--
-- Constraints for table `rentaltbl`
--
ALTER TABLE `rentaltbl`
  ADD CONSTRAINT `rentaltbl_ibfk_1` FOREIGN KEY (`carid`) REFERENCES `cartbl` (`carid`),
  ADD CONSTRAINT `rentaltbl_ibfk_2` FOREIGN KEY (`userid`) REFERENCES `usertbl` (`userid`),
  ADD CONSTRAINT `rentaltbl_ibfk_3` FOREIGN KEY (`ownerid`) REFERENCES `usertbl` (`userid`),
  ADD CONSTRAINT `rentaltbl_ibfk_4` FOREIGN KEY (`approved_by`) REFERENCES `admintbl` (`adminid`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
