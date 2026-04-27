const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send({
        status: 'online',
        message: 'Welcome to WebHost Node.js environment',
        server_info: {
            platform: process.platform,
            node_version: process.version,
            uptime: process.uptime()
        },
        powered_by: 'YuraCloud',
        timestamp: new Date()
    });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Server running at http://0.0.0.0:${port}`);
});
