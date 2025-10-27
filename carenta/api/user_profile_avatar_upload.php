<?php
// ======================================================
// user_profile_avatar_upload.php — Upload user avatar
// ======================================================

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(204);
  exit;
}

require_once __DIR__ . '/connection_service.php';

// ---------- Helper ----------
function respond($ok, $msg, $extra = []) {
  echo json_encode(array_merge([
    'success' => $ok,
    'status'  => $ok ? 'success' : 'error',
    'message' => $msg
  ], $extra), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
  exit;
}

try {
  $userId = (int)($_POST['user_id'] ?? 0);
  if ($userId <= 0) respond(false, 'Missing or invalid user_id');

  if (empty($_FILES['avatar'])) respond(false, 'No avatar file uploaded');

  $file = $_FILES['avatar'];
  if ($file['error'] !== UPLOAD_ERR_OK) respond(false, 'Upload error (code '.$file['error'].')');

  // ✅ Validate file type + size
  $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
  $allowed = ['jpg', 'jpeg', 'png', 'webp'];
  if (!in_array($ext, $allowed, true))
    respond(false, 'Invalid file type. Allowed: JPG, PNG, WEBP');
  if ($file['size'] > 2 * 1024 * 1024)
    respond(false, 'File too large (max 2MB)');

  // ✅ Ensure upload directory exists
  $uploadDir = __DIR__ . '/../uploads/avatars/';
  if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);

  // ✅ Remove old avatar (if exists)
  $check = $pdo->prepare("SELECT profile_picture FROM usertbl WHERE userid = :id LIMIT 1");
  $check->execute([':id' => $userId]);
  $old = $check->fetch(PDO::FETCH_ASSOC);

  if ($old && !empty($old['profile_picture'])) {
    $oldPath = __DIR__ . '/../' . $old['profile_picture'];
    if (is_file($oldPath)) @unlink($oldPath);
  }

  // ✅ Save new file
  $filename = "u{$userId}_" . time() . ".$ext";
  $dbPath = "uploads/avatars/$filename";
  $fullPath = $uploadDir . $filename;

  if (!move_uploaded_file($file['tmp_name'], $fullPath))
    respond(false, 'Failed to save uploaded file');

  // ✅ Update DB
  $stmt = $pdo->prepare("UPDATE usertbl SET profile_picture = :pic, updated_at = NOW() WHERE userid = :id");
  $stmt->execute([':pic' => $dbPath, ':id' => $userId]);

  // ✅ Build full URL for Flutter
  $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
  $base = $scheme . '://' . $_SERVER['HTTP_HOST'];
  $publicUrl = $base . '/' . ltrim($dbPath, '/');

  respond(true, 'Avatar updated successfully', [
    'data' => [
      'user_id' => $userId,
      'avatar_path' => $dbPath,
      'avatar_url'  => $publicUrl
    ]
  ]);

} catch (Throwable $e) {
  http_response_code(500);
  respond(false, 'Server error: ' . $e->getMessage());
}
