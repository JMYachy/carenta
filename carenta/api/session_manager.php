<?php
session_start();
error_reporting(0); // silence for production

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=utf-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

/* ---- DB ---- */
require_once __DIR__ . '/connection_service.php';

/* ---- Helpers ---- */
function ok($payload = []) {
  echo json_encode(array_merge(["success" => true, "status" => "success"], $payload), JSON_UNESCAPED_UNICODE);
  exit;
}
function fail($msg) {
  echo json_encode(["success" => false, "status" => "error", "message" => $msg], JSON_UNESCAPED_UNICODE);
  exit;
}

/* Normalize phone */
function normalizePhone($phone) {
  $phone = trim(preg_replace('/\s+/', '', $phone));
  $phone = preg_replace('/[^0-9+]/', '', $phone);
  if (preg_match('/^09\d{9}$/', $phone)) return '+63' . substr($phone, 1);
  if (preg_match('/^63\d{9}$/', $phone)) return '+' . $phone;
  if (preg_match('/^\+\d{10,15}$/', $phone)) return $phone;
  return $phone;
}

/* Extract login input */
function normalize_login_input() {
  $src = array_merge($_GET, $_POST);
  $login = trim($src['email'] ?? $src['username'] ?? $src['login'] ?? '');
  $pass  = trim($src['password'] ?? '');
  return [$login, $pass];
}

$method = $_SERVER['REQUEST_METHOD'];
$action = $_REQUEST['action'] ?? null;

/* ===========================================================
   LOGIN
   =========================================================== */
if ($method === 'POST' && ($action === 'login' || $action === null)) {
  list($login_input, $login_pass) = normalize_login_input();
  if ($login_input === '' || $login_pass === '') fail("Please fill in all fields.");

  if (preg_match('/^\+?\d+$/', $login_input)) $login_input = normalizePhone($login_input);

  try {
    /* --- Try admin/manager first --- */
    $stmt = $pdo->prepare("
      SELECT *, 'admin_table' AS table_name
      FROM admintbl
      WHERE username = :u1 OR email = :u2 OR phone_number = :u3
      LIMIT 1
    ");
    $stmt->execute([
      ':u1' => $login_input,
      ':u2' => $login_input,
      ':u3' => $login_input,
    ]);
    $account = $stmt->fetch();

    /* --- Otherwise, try usertbl --- */
    if (!$account) {
      $stmt = $pdo->prepare("
        SELECT *, 'user_table' AS table_name
        FROM usertbl
        WHERE username = :u1 OR email = :u2 OR phone_number = :u3
        LIMIT 1
      ");
      $stmt->execute([
        ':u1' => $login_input,
        ':u2' => $login_input,
        ':u3' => $login_input,
      ]);
      $account = $stmt->fetch();
    }

    if (!$account) fail("Account not found.");
    if (!password_verify($login_pass, $account['bcrypt'])) fail("Invalid password.");

    $isAdmin = ($account['table_name'] === 'admin_table');

    /* --- Store session --- */
    $_SESSION['account_type'] = $account['table_name'];
    $_SESSION['role']         = $account['role'] ?? ($isAdmin ? 'manager' : 'guest');
    $_SESSION['username']     = $account['username'] ?? '';
    $_SESSION['adminid']      = $isAdmin ? intval($account['adminid'] ?? 0) : null;
    $_SESSION['userid']       = $isAdmin ? null : intval($account['userid'] ?? 0);

    /* --- For renter/guest only --- */
    if (!$isAdmin) {
      if ($account['status'] === 'banned') fail("Account banned.");
      if ($account['status'] === 'inactive') fail("Account inactive.");
      if ($account['role'] === 'guest' || !$account['is_verified']) {
        $_SESSION['notice'] = "Your account is not verified yet. Please submit ID verification.";
      }
    }

    /* --- Update last login --- */
    $ip = $_SERVER['REMOTE_ADDR'] ?? '';
    if ($isAdmin) {
      $upd = $pdo->prepare("UPDATE admintbl SET last_login = NOW(), last_ip_address = :ip WHERE adminid = :id");
      $upd->execute([':ip' => $ip, ':id' => intval($account['adminid'] ?? 0)]);
    } else {
      $upd = $pdo->prepare("UPDATE usertbl SET last_login = NOW(), last_ip_address = :ip WHERE userid = :id");
      $upd->execute([':ip' => $ip, ':id' => intval($account['userid'] ?? 0)]);
    }

    ok([
      "message" => "Login successful",
      "data" => [
        "userid"       => $_SESSION['userid'],
        "adminid"      => $_SESSION['adminid'],
        "role"         => $_SESSION['role'],
        "account_type" => $_SESSION['account_type'],
        "username"     => $_SESSION['username'],
        "is_verified"  => $account['is_verified'] ?? null,
        "status"       => $account['status'] ?? null,
        "notice"       => $_SESSION['notice'] ?? null,
        "phpsessid"    => session_id(),
      ],
    ]);

  } catch (Throwable $e) {
    fail("Login failed: " . $e->getMessage());
  }
}

/* ===========================================================
   SESSION CHECK
   =========================================================== */
if ($method === 'GET' && $action === 'check') {
  if (empty($_SESSION['userid']) && empty($_SESSION['adminid'])) fail("No active session");
  ok([
    "message" => "Session active",
    "data" => [
      "userid"       => $_SESSION['userid'] ?? null,
      "adminid"      => $_SESSION['adminid'] ?? null,
      "role"         => $_SESSION['role'] ?? null,
      "account_type" => $_SESSION['account_type'] ?? null,
      "username"     => $_SESSION['username'] ?? null,
      "notice"       => $_SESSION['notice'] ?? null,
      "phpsessid"    => session_id(),
    ],
  ]);
}

/* ===========================================================
   LOGOUT
   =========================================================== */
if ($method === 'POST' && $action === 'logout') {
  $_SESSION = [];
  if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time() - 42000,
      $params["path"], $params["domain"],
      $params["secure"], $params["httponly"]
    );
  }
  session_destroy();
  ok(["message" => "Logged out successfully"]);
}

/* ---- Fallback ---- */
fail("Invalid request.");
