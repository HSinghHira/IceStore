<?php
// IceStore: make the first TryPost account, once. Self-hosted TryPost only
// lets people sign up with an invite, and upstream's UserSeeder makes
// admin@trypost.it / "password" for everyone. This makes the account from
// ADMIN_EMAIL and this install's ADMIN_PASSWORD instead. Once any account
// exists it does nothing. Runs inside the trypost chroot as www-data, after
// the app is up (migrations done, config cached).

declare(strict_types=1);

chdir('/var/www/html');
require '/var/www/html/vendor/autoload.php';
$app = require '/var/www/html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

if (App\Models\User::query()->exists()) {
    echo "an account already exists, nothing to do\n";
    exit(0);
}

$email = trim((string) getenv('ADMIN_EMAIL'));
$password = (string) getenv('ADMIN_PASSWORD');
if ($email === '' || $password === '') {
    fwrite(STDERR, "ADMIN_EMAIL or ADMIN_PASSWORD is empty, no account made\n");
    exit(1);
}

App\Actions\User\CreateUser::execute([
    'name' => trim((string) getenv('ADMIN_NAME')) ?: 'Admin',
    'email' => $email,
    'password' => $password,
    'email_verified_at' => now(),
]);

echo "made the first account: {$email}\n";
