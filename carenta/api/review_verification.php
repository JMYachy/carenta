<?php
/**
 * review_verification.php
 * Manager reviews pending user verification requests.
 * Supports actions: approve / reject
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

// ---------- Helpers ----------
function respond($ok, $msg, $extra = []) {
  echo json_encode(array_merge([
    "success" => $ok,
    "status"  => $ok ? "success" : "error",
    "message" => $msg
  ], $extra), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
  exit;
}

// ---------- Input Validation ----------
$userid = isset($_POST['userid']) ? (int)$_POST['userid'] : 0;
$action = strtolower(trim($_POST['action'] ?? ''));
$notes  = trim($_POST['notes'] ?? '');

if ($userid <= 0 || ($action !== 'approved' && $action !== 'rejected')) {
  respond(false, "Invalid request: missing or invalid fields.");
}

try {
  // Check if pending verification exists
  $stmt = $pdo->prepare("
    SELECT verification_id, status
    FROM user_verificationtbl
    WHERE userid = :id
    LIMIT 1
  ");
  $stmt->execute([':id' => $userid]);
  $record = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$record) respond(false, "No verification record found for this user.");
  if ($record['status'] !== 'pending') respond(false, "Verification already reviewed.");

  $pdo->beginTransaction();

  // ---------- APPROVE ----------
  if ($action === 'approved') {
    // Update verification table
    $upd = $pdo->prepare("
      UPDATE user_verificationtbl
      SET status = 'approved', review_notes = :notes, reviewed_at = NOW()
      WHERE userid = :id
    ");
    $upd->execute([':notes' => $notes, ':id' => $userid]);

    // Update user account (mark as verified renter)
    $pdo->prepare("
      UPDATE usertbl
      SET is_verified = 1, role = 'renter', status = 'active'
      WHERE userid = :id
    ")->execute([':id' => $userid]);

    // Add notification
    $pdo->prepare("
      INSERT INTO notificationtbl (userid, title, message, type, created_at)
      VALUES (:uid, 'Verification Approved', 'Your account has been verified successfully.', 'verification', NOW())
    ")->execute([':uid' => $userid]);

    $pdo->commit();
    respond(true, "Verification approved successfully.", [
      "data" => ["userid" => $userid, "new_status" => "approved"]
    ]);
  }

  // ---------- REJECT ----------
  if ($action === 'rejected') {
    $upd = $pdo->prepare("
      UPDATE user_verificationtbl
      SET status = 'rejected', review_notes = :notes, reviewed_at = NOW()
      WHERE userid = :id
    ");
    $upd->execute([':notes' => $notes, ':id' => $userid]);

    // Update user account (remain guest / pending)
    $pdo->prepare("
      UPDATE usertbl
      SET is_verified = 0, role = 'guest', status = 'rejected'
      WHERE userid = :id
    ")->execute([':id' => $userid]);

    // Notify user
    $pdo->prepare("
      INSERT INTO notificationtbl (userid, title, message, type, created_at)
      VALUES (:uid, 'Verification Rejected', :msg, 'verification', NOW())
    ")->execute([
      ':uid' => $userid,
      ':msg' => ($notes !== '' ? $notes : 'Your verification has been rejected.')
    ]);

    $pdo->commit();
    respond(true, "Verification rejected successfully.", [
      "data" => ["userid" => $userid, "new_status" => "rejected"]
    ]);
  }

} catch (Throwable $e) {
  $pdo->rollBack();
  respond(false, "Server error: " . $e->getMessage());
}
