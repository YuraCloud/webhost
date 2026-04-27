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

# Setup Workspace (Everything in /home/container)
mkdir -p /home/container/files /home/container/logs /home/container/.conf /home/container/.backups

# Config Management
CONF_FILE="/home/container/.conf/webhost.conf"
NGINX_CONF="/home/container/.conf/nginx.conf"
PHP_FPM_CONF="/home/container/.conf/php-fpm.conf"

auto_detect() {
    if [[ -f "/home/container/files/artisan" ]]; then WEB_TYPE="laravel"
    elif [[ -f "/home/container/files/package.json" ]]; then
        grep -q "next" "/home/container/files/package.json" && WEB_TYPE="nextjs" || WEB_TYPE="nodejs"
    elif [[ -f "/home/container/files/index.php" ]]; then WEB_TYPE="php"
    elif [[ -f "/home/container/files/index.html" ]]; then WEB_TYPE="html"
    else WEB_TYPE="none"
    fi
}

# Initial Config
if [[ ! -f "$CONF_FILE" ]]; then
    auto_detect
    cat <<EOF > "$CONF_FILE"
LANG=EN
DOMAIN=${DOMAIN:-localhost}
PORT=${SERVER_PORT:-80}
SSL=${SSL:-false}
WEB_TYPE=${WEB_TYPE_OVERRIDE:-$WEB_TYPE}
EOF
fi

source "$CONF_FILE"
CUR_LANG=${LANG:-EN}
source "/home/container/bahasa/${CUR_LANG,,}.sh" 2>/dev/null || T_TITLE="WebHost v1.0"

# --- Optimized Functions ---

start_web() {
    echo -e "${CYAN}[SYSTEM]${NC} Starting Web Services ($WEB_TYPE)..."
    
    # Kill existing
    pkill nginx php node 2>/dev/null

    # Generate Writable Nginx Config
    cat <<EOF > "$NGINX_CONF"
worker_processes auto;
pid /home/container/logs/nginx.pid;
events { worker_connections 768; }
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /home/container/logs/access.log;
    error_log /home/container/logs/error.log;
    client_body_temp_path /home/container/logs/nginx_body;
    proxy_temp_path /home/container/logs/nginx_proxy;
    fastcgi_temp_path /home/container/logs/nginx_fastcgi;
    uwsgi_temp_path /home/container/logs/nginx_uwsgi;
    scgi_temp_path /home/container/logs/nginx_scgi;
    server {
        listen ${SERVER_PORT};
        root /home/container/files;
        index index.php index.html;
        location / {
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

    # Generate Writable PHP-FPM Config
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

    # Start Services with Custom Config Paths
    php-fpm82 -y "$PHP_FPM_CONF" -D 2>/dev/null
    nginx -c "$NGINX_CONF" -g "daemon on;" 2>/dev/null

    if [[ "$WEB_TYPE" == "nodejs" || "$WEB_TYPE" == "react" || "$WEB_TYPE" == "nextjs" ]]; then
        cd /home/container/files
        [[ ! -d "node_modules" ]] && npm install --production
        [[ "$WEB_TYPE" == "nodejs" ]] && node index.js &
        [[ "$WEB_TYPE" == "nextjs" ]] && npm start &
        [[ "$WEB_TYPE" == "react" ]] && npm run dev -- --host 0.0.0.0 --port 3000 &
    fi

    echo -e "${GREEN}##################################################${NC}"
    echo -e "${GREEN}#                                                #${NC}"
    echo -e "${GREEN}#               WebHost Online!                  #${NC}"
    echo -e "${GREEN}#                                                #${NC}"
    echo -e "${GREEN}##################################################${NC}"
}

show_menu() {
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "  ${BOLD}${BLUE}YuraCloud WebHost - v1.0.0${NC}"
    echo -e "  ${WHITE}Status: ${GREEN}Online${NC} | Type: ${ORANGE}$WEB_TYPE${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e " [1] ${WHITE}Check Resources${NC}  [2] ${WHITE}Fix Permissions${NC}"
    echo -e " [3] ${WHITE}Git Pull${NC}         [4] ${WHITE}Restart Web${NC}"
    echo -e " [5] ${WHITE}Stop Web${NC}         [6] ${WHITE}Node.js Log${NC}"
    echo -e " [7] ${WHITE}Nginx Log${NC}        [8] ${WHITE}PHP Log${NC}"
    echo -e " [10] ${WHITE}Advanced Tools${NC}   [11] ${WHITE}Language${NC}"
    echo -e " [0] ${WHITE}Exit${NC}"
    echo -e "${CYAN}--------------------------------------------------${NC}"
}

# --- Auto Start ---
start_web

# --- Main Interaction Loop ---
while true; do
    show_menu
    read -t 60 -p "yuracloud@webhost > " choice
    [[ -z "$choice" ]] && continue
    case $choice in
        1) top -b -n 1 | head -n 20; read -p "Press Enter..." ;;
        2) chmod -R 755 /home/container/files; echo "Fixed."; sleep 1 ;;
        3) cd /home/container/files && git pull; read -p "Press Enter..." ;;
        4) start_web; sleep 1 ;;
        5) pkill nginx php node; echo "Services stopped."; sleep 1 ;;
        6) tail -n 50 /home/container/logs/node.log 2>/dev/null || echo "No log."; read -p "Enter..." ;;
        7) tail -n 50 /home/container/logs/error.log; read -p "Enter..." ;;
        8) tail -n 50 /home/container/logs/php-fpm.log; read -p "Enter..." ;;
        11) echo "1. EN 2. ID 3. KR 4. JP"; read -p "> " l; [ "$l" == "1" ] && L=EN; [ "$l" == "2" ] && L=ID; [ "$l" == "3" ] && L=KR; [ "$l" == "4" ] && L=JP;
            sed -i "s/LANG=.*/LANG=$L/" "$CONF_FILE"; source "$CONF_FILE"; clear ;;
        0) exit 0 ;;
        *) echo "Invalid option." ; sleep 1 ;;
    esac
done
