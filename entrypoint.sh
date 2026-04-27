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

# Setup Workspace
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

quick_setup() {
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "         ${BOLD}${BLUE}YuraCloud WebHost - Quick Setup${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${WHITE}First run detected. Please configure your server:${NC}"
    echo ""
    read -p "Enter Domain (default: localhost): " input_domain
    DOMAIN=${input_domain:-localhost}
    
    read -p "Enter Port (default: 80): " input_port
    PORT=${input_port:-80}
    
    read -p "Use SSL? (true/false, default: false): " input_ssl
    SSL=${input_ssl:-false}
    
    auto_detect
    echo -e "Detected Web Type: ${ORANGE}$WEB_TYPE${NC}"
    read -p "Override Web Type? (html/php/nodejs/nextjs/laravel, enter to skip): " input_type
    WEB_TYPE=${input_type:-$WEB_TYPE}

    cat <<EOF > "$CONF_FILE"
LANG=EN
DOMAIN=$DOMAIN
PORT=$PORT
SSL=$SSL
WEB_TYPE=$WEB_TYPE
EOF
    echo -e "${GREEN}Setup saved! Restarting...${NC}"
    sleep 2
}

if [[ ! -f "$CONF_FILE" ]]; then
    quick_setup
fi

source "$CONF_FILE"
CUR_LANG=${LANG:-EN}
source "/home/container/bahasa/${CUR_LANG,,}.sh" 2>/dev/null || T_TITLE="WebHost v1.0"

# --- Services ---

start_web() {
    echo -e "${CYAN}[SYSTEM]${NC} Starting Web Services ($WEB_TYPE)..."
    pkill nginx php node 2>/dev/null

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
        listen ${PORT};
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

    php-fpm82 -y "$PHP_FPM_CONF" -D 2>/dev/null
    nginx -c "$NGINX_CONF" -g "daemon on;" 2>/dev/null

    if [[ "$WEB_TYPE" == "nodejs" || "$WEB_TYPE" == "nextjs" ]]; then
        cd /home/container/files
        [[ ! -d "node_modules" ]] && npm install --production
        [[ "$WEB_TYPE" == "nodejs" ]] && node index.js > /home/container/logs/node.log 2>&1 &
        [[ "$WEB_TYPE" == "nextjs" ]] && npm start > /home/container/logs/node.log 2>&1 &
    fi

    echo -e "${GREEN}##################################################${NC}"
    echo -e "${GREEN}#                                                #${NC}"
    echo -e "${GREEN}#               WebHost Online!                  #${NC}"
    echo -e "${GREEN}#                                                #${NC}"
    echo -e "${GREEN}##################################################${NC}"
}

show_menu() {
    echo -e "${CYAN}==================================================${NC}"
    echo -e "  ${BOLD}${BLUE}YuraCloud WebHost - v1.0.0${NC}"
    echo -e "  ${WHITE}Status: ${GREEN}Online${NC} | Type: ${ORANGE}$WEB_TYPE${NC} | Port: ${ORANGE}$PORT${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e " [1] ${WHITE}Resources${NC}   [2] ${WHITE}Fix Perms${NC}  [3] ${WHITE}Git Pull${NC}"
    echo -e " [4] ${WHITE}Restart Web${NC} [5] ${WHITE}Stop Web${NC}   [6] ${WHITE}Check Logs${NC}"
    echo -e " [9] ${WHITE}Reset Config${NC} [11] ${WHITE}Language${NC} [0] ${WHITE}Exit${NC}"
    echo -e "${CYAN}--------------------------------------------------${NC}"
}

# --- Auto Start ---
start_web

# --- Loop ---
while true; do
    show_menu
    read -p "yuracloud@webhost > " choice
    case $choice in
        1) top -b -n 1 | head -n 15; read -p "Enter..." ;;
        2) chmod -R 755 /home/container/files; echo "Done." ;;
        3) cd /home/container/files && git pull; read -p "Enter..." ;;
        4) start_web ;;
        5) pkill nginx php node; echo "Stopped." ;;
        6) echo "1. Nginx 2. PHP 3. Node"; read -p "> " l; [ "$l" == "1" ] && tail -n 20 /home/container/logs/error.log; [ "$l" == "2" ] && tail -n 20 /home/container/logs/php-fpm.log; [ "$l" == "3" ] && tail -n 20 /home/container/logs/node.log; read -p "Enter..." ;;
        9) rm "$CONF_FILE"; echo "Config deleted. Restart to setup."; exit 0 ;;
        11) echo "1. EN 2. ID 3. KR 4. JP"; read -p "> " l; [ "$l" == "1" ] && L=EN; [ "$l" == "2" ] && L=ID; [ "$l" == "3" ] && L=KR; [ "$l" == "4" ] && L=JP;
            sed -i "s/LANG=.*/LANG=$L/" "$CONF_FILE"; source "$CONF_FILE"; clear ;;
        0) exit 0 ;;
    esac
done
