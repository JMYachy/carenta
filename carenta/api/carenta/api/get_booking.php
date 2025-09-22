<?php
declare(strict_types=1);

// ===== Always return JSON, no HTML =====
header('Content-Type: application/json; charset=utf-8');
ini_set('display_errors', '0');  // do not echo PHP warnings/notices
error_reporting(E_ALL);
ob_start();

// Convert warnings/notices into a JSON error
set_error_handler(function($errno, $errstr, $errfile, $errline) {
    http_response_code(500);
    $buf = ob_get_clean();
    echo json_encode([
        'ok' => false,
        'error' => 'PHP_WARNING',
        'message' => $errstr,
        'file' => $errfile,
        'line' => $errline,
        'buffer' => $buf,
    ]);
    exit;
});

register_shutdown_function(function() {
    $e = error_get_last();
    if ($e && in_array($e['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        http_response_code(500);
        $buf = ob_get_clean();
        echo json_encode([
            'ok' => false,
            'error' => 'PHP_FATAL',
            'message' => $e['message'],
            'file' => $e['file'],
            'line' => $e['line'],
            'buffer' => $buf,
        ]);
        exit;
    }
});

// ===== Your DB config (make sure this matches phpMyAdmin) =====
$host = "localhost";
$user = "root";
$pass = "";
$db   = "carentadb"; // <-- or "carenta_db" if that's the actual schema name

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    http_response_code(500);
    $buf = ob_get_clean();
    echo json_encode(['ok' => false, 'error' => 'DB_CONNECT_FAIL', 'message' => $conn->connect_error, 'buffer' => $buf]);
    exit;
}

$userId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;
$status = isset($_GET['status']) ? trim($_GET['status']) : null;
$limit  = isset($_GET['limit'])  ? max(1, (int) $_GET['limit']) : 50;
$offset = isset($_GET['offset']) ? max(0, (int) $_GET['offset']) : 0;
$order  = (isset($_GET['order']) && strtolower($_GET['order']) === 'asc') ? 'ASC' : 'DESC';

if ($userId <= 0) {
    http_response_code(400);
    $buf = ob_get_clean();
    echo json_encode(['ok' => false, 'error' => 'BAD_REQUEST', 'message' => 'Missing user_id', 'buffer' => $buf]);
    exit;
}

$sql = "
SELECT
    r.rentalid, r.userid, r.carid, r.rental_type,
    r.start_date, r.start_time, r.end_date, r.end_time,
    r.pickup_location, r.dropoff_location, r.total_amount, r.status,
    c.manufacturer, c.model, c.license_plate, c.withDriver,
    m.thumbnail_url, m.media_url
FROM rentaltbl r
JOIN cartbl c ON c.carid = r.carid
LEFT JOIN (
    SELECT carid, MAX(mediaid) AS max_mediaid
    FROM mediatbl
    WHERE media_type='image'
    GROUP BY carid
) t ON t.carid = c.carid
LEFT JOIN mediatbl m ON m.mediaid = t.max_mediaid
WHERE r.userid = ?
";

$types = "i";
$params = [$userId];

if (!empty($status)) {
    $sql .= " AND r.status = ?";
    $types .= "s";
    $params[] = $status;
}

$sql .= " ORDER BY r.start_date $order, r.start_time $order LIMIT ? OFFSET ?";
$types .= "ii";
$params[] = $limit;
$params[] = $offset;

$stmt = $conn->prepare($sql);
if (!$stmt) {
    http_response_code(500);
    $buf = ob_get_clean();
    echo json_encode(['ok' => false, 'error' => 'PREPARE_FAIL', 'message' => $conn->error, 'buffer' => $buf]);
    exit;
}
$stmt->bind_param($types, ...$params);
$stmt->execute();
$res = $stmt->get_result();

$data = [];
while ($row = $res->fetch_assoc()) {
    $row['car_name'] = trim(($row['manufacturer'] ?? '') . ' ' . ($row['model'] ?? ''));
    $row['date_range'] =
        ($row['start_date'] ?? '') . (!empty($row['start_time']) ? (' ' . $row['start_time']) : '') .
        " — " .
        ($row['end_date'] ?? '') . (!empty($row['end_time']) ? (' ' . $row['end_time']) : '');
    $data[] = $row;
}

$stmt->close();
$conn->close();

// clear any stray output (like accidental whitespace) then send JSON
ob_clean();
echo json_encode(['ok' => true, 'count' => count($data), 'data' => $data], JSON_UNESCAPED_SLASHES);
