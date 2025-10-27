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

require_once __DIR__ . '/connection_service.php';

$userId = isset($_GET['userid']) ? (int)$_GET['userid'] : 0;
$carId  = isset($_GET['carid']) ? (int)$_GET['carid'] : 0;

if ($userId <= 0 || $carId <= 0) {
    http_response_code(400);
    echo json_encode([
        "ok" => false,
        "message" => "Missing or invalid user/car ID."
    ]);
    exit;
}

try {
    // ✅ Check if user has a COMPLETED rental for this car
    $stmt = $pdo->prepare("
        SELECT COUNT(*) 
        FROM rentaltbl 
        WHERE userid = :uid AND carid = :cid AND status = 'completed'
    ");
    $stmt->execute([':uid' => $userId, ':cid' => $carId]);
    $completedRentals = (int)$stmt->fetchColumn();

    // ✅ Check if user already posted feedback for this car
    $stmt = $pdo->prepare("
        SELECT COUNT(*) 
        FROM feedbacktbl
        WHERE userid = :uid AND carid = :cid
    ");
    $stmt->execute([':uid' => $userId, ':cid' => $carId]);
    $existingReviews = (int)$stmt->fetchColumn();

    // ✅ User can only review if they completed rental and not yet left feedback
    $canReview = $completedRentals > 0 && $existingReviews === 0;

    echo json_encode([
        "ok" => true,
        "canReview" => $canReview,
        "completed_rentals" => $completedRentals,
        "existing_feedbacks" => $existingReviews
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        "ok" => false,
        "message" => "Error checking feedback eligibility.",
        "error" => $e->getMessage()
    ]);
}
