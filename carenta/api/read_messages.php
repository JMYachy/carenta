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
  echo json_encode(array_merge(["success" => true, "status" => "success"], $payload), JSON_UNESCAPED_UNICODE);
  exit;
}
function fail($msg) {
  echo json_encode(["success" => false, "status" => "error", "message" => $msg], JSON_UNESCAPED_UNICODE);
  exit;
}

// Decode JSON safely
$raw = file_get_contents("php://input");
$input = json_decode($raw, true);
if (!$input && isset($_POST['message_id'])) $input = $_POST;

$message_id = intval($input['message_id'] ?? 0);
if (!$message_id) fail("Missing message_id");

try {
  $stmt = $pdo->prepare("UPDATE messagestbl SET is_read = 1, read_at = NOW() WHERE message_id = :id");
  $stmt->execute([':id' => $message_id]);
  ok(["message" => "Message marked as read"]);
} catch (Throwable $e) {
  fail("Unable to mark message as read: " . $e->getMessage());
}
?>
