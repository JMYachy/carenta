<?php
/**
 * connection_service.php
 * Centralized PDO connection for all Carenta API scripts.
 * Include with:  require_once __DIR__ . '/connection_service.php';
 */

declare(strict_types=1);

// Prefer env vars if you deploy later; fall back to local defaults.
$DB_HOST = getenv('DB_HOST') ?: '127.0.0.1';
$DB_NAME = getenv('DB_NAME') ?: 'carentadb';
$DB_USER = getenv('DB_USER') ?: 'root';
$DB_PASS = getenv('DB_PASS') ?: '';

// Build DSN
$dsn = "mysql:host={$DB_HOST};dbname={$DB_NAME};charset=utf8mb4";

// Share ONE $pdo instance with the including script
try {
    $pdo = new PDO($dsn, $DB_USER, $DB_PASS, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    // Keep this generic for security; log $e->getMessage() on the server if you want.
    echo json_encode([
        'success' => false,
        'status'  => 'error',
        'message' => 'Database connection failed.'
    ]);
    exit;
}
