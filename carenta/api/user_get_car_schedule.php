<?php
// api/user_get_car_schedule.php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

ini_set('display_errors', '0');
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

/* ---- DB CONNECTION ---- */
require_once __DIR__ . '/connection_service.php';

try {
    $carId = isset($_GET['carid']) ? (int)$_GET['carid'] : 0;

    // ✅ Validate input
    if ($carId <= 0) {
        http_response_code(400);
        echo json_encode([
            "ok" => false,
            "error" => "BAD_REQUEST",
            "message" => "Missing or invalid carid"
        ]);
        exit;
    }

    // ✅ Fetch car schedule
    $stmt = $pdo->prepare("
        SELECT 
            available_day, 
            start_time, 
            end_time, 
            is_available, 
            notes
        FROM car_schedule
        WHERE carid = :carid
        ORDER BY FIELD(available_day, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')
    ");
    $stmt->execute([':carid' => $carId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // ✅ Normalize data
    $schedule = [];
    foreach ($rows as $row) {
        $schedule[] = [
            "day" => $row['available_day'],
            "start_time" => $row['start_time'],
            "end_time" => $row['end_time'],
            "is_available" => (int)$row['is_available'],
            "notes" => $row['notes'] ?? null,
        ];
    }

    echo json_encode([
        "ok" => true,
        "schedule" => $schedule
    ], JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "ok" => false,
        "error" => "SERVER_ERROR",
        "message" => $e->getMessage()
    ]);
}
?>
