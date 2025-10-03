<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// DB connection
$host = "localhost";
$dbname = "carentadb";
$dbuser = "root"; 
$dbpass = "";

try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $dbuser, $dbpass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Count total users
    $users = $conn->query("SELECT COUNT(*) as total FROM usertbl")->fetch(PDO::FETCH_ASSOC);

    // Count total cars
    $cars = $conn->query("SELECT COUNT(*) as total FROM cartbl")->fetch(PDO::FETCH_ASSOC);

    // Count total rentals (bookings)
    $bookings = $conn->query("SELECT COUNT(*) as total FROM rentaltbl")->fetch(PDO::FETCH_ASSOC);

    // Sum revenue from completed rentals
    $revenue = $conn->query("
        SELECT IFNULL(SUM(total_amount),0) as total 
        FROM rentaltbl 
        WHERE status = 'completed'
    ")->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => [
            "total_users"    => intval($users['total']),
            "total_cars"     => intval($cars['total']),
            "total_bookings" => intval($bookings['total']),
            "total_revenue"  => floatval($revenue['total']),
        ]
    ]);

} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => "Database error: " . $e->getMessage()
    ]);
}
