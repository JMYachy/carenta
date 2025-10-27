<?php
/**
 * user_verification_list.php
 * Fetches all user verification records (pending, approved, or rejected)
 * Used by manager dashboard to review pending verifications.
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
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

try {
  // Optional: filter by status (default: pending)
  $status = isset($_GET['status']) ? strtolower(trim($_GET['status'])) : 'pending';

  $validStatuses = ['pending', 'approved', 'rejected', 'all'];
  if (!in_array($status, $validStatuses, true)) {
    respond(false, "Invalid status filter. Must be one of: pending, approved, rejected, all.");
  }

  // ✅ Build SQL query
  $sql = "
    SELECT 
      u.userid,
      u.first_name,
      u.last_name,
      u.email,
      u.phone_number,
      v.id_type,
      v.id_front_url,
      v.id_back_url,
      v.status,
      v.review_notes,
      v.submitted_at,
      v.reviewed_at
    FROM user_verificationtbl v
    INNER JOIN usertbl u ON u.userid = v.userid
  ";

  // Add filter if not 'all'
  if ($status !== 'all') {
    $sql .= " WHERE v.status = :status";
  }

  $sql .= " ORDER BY v.submitted_at DESC";

  $stmt = $pdo->prepare($sql);
  if ($status !== 'all') {
    $stmt->execute([':status' => $status]);
  } else {
    $stmt->execute();
  }

  $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

  // ✅ Convert image paths to absolute URLs
  $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
  $base = $scheme . '://' . $_SERVER['HTTP_HOST'];

  foreach ($rows as &$r) {
    if (!empty($r['id_front_url']) && !preg_match('#^https?://#', $r['id_front_url'])) {
      $r['id_front_url'] = $base . '/' . ltrim($r['id_front_url'], '/');
    }
    if (!empty($r['id_back_url']) && !preg_match('#^https?://#', $r['id_back_url'])) {
      $r['id_back_url'] = $base . '/' . ltrim($r['id_back_url'], '/');
    }
  }

  respond(true, "Verification list fetched successfully", ["data" => $rows]);

} catch (Throwable $e) {
  respond(false, "Server error: " . $e->getMessage());
}
