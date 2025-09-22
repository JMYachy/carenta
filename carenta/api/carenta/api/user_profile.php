<?php
// htdocs/carenta/api/user_profile.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$host = "localhost";
$user = "root";
$pass = "";
$db   = "carentadb"; // <-- change to 'carentadb' if that's your actual DB name

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) { http_response_code(500); echo json_encode(['ok'=>false,'error'=>'DB_CONNECT_FAIL']); exit; }

$userid = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($userid <= 0) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'BAD_REQUEST','message'=>'user_id required']); exit; }

$sql = "SELECT
          userid, username, email, bcrypt,
          first_name, last_name,
          gender, birthdate,
          phone_number, profile_picture,
          street_address, city, state, postal_code, country,
          role AS account_type, status,
          created_at, updated_at
        FROM usertbl
        WHERE userid = ?
        LIMIT 1";
$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $userid);
$stmt->execute();
$res = $stmt->get_result();
if ($res->num_rows === 0) { http_response_code(404); echo json_encode(['ok'=>false,'error'=>'NOT_FOUND']); exit; }
$row = $res->fetch_assoc();

/* Provide aliases to match your Flutter mapping */
$row['address']  = $row['street_address'];
$row['province'] = $row['state'];
$row['zip_code'] = $row['postal_code'];

echo json_encode(['ok'=>true, 'data'=>$row], JSON_UNESCAPED_SLASHES);
