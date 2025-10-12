<?php

header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json; charset=utf-8");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

/* ---- DB (embedded, PDO) ---- */
$host = "127.0.0.1";     // or "localhost"
$dbname = "carentadb";
$dbuser = "root";        // change if needed
$dbpass = "";            // change if needed

try {
  $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $dbuser, $dbpass, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
  ]);
} catch (PDOException $e) {
  echo json_encode(["success" => false, "status" => "error", "message" => "Database connection failed."]);
  exit;
}

/* ---- Helpers ---- */
function ok($payload = []) {
  // Return BOTH 'success' and classic 'status' for backward compatibility
  echo json_encode(array_merge(["success" => true, "status" => "success"], $payload));
  exit;
}
function fail($msg) {
  echo json_encode(["success" => false, "status" => "error", "message" => $msg]);
  exit;
}
function normalize_login_input() {
  // Accept email/username/phone via multiple field names for compatibility:
  // 'email', 'username', 'login' (body or query)
  $src = array_merge($_GET, $_POST);
  $login = trim($src['email'] ?? $src['username'] ?? $src['login'] ?? '');
  $pass  = trim($src['password'] ?? '');
  return [$login, $pass];
}

/* ---- Router ---- */
$method = $_SERVER['REQUEST_METHOD'];
$action = $_REQUEST['action'] ?? null;

// LOGIN: supports both `action=login` and the legacy "POST without action"
if ($method === 'POST' && ($action === 'login' || $action === null)) {
  list($login_input, $login_pass) = normalize_login_input();
  if ($login_input === '' || $login_pass === '') {
    fail("Please fill in all fields.");
  }

  // 1) Try admin
  $stmt = $pdo->prepare("
    SELECT *, 'admin_table' AS table_name
    FROM admintbl
    WHERE username = :u OR email = :u OR phone_number = :u
    LIMIT 1
  ");
  $stmt->execute([':u' => $login_input]);
  $account = $stmt->fetch();

  // 2) Else user
  if (!$account) {
    $stmt = $pdo->prepare("
      SELECT *, 'user_table' AS table_name
      FROM usertbl
      WHERE username = :u OR email = :u OR phone_number = :u
      LIMIT 1
    ");
    $stmt->execute([':u' => $login_input]);
    $account = $stmt->fetch();
  }

  if (!$account) { fail("Account not found."); }
  if (!password_verify($login_pass, $account['bcrypt'])) { fail("Invalid password."); }

  // Build session
  $isAdmin = ($account['table_name'] === 'admin_table');
  $_SESSION['account_type'] = $account['table_name'];       // 'admin_table' | 'user_table'
  $_SESSION['role']         = $account['role'] ?? 'user';
  $_SESSION['username']     = $account['username'] ?? '';
  $_SESSION['adminid']      = $isAdmin ? intval($account['adminid']) : null;
  $_SESSION['userid']       = $isAdmin ? null : intval($account['userid']);

  // Update last_login/IP
  if ($isAdmin) {
    $upd = $pdo->prepare("UPDATE admintbl SET last_login = NOW(), last_ip_address = :ip WHERE adminid = :id");
    $upd->execute([':ip' => $_SERVER['REMOTE_ADDR'] ?? '', ':id' => $account['adminid']]);
  } else {
    $upd = $pdo->prepare("UPDATE usertbl SET last_login = NOW(), last_ip_address = :ip WHERE userid = :id");
    $upd->execute([':ip' => $_SERVER['REMOTE_ADDR'] ?? '', ':id' => $account['userid']]);
  }

  ok([
    "message" => "Login successful",
    // legacy fields (your old SigninScreen used these):
    "role" => $_SESSION['role'],
    "account_type" => $_SESSION['account_type'],
    "username" => $_SESSION['username'],
    // new unified payload for SessionService:
    "data" => [
      "userid"       => $_SESSION['userid'],
      "adminid"      => $_SESSION['adminid'],
      "role"         => $_SESSION['role'],
      "account_type" => $_SESSION['account_type'],
      "username"     => $_SESSION['username'],
      // send session id if client wants to pin Cookie header manually
      "phpsessid"    => session_id(),
    ],
  ]);
}

/* ---- CHECK ---- */
if ($method === 'GET' && $action === 'check') {
  $hasUser = !empty($_SESSION['userid']) || !empty($_SESSION['adminid']);
  if (!$hasUser) { fail("No active session"); }
  ok([
    "message" => "Session active",
    "data" => [
      "userid"       => $_SESSION['userid'] ?? null,
      "adminid"      => $_SESSION['adminid'] ?? null,
      "role"         => $_SESSION['role'] ?? null,
      "account_type" => $_SESSION['account_type'] ?? null,
      "username"     => $_SESSION['username'] ?? null,
      "phpsessid"    => session_id(),
    ],
  ]);
}

/* ---- LOGOUT ---- */
if ($method === 'POST' && $action === 'logout') {
  $_SESSION = [];
  if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time()-42000, $params["path"], $params["domain"], $params["secure"], $params["httponly"]);
  }
  session_destroy();
  ok(["message" => "Logged out successfully"]);
}

/* ---- Fallback ---- */
fail("Invalid request.");
