<?php
declare(strict_types=1);

// ===== JSON-only API =====
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

ini_set('display_errors', '0');
ini_set('log_errors', '1');
error_reporting(E_ALL);
ob_start();

// ===== Safe error handling =====
set_error_handler(function ($errno, $errstr, $errfile, $errline) {
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

register_shutdown_function(function () {
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

/* ---- DB CONNECTION ---- */
require_once __DIR__ . '/connection_service.php';

try {
    $userId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;
    $status = isset($_GET['status']) ? trim($_GET['status']) : null;
    $limit  = isset($_GET['limit'])  ? max(1, (int) $_GET['limit']) : 50;
    $offset = isset($_GET['offset']) ? max(0, (int) $_GET['offset']) : 0;
    $order  = (isset($_GET['order']) && strtolower($_GET['order']) === 'asc') ? 'ASC' : 'DESC';

    if ($userId <= 0) {
        http_response_code(400);
        echo json_encode(['ok' => false, 'error' => 'BAD_REQUEST', 'message' => 'Missing user_id']);
        exit;
    }

    // ===== Base query =====
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
            WHERE media_type = 'image'
            GROUP BY carid
        ) t ON t.carid = c.carid
        LEFT JOIN mediatbl m ON m.mediaid = t.max_mediaid
        WHERE r.userid = :userId
    ";

    $params = [':userId' => $userId];

    if (!empty($status)) {
        $sql .= " AND r.status = :status";
        $params[':status'] = $status;
    }

    $sql .= " ORDER BY r.start_date $order, r.start_time $order LIMIT :limit OFFSET :offset";

    // ===== Prepare & execute =====
    $stmt = $pdo->prepare($sql);
    // Explicitly bind limit/offset as integers
    $stmt->bindValue(':userId', $userId, PDO::PARAM_INT);
    if (!empty($status)) $stmt->bindValue(':status', $status, PDO::PARAM_STR);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $data = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $row['car_name'] = trim(($row['manufacturer'] ?? '') . ' ' . ($row['model'] ?? ''));
        $row['date_range'] =
            ($row['start_date'] ?? '') . (!empty($row['start_time']) ? (' ' . $row['start_time']) : '') .
            " — " .
            ($row['end_date'] ?? '') . (!empty($row['end_time']) ? (' ' . $row['end_time']) : '');
        $data[] = $row;
    }

    ob_clean();
    echo json_encode(['ok' => true, 'count' => count($data), 'data' => $data], JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);
    $buf = ob_get_clean();
    echo json_encode([
        'ok' => false,
        'error' => 'SERVER_ERROR',
        'message' => $e->getMessage(),
        'buffer' => $buf,
    ]);
}
