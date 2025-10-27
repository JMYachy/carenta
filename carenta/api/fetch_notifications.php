<?php
require_once __DIR__ . '/connection_service.php';
session_start();

$renter_id = $_SESSION['userid'] ?? ($_GET['renter_id'] ?? null);
if (!$renter_id) {
  echo json_encode(["success" => false, "message" => "Missing renter ID."]);
  exit;
}

try {
  $stmt = $pdo->prepare("
    SELECT notifid AS id, type, title, message AS content, status AS is_read,
           DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') AS created_at
    FROM notificationtbl
    WHERE userid = :rid
    ORDER BY created_at DESC
  ");
  $stmt->execute([':rid' => $renter_id]);
  $data = $stmt->fetchAll();

  echo json_encode(["success" => true, "notifications" => $data]);
} catch (Throwable $e) {
  echo json_encode(["success" => false, "message" => $e->getMessage()]);
}
?>
