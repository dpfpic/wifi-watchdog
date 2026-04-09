#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "❌ Lance en root (sudo)"
  exit 1
fi

set -e

echo "🚀 WiFi Watchdog - Installation universelle"

# Détection distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Impossible de détecter la distribution"
    exit 1
fi

echo "📦 Distribution détectée : $DISTRO"

install_packages() {
    case "$DISTRO" in
        ubuntu|debian|linuxmint)
            apt update
            apt install -y libnotify-bin iw wireless-tools network-manager dhcpcd5
            ;;
        fedora)
            dnf install -y libnotify iw NetworkManager dhclient
            ;;
        arch|manjaro)
            pacman -Sy --noconfirm libnotify iw networkmanager dhclient
            ;;
        *)
            echo "⚠️ Distribution non officiellement supportée, tentative générique..."
            ;;
    esac
}

install_packages

# Script watchdog
cat << 'EOF' > /usr/local/bin/wifi-check
#!/bin/bash

LOG="/var/log/wifi-watchdog.log"
STATE="/var/log/wifi-state.log"
PING_IP="8.8.8.8"
DNS_TEST="google.com"

log() {
    echo "$(date) - $1" >> $LOG
}

notify() {
    command -v notify-send &> /dev/null && notify-send "WiFi Watchdog" "$1"
}

INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)

if [ -z "$INTERFACE" ]; then
    log "No interface → reload driver"
    modprobe -r wl || true
    sleep 2
    modprobe wl || true
    notify "WiFi driver reloaded"
    exit 0
fi

ping -c 2 -W 2 $PING_IP > /dev/null

if [ $? -ne 0 ]; then

    IP=$(ip -4 addr show $INTERFACE | grep inet)

    if [ -z "$IP" ]; then
        log "No IP → DHCP issue"
        dhclient $INTERFACE || true
        notify "DHCP renew"
        exit 0
    fi

    ping -c 2 $DNS_TEST > /dev/null

    if [ $? -ne 0 ]; then
        log "DNS issue → restarting NetworkManager"
        systemctl restart NetworkManager
        notify "DNS fix"
        exit 0
    fi

    log "WiFi stuck → reset"
    nmcli radio wifi off
    sleep 2
    nmcli radio wifi on
    notify "WiFi reset"

else
    echo "$(date) OK" >> $STATE
fi
EOF

chmod +x /usr/local/bin/wifi-check

# Logs
touch /var/log/wifi-watchdog.log
touch /var/log/wifi-state.log
chmod 666 /var/log/wifi-watchdog.log
chmod 666 /var/log/wifi-state.log

# Systemd service
cat << 'EOF' > /etc/systemd/system/wifi-check.service
[Unit]
Description=WiFi Watchdog Intelligent

[Service]
Type=oneshot
ExecStart=/usr/local/bin/wifi-check
EOF

# Timer
cat << 'EOF' > /etc/systemd/system/wifi-check.timer
[Unit]
Description=WiFi Watchdog Timer

[Timer]
OnBootSec=30
OnUnitActiveSec=30
AccuracySec=5

[Install]
WantedBy=timers.target
EOF

# Activation
systemctl daemon-reload
systemctl enable wifi-check.timer
systemctl start wifi-check.timer

echo "✅ Installation terminée"
echo "👉 Vérification : systemctl list-timers | grep wifi"
