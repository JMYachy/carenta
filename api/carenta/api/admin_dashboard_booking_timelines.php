<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$host = "localhost";
$dbname = "carentadb";
$dbuser = "root"; 
$dbpass = "";

try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $dbuser, $dbpass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Today's bookings
    $stmt = $conn->prepare("
        SELECT r.rentalid, r.start_date, r.end_date, r.status, r.total_amount,
               c.model AS car_model, c.manufacturer,
               u.username
        FROM rentaltbl r
        JOIN cartbl c ON r.carid = c.carid
        JOIN usertbl u ON r.userid = u.userid
        WHERE DATE(r.start_date) = CURDATE()
        ORDER BY r.start_date ASC
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // format times (hh:mm AM/PM)
    foreach ($rows as &$row) {
        $row["time"] = date("h:i A", strtotime($row["start_date"]));
    }

    echo json_encode([
        "status" => "success",
        "data" => $rows
    ]);

} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
