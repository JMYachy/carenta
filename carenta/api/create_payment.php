<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once "connection_service.php";

try {
    $userId    = (int)($_POST['user_id'] ?? 0);
    $rentalId  = (int)($_POST['rental_id'] ?? 0);
    $amount    = (float)($_POST['amount'] ?? 0);
    $method    = trim($_POST['payment_method'] ?? 'Cash');
    $reference = trim($_POST['reference_no'] ?? '');
    $status    = trim($_POST['payment_status'] ?? 'Paid');

    if ($userId <= 0 || $rentalId <= 0 || $amount <= 0) {
        http_response_code(400);
        echo json_encode(["ok" => false, "message" => "Missing or invalid fields"]);
        exit;
    }

    $stmt = $pdo->prepare("
        INSERT INTO paymenttbl (userid, rentalid, amount, payment_method, reference_no, payment_status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ");
    $stmt->execute([$userId, $rentalId, $amount, $method, $reference, $status]);

    $paymentId = $pdo->lastInsertId();

    echo json_encode([
        "ok" => true,
        "message" => "Payment created successfully",
        "data" => [
            "payment_id" => (int)$paymentId,
            "user_id" => $userId,
            "rental_id" => $rentalId,
            "amount" => $amount,
            "payment_method" => $method,
            "reference_no" => $reference,
            "payment_status" => $status
        ]
    ], JSON_UNESCAPED_SLASHES);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["ok" => false, "message" => "Database error: " . $e->getMessage()]);
}
