<?php
// ===== Strict JSON API: keep output clean =====
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/php-error.log');

// CORS + preflight
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
header("Content-Type: application/json; charset=utf-8");

// Make sure nothing else was buffered
if (ob_get_level()) { ob_end_clean(); }
ob_start();

// ---------- DB CONNECT ----------
$host = "localhost";
$user = "root";
$pass = "";
$db   = "carentadb";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    http_response_code(500);
    $payload = json_encode(["success" => false, "message" => "DB connection failed"]);
    header("Content-Length: " . strlen($payload));
    echo $payload;
    ob_end_flush();
    exit;
}
$conn->set_charset('utf8mb4');

// ---------- UPLOAD DIRS ----------
$imageDir = __DIR__ . "/uploads/images/";
$videoDir = __DIR__ . "/uploads/videos/";
$publicImageBase = "uploads/images/"; // URL/path saved to DB
$publicVideoBase = "uploads/videos/";

if (!is_dir($imageDir)) mkdir($imageDir, 0777, true);
if (!is_dir($videoDir)) mkdir($videoDir, 0777, true);

// ---------- HELPERS ----------
function sanitize_filename($name) {
    $name = preg_replace('/[^\w\.\-]+/u', '_', $name);
    return trim($name, '_');
}
function json_fail($msg, $conn = null, $code = 400) {
    if ($conn) { $conn->rollback(); }
    http_response_code($code);
    $payload = json_encode(["success" => false, "message" => $msg], JSON_UNESCAPED_SLASHES);
    if (ob_get_level()) { ob_clean(); }
    header("Content-Type: application/json; charset=utf-8");
    header("Content-Length: " . strlen($payload));
    echo $payload;
    ob_end_flush();
    exit;
}
function in_whitelist($mime, $type = 'image') {
    static $img = ['image/jpeg','image/png','image/webp','image/gif'];
    static $vid = ['video/mp4','video/quicktime','video/webm','video/3gpp'];
    if ($type === 'image') return in_array($mime, $img, true);
    if ($type === 'video') return in_array($mime, $vid, true);
    return false;
}
/**
 * Normalize time strings to 24h "H:i" (e.g., "08:00", "17:30")
 * Accepts "8:00 AM", "5:30 pm", "08:00", "17:30"
 */
function normalize_time_24h(?string $s): ?string {
    if ($s === null) return null;
    $s = trim($s);
    if ($s === '') return null;

    // Try 12h with AM/PM
    $dt = DateTime::createFromFormat('g:i A', strtoupper($s));
    if (!$dt) $dt = DateTime::createFromFormat('g:iA', strtoupper($s));
    if (!$dt) $dt = DateTime::createFromFormat('h:i A', strtoupper($s));
    if (!$dt) $dt = DateTime::createFromFormat('h:iA', strtoupper($s));
    // Try 24h
    if (!$dt) $dt = DateTime::createFromFormat('H:i', $s);

    if ($dt) return $dt->format('H:i');
    // Last resort: strip non-digits/colon and try again
    $s2 = preg_replace('/[^0-9:apmAPM ]/', '', $s);
    if ($s2 !== $s) return normalize_time_24h($s2);

    return null;
}

// ---------- VALIDATE INPUT ----------
$required = [
    'year','manufacturer','model','type','licensePlate','color',
    'transmission','fuelType','milage','seatingCap','status','withDriver'
];
foreach ($required as $k) {
    if (!isset($_POST[$k]) || trim((string)$_POST[$k]) === '') {
        json_fail("Missing field: $k", $conn);
    }
}

// Optional adminId (used for mediatbl.uploaded_by and pricetbl.set_by_admin)
$uploadedBy = isset($_POST['adminId']) && $_POST['adminId'] !== '' ? (int)$_POST['adminId'] : null;

// Pricing: NOW a SINGLE OBJECT in "prices"
$prices = null;
if (isset($_POST['prices']) && trim($_POST['prices']) !== '') {
    $decoded = json_decode($_POST['prices'], true);
    if (!is_array($decoded)) {
        json_fail("Invalid 'prices' JSON (object expected)", $conn);
    }
    // Accept keys: daily, weekly, monthly, promo, discount
    $prices = [
        'daily'    => isset($decoded['daily'])    && $decoded['daily']    !== '' ? (float)$decoded['daily']    : null,
        'weekly'   => isset($decoded['weekly'])   && $decoded['weekly']   !== '' ? (float)$decoded['weekly']   : null,
        'monthly'  => isset($decoded['monthly'])  && $decoded['monthly']  !== '' ? (float)$decoded['monthly']  : null,
        'promo'    => isset($decoded['promo'])    && $decoded['promo']    !== '' ? (string)$decoded['promo']   : null,
        'discount' => isset($decoded['discount']) && $decoded['discount'] !== '' ? (float)$decoded['discount'] : null,
    ];
}

// Schedule: OPTIONAL array in "schedule"
$scheduleItems = [];
if (isset($_POST['schedule']) && trim($_POST['schedule']) !== '') {
    $scheduleItems = json_decode($_POST['schedule'], true);
    if (!is_array($scheduleItems)) {
        json_fail("Invalid 'schedule' JSON (array expected)", $conn);
    }
    // Validate each item minimal fields
    foreach ($scheduleItems as $idx => $row) {
        if (!is_array($row)) {
            json_fail("Invalid schedule item at index $idx", $conn);
        }
        if (empty($row['day'])) {
            json_fail("Schedule item $idx missing 'day'", $conn);
        }
        // Normalize times; use defaults if absent
        $start = isset($row['start_time']) ? normalize_time_24h($row['start_time']) : '08:00';
        $end   = isset($row['end_time'])   ? normalize_time_24h($row['end_time'])   : '17:00';
        if (!$start || !$end) {
            json_fail("Invalid time format in schedule item $idx", $conn);
        }
        $scheduleItems[$idx]['start_time'] = $start;
        $scheduleItems[$idx]['end_time']   = $end;
        // Optional fields
        if (!isset($scheduleItems[$idx]['is_available'])) $scheduleItems[$idx]['is_available'] = 1;
        if (!isset($scheduleItems[$idx]['notes'])) $scheduleItems[$idx]['notes'] = null;
    }
}

// ---------- START TRANSACTION ----------
$conn->begin_transaction();

try {
    // ---------- INSERT cartbl ----------
    $sqlCar = "
        INSERT INTO cartbl
            (year, manufacturer, model, type, license_plate, color, transmission, fueltype, milage, seatingcap, status, withDriver)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
    ";
    $stmtCar = $conn->prepare($sqlCar);
    if (!$stmtCar) { throw new Exception("Prepare cartbl failed: ".$conn->error); }

    $stmtCar->bind_param(
        "ssssssssssss",
        $_POST['year'],
        $_POST['manufacturer'],
        $_POST['model'],
        $_POST['type'],
        $_POST['licensePlate'],
        $_POST['color'],
        $_POST['transmission'],
        $_POST['fuelType'],
        $_POST['milage'],
        $_POST['seatingCap'],
        $_POST['status'],      // 'available' | 'under maintenance'
        $_POST['withDriver']   // 'Yes' | 'No'
    );
    if (!$stmtCar->execute()) { throw new Exception("Execute cartbl failed: ".$stmtCar->error); }
    $carId = $conn->insert_id;
    $stmtCar->close();

    // ---------- INSERT pricetbl (SINGLE row only) ----------
    if ($prices !== null) {
        $sqlPrice = "
            INSERT INTO pricetbl
                (carid, currency, hourly_rate,  daily_rate, weekly_rate, monthly_rate, seasonal, promo_code, discount_percent, valid_from, valid_to, set_by_admin)
            VALUES (?,    'PHP',   NULL,        ?,          ?,           ?,            0,        ?,          ?,                 NULL,       NULL,     ?)
        ";
        $stmtPrice = $conn->prepare($sqlPrice);
        if (!$stmtPrice) { throw new Exception("Prepare pricetbl failed: ".$conn->error); }

        $daily    = $prices['daily'];
        $weekly   = $prices['weekly'];
        $monthly  = $prices['monthly'];
        $promo    = $prices['promo'];
        $discount = $prices['discount'];
        $setBy    = $uploadedBy !== null ? $uploadedBy : null;

        // types: i d d d s d i
        $stmtPrice->bind_param("idddsdi", $carId, $daily, $weekly, $monthly, $promo, $discount, $setBy);
        if (!$stmtPrice->execute()) { throw new Exception("Execute pricetbl failed: ".$stmtPrice->error); }
        $stmtPrice->close();
    }

    // ---------- INSERT car_schedule (0..n rows) ----------
    if (!empty($scheduleItems)) {
        $sqlSched = "
            INSERT INTO car_schedule
                (carid, available_day, start_time, end_time, is_available, notes)
            VALUES (?, ?, ?, ?, ?, ?)
        ";
        $stmtSched = $conn->prepare($sqlSched);
        if (!$stmtSched) { throw new Exception("Prepare car_schedule failed: ".$conn->error); }

        foreach ($scheduleItems as $row) {
            // enforce enum values capitalization as per schema
            $day = $row['day'];
            // Basic guard against wrong day values
            $allowedDays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
            if (!in_array($day, $allowedDays, true)) {
                throw new Exception("Invalid schedule day: $day");
            }
            $start = $row['start_time']; // already normalized
            $end   = $row['end_time'];
            $avail = (int)$row['is_available'];
            $notes = $row['notes'];

            // i s s s i s
            $stmtSched->bind_param("isssis", $carId, $day, $start, $end, $avail, $notes);
            if (!$stmtSched->execute()) { throw new Exception("Execute car_schedule failed: ".$stmtSched->error); }
        }
        $stmtSched->close();
    }

    // ---------- HANDLE FILE UPLOADS ----------
    $savedMedia = [];

    // Images[]
    if (isset($_FILES['images']) && is_array($_FILES['images']['tmp_name'])) {
        foreach ($_FILES['images']['tmp_name'] as $i => $tmp) {
            if (!is_uploaded_file($tmp)) { continue; }

            $orig = sanitize_filename($_FILES['images']['name'][$i] ?? 'image.jpg');
            $ext  = pathinfo($orig, PATHINFO_EXTENSION);
            $mime = $_FILES['images']['type'][$i] ?? 'application/octet-stream';
            $size = (int)($_FILES['images']['size'][$i] ?? 0);

            if (!in_whitelist($mime, 'image')) {
                throw new Exception("Blocked image MIME type: $mime");
            }

            $fname = uniqid("img_", true) . ($ext ? ".".$ext : "");
            $dest  = $imageDir . $fname;
            if (!move_uploaded_file($tmp, $dest)) {
                throw new Exception("Failed to move uploaded image");
            }

            $publicPath = $publicImageBase . $fname;

            $stmtImg = $conn->prepare("
                INSERT INTO mediatbl (carid, uploaded_by, media_type, title, description, media_url, thumbnail_url, mime_type, file_size, duration_seconds, tags)
                VALUES (?, ?, 'image', NULL, NULL, ?, NULL, ?, ?, NULL, NULL)
            ");
            if (!$stmtImg) { throw new Exception("Prepare mediatbl(image) failed: ".$conn->error); }
            // i i s s i
            $stmtImg->bind_param("iissi", $carId, $uploadedBy, $publicPath, $mime, $size);
            if (!$stmtImg->execute()) { throw new Exception("Execute mediatbl(image) failed: ".$stmtImg->error); }
            $stmtImg->close();

            $savedMedia[] = ["type" => "image", "url" => $publicPath];
        }
    }

    // Video (single)
    if (isset($_FILES['video']['tmp_name']) && is_uploaded_file($_FILES['video']['tmp_name'])) {
        $orig = sanitize_filename($_FILES['video']['name'] ?? 'video.mp4');
        $ext  = pathinfo($orig, PATHINFO_EXTENSION);
        $mime = $_FILES['video']['type'] ?? 'application/octet-stream';
        $size = (int)($_FILES['video']['size'] ?? 0);

        if (!in_whitelist($mime, 'video')) {
            throw new Exception("Blocked video MIME type: $mime");
        }

        $fname = uniqid("vid_", true) . ($ext ? ".".$ext : "");
        $dest  = $videoDir . $fname;
        if (!move_uploaded_file($_FILES['video']['tmp_name'], $dest)) {
            throw new Exception("Failed to move uploaded video");
        }

        $publicPath = $publicVideoBase . $fname;

        $stmtVid = $conn->prepare("
            INSERT INTO mediatbl (carid, uploaded_by, media_type, title, description, media_url, thumbnail_url, mime_type, file_size, duration_seconds, tags)
            VALUES (?, ?, 'video', NULL, NULL, ?, NULL, ?, ?, NULL, NULL)
        ");
        if (!$stmtVid) { throw new Exception("Prepare mediatbl(video) failed: ".$conn->error); }
        $stmtVid->bind_param("iissi", $carId, $uploadedBy, $publicPath, $mime, $size);
        if (!$stmtVid->execute()) { throw new Exception("Execute mediatbl(video) failed: ".$stmtVid->error); }
        $stmtVid->close();

        $savedMedia[] = ["type" => "video", "url" => $publicPath];
    }

    // ---------- COMMIT ----------
    $conn->commit();

    $out = [
        "success" => true,
        "message" => "Car successfully added.",
        "carId"   => $carId,
        "media"   => $savedMedia
    ];
    $json = json_encode($out, JSON_UNESCAPED_SLASHES);
    header("Content-Length: " . strlen($json));
    echo $json;
    ob_end_flush();
    exit;

} catch (Exception $e) {
    json_fail("Error: " . $e->getMessage(), $conn, 400);
}
