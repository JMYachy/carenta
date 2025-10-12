<?php
header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");
ini_set('display_errors', '0');

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

// ===============================
// CAR STATUS COUNTS
// ===============================
$carStatuses = [
    "Available"         => 0,
    "Ongoing Rentals"   => 0,
    "Under Maintenance" => 0,
];

/**
 * Count cars that are in ongoing rentals
 */
$sqlOngoing = "
    SELECT COUNT(DISTINCT r.carid) AS cnt
    FROM rentaltbl r
    WHERE r.status = 'ongoing'
";
$resOngoing = $conn->query($sqlOngoing);
if ($resOngoing && $row = $resOngoing->fetch_assoc()) {
    $carStatuses["Ongoing Rentals"] = (int)$row['cnt'];
}

/**
 * Count cars under maintenance
 */
$sqlMaint = "SELECT COUNT(*) AS cnt FROM cartbl WHERE status IN ('maintenance','under maintenance')";
$resMaint = $conn->query($sqlMaint);
if ($resMaint && $row = $resMaint->fetch_assoc()) {
    $carStatuses["Under Maintenance"] = (int)$row['cnt'];
}

/**
 * Count available cars (exclude ongoing + maintenance)
 */
$sqlAvail = "
    SELECT COUNT(*) AS cnt
    FROM cartbl c
    WHERE c.status = 'available'
      AND c.carid NOT IN (SELECT carid FROM rentaltbl WHERE status = 'ongoing')
";
$resAvail = $conn->query($sqlAvail);
if ($resAvail && $row = $resAvail->fetch_assoc()) {
    $carStatuses["Available"] = (int)$row['cnt'];
}

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
$resRental = $conn->query($sqlRental);
while ($row = $resRental->fetch_assoc()) {
    $status = ucfirst(strtolower($row['status'])); // normalize
    if (array_key_exists($status, $rentalStatuses)) {
        $rentalStatuses[$status] = (int)$row['count'];
    }
}

echo json_encode([
    "ok"      => true,
    "cars"    => $carStatuses,
    "rentals" => $rentalStatuses
], JSON_PRETTY_PRINT);

$conn->close();
