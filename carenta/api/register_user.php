<?php
// ============================================
// register_user.php (Production-ready, aligned with renter/guest roles)
// ============================================

require_once __DIR__ . '/connection_service.php'; // ✅ uses $pdo

// ---------- HEADERS ----------
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit();
}

// ---------- Phone Normalization ----------
function normalizePhone($phone)
{
    $phone = trim($phone);
    $phone = preg_replace('/\s+/', '', $phone);
    $phone = preg_replace('/[^0-9+]/', '', $phone);

    if (preg_match('/^09\d{9}$/', $phone)) return '+63' . substr($phone, 1);
    if (preg_match('/^\d{10,15}$/', $phone)) return '+' . $phone;
    if (preg_match('/^\+\d{10,15}$/', $phone)) return $phone;
    return false;
}

try {
    if ($_SERVER["REQUEST_METHOD"] !== "POST") {
        echo json_encode(['success' => false, 'status' => 'error', 'message' => 'Invalid request method']);
        exit();
    }

    // Accept both form-data and raw JSON
    $input = $_POST;
    if (empty($input)) {
        $raw = file_get_contents('php://input');
        $json = json_decode($raw, true);
        if (is_array($json)) $input = $json;
    }

    $phone_raw = trim((string)($input['phone_number'] ?? ''));
    $pass = (string)($input['bcrypt'] ?? '');
    $username = trim((string)($input['username'] ?? ''));

    if ($phone_raw === '' || $pass === '') {
        echo json_encode(['success' => false, 'status' => 'error', 'message' => 'Missing required fields']);
        exit();
    }

    if (strlen($pass) < 6) {
        echo json_encode(['success' => false, 'status' => 'error', 'message' => 'Password must be at least 6 characters']);
        exit();
    }

    // ---------- Normalize phone ----------
    $phone = normalizePhone($phone_raw);
    if (!$phone) {
        echo json_encode([
            'success' => false,
            'status' => 'error',
            'message' => 'Invalid phone number format. Use +countrycodeXXXXXXXXXX or 09XXXXXXXXX'
        ]);
        exit();
    }

    // ---------- Check for duplicates ----------
    $stmt = $pdo->prepare("SELECT userid FROM usertbl WHERE phone_number = ? OR username = ? LIMIT 1");
    $stmt->execute([$phone, $username]);
    $exists = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($exists) {
        echo json_encode(['success' => false, 'status' => 'error', 'message' => 'Phone number or username already registered']);
        exit();
    }

    // ---------- Insert new user ----------
    $hashed_pass = password_hash($pass, PASSWORD_DEFAULT);

    $stmt = $pdo->prepare("
        INSERT INTO usertbl 
            (username, phone_number, bcrypt, role, is_verified, status, created_at) 
        VALUES (?, ?, ?, 'guest', 0, 'pending', NOW())
    ");
    $stmt->execute([$username ?: null, $phone, $hashed_pass]);
    $newUserId = (int)$pdo->lastInsertId();

    echo json_encode([
        'success' => true,
        'status'  => 'success',
        'message' => 'Signup successful. Account pending verification.',
        'data'    => [
            'userid' => $newUserId,
            'role' => 'guest',
            'is_verified' => 0,
            'status' => 'pending',
            'phone' => $phone
        ]
    ]);
    exit();

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Database error',
        'error' => $e->getMessage()
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'status' => 'error',
        'message' => 'Server error',
        'error' => $e->getMessage()
    ]);
}
