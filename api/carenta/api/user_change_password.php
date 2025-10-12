<?php
// htdocs/carenta/api/user_change_password.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$host="localhost"; $user="root"; $pass=""; $db="carentadb";
$conn = new mysqli($host,$user,$pass,$db);
if ($conn->connect_error) {
  http_response_code(500);
  echo json_encode(['ok'=>false,'message'=>'DB connection failed']);
  exit;
}

$userid  = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$current = $_POST['current_password'] ?? '';
$new     = $_POST['new_password'] ?? '';

if ($userid<=0 || $current==='' || $new==='') {
  http_response_code(400);
  echo json_encode(['ok'=>false,'message'=>'Missing fields']);
  exit;
}

/* fetch hash */
$stmt=$conn->prepare("SELECT bcrypt FROM usertbl WHERE userid=? LIMIT 1");
$stmt->bind_param('i',$userid);
$stmt->execute();
$res=$stmt->get_result();
if($res->num_rows===0){
  http_response_code(404); echo json_encode(['ok'=>false,'message'=>'User not found']); exit;
}
$row=$res->fetch_assoc();
$stmt->close();

/* verify current password */
if(!password_verify($current,$row['bcrypt'])){
  http_response_code(401);
  echo json_encode(['ok'=>false,'message'=>'Current password incorrect']);
  exit;
}

/* hash new */
$newHash=password_hash($new,PASSWORD_BCRYPT);

/* update */
$upd=$conn->prepare("UPDATE usertbl SET bcrypt=?, updated_at=CURRENT_TIMESTAMP WHERE userid=?");
$upd->bind_param('si',$newHash,$userid);
if(!$upd->execute()){
  http_response_code(500);
  echo json_encode(['ok'=>false,'message'=>'Password update failed']);
  exit;
}

echo json_encode(['ok'=>true,'message'=>'Password updated successfully']);
