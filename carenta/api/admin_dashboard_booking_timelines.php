<?php
// api/admin_dashboard_booking_timelines.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

ini_set('display_errors', '0');
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

/* ---- DB CONNECTION ---- */
require_once __DIR__ . '/connection_service.php';

try {
    // ✅ Get today’s bookings (start date = current date)
    $stmt = $pdo->prepare("
        SELECT 
            r.rentalid,
            r.start_date,
            r.end_date,
            r.start_time,
            r.end_time,
            r.status,
            r.total_amount,
            c.model AS car_model,
            c.manufacturer,
            u.username
        FROM rentaltbl r
        JOIN cartbl c ON r.carid = c.carid
        JOIN usertbl u ON r.userid = u.userid
        WHERE DATE(r.start_date) = CURDATE()
        ORDER BY r.start_date ASC, r.start_time ASC
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // ✅ Format times (hh:mm AM/PM)
    foreach ($rows as &$row) {
        $timeValue = $row["start_time"] ?? $row["start_date"];
        $row["time"] = date("h:i A", strtotime($timeValue ?? '00:00:00'));
    }

    echo json_encode([
        "status" => "success",
        "data" => $rows
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
