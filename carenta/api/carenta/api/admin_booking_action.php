<?php
// api/admin_booking_action.php
// POST rental_id, action=confirm|cancel, admin_id, reason? (for cancel)

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
ini_set('display_errors', '0');

$host = "localhost";
$user = "root";
$pass = "";
$db   = "carentadb";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
  http_response_code(500);
  echo json_encode(['ok' => false, 'error' => 'DB_CONNECT_FAIL', 'message' => $conn->connect_error]);
  exit;
}

// ---- inputs ----
$rentalId = isset($_POST['rental_id']) ? (int)$_POST['rental_id'] : 0;
$action   = isset($_POST['action']) ? strtolower(trim($_POST['action'])) : '';
$adminId  = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : 0;
$reason   = isset($_POST['reason']) ? trim($_POST['reason']) : null;

if ($rentalId <= 0 || $adminId <= 0 || !in_array($action, ['confirm','cancel'], true)) {
  http_response_code(400);
  echo json_encode(['ok' => false, 'error' => 'BAD_REQUEST', 'message' => 'rental_id, admin_id, action required']);
  exit;
}

// ---- load current booking ----
$q = $conn->prepare("SELECT status FROM rentaltbl WHERE rentalid = ?");
$q->bind_param('i', $rentalId);
$q->execute();
$res = $q->get_result();
if ($res->num_rows === 0) {
  http_response_code(404);
  echo json_encode(['ok' => false, 'error' => 'NOT_FOUND', 'message' => 'Booking not found']);
  exit;
}
$row = $res->fetch_assoc();
$current = strtolower($row['status'] ?? '');
$q->close();

if ($action === 'confirm') {
  // ✅ confirm only if pending
  if ($current !== 'pending') {
    http_response_code(409);
    echo json_encode(['ok' => false, 'error' => 'INVALID_STATE', 'message' => 'Only PENDING bookings can be confirmed']);
    exit;
  }

  $stmt = $conn->prepare("
    UPDATE rentaltbl
       SET status = 'confirmed',
           approved_by = ?,
           updated_at = NOW()
     WHERE rentalid = ?
     LIMIT 1
  ");
  $stmt->bind_param('ii', $adminId, $rentalId);
  $stmt->execute();
  if ($stmt->affected_rows > 0) {
    echo json_encode(['ok' => true, 'message' => 'Booking confirmed']);
  } else {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'UPDATE_FAIL', 'message' => 'No rows updated']);
  }
  $stmt->close();

} else { // cancel
  // ✅ allow cancel if pending, confirmed, or ongoing
  if (!in_array($current, ['pending','confirmed','ongoing'])) {
    http_response_code(409);
    echo json_encode(['ok' => false, 'error' => 'INVALID_STATE', 'message' => "Booking cannot be cancelled because it is already $current"]);
    exit;
  }

  $stmt = $conn->prepare("
    UPDATE rentaltbl
       SET status = 'cancelled',
           cancellation_reason = ?,
           cancelled_by = 'admin',
           updated_at = NOW()
     WHERE rentalid = ?
     LIMIT 1
  ");
  $reason = $reason ?: 'Cancelled by admin';
  $stmt->bind_param('si', $reason, $rentalId);
  $stmt->execute();
  if ($stmt->affected_rows > 0) {
    echo json_encode(['ok' => true, 'message' => 'Booking cancelled']);
  } else {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'UPDATE_FAIL', 'message' => 'No rows updated']);
  }
  $stmt->close();
}

$conn->close();
