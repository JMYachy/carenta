<?php
header('Content-Type: application/json');

$secretKey = "ssk_test_Uytt6LKc7QgYcvVJ216E6Fhq"; // replace with your real PayMongo Secret Key

$payload = json_decode(file_get_contents('php://input'), true);

$amount = intval($payload['amount'] * 100); // PayMongo expects cents
$currency = $payload['currency'] ?? "PHP";
$method = $payload['method'] ?? "gcash";

// Prepare PaymentIntent
$data = [
    "data" => [
        "attributes" => [
            "amount" => $amount,
            "currency" => $currency,
            "payment_method_allowed" => [$method],
            "payment_method_options" => ["request_three_d_secure" => "any"],
            "description" => "Car booking payment"
        ]
    ]
];

$ch = curl_init("https://api.paymongo.com/v1/payment_intents");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Content-Type: application/json",
    "Authorization: Basic " . base64_encode($secretKey . ":")
]);

$response = curl_exec($ch);
curl_close($ch);

echo $response;
