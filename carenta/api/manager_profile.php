<?php
// api/manager_profile.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/connection_service.php';

function respond($ok, $msg, $extra = []) {
  echo json_encode(array_merge([
    "success" => $ok,
    "status" => $ok ? "success" : "error",
    "message" => $msg
  ], $extra), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
  exit;
}

try {
  if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $id = intval($_GET['manager_id'] ?? 0);
    if ($id <= 0) respond(false, "Invalid manager_id");

    $stmt = $pdo->prepare("SELECT managerid, username, first_name, last_name, email, phone_number, profile_picture, last_login FROM managertbl WHERE managerid = ? LIMIT 1");
    $stmt->execute([$id]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) respond(false, "Manager not found");

    // convert profile picture to absolute
    if (!empty($row['profile_picture']) && !preg_match('#^https?://#', $row['profile_picture'])) {
      $base = (isset($_SERVER['HTTPS']) ? "https://" : "http://") . $_SERVER['HTTP_HOST'];
      $row['profile_picture'] = $base . '/' . ltrim($row['profile_picture'], '/');
    }

    respond(true, "Manager profile loaded", ["data" => $row]);
  }

  if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = intval($_POST['manager_id'] ?? 0);
    $email = trim($_POST['email'] ?? '');
    $phone = trim($_POST['phone_number'] ?? '');
    $username = trim($_POST['username'] ?? '');
    $first = trim($_POST['first_name'] ?? '');
    $last = trim($_POST['last_name'] ?? '');

    if ($id <= 0 || $email === '' || $username === '') respond(false, "Missing fields");

    $stmt = $pdo->prepare("
      UPDATE managertbl
      SET email=?, phone_number=?, username=?, first_name=?, last_name=?, updated_at=NOW()
      WHERE managerid=?
    ");
    $stmt->execute([$email, $phone, $username, $first, $last, $id]);

    respond(true, "Profile updated successfully");
  }

  respond(false, "Invalid request method");
} catch (Throwable $e) {
  respond(false, "Server error: " . $e->getMessage());
}
