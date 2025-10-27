<?php
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/connection_service.php';

/**
 * 🧩 Expected POST parameters:
 *   rental_id   -> booking ID (int)
 *   action      -> string: cancel | confirm | complete
 *   reason      -> optional, string for cancellation reason
 */

$input = json_decode(file_get_contents('php://input'), true) ?? $_POST;

$rentalId = isset($input['rental_id']) ? (int)$input['rental_id'] : 0;
$action   = strtolower(trim($input['action'] ?? ''));
$reason   = trim($input['reason'] ?? '');

if ($rentalId <= 0 || $action === '') {
    http_response_code(400);
    echo json_encode([
        "ok" => false,
        "message" => "Missing rental_id or action parameter."
    ]);
    exit;
}

$validActions = ['cancel', 'confirm', 'complete'];
if (!in_array($action, $validActions)) {
    http_response_code(400);
    echo json_encode([
        "ok" => false,
        "message" => "Invalid action. Allowed: cancel, confirm, complete."
    ]);
    exit;
}

try {
    $pdo->beginTransaction();

    switch ($action) {
        case 'cancel':
            $stmt = $pdo->prepare("
                UPDATE rentaltbl
                SET status = 'cancelled', cancellation_reason = :reason, updated_at = NOW()
                WHERE rentalid = :id
            ");
            $stmt->execute([
                ':id' => $rentalId,
                ':reason' => $reason ?: 'Cancelled by user'
            ]);
            $msg = "Booking has been cancelled.";
            break;

        case 'confirm':
            $stmt = $pdo->prepare("
                UPDATE rentaltbl
                SET status = 'confirmed', updated_at = NOW()
                WHERE rentalid = :id
            ");
            $stmt->execute([':id' => $rentalId]);
            $msg = "Booking confirmed.";
            break;

        case 'complete':
            $stmt = $pdo->prepare("
                UPDATE rentaltbl
                SET status = 'completed', updated_at = NOW()
                WHERE rentalid = :id
            ");
            $stmt->execute([':id' => $rentalId]);
            $msg = "Booking marked as completed.";
            break;
    }

    $pdo->commit();

    echo json_encode([
        "ok" => true,
        "message" => $msg,
    ]);

} catch (Throwable $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode([
        "ok" => false,
        "message" => "Error performing action",
        "error" => $e->getMessage()
    ]);
}
