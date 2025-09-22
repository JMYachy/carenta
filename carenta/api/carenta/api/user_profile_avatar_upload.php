<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$host="localhost"; $user="root"; $pass=""; $db="carentadb";
$conn = new mysqli($host,$user,$pass,$db);
if ($conn->connect_error) { http_response_code(500); echo json_encode(['ok'=>false,'error'=>'DB_CONNECT_FAIL']); exit; }

$userid = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
if ($userid <= 0) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'BAD_REQUEST']); exit; }

if (!isset($_FILES['avatar'])) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'NO_FILE']); exit; }

$dir = __DIR__ . '/../uploads/avatars/';
if (!is_dir($dir)) { @mkdir($dir, 0777, true); }

$f = $_FILES['avatar'];
if ($f['error'] !== UPLOAD_ERR_OK) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'UPLOAD_ERROR']); exit; }

$ext = strtolower(pathinfo($f['name'], PATHINFO_EXTENSION));
$allowed = ['jpg','jpeg','png','webp'];
if (!in_array($ext, $allowed)) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'BAD_TYPE']); exit; }

if ($f['size'] > 2 * 1024 * 1024) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'FILE_TOO_LARGE']); exit; }

$fname = 'u'.$userid.'_'.time().'.'.$ext;
$path = $dir . $fname;
if (!move_uploaded_file($f['tmp_name'], $path)) { http_response_code(500); echo json_encode(['ok'=>false,'error'=>'MOVE_FAIL']); exit; }

# Public URL (adjust if you have a different doc root)
$baseUrl = (isset($_SERVER['HTTPS']) ? "https" : "http")."://".$_SERVER['HTTP_HOST']."/carenta/uploads/avatars/".$fname;

$upd = $conn->prepare("UPDATE usertbl SET profile_picture=?, updated_at=CURRENT_TIMESTAMP WHERE userid=?");
$upd->bind_param('si', $baseUrl, $userid);
$upd->execute();

echo json_encode(['ok'=>true,'message'=>'Avatar updated','url'=>$baseUrl], JSON_UNESCAPED_SLASHES);

