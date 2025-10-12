<?php
// admin_profile_update.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$host="localhost"; $user="root"; $pass=""; $db="carentadb";
$conn = new mysqli($host,$user,$pass,$db);
if ($conn->connect_error) { http_response_code(500); echo json_encode(['ok'=>false,'error'=>'DB_CONNECT_FAIL']); exit; }

$adminId = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : 0;
$first   = trim($_POST['first_name'] ?? '');
$last    = trim($_POST['last_name'] ?? '');
$email   = trim($_POST['email'] ?? '');
$phone   = trim($_POST['phone_number'] ?? '');
$twofa   = isset($_POST['two_factor_enabled']) && $_POST['two_factor_enabled']=='1' ? 1 : 0;

if ($adminId<=0 || $email==='') { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'BAD_REQUEST']); exit; }

// unique email (if changed)
$stmt = $conn->prepare("SELECT adminid FROM admintbl WHERE email=? AND adminid<>? LIMIT 1");
$stmt->bind_param('si', $email, $adminId);
$stmt->execute(); $res=$stmt->get_result();
if ($res->num_rows>0) { http_response_code(409); echo json_encode(['ok'=>false,'error'=>'EMAIL_IN_USE','message'=>'Email already in use']); exit; }

$stmt = $conn->prepare("UPDATE admintbl SET first_name=?, last_name=?, email=?, phone_number=?, two_factor_enabled=?, updated_at=NOW() WHERE adminid=? LIMIT 1");
$stmt->bind_param('ssssii', $first, $last, $email, $phone, $twofa, $adminId);
$stmt->execute();
echo json_encode(['ok'=>true,'message'=>'Profile updated']);
