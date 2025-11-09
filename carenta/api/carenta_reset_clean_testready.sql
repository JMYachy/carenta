-- ==========================================================
-- Carenta Test-Ready Database Reset (PayMongo Integrated)
-- Author: ChatGPT Carenta Project
-- Date: 2025-11-07
-- Description:
--   - Drops only processed_by column from paymenttbl
--   - Truncates all data (except admin, manager, cars, prices, media)
--   - Resets AUTO_INCREMENT to start clean at 1
-- ==========================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ⚙️ Structural Fix: Remove deprecated column
ALTER TABLE `paymenttbl`
  DROP COLUMN IF EXISTS `processed_by`;

-- 🧹 Truncate all non-essential data
TRUNCATE TABLE `drivertbl`;
TRUNCATE TABLE `favoritecarstbl`;
TRUNCATE TABLE `feedbacktbl`;
TRUNCATE TABLE `messagestbl`;
TRUNCATE TABLE `notificationtbl`;
TRUNCATE TABLE `paymenttbl`;
TRUNCATE TABLE `receipttbl`;
TRUNCATE TABLE `rentaltbl`;
TRUNCATE TABLE `rental_cancellation_requesttbl`;
TRUNCATE TABLE `user_verificationtbl`;

-- 🧍 Reset user table but keep 1 test renter
TRUNCATE TABLE `usertbl`;
INSERT INTO `usertbl`
(`userid`, `username`, `email`, `bcrypt`, `first_name`, `last_name`, `phone_number`, `city`, `country`, `role`, `status`, `is_verified`)
VALUES
(1, 'testuser', 'testuser@example.com', 
 '$2y$10$7pJPfOMrPTI1PFSauph9/OdZM8WRZgdjihvPFk2odq7oRg5lbwBOG', 
 'Test', 'User', '+639999999999', 'Gensan', 'Philippines', 
 'renter', 'active', 1);

-- 🧾 Keep admin and manager intact
DELETE FROM `admintbl`;
INSERT INTO `admintbl` 
(`adminid`, `username`, `email`, `bcrypt`, `first_name`, `last_name`, `role`, `status`, `phone_number`, `created_at`, `updated_at`)
VALUES
(1, 'superadmin', 'superadmin@example.com',
 '$2y$10$Tkyy7U94rAGwvX5fwNjhFeKWZNgRF7eXIxbB11t7LODI/jk6roEOa',
 'Super', 'Admin', 'admin', 'active', '09171234567', NOW(), NOW()),
(2, 'manager', 'manager@example.com',
 '$2y$10$a8uHH2pGgfcTpuTpAFpRUOIxFc74k4GYO8T7dLOrzyL75CAJrgg72',
 'Daniel', 'Tapic', 'manager', 'active', '09112233445', NOW(), NOW());

-- 🚗 Keep core cars and their media
DELETE FROM `cartbl`;
INSERT INTO `cartbl`
(`carid`, `year`, `manufacturer`, `model`, `type`, `license_plate`, `color`, `transmission`, `fueltype`, `milage`, `seatingcap`, `status`, `created_at`, `updated_at`, `withDriver`)
VALUES
(1, '2019', 'Mitsubishi', 'Montero Sport', 'SUV', 'ABC-123', 'White', 'Automatic', 'Diesel', '35000', '7', 'available', NOW(), NOW(), 'No'),
(2, '2023', 'Toyota', 'Hilux', 'Pickup', 'ABC-987', 'Silver', 'Automatic', 'Gasoline', '25000', '5', 'available', NOW(), NOW(), 'No'),
(3, '2022', 'Toyota', 'Vios', 'Sedan', 'ABC-321', 'Red', 'Automatic', 'Gasoline', '2500', '4', 'available', NOW(), NOW(), 'No');

DELETE FROM `pricetbl`;
INSERT INTO `pricetbl`
(`priceid`, `carid`, `currency`, `daily_rate`, `min_days_for_promo1`, `promo1_discount_percent`, `min_days_for_promo2`, `promo2_discount_percent`, `min_days_for_promo3`, `promo3_discount_percent`, `created_at`, `updated_at`)
VALUES
(1, 1, 'PHP', 1000.00, 3, 10.00, 7, 15.00, 30, 20.00, NOW(), NOW()),
(2, 2, 'PHP', 2500.00, 3, 10.00, 7, 15.00, 30, 20.00, NOW(), NOW()),
(3, 3, 'PHP', 1000.00, 3, 5.00, 7, 10.00, 30, 15.00, NOW(), NOW());

DELETE FROM `mediatbl`;
INSERT INTO `mediatbl`
(`mediaid`, `carid`, `media_type`, `media_url`, `mime_type`, `file_size`, `created_at`, `updated_at`)
VALUES
(1, 1, 'image', 'uploads/images/montero1.jpg', 'image/jpeg', 35000, NOW(), NOW()),
(2, 2, 'image', 'uploads/images/hilux1.jpg', 'image/jpeg', 35000, NOW(), NOW()),
(3, 3, 'image', 'uploads/images/vios1.jpg', 'image/jpeg', 35000, NOW(), NOW());

-- 🔢 Reset all AUTO_INCREMENT counters
ALTER TABLE `admintbl` AUTO_INCREMENT = 3;
ALTER TABLE `cartbl` AUTO_INCREMENT = 4;
ALTER TABLE `drivertbl` AUTO_INCREMENT = 1;
ALTER TABLE `favoritecarstbl` AUTO_INCREMENT = 1;
ALTER TABLE `feedbacktbl` AUTO_INCREMENT = 1;
ALTER TABLE `mediatbl` AUTO_INCREMENT = 4;
ALTER TABLE `messagestbl` AUTO_INCREMENT = 1;
ALTER TABLE `notificationtbl` AUTO_INCREMENT = 1;
ALTER TABLE `paymenttbl` AUTO_INCREMENT = 1;
ALTER TABLE `pricetbl` AUTO_INCREMENT = 4;
ALTER TABLE `receipttbl` AUTO_INCREMENT = 1;
ALTER TABLE `rentaltbl` AUTO_INCREMENT = 1;
ALTER TABLE `rental_cancellation_requesttbl` AUTO_INCREMENT = 1;
ALTER TABLE `usertbl` AUTO_INCREMENT = 2;
ALTER TABLE `user_verificationtbl` AUTO_INCREMENT = 1;

SET FOREIGN_KEY_CHECKS = 1;

SELECT '✅ Carenta database reset complete — clean and test-ready (PayMongo integrated)' AS status_message;
