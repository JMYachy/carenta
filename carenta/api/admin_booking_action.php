<?php
// api/admin_booking_action.php
// POST rental_id, action=confirm|cancel, admin_id, reason? (for cancel)

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=utf-8");

ini_set("display_errors", 0);
error_reporting(E_ALL);

if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
  http_response_code(204);
  exit;
}

/* ---- DB ---- */
require_once __DIR__ . '/connection_service.php';

try {
  $rentalId = isset($_POST["rental_id"]) ? (int)$_POST["rental_id"] : 0;
  $action   = isset($_POST["action"]) ? strtolower(trim($_POST["action"])) : "";
  $adminId  = isset($_POST["admin_id"]) ? (int)$_POST["admin_id"] : 0;
  $reason   = isset($_POST["reason"]) ? trim($_POST["reason"]) : null;

  if ($rentalId <= 0 || $adminId <= 0 || !in_array($action, ["confirm", "cancel"], true)) {
    http_response_code(400);
    echo json_encode([
      "ok" => false,
      "error" => "BAD_REQUEST",
      "message" => "rental_id, admin_id, and valid action required"
    ]);
    exit;
  }

  // --- Fetch current status ---
  $stmt = $pdo->prepare("SELECT status FROM rentaltbl WHERE rentalid = ?");
  $stmt->execute([$rentalId]);
  $row = $stmt->fetch(PDO::FETCH_ASSOC);
  if (!$row) {
    http_response_code(404);
    echo json_encode(["ok" => false, "error" => "NOT_FOUND", "message" => "Booking not found"]);
    exit;
  }

  $current = strtolower($row["status"] ?? "");
  $pdo->beginTransaction();

  if ($action === "confirm") {
    // ✅ confirm only if pending
    if ($current !== "pending") {
      http_response_code(409);
      echo json_encode([
        "ok" => false,
        "error" => "INVALID_STATE",
        "message" => "Only PENDING bookings can be confirmed"
      ]);
      exit;
    }

    $update = $pdo->prepare("
      UPDATE rentaltbl
         SET status = 'confirmed',
             approved_by = :admin_id,
             updated_at = NOW()
       WHERE rentalid = :rental_id
       LIMIT 1
    ");
    $update->execute([":admin_id" => $adminId, ":rental_id" => $rentalId]);

    if ($update->rowCount() > 0) {
      $pdo->commit();
      echo json_encode(["ok" => true, "message" => "Booking confirmed"]);
    } else {
      throw new Exception("No rows updated");
    }

  } else { // cancel
    // ✅ allow cancel if pending, confirmed, or ongoing
    if (!in_array($current, ["pending", "confirmed", "ongoing"])) {
      http_response_code(409);
      echo json_encode([
        "ok" => false,
        "error" => "INVALID_STATE",
        "message" => "Booking cannot be cancelled because it is already $current"
      ]);
      exit;
    }

    $reason = $reason ?: "Cancelled by admin";

    $update = $pdo->prepare("
      UPDATE rentaltbl
         SET status = 'cancelled',
             cancellation_reason = :reason,
             cancelled_by = 'admin',
             updated_at = NOW()
       WHERE rentalid = :rental_id
       LIMIT 1
    ");
    $update->execute([":reason" => $reason, ":rental_id" => $rentalId]);

    if ($update->rowCount() > 0) {
      $pdo->commit();
      echo json_encode(["ok" => true, "message" => "Booking cancelled"]);
    } else {
      throw new Exception("No rows updated");
    }
  }

} catch (Throwable $e) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  http_response_code(500);
  echo json_encode([
    "ok" => false,
    "error" => "SERVER_ERROR",
    "message" => $e->getMessage()
  ]);
}
?>
