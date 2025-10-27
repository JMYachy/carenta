<?php
// api/admin_upload_avatar.php
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
  if ($adminId <= 0) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'BAD_REQUEST', 'message' => 'admin_id required']);
    exit;
  }

  if (!isset($_FILES['avatar'])) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'NO_FILE', 'message' => 'No file uploaded']);
    exit;
  }

  $up = $_FILES['avatar'];
  if ($up['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'UPLOAD_FAIL', 'message' => 'File upload failed']);
    exit;
  }

  // ✅ MIME type and size validation
  $allowed = [
    'image/jpeg' => '.jpg',
    'image/png'  => '.png',
    'image/webp' => '.webp',
  ];

  $finfo = finfo_open(FILEINFO_MIME_TYPE);
  $mime = finfo_file($finfo, $up['tmp_name']);
  finfo_close($finfo);

  if (!isset($allowed[$mime])) {
    http_response_code(415);
    echo json_encode(['ok' => false, 'error' => 'BAD_TYPE', 'message' => 'Unsupported image type']);
    exit;
  }

  if ($up['size'] > 5 * 1024 * 1024) { // 5 MB
    http_response_code(413);
    echo json_encode(['ok' => false, 'error' => 'FILE_TOO_BIG', 'message' => 'File exceeds 5MB limit']);
    exit;
  }

  // ✅ Prepare upload directory
  $dir = __DIR__ . '/../uploads/avatars';
  if (!is_dir($dir)) {
    mkdir($dir, 0777, true);
  }

  $ext = $allowed[$mime];
  $fname = 'admin_' . $adminId . '_' . time() . $ext;
  $path = $dir . '/' . $fname;

  if (!move_uploaded_file($up['tmp_name'], $path)) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'MOVE_FAIL', 'message' => 'Failed to move uploaded file']);
    exit;
  }

  // ✅ Build public URL (auto-detect HTTP/HTTPS + correct folder)
  $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
  $base = $scheme . '://' . $_SERVER['HTTP_HOST'];
  $publicUrl = $base . '/uploads/avatars/' . $fname; // hosted path (no /carenta prefix on Hostinger)

  // ✅ Update database
  $stmt = $pdo->prepare("UPDATE admintbl SET profile_picture = :url, updated_at = NOW() WHERE adminid = :id LIMIT 1");
  $stmt->execute([':url' => $publicUrl, ':id' => $adminId]);

  echo json_encode([
    'ok' => true,
    'message' => 'Avatar updated successfully',
    'avatar_url' => $publicUrl
  ], JSON_UNESCAPED_SLASHES);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode([
    'ok' => false,
    'error' => 'SERVER_ERROR',
    'message' => $e->getMessage()
  ]);
}
?>
