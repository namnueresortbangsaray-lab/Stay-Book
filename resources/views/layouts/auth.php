<?php
use App\Core\Session;
use App\Core\View;
$assets = View::assets();
?>
<!doctype html>
<html lang="th" class="h-full">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#f6fafe">
  <meta name="csrf-token" content="<?= View::e(Session::csrf()) ?>">
  <title>เข้าสู่ระบบ · Stay Book · น้ำเหนือรีสอร์ท</title>
  <link rel="icon" href="/images/logo_square.webp">
  <link rel="stylesheet" href="<?= View::e($assets['app.css'] ?? '/build/app.css') ?>">
</head>
<body class="min-h-full bg-canvas text-ink antialiased">
  <?= $content ?>
</body>
</html>
