<?php
// htdocs/carenta/api/user_profile.php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$host = "localhost";
$user = "root";
$pass = "";
$db   = "carentadb";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['ok'=>false,'message'=>'DB connection failed']);
    exit;
}

$userid = isset($_GET['user_id']) ? (int)$_GET['user_id'] : (isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0);
if ($userid <= 0) {
    http_response_code(400);
    echo json_encode(['ok'=>false,'message'=>'user_id required']);
    exit;
}

/* ============= GET: fetch profile ============= */
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $sql = "SELECT userid, username, email, first_name, last_name, gender, birthdate,
                   phone_number, profile_picture, street_address, city, state, postal_code, country,
                   role, status, is_verified, language, timezone, dark_mode,
                   last_login, last_ip_address, created_at, updated_at
            FROM usertbl WHERE userid=? LIMIT 1";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param('i', $userid);
    $stmt->execute();
    $res = $stmt->get_result();
    if ($res->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['ok'=>false,'message'=>'User not found']);
        exit;
    }
    $row = $res->fetch_assoc();
    // Aliases for Flutter
    $row['address']  = $row['street_address'];
    $row['province'] = $row['state'];
    $row['zip_code'] = $row['postal_code'];
    echo json_encode(['ok'=>true,'data'=>$row], JSON_UNESCAPED_SLASHES);
    exit;
}

/* ============= POST: update profile ============= */
$first_name     = trim($_POST['first_name'] ?? '');
$last_name      = trim($_POST['last_name'] ?? '');
$email          = trim($_POST['email'] ?? '');
$phone          = trim($_POST['phone_number'] ?? '');
$username       = $_POST['username'] ?? null;
$gender         = $_POST['gender'] ?? null;
$birthdate      = $_POST['birthdate'] ?? null;
$street_address = $_POST['address'] ?? ($_POST['street_address'] ?? '');
$city           = $_POST['city'] ?? '';
$state          = $_POST['province'] ?? ($_POST['state'] ?? '');
$postal_code    = $_POST['zip_code'] ?? ($_POST['postal_code'] ?? '');
$country        = $_POST['country'] ?? '';
$language       = $_POST['language'] ?? '';
$timezone       = $_POST['timezone'] ?? '';
$dark_mode      = isset($_POST['dark_mode']) ? (int)$_POST['dark_mode'] : null;

if ($first_name==='' || $email==='') {
    http_response_code(400);
    echo json_encode(['ok'=>false,'message'=>'Missing required fields']);
    exit;
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['ok'=>false,'message'=>'Invalid email']);
    exit;
}
if ($gender) {
    $gender = ucfirst(strtolower($gender));
    if (!in_array($gender, ['Male','Female','Other'])) {
        http_response_code(400);
        echo json_encode(['ok'=>false,'message'=>'Invalid gender']);
        exit;
    }
}

/* --- uniqueness checks --- */
$stmt = $conn->prepare("SELECT userid FROM usertbl WHERE email=? AND userid<>? LIMIT 1");
$stmt->bind_param('si', $email, $userid);
$stmt->execute();
if ($stmt->get_result()->num_rows > 0) {
    http_response_code(409);
    echo json_encode(['ok'=>false,'message'=>'Email already in use']);
    exit;
}
if ($username) {
    $stmt = $conn->prepare("SELECT userid FROM usertbl WHERE username=? AND userid<>? LIMIT 1");
    $stmt->bind_param('si', $username, $userid);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        http_response_code(409);
        echo json_encode(['ok'=>false,'message'=>'Username already in use']);
        exit;
    }
}

/* --- build update query --- */
$sql = "UPDATE usertbl SET first_name=?, last_name=?, email=?, phone_number=?,
          street_address=?, city=?, state=?, postal_code=?, updated_at=CURRENT_TIMESTAMP";
$types = "ssssssss";
$params = [$first_name,$last_name,$email,$phone,$street_address,$city,$state,$postal_code];

if ($country)   { $sql.=", country=?";   $types.="s"; $params[]=$country; }
if ($username)  { $sql.=", username=?";  $types.="s"; $params[]=$username; }
if ($gender)    { $sql.=", gender=?";    $types.="s"; $params[]=$gender; }
if ($birthdate) { $sql.=", birthdate=?"; $types.="s"; $params[]=$birthdate; }
if ($language)  { $sql.=", language=?";  $types.="s"; $params[]=$language; }
if ($timezone)  { $sql.=", timezone=?";  $types.="s"; $params[]=$timezone; }
if ($dark_mode!==null) { $sql.=", dark_mode=?"; $types.="i"; $params[]=$dark_mode; }

$sql.=" WHERE userid=?";
$types.="i";
$params[]=$userid;

$stmt=$conn->prepare($sql);
$stmt->bind_param($types,...$params);
if(!$stmt->execute()) {
    http_response_code(500);
    echo json_encode(['ok'=>false,'message'=>'Update failed','error'=>$conn->error]);
    exit;
}

/* --- avatar upload if provided --- */
if (isset($_FILES['avatar']) && $_FILES['avatar']['error']===UPLOAD_ERR_OK) {
    $dir = __DIR__ . '/../uploads/avatars/';
    if (!is_dir($dir)) @mkdir($dir,0777,true);
    $ext = strtolower(pathinfo($_FILES['avatar']['name'], PATHINFO_EXTENSION));
    $allowed=['jpg','jpeg','png','webp'];
    if (in_array($ext,$allowed)) {
        $fname="u{$userid}_".time().".$ext";
        $dest=$dir.$fname;
        if (move_uploaded_file($_FILES['avatar']['tmp_name'],$dest)) {
            $dbPath="uploads/avatars/$fname";
            $upd=$conn->prepare("UPDATE usertbl SET profile_picture=?, updated_at=CURRENT_TIMESTAMP WHERE userid=?");
            $upd->bind_param('si',$dbPath,$userid);
            $upd->execute();
        }
    }
}

echo json_encode(['ok'=>true,'message'=>'Profile updated']);
