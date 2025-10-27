<?php
/**
 * update_car_details.php
 * 
 * Secure endpoint for updating car information.
 * Used by AdminEditCarService.updateCarDetails()
 */

session_start();
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { 
  http_response_code(200);
  exit;
}

require_once __DIR__ . '/connection_service.php';

/* Helper functions */
function ok($message, $extra = []) {
  echo json_encode(array_merge([
    "success" => true,
    "status" => "success",
    "message" => $message
  ], $extra), JSON_UNESCAPED_UNICODE);
  exit;
}

function fail($message) {
  echo json_encode([
    "success" => false,
    "status" => "error",
    "message" => $message
  ], JSON_UNESCAPED_UNICODE);
  exit;
}

/* --- Input Handling --- */
$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

if (!$data) fail("Invalid or missing JSON body.");
if (empty($data['carid'])) fail("Missing required field: carid.");

$carid = (int)$data['carid'];

/* Allowed editable fields */
$allowed = [
  "year", "manufacturer", "model", "type", "license_plate",
  "color", "transmission", "fueltype", "milage", "seatingcap",
  "status", "withDriver"
];

$fields = [];
$params = [];

foreach ($allowed as $col) {
  if (isset($data[$col])) {
    $fields[] = "$col = :$col";
    $params[$col] = trim($data[$col]);
  }
}

if (empty($fields)) fail("No valid fields provided to update.");

$params['carid'] = $carid;

/* --- Execute Update --- */
try {
  $sql = "UPDATE cartbl SET " . implode(", ", $fields) . ", updated_at = NOW() WHERE carid = :carid";
  $stmt = $pdo->prepare($sql);
  $stmt->execute($params);

  if ($stmt->rowCount() > 0) {
    ok("Car details updated successfully.");
  } else {
    ok("No changes were made (fields may be identical).");
  }
} catch (PDOException $e) {
  fail("Database error: " . $e->getMessage());
}
