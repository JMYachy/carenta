<?php
/**
 * update_car_status.php
 * 
 * Updates only the status of a car (available, in-maintenance, disabled).
 * Used by AdminEditCarService.updateCarStatus()
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
if (empty($data['carid'])) fail("Missing carid.");
if (empty($data['status'])) fail("Missing status value.");

$carid = (int)$data['carid'];
$status = strtolower(trim($data['status']));

$validStatuses = ['available', 'in-maintenance', 'disabled'];
if (!in_array($status, $validStatuses)) {
  fail("Invalid status value. Allowed: available, in-maintenance, disabled.");
}

/* --- Execute Update --- */
try {
  $stmt = $pdo->prepare("UPDATE cartbl SET status = :status, updated_at = NOW() WHERE carid = :carid");
  $stmt->execute(['status' => $status, 'carid' => $carid]);

  if ($stmt->rowCount() > 0) {
    ok("Car status updated to '{$status}'.");
  } else {
    ok("No change applied. Status already set to '{$status}'.");
  }
} catch (PDOException $e) {
  fail("Database error: " . $e->getMessage());
}
