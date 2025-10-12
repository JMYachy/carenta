<?php
// admin_change_password.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$host="localhost"; $user="root"; $pass=""; $db="carentadb";
$conn = new mysqli($host,$user,$pass,$db);
if ($conn->connect_error) { http_response_code(500); echo json_encode(['ok'=>false,'error'=>'DB_CONNECT_FAIL']); exit; }

$adminId = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : 0;
$old = $_POST['old_password'] ?? '';
$new = $_POST['new_password'] ?? '';

if ($adminId<=0 || $old==='' || strlen($new)<8) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'BAD_REQUEST']); exit; }

$stmt = $conn->prepare("SELECT bcrypt FROM admintbl WHERE adminid=? LIMIT 1");
$stmt->bind_param('i', $adminId); $stmt->execute(); $res=$stmt->get_result();
if ($res->num_rows===0) { http_response_code(404); echo json_encode(['ok'=>false,'error'=>'NOT_FOUND']); exit; }
$row=$res->fetch_assoc();
if (!password_verify($old, $row['bcrypt'])) { http_response_code(401); echo json_encode(['ok'=>false,'error'=>'BAD_CREDENTIALS','message'=>'Current password is wrong']); exit; }

$newHash = password_hash($new, PASSWORD_BCRYPT);
$stmt = $conn->prepare("UPDATE admintbl SET bcrypt=?, updated_at=NOW() WHERE adminid=? LIMIT 1");
$stmt->bind_param('si', $newHash, $adminId); $stmt->execute();
echo json_encode(['ok'=>true,'message'=>'Password updated']);
