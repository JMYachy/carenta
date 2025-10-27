<?php
session_start();
error_reporting(0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=utf-8");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

require_once __DIR__ . '/connection_service.php';

function ok($payload = []) {
  echo json_encode(array_merge(["success" => true], $payload), JSON_UNESCAPED_UNICODE);
  exit;
}
function fail($msg) {
  echo json_encode(["success" => false, "message" => $msg], JSON_UNESCAPED_UNICODE);
  exit;
}

$userid  = $_SESSION['userid']  ?? ($_GET['renter_id'] ?? null);
$adminid = $_SESSION['adminid'] ?? ($_GET['admin_id'] ?? null);

if (!$userid && !$adminid) fail("Unauthorized: no active session or user ID");

try {
  if ($userid) {
    // renter view
    $stmt = $pdo->prepare("
      SELECT message_id, admin_id, renter_id, sender_role, message_text, is_read,
             DATE_FORMAT(sent_at, '%Y-%m-%d %H:%i:%s') AS sent_at
      FROM messagestbl WHERE renter_id = :rid ORDER BY sent_at DESC
    ");
    $stmt->execute([':rid' => $userid]);
  } else {
    // admin view: filter by renter if provided
    $renter_id = $_GET['renter_id'] ?? null;
    if (!$renter_id) fail("Missing renter_id for admin fetch");
    $stmt = $pdo->prepare("
      SELECT * FROM messagestbl WHERE renter_id = :rid ORDER BY sent_at DESC
    ");
    $stmt->execute([':rid' => $renter_id]);
  }

  ok(["messages" => $stmt->fetchAll()]);
} catch (Throwable $e) {
  fail("DB error: " . $e->getMessage());
}
?>
