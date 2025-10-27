<?php
// api/admin_add_manager.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/connection_service.php';

function respond($ok, $msg, $extra = []) {
  echo json_encode(array_merge([
    "success" => $ok,
    "status" => $ok ? "success" : "error",
    "message" => $msg
  ], $extra), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
  exit;
}

try {
  $required = ['first_name', 'last_name', 'email', 'phone_number', 'username', 'password'];
  foreach ($required as $r) {
    if (empty($_POST[$r])) respond(false, "Missing field: $r");
  }

  $first = trim($_POST['first_name']);
  $last = trim($_POST['last_name']);
  $email = trim($_POST['email']);
  $phone = trim($_POST['phone_number']);
  $username = trim($_POST['username']);
  $pass = trim($_POST['password']);

  if (!filter_var($email, FILTER_VALIDATE_EMAIL)) respond(false, "Invalid email format");

  // ✅ Prevent duplicates across admintbl
  $stmt = $pdo->prepare("SELECT adminid FROM admintbl WHERE username=? OR email=? OR phone_number=? LIMIT 1");
  $stmt->execute([$username, $email, $phone]);
  if ($stmt->fetch()) respond(false, "An admin/manager with that username, email, or phone already exists");

  // ✅ Hash password
  $hash = password_hash($pass, PASSWORD_DEFAULT);

  // ✅ Insert manager into admintbl (role='manager')
  $stmt = $pdo->prepare("
    INSERT INTO admintbl 
      (first_name, last_name, email, phone_number, username, bcrypt, role, created_at) 
    VALUES 
      (?, ?, ?, ?, ?, ?, 'manager', NOW())
  ");
  $stmt->execute([$first, $last, $email, $phone, $username, $hash]);

  $newId = $pdo->lastInsertId();
  respond(true, "Manager created successfully", ["adminid" => $newId]);

} catch (Throwable $e) {
  respond(false, "Server error: " . $e->getMessage());
}
