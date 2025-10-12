<?php
header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");

$host = "localhost";
$user = "root";
$pass = "";
$db   = "carentadb";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["ok" => false, "error" => $conn->connect_error]);
    exit;
}

$carid = isset($_GET['carid']) ? (int)$_GET['carid'] : 0;
if ($carid <= 0) {
    http_response_code(400);
    echo json_encode(["ok" => false, "error" => "Missing carid"]);
    exit;
}

$sql = "SELECT available_day, start_time, end_time, is_available
        FROM car_schedule
        WHERE carid = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $carid);
$stmt->execute();
$res = $stmt->get_result();

$data = [];
while ($row = $res->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode(["ok" => true, "schedule" => $data]);
$conn->close();
