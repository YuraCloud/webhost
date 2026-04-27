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
    pkill nginx php node 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM

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

copy_template() {
    case $1 in
        html) cp /home/container/templates/index.html /home/container/files/index.html ;;
        php) cp /home/container/templates/index.php /home/container/files/index.php ;;
        *) cp /home/container/templates/node_index.js /home/container/files/index.js ;;
    esac
}

quick_setup() {
    clear
    echo -e "${BLUE}##################################################${NC}"
    echo -e "${BLUE}#      YURACLOUD WEBHOST - INITIAL SETUP         #${NC}"
    echo -e "${BLUE}##################################################${NC}"
    echo ""
    echo -e "${YELLOW}[!] First run detected.${NC}"
    echo ""

    echo -e "${CYAN}[Step 1/4] Domain Name${NC}"
    echo -e "Please type your domain (ex: myweb.com) and press ENTER:"
    read DOMAIN
    DOMAIN=${DOMAIN:-localhost}
    echo -e "${GREEN}Domain set to: $DOMAIN${NC}"
    echo ""

    echo -e "${CYAN}[Step 2/4] Server Port${NC}"
    echo -e "Please type your Allocation Port and press ENTER:"
    read PORT
    PORT=${PORT:-80}
    echo -e "${GREEN}Port set to: $PORT${NC}"
    echo ""

    echo -e "${CYAN}[Step 3/4] SSL Support${NC}"
    echo -e "Enable SSL? (type 'true' or 'false') and press ENTER:"
    read SSL
    SSL=${SSL:-false}
    echo -e "${GREEN}SSL set to: $SSL${NC}"
    echo ""

    auto_detect
    echo -e "${CYAN}[Step 4/4] Web Framework${NC}"
    echo -e "Detected: $WEB_TYPE. Type new one or press ENTER to keep:"
    read input_type
    WEB_TYPE=${input_type:-$WEB_TYPE}
    echo -e "${GREEN}Type set to: $WEB_TYPE${NC}"
    echo ""

    cat <<EOF > "$CONF_FILE"
LANG=EN
DOMAIN=$DOMAIN
PORT=$PORT
SSL=$SSL
WEB_TYPE=$WEB_TYPE
EOF

    if [ ! "$(ls -A /home/container/files)" ]; then
        copy_template $WEB_TYPE
    fi

    echo -e "${GREEN}Setup Success! Starting services...${NC}"
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
        if [[ "$WEB_TYPE" == "nextjs" ]]; then
             npm start > /home/container/logs/node.log 2>&1 &
        else
             node index.js > /home/container/logs/node.log 2>&1 &
        fi
    fi

    echo -e "${GREEN}##################################################${NC}"
    echo -e "${GREEN}#               WebHost Online!                  #${NC}"
    echo -e "${GREEN}##################################################${NC}"
}

show_menu() {
    echo -e "${CYAN}==================================================${NC}"
    echo -e "  ${BOLD}${BLUE}YuraCloud WebHost - v1.0.0${NC}"
    echo -e "  ${WHITE}Status: ${GREEN}Online${NC} | Type: ${ORANGE}$WEB_TYPE${NC} | Port: ${ORANGE}$PORT${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e " [1] Resources   [2] Fix Perms  [3] Git Pull"
    echo -e " [4] Restart Web [5] Stop Web   [6] Check Logs"
    echo -e " [7] Template    [9] Reset      [0] Exit"
    echo -e "${CYAN}--------------------------------------------------${NC}"
}

# --- Auto Start ---
start_web

# --- Loop ---
while true; do
    show_menu
    echo -e "Type your choice and press ENTER:"
    read -t 60 choice
    case $choice in
        1) top -b -n 1 | head -n 15; echo "Press ENTER to continue..."; read ;;
        2) chmod -R 755 /home/container/files; echo "Done." ;;
        3) cd /home/container/files && git pull; echo "Press ENTER to continue..."; read ;;
        4) start_web ;;
        5) pkill nginx php node; echo "Stopped." ;;
        6) echo "1. Nginx 2. PHP 3. Node"; read l; [ "$l" == "1" ] && tail -n 20 /home/container/logs/error.log; [ "$l" == "2" ] && tail -n 20 /home/container/logs/php-fpm.log; [ "$l" == "3" ] && tail -n 20 /home/container/logs/node.log; echo "Press ENTER to continue..."; read ;;
        7) echo "Choose Template: (html/php/node)"; read t; copy_template $t; start_web ;;
        9) rm "$CONF_FILE"; echo "Config deleted. Restarting..."; exit 0 ;;
        0) cleanup ;;
    esac
done
