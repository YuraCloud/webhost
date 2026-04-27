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

# Clear screen & Setup
clear
mkdir -p /home/container/files /home/container/logs /home/container/.conf /home/container/.backups

# Config Management
CONF_FILE="/home/container/.conf/webhost.conf"

auto_detect() {
    if [[ -f "/home/container/files/artisan" ]]; then WEB_TYPE="laravel"
    elif [[ -f "/home/container/files/package.json" ]]; then
        grep -q "next" "/home/container/files/package.json" && WEB_TYPE="nextjs" || WEB_TYPE="nodejs"
    elif [[ -f "/home/container/files/index.php" ]]; then WEB_TYPE="php"
    elif [[ -f "/home/container/files/index.html" ]]; then WEB_TYPE="html"
    else WEB_TYPE="none"
    fi
}

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

show_info() {
    echo -e "\n${CYAN}═══ SYSTEM INFO ═══${NC}"
    echo -e "Mode: $WEB_TYPE | Host: $DOMAIN | Port: $PORT"
    
    # Accurate Resource Monitoring
    if [[ -f /sys/fs/cgroup/memory.current ]]; then
        USED=$(( $(cat /sys/fs/cgroup/memory.current) / 1024 / 1024 ))
        TOTAL=$(( $(cat /sys/fs/cgroup/memory.max) / 1024 / 1024 ))
    else
        USED=$(free -m | awk '/Mem:/ {print $3}')
        TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    fi
    CPU=$(top -bn1 | grep "CPU:" | head -n1 | awk '{print $2}')
    echo -e "RAM: ${CYAN}$USED MB / $TOTAL MB${NC} | CPU: ${CYAN}$CPU%${NC}"
    echo -e "${CYAN}═══════════════════${NC}"
}

version_manager() {
    clear
    echo -e "${CYAN}═══ VERSION MANAGER ═══${NC}"
    echo "1. Node.js (v18/v20/v21) | 2. PHP (v8.1/v8.2/v8.3) | 0. Back"
    read -p "> " v
    case $v in
        1) echo "1. v18  2. v20  3. v21"; read -p "> " n; 
           [ "$n" == "1" ] && apk add --no-cache nodejs-lts; [ "$n" == "2" ] && apk add --no-cache nodejs-current; [ "$n" == "3" ] && apk add --no-cache nodejs ;;
        2) echo "1. 8.1  2. 8.2  3. 8.3"; read -p "> " p;
           ver="8$p"; apk add --no-cache "php$ver" "php$ver-fpm"; ln -sf "/usr/bin/php$ver" /usr/bin/php ;;
    esac
}

advanced_tools() {
    clear
    echo -e "${CYAN}═══ TOOLS ═══${NC}"
    echo "1. Git  2. Cron  3. Version  4. Backup  5. Perms  0. Back"
    read -p "> " c
    case $c in
        1) read -p "URL: " u; b=${b:-main}; cd /home/container/files && { [ -d ".git" ] && git pull || git clone -b "$b" "$u" .; } ;;
        2) crontab -l; echo "1. Add 2. Clear"; read -p "> " cr; [ "$cr" == "1" ] && { read -p "Cmd: " nc; (crontab -l; echo "$nc") | crontab -; } || crontab -r ;;
        3) version_manager ;;
        4) zip -r "/home/container/.backups/$(date +%s).zip" /home/container/files ;;
        5) chown -R container: . && find . -type d -exec chmod 755 {} + && find . -type f -exec chmod 644 {} + ;;
    esac
}

# --- Service Management ---

start_web() {
    # Generate Nginx Config
    if [[ "$WEB_TYPE" =~ ^(nodejs|react|nextjs)$ ]]; then
        LOC="location / { proxy_pass http://127.0.0.1:3000; proxy_set_header Host \$host; }"
    else
        LOC="location / { try_files \$uri \$uri/ /index.php?\$query_string; }
        location ~ \.php$ { include fastcgi_params; fastcgi_pass 127.0.0.1:9000; fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; }"
    fi
    cat <<EOF > /etc/nginx/http.d/default.conf
server {
    listen $PORT; server_name $DOMAIN; root /home/container/files; index index.php index.html;
    $LOC
}
EOF
    [[ "$WEB_TYPE" =~ ^(php|laravel)$ ]] && php-fpm82 -d daemonize=yes
    nginx &
    [[ "$WEB_TYPE" == "nodejs" ]] && node /home/container/files/index.js &
    [[ "$WEB_TYPE" == "react" ]] && cd /home/container/files && npm run dev -- --host 0.0.0.0 --port 3000 &
    [[ "$WEB_TYPE" == "nextjs" ]] && cd /home/container/files && npm run dev -- -p 3000 &
    echo -e "${GREEN}##################################################${NC}"
    echo -e "${GREEN}#                                                #${NC}"
    echo -e "${GREEN}#               WebHost Online!                  #${NC}"
    echo -e "${GREEN}#                                                #${NC}"
    echo -e "${GREEN}##################################################${NC}"
}

# --- Main UI Loop ---

while true; do
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}      __  __      __   __  __           __            ${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}     / / / /_  __/ /_ / / / /___  _____/ /_           ${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}    / /_/ / / / / __// /_/ / __ \/ ___/ __/           ${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}   / __  / /_/ / /_ / __  / /_/ (__  ) /_             ${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}  /_/ /_/\__,_/\__//_/ /_/\____/____/\__/             ${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}           $T_TITLE                  ${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"

    echo -e "\n${CYAN}>> $T_MENU${NC}"
    echo -e " [1] $T_OPT1  [2] $T_OPT2  [3] $T_OPT3"
    echo -e " [4] $T_OPT4       [5] $T_OPT5      [6] $T_OPT6"
    echo -e " [7] $T_OPT7        [8] $T_OPT8    [9] $T_OPT9"
    echo -e " [10] Tools        [11] Lang       [12] Guide      [0] $T_OPT0"
    
    read -p "$T_SELECT > " cmd
    case $cmd in
        1) echo "1. HTML 2. PHP 3. Node 4. React 5. Next 6. Laravel"; read -p "> " i; cd /home/container/files;
           [ "$i" == "1" ] && cp /home/container/templates/index.html . ; [ "$i" == "2" ] && cp /home/container/templates/index.php . ;
           [ "$i" == "3" ] && { npm init -y; npm i express; cp /home/container/templates/node_index.js index.js; } ;
           [ "$i" == "4" ] && { npm create vite@latest . -- --template react-ts; npm i; } ;
           [ "$i" == "5" ] && { npx create-next-app@latest . --typescript --tailwind --app --use-npm --skip-install; npm i; } ;
           [ "$i" == "6" ] && composer create-project laravel/laravel .;
           auto_detect; sed -i "s/WEB_TYPE=.*/WEB_TYPE=$WEB_TYPE/" "$CONF_FILE" ;;
        2) read -p "Host: " h; read -p "Name: " n; read -p "User: " u; read -p "Pass: " p;
           [ -f ".env" ] && sed -i "s/DB_HOST=.*/DB_HOST=$h/;s/DB_DATABASE=.*/DB_DATABASE=$n/;s/DB_USERNAME=.*/DB_USERNAME=$u/;s/DB_PASSWORD=.*/DB_PASSWORD=$p/" .env ;;
        3) show_info ;;
        4) start_web ;;
        5) pkill nginx; pkill php; pkill node; echo -e "${RED}✘ Offline!${NC}" ;;
        6) pkill nginx; pkill php; pkill node; start_web ;;
        7) pkill -9 -u container ;;
        8) read -p "sh > " c; eval "$c" ;;
        9) clear; echo -e "${CYAN}Guide:${NC} Set Cloudflare SSL to Full/Strict. Use Git Deploy for auto-updates."; sleep 3 ;;
        10) advanced_tools ;;
        11) echo "1. EN 2. ID 3. KR 4. JP"; read -p "> " l; [ "$l" == "1" ] && L=EN; [ "$l" == "2" ] && L=ID; [ "$l" == "3" ] && L=KR; [ "$l" == "4" ] && L=JP;
            sed -i "s/LANG=.*/LANG=$L/" "$CONF_FILE"; CUR_LANG=$L; source "/home/container/bahasa/${CUR_LANG,,}.sh"; clear ;;
        12) echo -e "${CYAN}YuraCloud WebHost Guide${NC}\n[1] Install Framework\n[2] Config DB (.env)\n[3] Start Web\n[10] Git/Cron/Version Tools"; sleep 5 ;;
        0) exit 0 ;;
    esac
done
