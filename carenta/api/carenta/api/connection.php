<?php
// connection.php  (UTF-8, NO BOM, no echo/print)
$host   = "localhost";
$dbname = "carentadb";
$dbuser = "root";  // change if needed
$dbpass = "";      // change if needed

$dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";
$options = [
  PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
  PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
  PDO::ATTR_EMULATE_PREPARES   => false,
];

$conn = new PDO($dsn, $dbuser, $dbpass, $options);
