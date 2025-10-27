<?php
// ==========================================
// user_profile_update.php — Updated Version
// ==========================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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
  ], $extra), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
  exit;
}

try {
  $userId = (int)($_POST['user_id'] ?? 0);
  if ($userId <= 0) respond(false, 'Missing user_id');

  $first_name  = trim($_POST['first_name'] ?? '');
  $last_name   = trim($_POST['last_name'] ?? '');
  $email       = trim($_POST['email'] ?? '');
  $phone       = trim($_POST['phone_number'] ?? '');
  $username    = trim($_POST['username'] ?? '');
  $gender      = trim($_POST['gender'] ?? '');
  $birthdate   = trim($_POST['birthdate'] ?? '');
  $street      = trim($_POST['street_address'] ?? ($_POST['address'] ?? ''));
  $city        = trim($_POST['city'] ?? '');
  $state       = trim($_POST['state'] ?? ($_POST['province'] ?? ''));
  $postal      = trim($_POST['postal_code'] ?? ($_POST['zip_code'] ?? ''));
  $country     = trim($_POST['country'] ?? '');
  $language    = trim($_POST['language'] ?? '');
  $timezone    = trim($_POST['timezone'] ?? '');
  $dark_mode   = isset($_POST['dark_mode']) ? (int)$_POST['dark_mode'] : null;

  if ($first_name === '' || $email === '') respond(false, 'Missing required fields');
  if (!filter_var($email, FILTER_VALIDATE_EMAIL)) respond(false, 'Invalid email');

  if ($gender !== '') {
    $gender = ucfirst(strtolower($gender));
    if (!in_array($gender, ['Male', 'Female', 'Other'])) respond(false, 'Invalid gender');
  }

  if ($birthdate !== '' && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $birthdate))
    respond(false, 'Invalid birthdate format (YYYY-MM-DD)');

  // Unique checks
  $stmt = $pdo->prepare("SELECT userid FROM usertbl WHERE email = :email AND userid <> :id LIMIT 1");
  $stmt->execute([':email' => $email, ':id' => $userId]);
  if ($stmt->fetch()) respond(false, 'Email already in use');

  if ($username !== '') {
    $stmt = $pdo->prepare("SELECT userid FROM usertbl WHERE username = :username AND userid <> :id LIMIT 1");
    $stmt->execute([':username' => $username, ':id' => $userId]);
    if ($stmt->fetch()) respond(false, 'Username already in use');
  }

  // Build dynamic update query
  $fields = [
    'first_name' => $first_name,
    'last_name' => $last_name,
    'email' => $email,
    'phone_number' => $phone,
    'street_address' => $street,
    'city' => $city,
    'state' => $state,
    'postal_code' => $postal
  ];

  if ($country)  $fields['country'] = $country;
  if ($username) $fields['username'] = $username;
  if ($gender)   $fields['gender'] = $gender;
  if ($birthdate) $fields['birthdate'] = $birthdate;
  if ($language) $fields['language'] = $language;
  if ($timezone) $fields['timezone'] = $timezone;
  if ($dark_mode !== null) $fields['dark_mode'] = $dark_mode;

  $updates = [];
  foreach ($fields as $k => $v) $updates[] = "$k = :$k";
  $sql = "UPDATE usertbl SET " . implode(', ', $updates) . ", updated_at = NOW() WHERE userid = :id";
  $fields['id'] = $userId;

  $stmt = $pdo->prepare($sql);
  $stmt->execute($fields);

  // Fetch updated data
  $stmt = $pdo->prepare("SELECT * FROM usertbl WHERE userid = :id LIMIT 1");
  $stmt->execute([':id' => $userId]);
  $data = $stmt->fetch(PDO::FETCH_ASSOC);

  if ($data && !empty($data['profile_picture']) && !preg_match('#^https?://#', $data['profile_picture'])) {
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $base = $scheme . '://' . $_SERVER['HTTP_HOST'];
    $data['profile_picture'] = $base . '/' . ltrim($data['profile_picture'], '/');
  }

  respond(true, 'Profile updated successfully', ['data' => $data]);

} catch (Throwable $e) {
  http_response_code(500);
  respond(false, 'Server error: ' . $e->getMessage());
}
