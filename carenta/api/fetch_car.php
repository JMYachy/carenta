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

/* ---- DB Connection ---- */
require_once __DIR__ . '/connection_service.php';

/* ---- ABSOLUTE URL HELPERS ---- */
$scheme    = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$hostHdr   = $_SERVER['HTTP_HOST'];
$scriptDir = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'])), '/');
$baseApi   = $scheme . '://' . $hostHdr . $scriptDir . '/';
$baseApp   = preg_replace('#/api/?$#', '/', $baseApi);

$docroot   = rtrim(str_replace('\\', '/', $_SERVER['DOCUMENT_ROOT']), '/');
$fsApi     = $docroot . $scriptDir . '/';
$fsApp     = preg_replace('#/api/?$#', '/', $fsApi);

$make_abs = function($p) use ($baseApi, $baseApp, $fsApi, $fsApp) {
    $p = trim((string)($p ?? ''));
    if ($p === '') return '';
    if (preg_match('#^https?://#i', $p)) return $p;
    $rel = ltrim($p, '/');
    if (@file_exists($fsApi . $rel)) return $baseApi . $rel;
    if (@file_exists($fsApp . $rel)) return $baseApp . $rel;
    return $baseApp . $rel;
};

/* ---- INPUTS ---- */
$limit  = max(1, (int)($_GET['limit']  ?? 50));
$offset = max(0, (int)($_GET['offset'] ?? 0));
$q      = trim((string)($_GET['q'] ?? ''));

try {
    /* ---- WHERE (search) ---- */
    $whereSql = "";
    $params   = [];
    if ($q !== "") {
        $whereSql = "WHERE (c.manufacturer LIKE :q OR c.model LIKE :q OR c.type LIKE :q OR c.license_plate LIKE :q OR c.color LIKE :q)";
        $params[':q'] = "%{$q}%";
    }

    /* ---- COUNT ---- */
    $countSql = "SELECT COUNT(*) AS total FROM cartbl c $whereSql";
    $stmt = $pdo->prepare($countSql);
    $stmt->execute($params);
    $total = (int)$stmt->fetchColumn();

    /* ---- MAIN QUERY (car info + latest price) ---- */
    $sql = "
        SELECT 
            c.carid, c.year, c.manufacturer, c.model, c.type,
            c.license_plate, c.color, c.transmission, c.fueltype,
            c.milage, c.seatingcap, c.status, c.created_at, c.withDriver,
            p.hourly_rate, p.daily_rate, p.weekly_rate, p.monthly_rate, p.currency
        FROM cartbl c
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
        LIMIT :limit OFFSET :offset
    ";

    $stmt = $pdo->prepare($sql);
    if ($q !== "") $stmt->bindValue(':q', "%{$q}%");
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $cars = [];
    $carIds = [];

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        foreach (['hourly_rate','daily_rate','weekly_rate','monthly_rate'] as $k) {
            if (isset($row[$k])) $row[$k] = $row[$k] === null ? null : (float)$row[$k];
        }
        $row['carid'] = (int)$row['carid'];
        $carIds[] = $row['carid'];

        // UI aliases
        $row['car_name']      = trim(($row['manufacturer'] ?? '') . ' ' . ($row['model'] ?? ''));
        $row['price_per_day'] = $row['daily_rate'];
        $row['name']          = $row['car_name'];
        $row['brand']         = $row['manufacturer'];
        $row['seats']         = (int)($row['seatingcap'] ?? 0);
        $row['price']         = $row['price_per_day'];

        $cars[$row['carid']] = $row;
    }

    /* ---- Fetch media (images + videos) for all cars ---- */
    if (!empty($carIds)) {
        $inClause = implode(',', array_map('intval', $carIds));
        $mediaSql = "
            SELECT carid, media_url, thumbnail_url, media_type
            FROM mediatbl
            WHERE carid IN ($inClause)
            ORDER BY carid, mediaid ASC
        ";
        $mediaRes = $pdo->query($mediaSql);

        while ($m = $mediaRes->fetch(PDO::FETCH_ASSOC)) {
            $cid = (int)$m['carid'];
            if (!isset($cars[$cid]['media'])) $cars[$cid]['media'] = [];
            if (!isset($cars[$cid]['videos'])) $cars[$cid]['videos'] = [];

            $m['media_url'] = $make_abs($m['media_url']);
            $m['thumbnail_url'] = $make_abs($m['thumbnail_url']);

            if (strtolower($m['media_type']) === 'video') {
                $cars[$cid]['videos'][] = $m;
            } else {
                $cars[$cid]['media'][] = $m;
            }
        }

        // assign main media for backward compatibility
        foreach ($cars as &$c) {
            if (!empty($c['media'])) {
                $c['media_url'] = $c['media'][0]['media_url'];
                $c['thumbnail_url'] = $c['media'][0]['thumbnail_url'];
            } elseif (!empty($c['videos'])) {
                // fallback to video thumbnail if no image
                $c['media_url'] = $c['videos'][0]['thumbnail_url'];
            }
        }
    }

    echo json_encode([
        "success" => true,
        "total"   => $total,
        "limit"   => $limit,
        "offset"  => $offset,
        "cars"    => array_values($cars)
    ], JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Error fetching cars",
        "error"   => $e->getMessage()
    ]);
}
?>
