<?php
header('Content-Type: application/json');
$raw = file_get_contents("php://input");
$event = json_decode($raw, true);

// Log for debugging
file_put_contents("paymongo_log.txt", $raw.PHP_EOL, FILE_APPEND);

if (!isset($event['data']['attributes']['type'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid payload"]);
    exit;
}

$type = $event['data']['attributes']['type'];

if ($type === "payment.paid") {
    $paymentData = $event['data']['attributes']['data'];
    $intentId = $paymentData['id'] ?? null;

    // TODO: link PaymentIntent to rentalId (store intentId when creating booking!)
    // Example: UPDATE rentaltbl SET status='confirmed' WHERE rentalid=...

    http_response_code(200);
    echo json_encode(["success" => true, "message" => "Payment confirmed"]);
}
elseif ($type === "payment.failed") {
    // Update booking as failed/cancelled
    http_response_code(200);
    echo json_encode(["success" => true, "message" => "Payment failed"]);
}
else {
    http_response_code(200);
    echo json_encode(["success" => true, "message" => "Event ignored"]);
}
