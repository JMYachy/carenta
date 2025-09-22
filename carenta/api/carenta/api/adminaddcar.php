<?php
// ===== Strict JSON API: keep output clean =====
ini_set('display_errors', 0);               // don't echo warnings to client
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

// Pricing array in single field "prices" (JSON)
$prices = [];
if (isset($_POST['prices']) && trim($_POST['prices']) !== '') {
    $prices = json_decode($_POST['prices'], true);
    if (!is_array($prices)) {
        json_fail("Invalid 'prices' JSON", $conn);
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

    // ---------- INSERT pricetbl (multiple rows supported) ----------
    if (!empty($prices)) {
        $sqlPrice = "
            INSERT INTO pricetbl
                (carid, currency, hourly_rate, daily_rate, weekly_rate, monthly_rate, seasonal, promo_code, discount_percent, valid_from, valid_to, set_by_admin)
            VALUES (?, 'PHP', NULL, ?, ?, ?, 0, ?, ?, NULL, NULL, ?)
        ";
        $stmtPrice = $conn->prepare($sqlPrice);
        if (!$stmtPrice) { throw new Exception("Prepare pricetbl failed: ".$conn->error); }

        foreach ($prices as $p) {
            // Accept empty strings gracefully → store NULL
            $daily    = isset($p['daily'])    && $p['daily']    !== '' ? (float)$p['daily']    : null;
            $weekly   = isset($p['weekly'])   && $p['weekly']   !== '' ? (float)$p['weekly']   : null;
            $monthly  = isset($p['monthly'])  && $p['monthly']  !== '' ? (float)$p['monthly']  : null;
            $promo    = isset($p['promo'])    && $p['promo']    !== '' ? (string)$p['promo']   : null;
            $discount = isset($p['discount']) && $p['discount'] !== '' ? (float)$p['discount'] : null;
            $setBy    = $uploadedBy !== null ? $uploadedBy : null;

            // Types: i d d d s d i   (NO SPACES)
            $stmtPrice->bind_param("idddsdi", $carId, $daily, $weekly, $monthly, $promo, $discount, $setBy);
            if (!$stmtPrice->execute()) { throw new Exception("Execute pricetbl failed: ".$stmtPrice->error); }
        }
        $stmtPrice->close();
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

            // Optional: enforce whitelist
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
