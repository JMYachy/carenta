<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
require_once "connection_service.php"; // ✅ Uses PDO ($pdo)

try {
    $carId = isset($_GET['carid']) ? (int)$_GET['carid'] : 0;
    if ($carId <= 0) {
        echo json_encode(["ok" => false, "message" => "Missing or invalid carid"]);
        exit;
    }

    // 🔹 Fetch feedback (reviews) for the car
    $stmt = $pdo->prepare("
        SELECT 
            f.feedbackid AS review_id,
            f.carid,
            f.userid,
            f.rating,
            f.comment,
            f.created_at,
            u.username,
            CONCAT(u.first_name, ' ', u.last_name) AS full_name,
            u.profile_picture
        FROM feedbacktbl f
        JOIN usertbl u ON f.userid = u.userid
        WHERE f.carid = ?
        ORDER BY f.created_at DESC
    ");
    $stmt->execute([$carId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 🔹 Normalize image URLs (if relative path)
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $base = $scheme . "://" . $_SERVER['HTTP_HOST'] . "/carenta/";
    foreach ($rows as &$r) {
        if (!empty($r['profile_picture']) && !preg_match('#^https?://#', $r['profile_picture'])) {
            $r['profile_picture'] = $base . ltrim($r['profile_picture'], '/');
        }
    }

    echo json_encode([
        "ok" => true,
        "count" => count($rows),
        "data" => $rows
    ], JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "ok" => false,
        "message" => "Server error",
        "error" => $e->getMessage()
    ]);
}
