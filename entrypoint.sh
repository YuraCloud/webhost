#!/bin/bash

# WebHost System - by dapaupau@sigaul.com
# Light, Optimized, Professional.

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
ORANGE='\033[0;33m'
NC='\033[0m' 
BOLD='\033[1m'

# --- Signal Handling ---
cleanup() {
    echo -e "\n${RED}[SYSTEM]${NC} Shutting down services..."
    pkill -9 nginx php node 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM

# Setup Workspace
mkdir -p /home/container/files /home/container/logs /home/container/.conf /home/container/.backups

# Config Management
CONF_FILE="/home/container/.conf/webhost.conf"
NGINX_CONF="/home/container/.conf/nginx.conf"
PHP_FPM_CONF="/home/container/.conf/php-fpm.conf"

generate_template() {
    echo -e "${CYAN}[SYSTEM]${NC} Generating $1 starter files..."
    case $1 in
        html)
            cat <<EOF > /home/container/files/index.html
<h1>YuraCloud Online</h1><p>Static HTML is working.</p>
EOF
            ;;
        php)
            cat <<EOF > /home/container/files/index.php
<?php echo "<h1>YuraCloud PHP Online</h1>"; phpinfo(); ?>
EOF
            ;;
        node|nodejs|react|nextjs)
            cat <<EOF > /home/container/files/index.js
const http = require('http');
http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end('<h1>YuraCloud Node/React Online</h1><p>Server running on port 3000</p>');
}).listen(3000, '0.0.0.0');
console.log('Server running on port 3000');
EOF
            ;;
    esac
}

quick_setup() {
    clear
    echo -e "${BLUE}##################################################${NC}"
    echo -e "${BLUE}#      YURACLOUD WEBHOST - INITIAL SETUP         #${NC}"
    echo -e "${BLUE}##################################################${NC}"
    echo ""
    echo -e "${YELLOW}[Step 1/2] Server Port${NC}"
    echo -e "Enter Allocation Port (ex: 80 or 25565):"
    read PORT
    PORT=${PORT:-80}

    echo -e "${YELLOW}[Step 2/2] Web Framework${NC}"
    echo -e "Choose: html, php, node, react, nextjs"
    read WEB_TYPE
    WEB_TYPE=${WEB_TYPE:-html}

    cat <<EOF > "$CONF_FILE"
DOMAIN=localhost
PORT=$PORT
WEB_TYPE=$WEB_TYPE
EOF

    if [ ! "$(ls -A /home/container/files)" ]; then
        generate_template $WEB_TYPE
    fi

    echo -e "${GREEN}Setup Success!${NC}"
    sleep 1
}

if [[ ! -f "$CONF_FILE" ]]; then
    quick_setup
fi

source "$CONF_FILE"

# --- Services ---

start_web() {
    echo -e "${CYAN}[SYSTEM]${NC} Starting Web Services ($WEB_TYPE)..."
    pkill -9 nginx php node 2>/dev/null
    rm -rf /home/container/logs/nginx.pid 2>/dev/null

    # Nginx Config (No SSL, Clean Proxy)
    cat <<EOF > "$NGINX_CONF"
worker_processes auto;
pid /home/container/logs/nginx.pid;
events { worker_connections 768; }
http {
    include /etc/nginx/mime.types;
    sendfile on;
    access_log /home/container/logs/access.log;
    error_log /home/container/logs/error.log;
    
    server {
        listen ${PORT};
        root /home/container/files;
        index index.php index.html;

        location / {
            if ("$WEB_TYPE" ~* (node|react|nextjs)) {
                proxy_pass http://127.0.0.1:3000;
            }
            try_files \$uri \$uri/ /index.php?\$query_string;
        }

        location ~ \.php$ {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }
    }
}
EOF

    # PHP-FPM Config
    cat <<EOF > "$PHP_FPM_CONF"
[global]
error_log = /home/container/logs/php-fpm.log
[www]
user = container
group = container
listen = 127.0.0.1:9000
pm = ondemand
pm.max_children = 5
EOF

    # Start PHP
    php-fpm82 -y "$PHP_FPM_CONF" -D 2>/dev/null
    
    # Start Nginx
    nginx -c "$NGINX_CONF" -g "daemon on;" 2>/dev/null

    # Start Node/React/Next
    if [[ "$WEB_TYPE" =~ (node|react|nextjs) ]]; then
        cd /home/container/files
        if [[ "$WEB_TYPE" == "nextjs" ]]; then
            npm install && npm run build && npm start &
        elif [[ "$WEB_TYPE" == "react" ]]; then
            npm install && npm run dev -- --host 0.0.0.0 --port 3000 &
        else
            node index.js > /home/container/logs/node.log 2>&1 &
        fi
    fi

    echo -e "${GREEN}##################################################${NC}"
    echo -e "${GREEN}#               WebHost Online!                  #${NC}"
    echo -e "  URL: http://localhost:$PORT"
    echo -e "##################################################${NC}"
}

show_menu() {
    echo -e "${CYAN}==================================================${NC}"
    echo -e "  ${BOLD}${BLUE}YuraCloud WebHost - v1.0.0${NC}"
    echo -e "  Status: ${GREEN}Online${NC} | Type: ${ORANGE}$WEB_TYPE${NC} | Port: ${ORANGE}$PORT${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e " [1] Resources  [2] Fix Perms  [3] Git Pull"
    echo -e " [4] Restart    [5] Stop       [6] Logs"
    echo -e " [7] Template   [9] Reset      [0] Exit"
    echo -e "Choice and press ENTER:"
}

# --- Auto Start ---
start_web

# --- Loop ---
while true; do
    show_menu
    read choice
    case $choice in
        1) top -b -n 1 | head -n 15; echo "Press ENTER..."; read ;;
        2) chmod -R 755 /home/container/files; echo "Done." ;;
        3) cd /home/container/files && git pull; echo "Press ENTER..."; read ;;
        4) start_web ;;
        5) pkill -9 nginx php node; echo "Stopped." ;;
        6) echo "1. Nginx 2. PHP 3. Node"; read l; [ "$l" == "1" ] && tail -n 20 /home/container/logs/error.log; [ "$l" == "2" ] && tail -n 20 /home/container/logs/php-fpm.log; [ "$l" == "3" ] && tail -n 20 /home/container/logs/node.log; echo "Press ENTER..."; read ;;
        7) echo "Type: html, php, node"; read t; generate_template $t; start_web ;;
        9) rm "$CONF_FILE"; echo "Resetting..."; exit 0 ;;
        0) cleanup ;;
        *) sleep 1 ;;
    esac
done
