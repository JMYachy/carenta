<?php
header('Content-Type: application/json; charset=utf-8');

// ✅ Securely load .env from one level above public_html
$envPath = dirname(__DIR__) . '/../.env';
if (!file_exists($envPath)) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Missing .env file"]);
    exit;
}

$env = parse_ini_file($envPath);
$host = $env['DB_HOST'] ?? 'localhost';
$db   = $env['DB_NAME'] ?? '';
$user = $env['DB_USER'] ?? '';
$pass = $env['DB_PASS'] ?? '';
$charset = 'utf8mb4';

// ✅ Create PDO DSN
$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false, // protect against SQL injection
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Database connection failed",
        "error" => $e->getMessage()
    ]);
    exit;
}
?>
