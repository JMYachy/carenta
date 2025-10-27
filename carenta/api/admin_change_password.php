<?php
// api/admin_change_password.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

ini_set('display_errors', '0');
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(204);
  exit;
}

/* ---- DB CONNECTION ---- */
require_once __DIR__ . '/connection_service.php';

try {
  $adminId = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : 0;
  $oldPass = $_POST['old_password'] ?? '';
  $newPass = $_POST['new_password'] ?? '';

  // ✅ Basic validation
  if ($adminId <= 0 || $oldPass === '' || strlen($newPass) < 8) {
    http_response_code(400);
    echo json_encode([
      'ok' => false,
      'error' => 'BAD_REQUEST',
      'message' => 'Invalid input or password too short (min 8 characters)'
    ]);
    exit;
  }

  // ✅ Fetch current bcrypt hash
  $stmt = $pdo->prepare("SELECT bcrypt FROM admintbl WHERE adminid = :id LIMIT 1");
  $stmt->execute([':id' => $adminId]);
  $row = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$row) {
    http_response_code(404);
    echo json_encode(['ok' => false, 'error' => 'NOT_FOUND', 'message' => 'Admin not found']);
    exit;
  }

  // ✅ Verify old password
  if (!password_verify($oldPass, $row['bcrypt'])) {
    http_response_code(401);
    echo json_encode([
      'ok' => false,
      'error' => 'BAD_CREDENTIALS',
      'message' => 'Current password is incorrect'
    ]);
    exit;
  }

  // ✅ Hash and update new password
  $newHash = password_hash($newPass, PASSWORD_BCRYPT);
  $update = $pdo->prepare("UPDATE admintbl SET bcrypt = :newHash, updated_at = NOW() WHERE adminid = :id LIMIT 1");
  $update->execute([':newHash' => $newHash, ':id' => $adminId]);

  echo json_encode([
    'ok' => true,
    'message' => 'Password updated successfully'
  ]);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    'ok' => false,
    'error' => 'SERVER_ERROR',
    'message' => $e->getMessage()
  ]);
}
?>
