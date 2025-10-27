<?php
session_start();
error_reporting(0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
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

// Decode JSON
$raw = file_get_contents("php://input");
$input = json_decode($raw, true);
if (!$input && isset($_POST['message_text'])) $input = $_POST;

$message_text = trim($input['message_text'] ?? '');
$renter_id    = intval($input['renter_id'] ?? ($_GET['renter_id'] ?? null));
$adminid      = $_SESSION['adminid'] ?? ($_GET['admin_id'] ?? ($_POST['admin_id'] ?? null));

if ($message_text === '') fail("Message text is required.");
if (!$renter_id) fail("Missing renter_id.");

try {
  $role = $adminid ? 'admin' : 'renter';
  $stmt = $pdo->prepare("
    INSERT INTO messagestbl (admin_id, renter_id, sender_role, message_text, is_read, sent_at)
    VALUES (:aid, :rid, :role, :msg, 0, NOW())
  ");
  $stmt->execute([
    ':aid' => $adminid ?: null,
    ':rid' => $renter_id,
    ':role' => $role,
    ':msg' => $message_text
  ]);

  $id = $pdo->lastInsertId();
  $new = $pdo->prepare("SELECT * FROM messagestbl WHERE message_id = :id");
  $new->execute([':id' => $id]);
  ok(["message" => "Message sent", "data" => $new->fetch()]);
} catch (Throwable $e) {
  fail("Unable to send: " . $e->getMessage());
}
?>
