<?php
// api/admin_profile_update.php
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
  $adminId = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : 0;
  $first   = trim($_POST['first_name'] ?? '');
  $last    = trim($_POST['last_name'] ?? '');
  $email   = trim($_POST['email'] ?? '');
  $phone   = trim($_POST['phone_number'] ?? '');
  $twofa   = isset($_POST['two_factor_enabled']) && $_POST['two_factor_enabled'] === '1' ? 1 : 0;

  // ✅ Validate input
  if ($adminId <= 0 || $email === '') {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'BAD_REQUEST', 'message' => 'admin_id and email are required']);
    exit;
  }

  // ✅ Check if email already exists for another admin
  $check = $pdo->prepare("SELECT adminid FROM admintbl WHERE email = :email AND adminid <> :id LIMIT 1");
  $check->execute([':email' => $email, ':id' => $adminId]);
  if ($check->fetch()) {
    http_response_code(409);
    echo json_encode(['ok' => false, 'error' => 'EMAIL_IN_USE', 'message' => 'Email already in use']);
    exit;
  }

  // ✅ Update admin profile
  $stmt = $pdo->prepare("
    UPDATE admintbl
       SET first_name = :first,
           last_name = :last,
           email = :email,
           phone_number = :phone,
           two_factor_enabled = :twofa,
           updated_at = NOW()
     WHERE adminid = :id
     LIMIT 1
  ");
  $stmt->execute([
    ':first' => $first,
    ':last'  => $last,
    ':email' => $email,
    ':phone' => $phone,
    ':twofa' => $twofa,
    ':id'    => $adminId,
  ]);

  if ($stmt->rowCount() > 0) {
    echo json_encode(['ok' => true, 'message' => 'Profile updated']);
  } else {
    echo json_encode(['ok' => true, 'message' => 'No changes detected']);
  }

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    'ok' => false,
    'error' => 'SERVER_ERROR',
    'message' => $e->getMessage(),
  ]);
}
?>
