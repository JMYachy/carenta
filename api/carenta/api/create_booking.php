<?php
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$host = "localhost";
$user = "root";
$pass = "";
$db   = "carentadb"; // <-- ensure this matches your DB name

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    $conn = new mysqli($host, $user, $pass, $db);
    $conn->set_charset("utf8mb4");

    // Accept form-urlencoded (Flutter default) OR JSON
    $input = $_POST;
    if (empty($input)) {
        $raw = file_get_contents('php://input');
        $json = json_decode($raw, true);
        if (is_array($json)) $input = $json;
    }

    // --------- Read & validate inputs ----------
    $carid            = isset($input['carid']) ? (int)$input['carid'] : 0;
    $userid           = isset($input['userid']) ? (int)$input['userid'] : 0;
    $start_date       = trim((string)($input['start_date'] ?? ''));
    $start_time       = trim((string)($input['start_time'] ?? '00:00'));
    $end_date         = trim((string)($input['end_date'] ?? ''));
    $end_time         = trim((string)($input['end_time'] ?? '00:00'));
    $pickup_location  = trim((string)($input['pickup_location'] ?? ''));
    $dropoff_location = trim((string)($input['dropoff_location'] ?? ''));
    $client_total     = isset($input['total_amount']) ? (float)$input['total_amount'] : null;

    if ($carid <= 0 || $userid <= 0 || $start_date === '' || $end_date === '' ||
        $pickup_location === '' || $dropoff_location === '') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing required fields']);
        exit;
    }

    $isDate = function(string $d): bool {
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $d)) return false;
        $dt = DateTime::createFromFormat('Y-m-d', $d);
        return $dt && $dt->format('Y-m-d') === $d;
    };
    if (!$isDate($start_date) || !$isDate($end_date)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid date format (use YYYY-MM-DD)']);
        exit;
    }
    if (strtotime($end_date) < strtotime($start_date)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'End date cannot be before start date']);
        exit;
    }

    // Optional: disallow past dates
    $today = new DateTime('today');
    if (new DateTime($start_date) < $today) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Start date cannot be in the past']);
        exit;
    }

    // --------- Transaction ----------
    $conn->begin_transaction();

    // Ensure car exists
    $stmt = $conn->prepare("SELECT carid FROM cartbl WHERE carid = ? LIMIT 1 FOR UPDATE");
    $stmt->bind_param("i", $carid);
    $stmt->execute();
    $carRow = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$carRow) {
        $conn->rollback();
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Car not found']);
        exit;
    }

    // Prevent overlaps
    $stmt = $conn->prepare("
        SELECT 1
        FROM rentaltbl
        WHERE carid = ?
          AND NOT (? < start_date OR ? > end_date)
        LIMIT 1
        FOR UPDATE
    ");
    $stmt->bind_param("iss", $carid, $start_date, $end_date);
    $stmt->execute();
    $overlap = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if ($overlap) {
        $conn->rollback();
        http_response_code(409);
        echo json_encode(['success' => false, 'message' => 'Car is not available for the selected dates']);
        exit;
    }

    // Compute total on server if possible
    $stmt = $conn->prepare("
        SELECT t.daily_rate, t.currency
        FROM pricetbl t
        JOIN (
            SELECT carid, MAX(updated_at) AS latest
            FROM pricetbl
            WHERE (valid_from IS NULL OR valid_from <= CURDATE())
              AND (valid_to   IS NULL OR valid_to   >= CURDATE())
              AND carid = ?
        ) u ON u.carid = t.carid AND u.latest = t.updated_at
        LIMIT 1
    ");
    $stmt->bind_param("i", $carid);
    $stmt->execute();
    $priceRow = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    $days = (new DateTime($start_date))->diff(new DateTime($end_date))->days + 1;
    if ($days < 1) {
        $conn->rollback();
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid date range']);
        exit;
    }

    if ($priceRow && isset($priceRow['daily_rate'])) {
        $daily = (float)$priceRow['daily_rate'];
        $total_amount = $daily * $days;
    } else {
        if ($client_total === null) {
            $conn->rollback();
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'No pricing available for this car']);
            exit;
        }
        $total_amount = (float)$client_total;
    }

    // Insert booking
    $stmt = $conn->prepare("
        INSERT INTO rentaltbl
            (carid, userid, start_date, start_time, end_date, end_time, total_amount, pickup_location, dropoff_location, status)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ");
    $stmt->bind_param(
        "iisssdsss",
        $carid,
        $userid,
        $start_date,
        $start_time,
        $end_date,
        $end_time,
        $total_amount,
        $pickup_location,
        $dropoff_location
    );
    $stmt->execute();
    $rentalId = $stmt->insert_id;
    $stmt->close();

    $conn->commit();

    echo json_encode([
        'success'       => true,
        'message'       => 'Booking created successfully (pending payment)',
        'rental_id'     => (int)$rentalId,
        'carid'         => (int)$carid,
        'userid'        => (int)$userid,
        'start_date'    => $start_date,
        'start_time'    => $start_time,
        'end_date'      => $end_date,
        'end_time'      => $end_time,
        'days'          => $days,
        'total_amount'  => (float)$total_amount,
        'pickup'        => $pickup_location,
        'dropoff'       => $dropoff_location,
        'status'        => 'pending'
    ], JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    if (isset($conn) && $conn instanceof mysqli) {
        try { $conn->rollback(); } catch (Throwable $ignored) {}
    }
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error'   => $e->getMessage()
    ]);
} finally {
    if (isset($conn) && $conn instanceof mysqli) { $conn->close(); }
}
