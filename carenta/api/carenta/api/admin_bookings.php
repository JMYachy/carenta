<?php
// api/admin_bookings.php
// GET ?status=pending|confirmed|ongoing|completed|cancelled&limit=100&offset=0&order=desc

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
ini_set('display_errors', '0'); // avoid HTML notices in JSON

// ---- DB connection ----
$host = "localhost";
$user = "root";
$pass = "";
$db   = "carentadb"; // adjust if needed

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
  http_response_code(500);
  echo json_encode(['ok' => false, 'error' => 'DB_CONNECT_FAIL', 'message' => $conn->connect_error]);
  exit;
}

// ---- inputs ----
$status = isset($_GET['status']) ? strtolower(trim($_GET['status'])) : null;
$limit  = isset($_GET['limit'])  ? max(1, (int)$_GET['limit']) : 100;
$offset = isset($_GET['offset']) ? max(0, (int)$_GET['offset']) : 0;
$order  = (isset($_GET['order']) && strtolower($_GET['order']) === 'asc') ? 'ASC' : 'DESC';

$allowedStatus = ['pending','confirmed','ongoing','completed','cancelled'];
if ($status !== null && !in_array($status, $allowedStatus, true)) {
  http_response_code(400);
  echo json_encode(['ok' => false, 'error' => 'BAD_STATUS', 'message' => 'Invalid status filter']);
  exit;
}

// ---- auto-update statuses ----
$conn->query("
  UPDATE rentaltbl
  SET status = 'ongoing'
  WHERE status = 'confirmed'
    AND NOW() >= STR_TO_DATE(CONCAT(start_date, ' ', IFNULL(start_time, '00:00:00')), '%Y-%m-%d %H:%i:%s')
    AND NOW() <= STR_TO_DATE(CONCAT(end_date, ' ', IFNULL(end_time, '23:59:59')), '%Y-%m-%d %H:%i:%s')
");

$conn->query("
  UPDATE rentaltbl
  SET status = 'completed'
  WHERE status = 'ongoing'
    AND NOW() > STR_TO_DATE(CONCAT(end_date, ' ', IFNULL(end_time, '23:59:59')), '%Y-%m-%d %H:%i:%s')
");

// ---- query ----
$sql = "
SELECT
  r.rentalid, r.userid, r.carid, r.rental_type,
  r.start_date, r.start_time, r.end_date, r.end_time,
  r.pickup_location, r.dropoff_location, r.total_amount,
  r.status,
  r.cancellation_reason,
  r.cancelled_by,
  r.cancelled_at,
  r.admin_notes,
  r.created_at AS rental_created_at,
  r.updated_at AS rental_updated_at,
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
WHERE 1=1
";

$types = '';
$params = [];

if ($status !== null) {
  $sql .= " AND r.status = ? ";
  $types .= 's';
  $params[] = $status;
}

$sql .= " ORDER BY r.start_date $order, r.start_time $order LIMIT ? OFFSET ? ";
$types .= 'ii';
$params[] = $limit;
$params[] = $offset;

$stmt = $conn->prepare($sql);
if (!$stmt) {
  http_response_code(500);
  echo json_encode(['ok' => false, 'error' => 'PREPARE_FAIL', 'message' => $conn->error]);
  exit;
}
$stmt->bind_param($types, ...$params);
$stmt->execute();
$res = $stmt->get_result();

$data = [];
while ($row = $res->fetch_assoc()) {
  $row['car_name'] = trim(($row['manufacturer'] ?? '').' '.($row['model'] ?? ''));
  $row['date_range'] =
    ($row['start_date'] ?? '') . (!empty($row['start_time']) ? (' '.$row['start_time']) : '') .
    ' — ' .
    ($row['end_date'] ?? '') . (!empty($row['end_time']) ? (' '.$row['end_time']) : '');
  $data[] = $row;
}
$stmt->close();
$conn->close();

echo json_encode(['ok' => true, 'count' => count($data), 'data' => $data], JSON_UNESCAPED_SLASHES);
