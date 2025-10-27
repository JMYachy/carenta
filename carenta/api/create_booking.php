<?php
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") { http_response_code(204); exit; }

require_once "connection_service.php";

try {
    $carId = isset($_POST['carid']) ? (int) $_POST['carid'] : 0;
    $userId = isset($_POST['userid']) ? (int) $_POST['userid'] : 0;
    $startDate = trim($_POST['start_date'] ?? '');
    $endDate = trim($_POST['end_date'] ?? '');
    $startTime = trim($_POST['start_time'] ?? '00:00');
    $endTime = trim($_POST['end_time'] ?? '00:00');
    $pickup = trim($_POST['pickup_location'] ?? '-');
    $dropoff = trim($_POST['dropoff_location'] ?? '-');
    $totalAmount = isset($_POST['total_amount']) ? (float) $_POST['total_amount'] : 0;

    if ($carId <= 0 || $userId <= 0 || !$startDate || !$endDate) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Missing required fields"]);
        exit;
    }

    // ✅ Step 1: Check overlapping bookings (ignore cancelled or completed)
    $sqlCheck = "
        SELECT COUNT(*) AS cnt 
        FROM rentaltbl 
        WHERE carid = ? 
        AND status NOT IN ('Cancelled', 'Completed') 
        AND (
            (start_date <= ? AND end_date >= ?) OR
            (start_date <= ? AND end_date >= ?)
        )";
    $stmt = $pdo->prepare($sqlCheck);
    $stmt->execute([$carId, $endDate, $startDate, $startDate, $endDate]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row && $row['cnt'] > 0) {
        echo json_encode(["success" => false, "message" => "Car is not available on selected dates"]);
        exit;
    }

    // ✅ Step  2I nsert booking
    $sql = "INSERT INTO rentaltbl
            (carid, userid, start_date, start_time, end_date, end_time, pickup_location, dropoff_location, total_amount, status, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending', NOW())";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$carId, $userId, $startDate, $startTime, $endDate, $endTime, $pickup, $dropoff, $totalAmount]);

    $rentalId = $pdo->lastInsertId();

    echo json_encode([
        "success" => true,
        "message" => "Booking created successfully",
        "rental_id" => (int)$rentalId,
        "carid" => (int)$carId,
        "userid" => (int)$userId,
        "start_date" => $startDate,
        "end_date" => $endDate,
        "pickup_location" => $pickup,
        "dropoff_location" => $dropoff,
        "total_amount" => $totalAmount,
        "status" => "Pending"
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Server error: " . $e->getMessage(),
        "file" => basename(__FILE__)
    ]);
}
