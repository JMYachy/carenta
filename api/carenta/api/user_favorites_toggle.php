<?php
// htdocs/carenta/api/user_favorite_toggle.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$host="localhost"; $user="root"; $pass=""; $db="carentadb";
$conn = new mysqli($host,$user,$pass,$db);
if ($conn->connect_error) { http_response_code(500); echo json_encode(['ok'=>false,'error'=>'DB_CONNECT_FAIL']); exit; }

$userid = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$carid  = isset($_POST['car_id'])  ? (int)$_POST['car_id']  : 0;
$action = $_POST['action'] ?? ''; // 'add' or 'remove'

if ($userid<=0 || $carid<=0 || !in_array($action, ['add','remove'], true)) {
  http_response_code(400);
  echo json_encode(['ok'=>false,'error'=>'BAD_REQUEST','message'=>'user_id, car_id, action required']);
  exit;
}

// Optional: verify car exists
$chk = $conn->prepare("SELECT carid FROM cartbl WHERE carid=? LIMIT 1");
$chk->bind_param('i', $carid); $chk->execute();
if ($chk->get_result()->num_rows === 0) {
  http_response_code(404);
  echo json_encode(['ok'=>false,'error'=>'CAR_NOT_FOUND']); exit;
}

if ($action === 'add') {
  $stmt = $conn->prepare("INSERT INTO favoritecarstbl (userid, carid) VALUES (?, ?) ON DUPLICATE KEY UPDATE created_at=CURRENT_TIMESTAMP");
  $stmt->bind_param('ii', $userid, $carid);
  $stmt->execute();
  echo json_encode(['ok'=>true,'message'=>'Added to favorites']); exit;
} else {
  $stmt = $conn->prepare("DELETE FROM favoritecarstbl WHERE userid=? AND carid=?");
  $stmt->bind_param('ii', $userid, $carid);
  $stmt->execute();
  echo json_encode(['ok'=>true,'message'=>'Removed from favorites']); exit;
}
