<?php
// api/user_favorite_toggle.php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

ini_set('display_errors', '0');
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(204);
  exit;
}

/* ---- DB CONNECTION ---- */
require_once __DIR__ . '/connection_service.php';

try {
  $userId = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
  $carId  = isset($_POST['car_id'])  ? (int)$_POST['car_id']  : 0;
  $action = trim($_POST['action'] ?? ''); // 'add' or 'remove'

  // ✅ Validate input
  if ($userId <= 0 || $carId <= 0 || !in_array($action, ['add', 'remove'], true)) {
    http_response_code(400);
    echo json_encode([
      'ok' => false,
      'error' => 'BAD_REQUEST',
      'message' => 'user_id, car_id, and valid action ("add" or "remove") are required'
    ]);
    exit;
  }

  // ✅ Verify that car exists
  $check = $pdo->prepare("SELECT carid FROM cartbl WHERE carid = :carid LIMIT 1");
  $check->execute([':carid' => $carId]);
  if (!$check->fetch()) {
    http_response_code(404);
    echo json_encode(['ok' => false, 'error' => 'CAR_NOT_FOUND', 'message' => 'Car not found']);
    exit;
  }

  // ✅ Perform add/remove action
  if ($action === 'add') {
    $stmt = $pdo->prepare("
      INSERT INTO favoritecarstbl (userid, carid, created_at)
      VALUES (:userId, :carId, NOW())
      ON DUPLICATE KEY UPDATE created_at = NOW()
    ");
    $stmt->execute([':userId' => $userId, ':carId' => $carId]);

    echo json_encode(['ok' => true, 'message' => 'Added to favorites']);
    exit;
  } else {
    $stmt = $pdo->prepare("DELETE FROM favoritecarstbl WHERE userid = :userId AND carid = :carId");
    $stmt->execute([':userId' => $userId, ':carId' => $carId]);

    echo json_encode(['ok' => true, 'message' => 'Removed from favorites']);
    exit;
  }

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    'ok' => false,
    'error' => 'SERVER_ERROR',
    'message' => $e->getMessage()
  ]);
}
?>
