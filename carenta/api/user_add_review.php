<?php
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/connection_service.php';

$userId  = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$carId   = isset($_POST['car_id']) ? (int)$_POST['car_id'] : 0;
$rating  = isset($_POST['rating']) ? (int)$_POST['rating'] : 0;
$comment = trim($_POST['comment'] ?? '');
$media   = null;

if ($userId <= 0 || $carId <= 0 || $rating <= 0) {
    http_response_code(400);
    echo json_encode(["ok" => false, "message" => "Missing or invalid parameters."]);
    exit;
}

try {
    // ✅ Handle optional media upload
    if (!empty($_FILES['media']['tmp_name'])) {
        $uploadDir = __DIR__ . '/../uploads/feedback_media/';
        if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);

        $ext = pathinfo($_FILES['media']['name'], PATHINFO_EXTENSION);
        $fileName = 'fb_' . time() . '_' . uniqid() . '.' . $ext;
        $targetFile = $uploadDir . $fileName;

        if (move_uploaded_file($_FILES['media']['tmp_name'], $targetFile)) {
            $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
            $host = $_SERVER['HTTP_HOST'];
            $scriptDir = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'])), '/');
            $media = "$scheme://$host$scriptDir/../uploads/feedback_media/$fileName";
        }
    }

    // ✅ Check if user already has a feedback entry for this car
    $stmt = $pdo->prepare("SELECT feedbackid FROM feedbacktbl WHERE userid = :uid AND carid = :cid LIMIT 1");
    $stmt->execute([':uid' => $userId, ':cid' => $carId]);
    $existing = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        // ✅ Update existing feedback
        $query = "
            UPDATE feedbacktbl
            SET rating = :rating, comment = :comment, updated_at = NOW()
            " . ($media ? ", media_url = :media" : "") . "
            WHERE userid = :uid AND carid = :cid
        ";
        $stmt = $pdo->prepare($query);
        $stmt->execute([
            ':uid' => $userId,
            ':cid' => $carId,
            ':rating' => $rating,
            ':comment' => $comment,
            ...($media ? [':media' => $media] : []),
        ]);

        echo json_encode([
            "ok" => true,
            "message" => "Your review has been updated successfully!"
        ]);
    } else {
        // ✅ Insert new feedback
        $stmt = $pdo->prepare("
            INSERT INTO feedbacktbl (userid, carid, rating, comment, media_url, created_at)
            VALUES (:uid, :cid, :rating, :comment, :media, NOW())
        ");
        $stmt->execute([
            ':uid' => $userId,
            ':cid' => $carId,
            ':rating' => $rating,
            ':comment' => $comment,
            ':media' => $media
        ]);

        echo json_encode([
            "ok" => true,
            "message" => "Feedback added successfully!"
        ]);
    }
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "ok" => false,
        "message" => "Error saving feedback.",
        "error" => $e->getMessage()
    ]);
}