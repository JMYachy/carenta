<?php
require_once __DIR__ . '/connection_service.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(200);
  exit;
}

if (empty($_GET['carid'])) {
  echo json_encode(["success" => false, "message" => "Missing carid."]);
  exit;
}

$carid = intval($_GET['carid']);

try {
  $stmt = $pdo->prepare("
    SELECT c.*, 
           p.daily_rate, p.weekly_rate, p.monthly_rate, 
           p.currency, p.promo_code, p.discount_percent,
           GROUP_CONCAT(m.media_url) AS image_urls
    FROM cartbl c
    LEFT JOIN pricetbl p ON p.carid = c.carid
    LEFT JOIN mediatbl m ON m.carid = c.carid AND m.media_type = 'image'
    WHERE c.carid = :carid
    GROUP BY c.carid
  ");
  $stmt->execute(['carid' => $carid]);
  $car = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$car) {
    echo json_encode(["success" => false, "message" => "Car not found."]);
    exit;
  }

  // Convert concatenated images to array
  $car['image_urls'] = $car['image_urls'] ? explode(',', $car['image_urls']) : [];

  echo json_encode(["success" => true, "data" => $car]);
} catch (PDOException $e) {
  echo json_encode(["success" => false, "message" => $e->getMessage()]);
}
