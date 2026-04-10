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

# ⏳ Grace period au boot (120s)
UPTIME=$(cut -d. -f1 /proc/uptime)
if [ "$UPTIME" -lt 120 ]; then
    log "Startup grace period → skipping"
    exit 0
fi

# ❌ Pas d'interface → reload driver
if [ -z "$INTERFACE" ]; then
    log "No interface → reload driver"
    modprobe -r wl || true
    sleep 2
    modprobe wl || true
    notify "WiFi driver reloaded"
    exit 0
fi

# 🚫 Pas connecté → ne rien faire (IMPORTANT FIX)
CONNECTED=$(nmcli -t -f ACTIVE,DEVICE dev wifi | grep "^yes" | grep "$INTERFACE")

if [ -z "$CONNECTED" ]; then
    log "Not connected → skipping (user action)"
    exit 0
fi

# 🌐 Test connectivité brute
ping -c 2 -W 2 $PING_IP > /dev/null

if [ $? -ne 0 ]; then

    IP=$(ip -4 addr show $INTERFACE | grep inet)

    # 📡 DHCP KO
    if [ -z "$IP" ]; then
        log "No IP → DHCP issue"
        dhclient $INTERFACE || true
        notify "DHCP renew"
        exit 0
    fi

    # 🌍 DNS KO
    ping -c 2 $DNS_TEST > /dev/null

    if [ $? -ne 0 ]; then
        log "DNS issue → restarting NetworkManager"
        systemctl restart NetworkManager
        notify "DNS fix"
        exit 0
    fi

    # ⚠️ Wi-Fi bloqué
    log "WiFi stuck → reset"
    nmcli radio wifi off
    sleep 2
    nmcli radio wifi on
    notify "WiFi reset"

else
    echo "$(date) OK" >> $STATE
fi
