<?php
// IceStore: replace BookStack's default admin password ("password") with
// this install's own, only while the account still has the default one.
$pdo = new PDO(
    sprintf('mysql:host=127.0.0.1;port=3306;dbname=%s;charset=utf8mb4', getenv('DB_DATABASE')),
    getenv('DB_USERNAME'),
    getenv('DB_PASSWORD'),
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);
$new = getenv('ADMIN_PASSWORD');
if ($new === false || $new === '') {
    fwrite(STDERR, "[icestore] ADMIN_PASSWORD is empty; leaving the admin account alone\n");
    exit(0);
}
$rows = $pdo->query("SELECT id, password FROM users WHERE email = 'admin@admin.com'")->fetchAll();
foreach ($rows as $row) {
    if (password_verify('password', $row['password'])) {
        $stmt = $pdo->prepare('UPDATE users SET password = ? WHERE id = ?');
        $stmt->execute([password_hash($new, PASSWORD_BCRYPT), $row['id']]);
        echo "[icestore] set this install's password on admin@admin.com\n";
    }
}
