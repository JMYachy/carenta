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

    // 🔹 Link car → admintbl (as the owner)
    $stmt = $pdo->prepare("
        SELECT 
            a.adminid        AS owner_id,
            a.username,
            CONCAT(a.first_name, ' ', a.last_name) AS full_name,
            a.email,
            a.phone_number,
            a.profile_picture,
            a.role,
            a.status,
            a.created_at
        FROM cartbl c
        JOIN admintbl a ON c.ownerid = a.adminid
        WHERE c.carid = ?
        LIMIT 1
    ");
    $stmt->execute([$carId]);
    $owner = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$owner) {
        echo json_encode(["ok" => false, "message" => "Owner not found"]);
        exit;
    }

    // 🔹 Normalize profile picture URL
    if (!empty($owner["profile_picture"]) && !preg_match("#^https?://#", $owner["profile_picture"])) {
        $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
        $owner["profile_picture"] = $scheme . "://" . $_SERVER['HTTP_HOST'] . "/carenta/" . ltrim($owner["profile_picture"], "/");
    }

    echo json_encode(["ok" => true, "data" => $owner], JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "ok" => false,
        "message" => "Server error",
        "error" => $e->getMessage()
    ]);
}
