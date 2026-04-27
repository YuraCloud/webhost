const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>YuraCloud - Node.js Online</title>
        <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600&display=swap" rel="stylesheet">
        <style>
            body { background: #0f172a; color: white; font-family: 'Outfit', sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .card { text-align: center; padding: 3rem; background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border-radius: 24px; border: 1px solid rgba(255,255,255,0.1); }
            h1 { background: linear-gradient(to right, #4facfe, #00f2fe); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-size: 3rem; margin: 1rem 0; }
            .tag { color: #4facfe; background: rgba(79, 172, 254, 0.1); padding: 0.5rem 1rem; border-radius: 99px; font-weight: 600; }
        </style>
    </head>
    <body>
        <div class="card">
            <span class="tag">Node.js ${process.version}</span>
            <h1>YuraCloud</h1>
            <p>Node.js Server is running on port 3000</p>
            <div style="margin-top: 2rem; color: #64748b;">Powered by <strong>YuraCloud</strong></div>
        </div>
    </body>
    </html>
  `);
});

server.listen(3000, '0.0.0.0', () => {
  console.log('YuraCloud Node.js Server is ready!');
});
