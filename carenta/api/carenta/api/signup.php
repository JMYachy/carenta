<?php
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit();
}

$servername = "localhost";
$username   = "root";
$password   = "";
$dbname     = "carentadb";

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    $conn = new mysqli($servername, $username, $password, $dbname);
    $conn->set_charset("utf8mb4");

    if ($_SERVER["REQUEST_METHOD"] !== "POST") {
        echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
        exit();
    }

    // Accept application/x-www-form-urlencoded (Flutter default) or JSON
    $input = $_POST;
    if (empty($input)) {
        $raw = file_get_contents('php://input');
        $json = json_decode($raw, true);
        if (is_array($json)) $input = $json;
    }

    $phone = trim((string)($input['phone_number'] ?? ''));
    $pass  = (string)($input['bcrypt'] ?? ''); // name kept for backward-compat, but it's the plain password

    if ($phone === '' || $pass === '') {
        echo json_encode(['status' => 'error', 'message' => 'Missing fields']);
        exit();
    }

    // Optional: basic validation
    if (strlen($pass) < 6) {
        echo json_encode(['status' => 'error', 'message' => 'Password must be at least 6 characters']);
        exit();
    }
    if (strlen($phone) > 20) {
        echo json_encode(['status' => 'error', 'message' => 'Phone number is too long']);
        exit();
    }

    // Check if phone already exists (since phone_number isn’t UNIQUE by default)
    $check = $conn->prepare("SELECT userid FROM usertbl WHERE phone_number = ? LIMIT 1");
    $check->bind_param("s", $phone);
    $check->execute();
    $exists = $check->get_result()->fetch_assoc();
    $check->close();

    if ($exists) {
        echo json_encode(['status' => 'error', 'message' => 'Phone number already registered']);
        exit();
    }

    // Hash password
    $hashed_pass = password_hash($pass, PASSWORD_DEFAULT);

    // Insert
    $stmt = $conn->prepare("INSERT INTO usertbl (phone_number, bcrypt) VALUES (?, ?)");
    $stmt->bind_param("ss", $phone, $hashed_pass);
    $stmt->execute();
    $newId = $stmt->insert_id;
    $stmt->close();

    echo json_encode([
        'status'  => 'success',
        'message' => 'Signup successful',
        'userid'  => (int)$newId,
        'phone'   => $phone
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Server error']);
} finally {
    if (isset($conn) && $conn instanceof mysqli) $conn->close();
}
