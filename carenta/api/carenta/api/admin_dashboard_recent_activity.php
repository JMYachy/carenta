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

    // Latest 10 activities
    $stmt = $conn->prepare("
        SELECT r.rentalid, r.status, r.updated_at, r.created_at,
               c.model AS car_model, u.username
        FROM rentaltbl r
        JOIN cartbl c ON r.carid = c.carid
        JOIN usertbl u ON r.userid = u.userid
        ORDER BY COALESCE(r.updated_at, r.created_at) DESC
        LIMIT 10
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format activity string
    foreach ($rows as &$row) {
        $ts = $row["updated_at"] ?? $row["created_at"];
        $row["timestamp"] = date("Y-m-d H:i", strtotime($ts));
        $row["activity"] = "{$row['username']} {$row['status']} rental for {$row['car_model']}";
    }

    echo json_encode([
        "status" => "success",
        "data" => $rows
    ]);

} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
