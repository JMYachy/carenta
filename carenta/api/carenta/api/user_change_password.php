<?php
// htdocs/carenta/api/user_change_password.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$host = "localhost";
$user = "root";
$pass = "";
$db   = "carentadb"; // <-- change if needed

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
  http_response_code(500);
  echo json_encode(['ok' => false, 'error' => 'DB_CONNECT_FAIL']);
  exit;
}

$userid          = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$currentPassword = $_POST['current_password'] ?? '';
$newPassword     = $_POST['new_password'] ?? '';

if ($userid <= 0 || $currentPassword === '' || $newPassword === '') {
  http_response_code(400);
  echo json_encode(['ok' => false, 'error' => 'BAD_REQUEST']);
  exit;
}
if (strlen($newPassword) < 6) {
  http_response_code(400);
  echo json_encode(['ok' => false, 'error' => 'WEAK_PASSWORD', 'message' => 'Min length 6']);
  exit;
}

// Get current hash
$stmt = $conn->prepare("SELECT bcrypt FROM usertbl WHERE userid = ? LIMIT 1");
$stmt->bind_param('i', $userid);
$stmt->execute();
$res = $stmt->get_result();
if ($res->num_rows === 0) {
  http_response_code(404);
  echo json_encode(['ok' => false, 'error' => 'NOT_FOUND']);
  exit;
}
$row = $res->fetch_assoc();
$hash = $row['bcrypt'] ?? '';

if (!password_verify($currentPassword, $hash)) {
  http_response_code(403);
  echo json_encode(['ok' => false, 'error' => 'INVALID_PASSWORD']);
  exit;
}

$newHash = password_hash($newPassword, PASSWORD_BCRYPT);
$upd = $conn->prepare("UPDATE usertbl SET bcrypt = ?, updated_at = CURRENT_TIMESTAMP WHERE userid = ?");
$upd->bind_param('si', $newHash, $userid);
if (!$upd->execute()) {
  http_response_code(500);
  echo json_encode(['ok' => false, 'error' => 'UPDATE_FAIL', 'message' => $conn->error]);
  exit;
}

echo json_encode(['ok' => true, 'message' => 'Password updated']);

