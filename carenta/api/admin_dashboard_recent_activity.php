<?php
// api/admin_dashboard_recent_activity.php
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
    // ✅ Fetch latest 10 rental activities
    $stmt = $pdo->prepare("
        SELECT 
            r.rentalid,
            r.status,
            r.updated_at,
            r.created_at,
            c.model AS car_model,
            c.manufacturer,
            u.username
        FROM rentaltbl r
        JOIN cartbl c ON r.carid = c.carid
        JOIN usertbl u ON r.userid = u.userid
        ORDER BY COALESCE(r.updated_at, r.created_at) DESC
        LIMIT 10
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // ✅ Format timestamps and human-readable activity messages
    foreach ($rows as &$row) {
        $ts = $row["updated_at"] ?? $row["created_at"];
        $row["timestamp"] = date("Y-m-d H:i", strtotime($ts ?? 'now'));
        $status = ucfirst(strtolower($row["status"] ?? "updated"));
        $user = $row["username"] ?? "Unknown user";
        $car = trim(($row["manufacturer"] ?? "") . " " . ($row["car_model"] ?? ""));
        $row["activity"] = "$user $status rental for $car";
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
