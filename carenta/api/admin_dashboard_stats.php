<?php
// api/admin_dashboard_summary.php
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
    // ✅ Count total users
    $users = $pdo->query("SELECT COUNT(*) AS total FROM usertbl")->fetch(PDO::FETCH_ASSOC);

    // ✅ Count total cars
    $cars = $pdo->query("SELECT COUNT(*) AS total FROM cartbl")->fetch(PDO::FETCH_ASSOC);

    // ✅ Count total rentals (bookings)
    $bookings = $pdo->query("SELECT COUNT(*) AS total FROM rentaltbl")->fetch(PDO::FETCH_ASSOC);

    // ✅ Sum revenue from completed rentals
    $revenue = $pdo->query("
        SELECT IFNULL(SUM(total_amount), 0) AS total
        FROM rentaltbl
        WHERE status = 'completed'
    ")->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data" => [
            "total_users"    => (int)($users['total'] ?? 0),
            "total_cars"     => (int)($cars['total'] ?? 0),
            "total_bookings" => (int)($bookings['total'] ?? 0),
            "total_revenue"  => (float)($revenue['total'] ?? 0.0),
        ]
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Server error: " . $e->getMessage()
    ]);
}
?>
