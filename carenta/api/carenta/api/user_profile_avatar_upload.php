<?php
// htdocs/carenta/api/update_avatar.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$host = "localhost"; 
$user = "root"; 
$pass = ""; 
$db   = "carentadb";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'message' => 'Database connection failed']);
    exit;
}

$userid = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
if ($userid <= 0) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'Missing or invalid user_id']);
    exit;
}

if (!isset($_FILES['avatar'])) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'No avatar file uploaded']);
    exit;
}

$dir = __DIR__ . '/../uploads/avatars/';
$publicBase = "uploads/avatars/"; // path stored in DB
if (!is_dir($dir)) { @mkdir($dir, 0777, true); }

$f = $_FILES['avatar'];
if ($f['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'Upload error']);
    exit;
}

$ext = strtolower(pathinfo($f['name'], PATHINFO_EXTENSION));
$allowed = ['jpg','jpeg','png','webp'];
if (!in_array($ext, $allowed)) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'Invalid file type']);
    exit;
}

if ($f['size'] > 2 * 1024 * 1024) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'message' => 'File too large (max 2MB)']);
    exit;
}

// Sanitize filename
$fname = 'u'.$userid.'_'.time().'.'.$ext;
$path = $dir . $fname;
if (!move_uploaded_file($f['tmp_name'], $path)) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'message' => 'Failed to save file']);
    exit;
}

// Optional: remove old avatar
$res = $conn->prepare("SELECT profile_picture FROM usertbl WHERE userid=? LIMIT 1");
$res->bind_param('i', $userid);
$res->execute();
$resRow = $res->get_result()->fetch_assoc();
if ($resRow && !empty($resRow['profile_picture'])) {
    $oldFile = __DIR__ . '/../' . $resRow['profile_picture'];
    if (is_file($oldFile)) @unlink($oldFile);
}
$res->close();

// Store relative path in DB
$dbPath = $publicBase . $fname;
$upd = $conn->prepare("UPDATE usertbl SET profile_picture=?, updated_at=CURRENT_TIMESTAMP WHERE userid=?");
$upd->bind_param('si', $dbPath, $userid);
$upd->execute();
$upd->close();

// Public URL for Flutter
$publicUrl = (isset($_SERVER['HTTPS']) ? "https" : "http") . "://" . $_SERVER['HTTP_HOST'] . "/carenta/" . $dbPath;

echo json_encode([
    'ok' => true,
    'message' => 'Avatar updated successfully',
    'path' => $dbPath,   // stored in DB
    'url' => $publicUrl  // usable by Flutter
], JSON_UNESCAPED_SLASHES);
