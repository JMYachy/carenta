<?php
require_once __DIR__ . '/connection_service.php';
session_start();

$renter_id = $_SESSION['userid'] ?? ($_GET['renter_id'] ?? null);
if (!$renter_id) {
  echo json_encode(["success" => false, "message" => "Missing renter_id"]);
  exit;
}

try {
  $stmt = $pdo->prepare("
    SELECT 
      m.admin_id,
      a.username AS admin_name,
      m.message_text,
      m.sender_role,
      DATE_FORMAT(m.sent_at, '%Y-%m-%d %H:%i:%s') AS sent_at
    FROM messagestbl m
    LEFT JOIN admintbl a ON m.admin_id = a.adminid
    WHERE m.renter_id = :rid
    ORDER BY m.sent_at DESC
  ");
  $stmt->execute([':rid' => $renter_id]);
  $messages = $stmt->fetchAll();

  // Optionally group by admin_id (one conversation per manager)
  $threads = [];
  foreach ($messages as $msg) {
    $key = $msg['admin_id'] ?: 'system';
    if (!isset($threads[$key])) {
      $threads[$key] = $msg;
    }
  }

  echo json_encode(["success" => true, "messages" => array_values($threads)]);
} catch (Throwable $e) {
  echo json_encode(["success" => false, "message" => $e->getMessage()]);
}
?>
