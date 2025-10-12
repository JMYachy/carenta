<?php
// htdocs/carenta/api/user_profile_update.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$host="localhost"; $user="root"; $pass=""; $db="carentadb";
$conn = new mysqli($host,$user,$pass,$db);
if ($conn->connect_error) {
  http_response_code(500);
  echo json_encode(['ok'=>false,'error'=>'DB_CONNECT_FAIL']);
  exit;
}

$userid      = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$first_name  = trim($_POST['first_name'] ?? '');
$last_name   = trim($_POST['last_name'] ?? '');
$email       = trim($_POST['email'] ?? '');
$phone       = trim($_POST['phone_number'] ?? '');
$username    = isset($_POST['username']) ? trim($_POST['username']) : null;

$gender      = isset($_POST['gender']) ? trim($_POST['gender']) : null; // Male|Female|Other
$birthdate   = isset($_POST['birthdate']) ? trim($_POST['birthdate']) : null;

// Address mapping
$street_address = trim($_POST['street_address'] ?? ($_POST['address'] ?? ''));
$city           = trim($_POST['city'] ?? '');
$state          = trim($_POST['state'] ?? ($_POST['province'] ?? ''));
$postal_code    = trim($_POST['postal_code'] ?? ($_POST['zip_code'] ?? ''));
$country        = trim($_POST['country'] ?? '');

// New optional fields
$language   = trim($_POST['language'] ?? '');
$timezone   = trim($_POST['timezone'] ?? '');
$dark_mode  = isset($_POST['dark_mode']) ? (int)$_POST['dark_mode'] : null;

if ($userid<=0 || $first_name==='' || $email==='') {
  http_response_code(400);
  echo json_encode(['ok'=>false,'error'=>'BAD_REQUEST','message'=>'Missing fields']);
  exit;
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
  http_response_code(400);
  echo json_encode(['ok'=>false,'error'=>'INVALID_EMAIL']);
  exit;
}
if ($gender !== null && $gender !== '') {
  $genderNorm = ucfirst(strtolower($gender));
  if (!in_array($genderNorm, ['Male','Female','Other'])) {
    http_response_code(400);
    echo json_encode(['ok'=>false,'error'=>'INVALID_GENDER']);
    exit;
  }
  $gender = $genderNorm;
}

// ---- Uniqueness checks ----
$stmt = $conn->prepare("SELECT userid FROM usertbl WHERE email = ? AND userid <> ? LIMIT 1");
$stmt->bind_param('si', $email, $userid);
$stmt->execute();
if ($stmt->get_result()->num_rows > 0) {
  http_response_code(409);
  echo json_encode(['ok'=>false,'error'=>'EMAIL_IN_USE']);
  exit;
}

if ($username !== null && $username !== '') {
  $stmt = $conn->prepare("SELECT userid FROM usertbl WHERE username = ? AND userid <> ? LIMIT 1");
  $stmt->bind_param('si', $username, $userid);
  $stmt->execute();
  if ($stmt->get_result()->num_rows > 0) {
    http_response_code(409);
    echo json_encode(['ok'=>false,'error'=>'USERNAME_IN_USE']);
    exit;
  }
}

// ---- Build dynamic update ----
$sql = "UPDATE usertbl SET
          first_name = ?, last_name = ?, email = ?, phone_number = ?,
          street_address = ?, city = ?, state = ?, postal_code = ?,
          updated_at = CURRENT_TIMESTAMP";
$types = "ssssssss";
$params = [$first_name, $last_name, $email, $phone, $street_address, $city, $state, $postal_code];

if ($country !== '') { $sql .= ", country = ?"; $types .= "s"; $params[] = $country; }
if ($username !== null && $username !== '') { $sql .= ", username = ?"; $types .= "s"; $params[] = $username; }
if ($gender !== null && $gender !== '') { $sql .= ", gender = ?"; $types .= "s"; $params[] = $gender; }
if ($birthdate !== null && $birthdate !== '') {
  if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $birthdate)) {
    http_response_code(400);
    echo json_encode(['ok'=>false,'error'=>'INVALID_BIRTHDATE']);
    exit;
  }
  $sql .= ", birthdate = ?"; $types .= "s"; $params[] = $birthdate;
}
if ($language !== '') { $sql .= ", language = ?"; $types .= "s"; $params[] = $language; }
if ($timezone !== '') { $sql .= ", timezone = ?"; $types .= "s"; $params[] = $timezone; }
if ($dark_mode !== null) { $sql .= ", dark_mode = ?"; $types .= "i"; $params[] = $dark_mode; }

$sql .= " WHERE userid = ?";
$types .= "i";
$params[] = $userid;

$stmt = $conn->prepare($sql);
$stmt->bind_param($types, ...$params);
if (!$stmt->execute()) {
  http_response_code(500);
  echo json_encode(['ok'=>false,'error'=>'UPDATE_FAIL','message'=>$conn->error]);
  exit;
}

// ---- Return updated profile ----
$res = $conn->query("SELECT * FROM usertbl WHERE userid = $userid LIMIT 1");
$data = $res ? $res->fetch_assoc() : null;

echo json_encode(['ok'=>true,'message'=>'Profile updated','data'=>$data], JSON_UNESCAPED_SLASHES);
