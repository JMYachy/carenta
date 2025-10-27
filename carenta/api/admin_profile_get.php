<?php
// api/admin_profile_get.php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
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
  $adminId = isset($_GET['admin_id']) ? (int)$_GET['admin_id'] : 0;
  if ($adminId <= 0) {
    http_response_code(400);
    echo json_encode([
      'ok' => false,
      'error' => 'BAD_REQUEST',
      'message' => 'admin_id is required'
    ]);
    exit;
  }

  // ✅ Fetch admin profile
  $stmt = $pdo->prepare("
    SELECT 
      adminid, username, email, first_name, last_name, role, status,
      phone_number, profile_picture, two_factor_enabled,
      last_login, last_ip_address, created_at, updated_at
    FROM admintbl
    WHERE adminid = :id
    LIMIT 1
  ");
  $stmt->execute([':id' => $adminId]);
  $row = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$row) {
    http_response_code(404);
    echo json_encode(['ok' => false, 'error' => 'NOT_FOUND', 'message' => 'Admin not found']);
    exit;
  }

  // ✅ Optionally format or normalize fields
  if (!empty($row['profile_picture']) && !preg_match('#^https?://#', $row['profile_picture'])) {
    // auto-prepend uploads path if needed
    $row['profile_picture'] = 'uploads/images/' . ltrim($row['profile_picture'], '/');
  }

  echo json_encode(['ok' => true, 'data' => $row], JSON_UNESCAPED_SLASHES);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    'ok' => false,
    'error' => 'SERVER_ERROR',
    'message' => $e->getMessage()
  ]);
}
?>
