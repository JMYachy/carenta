<?php
require_once 'connection_service.php';

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit();
}

/**
 * Normalize phone number into consistent E.164 format.
 * - Converts local PH (09...) into +63 format
 * - Keeps valid international numbers (+1..., +44..., etc.)
 * - Rejects clearly invalid inputs
 */
function normalizePhone($phone) {
    $phone = trim($phone);
    $phone = preg_replace('/\s+/', '', $phone);        // remove spaces
    $phone = preg_replace('/[^0-9+]/', '', $phone);    // keep digits and +

    // Case 1: Local Philippine number (starts with 09)
    if (preg_match('/^09\d{9}$/', $phone)) {
        return '+63' . substr($phone, 1); // convert to +63xxxxxxxxxx
    }

    // Case 2: No + but starts with country code (e.g., 639, 1415...)
    if (preg_match('/^\d{10,15}$/', $phone)) {
        return '+' . $phone;
    }

    // Case 3: Already in + format
    if (preg_match('/^\+\d{10,15}$/', $phone)) {
        return $phone;
    }

    // Invalid format
    return false;
}

try {
    if ($_SERVER["REQUEST_METHOD"] !== "POST") {
        echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
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
    $pass  = (string)($input['bcrypt'] ?? '');

    if ($phone_raw === '' || $pass === '') {
        echo json_encode(['status' => 'error', 'message' => 'Missing fields']);
        exit();
    }

    if (strlen($pass) < 6) {
        echo json_encode(['status' => 'error', 'message' => 'Password must be at least 6 characters']);
        exit();
    }

    // Normalize and validate phone
    $phone = normalizePhone($phone_raw);
    if (!$phone) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid phone number format. Use +countrycodeXXXXXXXXXX or 09XXXXXXXXX']);
        exit();
    }

    // Check if phone already exists (normalized)
    $check = $conn->prepare("SELECT userid FROM usertbl WHERE phone_number = ? LIMIT 1");
    $check->bind_param("s", $phone);
    $check->execute();
    $exists = $check->get_result()->fetch_assoc();
    $check->close();

    if ($exists) {
        echo json_encode(['status' => 'error', 'message' => 'Phone number already registered']);
        exit();
    }

    // Hash password and insert new user
    $hashed_pass = password_hash($pass, PASSWORD_DEFAULT);
    $stmt = $conn->prepare("INSERT INTO usertbl (phone_number, bcrypt) VALUES (?, ?)");
    $stmt->bind_param("ss", $phone, $hashed_pass);
    $stmt->execute();

    echo json_encode([
        'status'  => 'success',
        'message' => 'Signup successful',
        'userid'  => (int)$stmt->insert_id,
        'phone'   => $phone
    ]);

    $stmt->close();

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Server error', 'error' => $e->getMessage()]);
} finally {
    if (isset($conn) && $conn instanceof mysqli) $conn->close();
}
?>
