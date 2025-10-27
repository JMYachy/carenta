<?php
// =============================================
// user_profile.php — renter/guest profile API
// =============================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(204);
  exit;
}

require_once __DIR__ . '/connection_service.php';

function respond($ok, $msg, $extra = []) {
  echo json_encode(array_merge([
    'success' => $ok,
    'status'  => $ok ? 'success' : 'error',
    'message' => $msg
  ], $extra), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
  exit;
}

try {
  $userId = (int)($_GET['user_id'] ?? $_POST['user_id'] ?? 0);
  if ($userId <= 0) respond(false, 'user_id required');

  // =====================================================
  // ✅ GET: Fetch user profile
  // =====================================================
  if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $pdo->prepare("
      SELECT userid, username, email, first_name, last_name, gender, birthdate,
             phone_number, profile_picture, street_address, city, state, postal_code, country,
             role, status, is_verified, language, timezone, dark_mode,
             last_login, last_ip_address, created_at, updated_at
      FROM usertbl
      WHERE userid = :id
      LIMIT 1
    ");
    $stmt->execute([':id' => $userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) respond(false, 'User not found');

    // Aliases for Flutter
    $user['address']  = $user['street_address'];
    $user['province'] = $user['state'];
    $user['zip_code'] = $user['postal_code'];

    // Build absolute profile image URL
    if (!empty($user['profile_picture']) && !preg_match('#^https?://#', $user['profile_picture'])) {
      $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
      $base = $scheme . '://' . $_SERVER['HTTP_HOST'];
      $user['profile_picture'] = $base . '/' . ltrim($user['profile_picture'], '/');
    }

    respond(true, 'Profile loaded', ['data' => $user]);
  }

  // =====================================================
  // ✅ POST: Update user profile
  // =====================================================
  $fields = [
    'first_name'     => trim($_POST['first_name'] ?? ''),
    'last_name'      => trim($_POST['last_name'] ?? ''),
    'email'          => trim($_POST['email'] ?? ''),
    'phone_number'   => trim($_POST['phone_number'] ?? ''),
    'username'       => trim($_POST['username'] ?? ''),
    'gender'         => $_POST['gender'] ?? null,
    'birthdate'      => $_POST['birthdate'] ?? null,
    'street_address' => $_POST['address'] ?? ($_POST['street_address'] ?? ''),
    'city'           => $_POST['city'] ?? '',
    'state'          => $_POST['province'] ?? ($_POST['state'] ?? ''),
    'postal_code'    => $_POST['zip_code'] ?? ($_POST['postal_code'] ?? ''),
    'country'        => $_POST['country'] ?? '',
    'language'       => $_POST['language'] ?? '',
    'timezone'       => $_POST['timezone'] ?? '',
  ];
  $dark_mode = isset($_POST['dark_mode']) ? (int)$_POST['dark_mode'] : null;

  if ($fields['first_name'] === '' || $fields['email'] === '')
    respond(false, 'Missing required fields');
  if (!filter_var($fields['email'], FILTER_VALIDATE_EMAIL))
    respond(false, 'Invalid email');
  if ($fields['gender']) {
    $fields['gender'] = ucfirst(strtolower($fields['gender']));
    if (!in_array($fields['gender'], ['Male', 'Female', 'Other']))
      respond(false, 'Invalid gender');
  }

  // Check email uniqueness
  $stmt = $pdo->prepare("SELECT userid FROM usertbl WHERE email = :e AND userid <> :id LIMIT 1");
  $stmt->execute([':e' => $fields['email'], ':id' => $userId]);
  if ($stmt->fetch()) respond(false, 'Email already in use');

  // Check username uniqueness
  if ($fields['username']) {
    $stmt = $pdo->prepare("SELECT userid FROM usertbl WHERE username = :u AND userid <> :id LIMIT 1");
    $stmt->execute([':u' => $fields['username'], ':id' => $userId]);
    if ($stmt->fetch()) respond(false, 'Username already in use');
  }

  // Build dynamic query
  $updates = [];
  foreach ($fields as $k => $v) {
    if ($v !== null && $v !== '') $updates[] = "$k = :$k";
  }
  if ($dark_mode !== null) {
    $updates[] = "dark_mode = :dark_mode";
    $fields['dark_mode'] = $dark_mode;
  }
  if (empty($updates)) respond(false, 'No fields to update');

  $sql = "UPDATE usertbl SET " . implode(', ', $updates) . ", updated_at = NOW() WHERE userid = :id";
  $fields['id'] = $userId;
  $stmt = $pdo->prepare($sql);
  $stmt->execute($fields);

  // ✅ Handle profile picture upload
  if (!empty($_FILES['avatar']['tmp_name']) && $_FILES['avatar']['error'] === UPLOAD_ERR_OK) {
    $uploadDir = __DIR__ . '/../uploads/avatars/';
    if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);

    $ext = strtolower(pathinfo($_FILES['avatar']['name'], PATHINFO_EXTENSION));
    $allowed = ['jpg', 'jpeg', 'png', 'webp'];
    if (in_array($ext, $allowed, true)) {
      $fname = "u{$userId}_" . time() . ".$ext";
      $dest = $uploadDir . $fname;
      if (move_uploaded_file($_FILES['avatar']['tmp_name'], $dest)) {
        $path = "uploads/avatars/$fname";
        $upd = $pdo->prepare("UPDATE usertbl SET profile_picture = :pic, updated_at = NOW() WHERE userid = :id");
        $upd->execute([':pic' => $path, ':id' => $userId]);
      }
    }
  }

  respond(true, 'Profile updated successfully');

} catch (Throwable $e) {
  http_response_code(500);
  respond(false, 'Server error: ' . $e->getMessage());
}
