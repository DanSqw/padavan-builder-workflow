#!/bin/sh
# Adblock and telemetry blocklist updater for Padavan dnsmasq

TARGET_DIR="/tmp/dnsmasq.d"
TARGET_FILE="${TARGET_DIR}/adblock.conf"
TMP_FILE="/tmp/adblock.conf.tmp"

XIAOMI="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/native.xiaomi.txt"
SAMSUNG="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/native.samsung.txt"
WINOFFICE="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/native.winoffice.txt"
OISD_SMALL="https://raw.githubusercontent.com/sjhgvr/oisd/main/dnsmasq2_small.txt"

mkdir -p "$TARGET_DIR"
rm -f "$TMP_FILE"

logger -t "Adblock" "Updating adblock lists..."

for url in "$XIAOMI" "$SAMSUNG" "$WINOFFICE" "$OISD_SMALL"; do
    wget -qO - "$url" >> "$TMP_FILE" 2>/dev/null
done

if [ -s "$TMP_FILE" ]; then
    sort -u "$TMP_FILE" > "$TARGET_FILE"
    rm -f "$TMP_FILE"
    COUNT=$(wc -l < "$TARGET_FILE")
    logger -t "Adblock" "Successfully loaded $COUNT adblock rules."
    
    # Reload dnsmasq if running
    PID=$(pidof dnsmasq)
    if [ -n "$PID" ]; then
        kill -HUP $PID
    fi
else
    logger -t "Adblock" "Failed to download adblock lists."
    rm -f "$TMP_FILE"
fi
