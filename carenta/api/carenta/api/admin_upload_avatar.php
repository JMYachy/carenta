<?php
// admin_upload_avatar.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$host="localhost"; $user="root"; $pass=""; $db="carentadb";
$conn = new mysqli($host,$user,$pass,$db);
if ($conn->connect_error) { http_response_code(500); echo json_encode(['ok'=>false,'error'=>'DB_CONNECT_FAIL']); exit; }

$adminId = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : 0;
if ($adminId<=0) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'BAD_REQUEST']); exit; }
if (!isset($_FILES['avatar'])) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'NO_FILE']); exit; }

$up = $_FILES['avatar'];
if ($up['error'] !== UPLOAD_ERR_OK) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'UPLOAD_FAIL']); exit; }

$allowed = ['image/jpeg'=>'.jpg','image/png'=>'.png','image/webp'=>'.webp'];
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mime = finfo_file($finfo, $up['tmp_name']); finfo_close($finfo);
if (!isset($allowed[$mime])) { http_response_code(415); echo json_encode(['ok'=>false,'error'=>'BAD_TYPE']); exit; }
if ($up['size'] > 5*1024*1024) { http_response_code(413); echo json_encode(['ok'=>false,'error'=>'FILE_TOO_BIG']); exit; }

$ext = $allowed[$mime];
$dir = __DIR__ . '/../uploads/avatars';
if (!is_dir($dir)) mkdir($dir, 0777, true);
$fname = 'admin_'.$adminId.'_'.time().$ext;
$path = $dir . '/' . $fname;
if (!move_uploaded_file($up['tmp_name'], $path)) { http_response_code(500); echo json_encode(['ok'=>false,'error'=>'MOVE_FAIL']); exit; }

$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$base = $scheme.'://'.$_SERVER['HTTP_HOST'];
$publicUrl = $base . '/carenta/uploads/avatars/' . $fname;

$stmt = $conn->prepare("UPDATE admintbl SET profile_picture=?, updated_at=NOW() WHERE adminid=? LIMIT 1");
$stmt->bind_param('si', $publicUrl, $adminId); $stmt->execute();

echo json_encode(['ok'=>true,'message'=>'Avatar updated','avatar_url'=>$publicUrl], JSON_UNESCAPED_SLASHES);
