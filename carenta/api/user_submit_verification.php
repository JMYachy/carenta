<?php
/**
 * user_submit_verification.php
 * Handles renter/guest ID upload and verification submission
 * Sets role='guest', status='pending', is_verified=0 until reviewed
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(200);
  exit;
}

require_once __DIR__ . '/connection_service.php';

// ---------- Helper Functions ----------
function respond($ok, $msg, $extra = []) {
  echo json_encode(array_merge([
    "success" => $ok,
    "status"  => $ok ? "success" : "error",
    "message" => $msg
  ], $extra), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
  exit;
}

// ---------- Validate Input ----------
$userid = isset($_POST['userid']) ? (int)$_POST['userid'] : 0;
$idType = trim($_POST['id_type'] ?? '');

if ($userid <= 0 || $idType === '') respond(false, "Missing required fields (userid, id_type)");

$validTypes = ['National ID', 'Driver License'];
if (!in_array($idType, $validTypes, true)) respond(false, "Invalid ID type");

// ---------- Upload Directory ----------
$uploadDir = __DIR__ . '/../uploads/ids/';
if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);

// ---------- File Upload Helper ----------
function save_upload($key, $prefix, $userId) {
  global $uploadDir;
  if (!isset($_FILES[$key]) || $_FILES[$key]['error'] !== UPLOAD_ERR_OK) return null;

  $allowedExt = ['jpg', 'jpeg', 'png', 'pdf'];
  $ext = strtolower(pathinfo($_FILES[$key]['name'], PATHINFO_EXTENSION));
  if (!in_array($ext, $allowedExt, true))
    respond(false, "Invalid file type for $key (allowed: jpg, png, pdf)");

  if ($_FILES[$key]['size'] > 5 * 1024 * 1024)
    respond(false, "$key exceeds 5MB limit");

  $filename = sprintf('%s_%d_%s.%s', $prefix, $userId, uniqid(), $ext);
  $dest = $uploadDir . $filename;
  if (!move_uploaded_file($_FILES[$key]['tmp_name'], $dest))
    respond(false, "Failed to save $key");

  return 'uploads/ids/' . $filename;
}

// ---------- Save Uploaded Files ----------
$idFrontUrl = save_upload('id_front', 'front', $userid);
$idBackUrl  = save_upload('id_back',  'back',  $userid);
if (!$idFrontUrl) respond(false, "Front ID image required");

// ---------- Database Transaction ----------
try {
  $pdo->beginTransaction();

  // Check if record already exists
  $check = $pdo->prepare("SELECT verification_id FROM user_verificationtbl WHERE userid = ?");
  $check->execute([$userid]);
  $exists = $check->fetchColumn();

  if ($exists) {
    $update = $pdo->prepare("
      UPDATE user_verificationtbl 
      SET id_type = ?, id_front_url = ?, id_back_url = ?, status = 'pending',
          reviewed_by = NULL, review_notes = NULL, reviewed_at = NULL, submitted_at = NOW()
      WHERE userid = ?
    ");
    $update->execute([$idType, $idFrontUrl, $idBackUrl, $userid]);
  } else {
    $insert = $pdo->prepare("
      INSERT INTO user_verificationtbl (userid, id_type, id_front_url, id_back_url, status, submitted_at)
      VALUES (?, ?, ?, ?, 'pending', NOW())
    ");
    $insert->execute([$userid, $idType, $idFrontUrl, $idBackUrl]);
  }

  // Mark user as guest/pending
  $pdo->prepare("
    UPDATE usertbl
    SET role = 'guest', is_verified = 0, status = 'pending'
    WHERE userid = ?
  ")->execute([$userid]);

  // Notify admin/manager (optional)
  $pdo->prepare("
    INSERT INTO notificationtbl (userid, title, message, type, created_at)
    VALUES (?, 'New Verification Request', 'A user has submitted verification for review.', 'verification', NOW())
  ")->execute([$userid]);

  $pdo->commit();

  // Build absolute URLs
  $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
  $base = $scheme . '://' . $_SERVER['HTTP_HOST'];
  $frontFull = $base . '/' . ltrim($idFrontUrl, '/');
  $backFull  = $idBackUrl ? $base . '/' . ltrim($idBackUrl, '/') : null;

  respond(true, "Verification submitted successfully and awaiting review.", [
    "data" => [
      "userid" => $userid,
      "id_type" => $idType,
      "id_front_url" => $frontFull,
      "id_back_url" => $backFull,
      "status" => "pending"
    ]
  ]);
} catch (Throwable $e) {
  $pdo->rollBack();
  respond(false, "Server error: " . $e->getMessage());
}
