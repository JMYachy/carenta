<?php
session_start();

// Always send JSON response
header('Content-Type: application/json; charset=utf-8');

// Database connection
$host = "localhost";
$dbname = "carentadb";
$dbuser = "root"; // change if needed
$dbpass = "";     // change if needed

try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $dbuser, $dbpass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(["status" => "error", "message" => "Database connection failed."]);
    exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $login_input = trim($_POST['username'] ?? '');
    $login_pass = trim($_POST['password'] ?? '');

    if (empty($login_input) || empty($login_pass)) {
        echo json_encode(["status" => "error", "message" => "Please fill in all fields."]);
        exit;
    }

    // 1. Check in admintbl
    $stmt = $conn->prepare("
        SELECT *, 'admin_table' as table_name 
        FROM admintbl 
        WHERE username = :user OR email = :user OR phone_number = :user 
        LIMIT 1
    ");
    $stmt->bindParam(':user', $login_input);
    $stmt->execute();
    $account = $stmt->fetch(PDO::FETCH_ASSOC);

    // 2. If not found in admin, check usertbl
    if (!$account) {
        $stmt = $conn->prepare("
            SELECT *, 'user_table' as table_name 
            FROM usertbl 
            WHERE username = :user OR email = :user OR phone_number = :user 
            LIMIT 1
        ");
        $stmt->bindParam(':user', $login_input);
        $stmt->execute();
        $account = $stmt->fetch(PDO::FETCH_ASSOC);
    }

    if ($account) {
        // Verify password with bcrypt column
        if (password_verify($login_pass, $account['bcrypt'])) {
            $_SESSION['id'] = ($account['table_name'] == 'admin_table') ? $account['adminid'] : $account['userid'];
            $_SESSION['username'] = $account['username'];
            $_SESSION['role'] = $account['role'];
            $_SESSION['account_type'] = $account['table_name'];

            // Update last login
            if ($account['table_name'] == 'admin_table') {
                $update = $conn->prepare("UPDATE admintbl SET last_login = NOW(), last_ip_address = :ip WHERE adminid = :id");
                $update->execute([':ip' => $_SERVER['REMOTE_ADDR'], ':id' => $account['adminid']]);
            } else {
                $update = $conn->prepare("UPDATE usertbl SET last_login = NOW(), last_ip_address = :ip WHERE userid = :id");
                $update->execute([':ip' => $_SERVER['REMOTE_ADDR'], ':id' => $account['userid']]);
            }

            echo json_encode([
                "status" => "success",
                "message" => "Login successful",
                "role" => $account['role'],
                "account_type" => $account['table_name'],
                "username" => $account['username']
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => "Invalid password."]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Account not found."]);
    }
}
    