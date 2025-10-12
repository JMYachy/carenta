<?php
// admin_profile_get.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$host="localhost"; $user="root"; $pass=""; $db="carentadb"; // or carenta_db
$conn = new mysqli($host,$user,$pass,$db);
if ($conn->connect_error) { http_response_code(500); echo json_encode(['ok'=>false,'error'=>'DB_CONNECT_FAIL']); exit; }

$adminId = isset($_GET['admin_id']) ? (int)$_GET['admin_id'] : 0;
if ($adminId<=0) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'BAD_REQUEST','message'=>'admin_id required']); exit; }

$stmt = $conn->prepare("SELECT adminid, username, email, first_name, last_name, role, status, phone_number, profile_picture, two_factor_enabled, last_login, last_ip_address, created_at, updated_at FROM admintbl WHERE adminid=? LIMIT 1");
$stmt->bind_param('i', $adminId);
$stmt->execute(); $res=$stmt->get_result();
if ($res->num_rows===0) { http_response_code(404); echo json_encode(['ok'=>false,'error'=>'NOT_FOUND']); exit; }
$row = $res->fetch_assoc();
echo json_encode(['ok'=>true,'data'=>$row], JSON_UNESCAPED_SLASHES);
