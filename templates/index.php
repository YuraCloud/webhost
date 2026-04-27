<?php
$type = "PHP Runtime";
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>YuraCloud - PHP Online</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #777bb4;
            --secondary: #4f5b93;
            --bg: #0f172a;
        }
        body {
            margin: 0;
            font-family: 'Outfit', sans-serif;
            background: var(--bg);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }
        .container {
            text-align: center;
            padding: 3rem;
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            border-radius: 24px;
            border: 1px solid rgba(255, 255, 255, 0.1);
            animation: fadeIn 1s ease-out;
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 0.5rem;
            background: linear-gradient(to right, var(--primary), var(--secondary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .status {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1.5rem;
            background: rgba(119, 123, 180, 0.1);
            border-radius: 99px;
            color: var(--primary);
            font-weight: 600;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="status">PHP v<?php echo phpversion(); ?></div>
        <h1>YuraCloud</h1>
        <p>PHP Environment is working perfectly.</p>
        <div style="font-size: 0.9rem; color: #64748b; border-top: 1px solid rgba(255,255,255,0.1); padding-top: 1rem;">
            Host: <strong><?php echo $_SERVER['HTTP_HOST']; ?></strong>
        </div>
        <div style="margin-top: 2rem; font-size: 0.8rem; color: #64748b;">Powered by <strong>YuraCloud</strong></div>
    </div>
</body>
</html>
