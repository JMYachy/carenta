<?php
// htdocs/carenta/api/user_favorites.php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$host="localhost"; $user="root"; $pass=""; $db="carentadb";
$conn = new mysqli($host,$user,$pass,$db);
if ($conn->connect_error) { http_response_code(500); echo json_encode(['ok'=>false,'error'=>'DB_CONNECT_FAIL']); exit; }

$userid = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($userid <= 0) { http_response_code(400); echo json_encode(['ok'=>false,'error'=>'BAD_REQUEST','message'=>'user_id required']); exit; }

$sort = $_GET['sort'] ?? 'recent'; // recent | price_asc | price_desc | rating_desc
$orderBy = "f.created_at DESC";
if     ($sort === 'price_asc')  $orderBy = "c.daily_rate ASC";
elseif ($sort === 'price_desc') $orderBy = "c.daily_rate DESC";
elseif ($sort === 'rating_desc')$orderBy = "c.rating DESC, f.created_at DESC"; // if you have rating

// optional free-text filter
$q = trim($_GET['q'] ?? '');
$hasQ = $q !== '';
$qLike = "%$q%";

// Basic join: favorite -> car (plus optional media for a thumbnail)
// Adjust column names if your schema differs (e.g., brand/model/plate/daily_rate)
$sql = "
  SELECT
    c.*,
    f.created_at AS favorited_at,
    MIN(m.media_url) AS media_url -- any image; adjust if you have thumbnail flag
  FROM favoritecarstbl f
  JOIN cartbl c ON c.carid = f.carid
  LEFT JOIN mediatbl m ON m.carid = c.carid
  WHERE f.userid = ?
  " . ($hasQ ? "AND (c.carname LIKE ? OR c.brand LIKE ? OR c.model LIKE ?)" : "") . "
  GROUP BY c.carid
  ORDER BY $orderBy
";

if ($hasQ) {
  $stmt = $conn->prepare($sql);
  $stmt->bind_param('isss', $userid, $qLike, $qLike, $qLike);
} else {
  $stmt = $conn->prepare($sql);
  $stmt->bind_param('i', $userid);
}

$stmt->execute();
$res = $stmt->get_result();

$out = [];
while ($row = $res->fetch_assoc()) {
  $out[] = $row;
}

echo json_encode(['ok'=>true,'count'=>count($out),'data'=>$out], JSON_UNESCAPED_SLASHES);
