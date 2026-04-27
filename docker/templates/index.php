<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>PHP Dashboard - WebHost Pro</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background: #f3f4f6; padding: 2rem; }
        .card { background: white; padding: 2rem; border-radius: 1rem; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); max-width: 600px; margin: auto; }
        .info { background: #eff6ff; padding: 1rem; border-radius: 0.5rem; margin-top: 1rem; border-left: 4px solid #3b82f6; }
        .success { color: #059669; font-weight: bold; }
    </style>
</head>
<body>
    <div class="card">
        <h2>PHP System Status</h2>
        <div class="info">
            <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
            <p><strong>Server Software:</strong> <?php echo $_SERVER['SERVER_SOFTWARE']; ?></p>
            <p><strong>Server IP:</strong> <?php echo $_SERVER['SERVER_ADDR'] ?? '127.0.0.1'; ?></p>
            <p><strong>Status:</strong> <span class="success">Active</span></p>
        </div>
        <div style="margin-top: 1.5rem; text-align: center; color: #94a3b8; font-size: 0.8rem;">Powered by YuraCloud</div>
    </div>
</body>
</html>
