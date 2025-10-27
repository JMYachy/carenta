<?php
// api/admin_dashboard_counts.php
header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");
ini_set('display_errors', '0');
error_reporting(E_ALL);

/* ---- DB Connection ---- */
require_once __DIR__ . '/connection_service.php';

try {
    // ===============================
    // CAR STATUS COUNTS
    // ===============================
    $carStatuses = [
        "Available"         => 0,
        "Ongoing Rentals"   => 0,
        "Under Maintenance" => 0,
    ];

    // Cars currently in ongoing rentals
    $sqlOngoing = "
        SELECT COUNT(DISTINCT r.carid) AS cnt
        FROM rentaltbl r
        WHERE r.status = 'ongoing'
    ";
    $carStatuses["Ongoing Rentals"] =
        (int) $pdo->query($sqlOngoing)->fetchColumn();

    // Cars under maintenance
    $sqlMaint = "
        SELECT COUNT(*) AS cnt
        FROM cartbl
        WHERE status IN ('maintenance','under maintenance')
    ";
    $carStatuses["Under Maintenance"] =
        (int) $pdo->query($sqlMaint)->fetchColumn();

    // Available cars (not ongoing / maintenance)
    $sqlAvail = "
        SELECT COUNT(*) AS cnt
        FROM cartbl c
        WHERE c.status = 'available'
          AND c.carid NOT IN (
              SELECT carid FROM rentaltbl WHERE status = 'ongoing'
          )
    ";
    $carStatuses["Available"] =
        (int) $pdo->query($sqlAvail)->fetchColumn();

    // ===============================
    // RENTAL STATUS COUNTS
    // ===============================
    $rentalStatuses = [
        "Pending"   => 0,
        "Confirmed" => 0,
        "Ongoing"   => 0,
        "Completed" => 0,
        "Cancelled" => 0,
    ];

    $sqlRental = "SELECT status, COUNT(*) AS count FROM rentaltbl GROUP BY status";
    foreach ($pdo->query($sqlRental, PDO::FETCH_ASSOC) as $row) {
        $status = ucfirst(strtolower($row['status'] ?? ''));
        if (array_key_exists($status, $rentalStatuses)) {
            $rentalStatuses[$status] = (int) $row['count'];
        }
    }

    echo json_encode([
        "ok"      => true,
        "cars"    => $carStatuses,
        "rentals" => $rentalStatuses
    ], JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "ok" => false,
        "error" => "SERVER_ERROR",
        "message" => $e->getMessage()
    ]);
}
?>
