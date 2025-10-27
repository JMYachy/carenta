<?php
// api/user_favorites.php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

ini_set('display_errors', '0');
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

/* ---- DB CONNECTION ---- */
require_once __DIR__ . '/connection_service.php';

try {
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    if ($userId <= 0) {
        http_response_code(400);
        echo json_encode([
            'ok' => false,
            'error' => 'BAD_REQUEST',
            'message' => 'user_id required'
        ]);
        exit;
    }

    // ===== Sorting =====
    $sort = $_GET['sort'] ?? 'recent'; // recent | price_asc | price_desc | rating_desc
    $orderBy = "f.created_at DESC";
    if ($sort === 'price_asc') {
        $orderBy = "p.daily_rate ASC";
    } elseif ($sort === 'price_desc') {
        $orderBy = "p.daily_rate DESC";
    } elseif ($sort === 'rating_desc') {
        $orderBy = "c.rating DESC, f.created_at DESC";
    }

    // ===== Optional search filter =====
    $q = trim($_GET['q'] ?? '');
    $hasQ = $q !== '';
    $like = "%$q%";

    // ===== Query: favorites + car + media + price =====
    $sql = "
        SELECT 
            c.carid,
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
            c.withDriver,
            c.created_at,
            f.created_at AS favorited_at,
            p.daily_rate,
            p.weekly_rate,
            p.monthly_rate,
            p.currency,
            MIN(m.media_url) AS media_url
        FROM favoritecarstbl f
        JOIN cartbl c ON c.carid = f.carid
        LEFT JOIN mediatbl m ON m.carid = c.carid AND m.media_type = 'image'
        LEFT JOIN (
            SELECT carid, MAX(updated_at) AS latest, daily_rate, weekly_rate, monthly_rate, currency
            FROM pricetbl
            GROUP BY carid
        ) p ON p.carid = c.carid
        WHERE f.userid = :userId
    ";

    if ($hasQ) {
        $sql .= " AND (c.manufacturer LIKE :q OR c.model LIKE :q OR c.license_plate LIKE :q)";
    }

    $sql .= " GROUP BY c.carid ORDER BY $orderBy";

    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':userId', $userId, PDO::PARAM_INT);
    if ($hasQ) {
        $stmt->bindValue(':q', $like, PDO::PARAM_STR);
    }

    $stmt->execute();

    $favorites = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        // ✅ Normalize structure for Flutter
        $row['car_name'] = trim(($row['manufacturer'] ?? '') . ' ' . ($row['model'] ?? ''));
        $row['price_per_day'] = isset($row['daily_rate']) ? (float)$row['daily_rate'] : null;
        $row['favorited_at'] = $row['favorited_at'] ?? null;
        $favorites[] = $row;
    }

    echo json_encode([
        'ok' => true,
        'count' => count($favorites),
        'data' => $favorites
    ], JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'ok' => false,
        'error' => 'SERVER_ERROR',
        'message' => $e->getMessage()
    ]);
}
?>
