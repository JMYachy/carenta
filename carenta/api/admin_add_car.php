<?php
// ===== Strict JSON API: keep output clean =====
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/php-error.log');

// ----- CORS -----
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
header("Content-Type: application/json; charset=utf-8");

// ----- DB CONNECTION -----
require_once __DIR__ . '/connection_service.php';
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// ----- UPLOAD DIRECTORIES -----
$imageDir = __DIR__ . "/../uploads/images/";
$videoDir = __DIR__ . "/../uploads/videos/";
$publicImageBase = "uploads/images/";
$publicVideoBase = "uploads/videos/";

if (!is_dir($imageDir)) mkdir($imageDir, 0777, true);
if (!is_dir($videoDir)) mkdir($videoDir, 0777, true);

// ----- HELPERS -----
function sanitize_filename($name) {
  return trim(preg_replace('/[^\w\.\-]+/u', '_', $name), '_');
}
function json_fail($msg, $pdo = null, $code = 400) {
  if ($pdo) $pdo->rollBack();
  http_response_code($code);
  echo json_encode(["success" => false, "message" => $msg], JSON_UNESCAPED_SLASHES);
  exit;
}
function in_whitelist($mime, $type = 'image') {
  $img = ['image/jpeg','image/png','image/webp','image/gif'];
  $vid = ['video/mp4','video/quicktime','video/webm','video/3gpp'];
  return $type === 'image' ? in_array($mime, $img, true) : in_array($mime, $vid, true);
}
function normalize_time_24h(?string $s): ?string {
  if ($s === null) return null;
  $s = trim($s);
  if ($s === '') return null;
  $formats = ['g:i A','g:iA','h:i A','h:iA','H:i'];
  foreach ($formats as $f) {
    $dt = DateTime::createFromFormat($f, strtoupper($s));
    if ($dt) return $dt->format('H:i');
  }
  $s2 = preg_replace('/[^0-9:apmAPM ]/', '', $s);
  return $s2 !== $s ? normalize_time_24h($s2) : null;
}

// ----- VALIDATE REQUIRED FIELDS -----
$required = [
  'year','manufacturer','model','type','licensePlate','color',
  'transmission','fuelType','milage','seatingCap','status','withDriver'
];
foreach ($required as $k) {
  if (!isset($_POST[$k]) || trim((string)$_POST[$k]) === '') {
    json_fail("Missing field: $k", $pdo);
  }
}

$uploadedBy = isset($_POST['adminId']) && $_POST['adminId'] !== '' ? (int)$_POST['adminId'] : null;

// ----- Parse Pricing -----
$prices = null;
if (!empty($_POST['prices'])) {
  $decoded = json_decode($_POST['prices'], true);
  if (!is_array($decoded)) json_fail("Invalid 'prices' JSON", $pdo);
  $prices = [
    'daily'    => isset($decoded['daily'])    ? (float)$decoded['daily']    : null,
    'weekly'   => isset($decoded['weekly'])   ? (float)$decoded['weekly']   : null,
    'monthly'  => isset($decoded['monthly'])  ? (float)$decoded['monthly']  : null,
    'promo'    => $decoded['promo']    ?? null,
    'discount' => isset($decoded['discount']) ? (float)$decoded['discount'] : null,
  ];
}

// ----- Parse Schedule -----
$scheduleItems = [];
if (!empty($_POST['schedule'])) {
  $scheduleItems = json_decode($_POST['schedule'], true);
  if (!is_array($scheduleItems)) json_fail("Invalid 'schedule' JSON", $pdo);
  $allowedDays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  foreach ($scheduleItems as $i => &$row) {
    if (empty($row['day']) || !in_array($row['day'], $allowedDays, true)) {
      json_fail("Invalid schedule day at index $i", $pdo);
    }
    $row['start_time'] = normalize_time_24h($row['start_time'] ?? '08:00') ?? '08:00';
    $row['end_time']   = normalize_time_24h($row['end_time'] ?? '17:00') ?? '17:00';
    $row['is_available'] = (int)($row['is_available'] ?? 1);
    $row['notes'] = $row['notes'] ?? null;
  }
  unset($row);
}

// ----- BEGIN TRANSACTION -----
$pdo->beginTransaction();

try {
  // --- INSERT INTO cartbl ---
  $sqlCar = "INSERT INTO cartbl 
    (year, manufacturer, model, type, license_plate, color, transmission, fueltype, milage, seatingcap, status, withDriver)
    VALUES (:year, :manufacturer, :model, :type, :license_plate, :color, :transmission, :fueltype, :milage, :seatingcap, :status, :withDriver)";
  $stmtCar = $pdo->prepare($sqlCar);
  $stmtCar->execute([
    ':year' => $_POST['year'],
    ':manufacturer' => $_POST['manufacturer'],
    ':model' => $_POST['model'],
    ':type' => $_POST['type'],
    ':license_plate' => $_POST['licensePlate'],
    ':color' => $_POST['color'],
    ':transmission' => $_POST['transmission'],
    ':fueltype' => $_POST['fuelType'],
    ':milage' => $_POST['milage'],
    ':seatingcap' => $_POST['seatingCap'],
    ':status' => $_POST['status'],
    ':withDriver' => $_POST['withDriver']
  ]);
  $carId = $pdo->lastInsertId();

  // --- INSERT INTO pricetbl ---
  if ($prices) {
    $sqlPrice = "INSERT INTO pricetbl
      (carid, currency, hourly_rate, daily_rate, weekly_rate, monthly_rate, seasonal, promo_code, discount_percent, valid_from, valid_to, set_by_admin)
      VALUES (:carid, 'PHP', NULL, :daily, :weekly, :monthly, 0, :promo, :discount, NULL, NULL, :set_by)";
    $stmtPrice = $pdo->prepare($sqlPrice);
    $stmtPrice->execute([
      ':carid' => $carId,
      ':daily' => $prices['daily'],
      ':weekly' => $prices['weekly'],
      ':monthly' => $prices['monthly'],
      ':promo' => $prices['promo'],
      ':discount' => $prices['discount'],
      ':set_by' => $uploadedBy
    ]);
  }

  // --- INSERT INTO car_schedule ---
  if ($scheduleItems) {
    $sqlSched = "INSERT INTO car_schedule (carid, available_day, start_time, end_time, is_available, notes)
                 VALUES (:carid, :day, :start, :end, :avail, :notes)";
    $stmtSched = $pdo->prepare($sqlSched);
    foreach ($scheduleItems as $s) {
      $stmtSched->execute([
        ':carid' => $carId,
        ':day' => $s['day'],
        ':start' => $s['start_time'],
        ':end' => $s['end_time'],
        ':avail' => $s['is_available'],
        ':notes' => $s['notes']
      ]);
    }
  }

  // --- HANDLE FILE UPLOADS ---
  $savedMedia = [];

  // Multiple images[]
  if (!empty($_FILES['images']['tmp_name'])) {
    foreach ($_FILES['images']['tmp_name'] as $i => $tmp) {
      if (!is_uploaded_file($tmp)) continue;
      $orig = sanitize_filename($_FILES['images']['name'][$i] ?? 'image.jpg');
      $ext  = pathinfo($orig, PATHINFO_EXTENSION);
      $mime = $_FILES['images']['type'][$i] ?? 'application/octet-stream';
      $size = (int)($_FILES['images']['size'][$i] ?? 0);
      if (!in_whitelist($mime, 'image')) throw new Exception("Invalid image type: $mime");
      $fname = uniqid("img_", true) . ($ext ? ".$ext" : "");
      $dest  = $imageDir . $fname;
      if (!move_uploaded_file($tmp, $dest)) throw new Exception("Failed to move uploaded image");
      $publicPath = $publicImageBase . $fname;
      $pdo->prepare("INSERT INTO mediatbl (carid, uploaded_by, media_type, media_url, mime_type, file_size)
                     VALUES (?, ?, 'image', ?, ?, ?)")
          ->execute([$carId, $uploadedBy, $publicPath, $mime, $size]);
      $savedMedia[] = ["type" => "image", "url" => $publicPath];
    }
  }

  // Single video
  if (isset($_FILES['video']['tmp_name']) && is_uploaded_file($_FILES['video']['tmp_name'])) {
    $orig = sanitize_filename($_FILES['video']['name'] ?? 'video.mp4');
    $ext  = pathinfo($orig, PATHINFO_EXTENSION);
    $mime = $_FILES['video']['type'] ?? 'application/octet-stream';
    $size = (int)($_FILES['video']['size'] ?? 0);
    if (!in_whitelist($mime, 'video')) throw new Exception("Invalid video type: $mime");
    $fname = uniqid("vid_", true) . ($ext ? ".$ext" : "");
    $dest  = $videoDir . $fname;
    if (!move_uploaded_file($_FILES['video']['tmp_name'], $dest)) throw new Exception("Failed to move uploaded video");
    $publicPath = $publicVideoBase . $fname;
    $pdo->prepare("INSERT INTO mediatbl (carid, uploaded_by, media_type, media_url, mime_type, file_size)
                   VALUES (?, ?, 'video', ?, ?, ?)")
        ->execute([$carId, $uploadedBy, $publicPath, $mime, $size]);
    $savedMedia[] = ["type" => "video", "url" => $publicPath];
  }

  // --- COMMIT ---
  $pdo->commit();

  echo json_encode([
    "success" => true,
    "message" => "Car successfully added.",
    "carId" => (int)$carId,
    "media" => $savedMedia
  ], JSON_UNESCAPED_SLASHES);

} catch (Throwable $e) {
  json_fail("Error: " . $e->getMessage(), $pdo);
}
?>
