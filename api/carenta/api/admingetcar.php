<?php
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$host = "localhost";
$user = "root";
$pass = "";
$db   = "carentadb";

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    $conn = new mysqli($host, $user, $pass, $db);
    $conn->set_charset("utf8mb4");

    // === ABSOLUTE URL HELPER (auto-detects /carenta/api vs /carenta) ===
    $scheme    = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $hostHdr   = $_SERVER['HTTP_HOST'];
    $scriptDir = rtrim(str_replace('\\','/', dirname($_SERVER['SCRIPT_NAME'])), '/'); // e.g. /carenta/api
    $baseApi   = $scheme . '://' . $hostHdr . $scriptDir . '/';  // http(s)://.../carenta/api/
    $baseApp   = preg_replace('#/api/?$#', '/', $baseApi);        // http(s)://.../carenta/

    $docroot   = rtrim(str_replace('\\','/', $_SERVER['DOCUMENT_ROOT']), '/');
    $fsApi     = $docroot . $scriptDir . '/';                     // .../htdocs/carenta/api/
    $fsApp     = preg_replace('#/api/?$#', '/', $fsApi);          // .../htdocs/carenta/

    $make_abs = function($p) use ($baseApi, $baseApp, $fsApi, $fsApp) {
        $p = trim((string)($p ?? ''));
        if ($p === '') return '';
        if (preg_match('#^https?://#i', $p)) return $p;
        $rel = ltrim($p, '/');
        if (@file_exists($fsApi . $rel)) return $baseApi . $rel;  // prefer api/ if present
        if (@file_exists($fsApp . $rel)) return $baseApp . $rel;  // fallback to app/
        return $baseApi . $rel; // default to api base if file check fails
    };
    // ===================================================================

    // Inputs
    $limit  = max(1, (int)($_GET['limit']  ?? 50));
    $offset = max(0, (int)($_GET['offset'] ?? 0));
    $q      = trim((string)($_GET['q'] ?? ''));

    // WHERE (search) — matches manufacturer, model, type, plate, color
    $whereSql = "";
    $params   = [];
    $types    = "";
    if ($q !== "") {
        $whereSql = "WHERE (c.manufacturer LIKE ? OR c.model LIKE ? OR c.type LIKE ? OR c.license_plate LIKE ? OR c.color LIKE ?)";
        $needle = "%{$q}%";
        $params = [$needle, $needle, $needle, $needle, $needle];
        $types  = "sssss";
    }

    // COUNT for pagination
    $countSql = "
        SELECT COUNT(*) AS total
        FROM cartbl c
        $whereSql
    ";
    $stmt = $conn->prepare($countSql);
    if ($q !== "") { $stmt->bind_param($types, ...$params); }
    $stmt->execute();
    $total = (int)$stmt->get_result()->fetch_assoc()['total'];
    $stmt->close();

    // Pick ONE image per car (first image) and ONE active price per car (latest valid)
    $sql = "
        SELECT 
    c.carid,
    c.year,
    c.manufacturer,
    c.model,
    c.type,
    c.license_plate,
    c.color,
    c.transmission,
    c.fueltype,
    c.milage,
    c.seatingcap,
    c.status,
    c.created_at,
    c.withDriver,
    m.media_url,
    m.thumbnail_url,
    p.hourly_rate,
    p.daily_rate,
    p.weekly_rate,
    p.monthly_rate,
    p.currency
FROM cartbl c
LEFT JOIN (
    SELECT x.carid, x.media_url, x.thumbnail_url
    FROM mediatbl x
    JOIN (
        SELECT carid, MIN(mediaid) AS mid
        FROM mediatbl
        WHERE media_type = 'image'
        GROUP BY carid
    ) y ON y.carid = x.carid AND y.mid = x.mediaid
) m ON m.carid = c.carid
LEFT JOIN (
    SELECT t.carid, t.hourly_rate, t.daily_rate, t.weekly_rate, t.monthly_rate, t.currency, t.updated_at
    FROM pricetbl t
    JOIN (
        SELECT carid, MAX(updated_at) AS latest
        FROM pricetbl
        WHERE (valid_from IS NULL OR valid_from <= CURDATE())
          AND (valid_to   IS NULL OR valid_to   >= CURDATE())
        GROUP BY carid
    ) u ON u.carid = t.carid AND u.latest = t.updated_at
) p ON p.carid = c.carid
$whereSql
ORDER BY c.created_at DESC
LIMIT ? OFFSET ?
    ";

    // Bind parameters (search + limit/offset) using call_user_func_array (needs references)
    $stmt = $conn->prepare($sql);
    $bindValues = ($q !== "") ? array_merge($params, [$limit, $offset]) : [$limit, $offset];
    $types2     = ($q !== "") ? str_repeat('s', count($params)) . 'ii' : 'ii';

    $tmp = [];
    $tmp[] = &$types2;
    foreach ($bindValues as $i => $v) {
        $tmp[] = &$bindValues[$i]; // bind_param needs references
    }
    call_user_func_array([$stmt, 'bind_param'], $tmp);

    $stmt->execute();
    $res = $stmt->get_result();

    $cars = [];
    while ($row = $res->fetch_assoc()) {
        // cast numerics
        foreach (['hourly_rate','daily_rate','weekly_rate','monthly_rate'] as $k) {
            if (isset($row[$k])) $row[$k] = $row[$k] === null ? null : (float)$row[$k];
        }
        $row['carid'] = (int)$row['carid'];

        // absolutize URLs
        $row['media_url']     = $make_abs($row['media_url']);
        $row['thumbnail_url'] = $make_abs($row['thumbnail_url']);

        // aliases for Flutter UI
        $row['car_name']      = trim(($row['manufacturer'] ?? '') . ' ' . ($row['model'] ?? ''));
        $row['price_per_day'] = $row['daily_rate'];
        $row['name']          = $row['car_name'];
        $row['brand']         = $row['manufacturer'];
        $row['seats']         = (int)($row['seatingcap'] ?? 0);
        $row['price']         = $row['price_per_day'];
        $row['image_url']     = $row['media_url']; // absolute now

        $cars[] = $row;
    }
    $stmt->close();

    echo json_encode([
        "success" => true,
        "total"   => $total,
        "limit"   => $limit,
        "offset"  => $offset,
        "cars"    => $cars
    ], JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Error fetching cars",
        "error"   => $e->getMessage()
    ]);
} finally {
    if (isset($conn) && $conn instanceof mysqli) { $conn->close(); }
}
