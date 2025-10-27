<?php
session_start();
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(200);
  exit;
}

require_once __DIR__ . '/connection_service.php'; // ✅ uses your shared PDO connection

function ok($data = []) {
  echo json_encode(array_merge(['success' => true, 'status' => 'success'], $data), JSON_UNESCAPED_UNICODE);
  exit;
}

function fail($msg) {
  echo json_encode(['success' => false, 'status' => 'error', 'message' => $msg], JSON_UNESCAPED_UNICODE);
  exit;
}

try {
  // ✅ Pending user verifications
  $stmt = $conn->query("SELECT COUNT(*) AS count FROM user_verificationtbl WHERE status = 'pending'");
  $pendingVerifications = (int) $stmt->fetch(PDO::FETCH_ASSOC)['count'];

  // ✅ Available cars (enabled or available)
  $stmt = $conn->query("SELECT COUNT(*) AS count FROM cartbl WHERE status IN ('available','enabled')");
  $availableCars = (int) $stmt->fetch(PDO::FETCH_ASSOC)['count'];

  // ✅ Active rentals (ongoing or confirmed)
  $stmt = $conn->query("SELECT COUNT(*) AS count FROM rentaltbl WHERE status IN ('ongoing','confirmed')");
  $activeRentals = (int) $stmt->fetch(PDO::FETCH_ASSOC)['count'];

  // ✅ Bookings created today
  $stmt = $conn->query("SELECT COUNT(*) AS count FROM rentaltbl WHERE DATE(created_at) = CURDATE()");
  $bookingsToday = (int) $stmt->fetch(PDO::FETCH_ASSOC)['count'];

  ok([
    'data' => [
      'pending_verifications' => $pendingVerifications,
      'available_cars' => $availableCars,
      'active_rentals' => $activeRentals,
      'bookings_today' => $bookingsToday,
    ]
  ]);
} catch (Exception $e) {
  fail("Server error: " . $e->getMessage());
}
