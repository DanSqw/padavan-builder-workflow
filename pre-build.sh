#!/bin/bash
set -e

echo "=== [PRE-BUILD] Starting Padavan custom modifications ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PADAVAN_ROOT="${SCRIPT_DIR}/padavan-ng"
TRUNK="${PADAVAN_ROOT}/trunk"

if [ ! -d "${TRUNK}" ]; then
    echo "ERROR: ${TRUNK} not found!"
    exit 1
fi

echo "1. Configuring NFQWS v72.13 and Zapret ALT13..."
NFQWS_DIR="${TRUNK}/user/nfqws"
mkdir -p "${NFQWS_DIR}/share/zapret/fake"

# Copy binary and scripts
cp -f "${SCRIPT_DIR}/files/bin/nfqws" "${NFQWS_DIR}/nfqws"
chmod +x "${NFQWS_DIR}/nfqws"
cp -f "${SCRIPT_DIR}/files/zapret.sh" "${NFQWS_DIR}/zapret.sh"
chmod +x "${NFQWS_DIR}/zapret.sh"

# Copy base share files (strategies 0-8, config, lists)
cp -f "${SCRIPT_DIR}/files/base_share/"* "${NFQWS_DIR}/share/zapret/"

# Copy ALT13 strategy and clean post_script
cp -f "${SCRIPT_DIR}/files/strategy9" "${NFQWS_DIR}/share/zapret/strategy9"
cp -f "${SCRIPT_DIR}/files/strategy9" "${NFQWS_DIR}/share/zapret/strategy"
cp -f "${SCRIPT_DIR}/files/post_script.sh" "${NFQWS_DIR}/share/zapret/post_script.sh"

# Copy fake payloads
cp -f "${SCRIPT_DIR}/files/fake/"* "${NFQWS_DIR}/share/zapret/fake/"

# Copy domain lists and ipsets
cp -f "${SCRIPT_DIR}/files/lists/"* "${NFQWS_DIR}/share/zapret/"

# Replace trunk/user/nfqws/Makefile to install prebuilt v72.13 and assets
cat > "${NFQWS_DIR}/Makefile" << 'EOF'
THISDIR = $(shell pwd)

all:
	chmod +x $(THISDIR)/nfqws $(THISDIR)/zapret.sh

clean:

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/nfqws /usr/bin/nfqws
	$(ROMFSINST) -p +x $(THISDIR)/zapret.sh /usr/bin/zapret.sh
	$(ROMFSINST) -d $(THISDIR)/share/zapret /usr/share/zapret
EOF

echo "2. Installing Adblock updater script..."
SCRIPTS_DIR="${TRUNK}/user/scripts"
cp -f "${SCRIPT_DIR}/files/update_adblock.sh" "${SCRIPTS_DIR}/update_adblock.sh"
chmod +x "${SCRIPTS_DIR}/update_adblock.sh"

# Add update_adblock.sh to trunk/user/scripts/Makefile if not already present
if ! grep -q "update_adblock.sh" "${SCRIPTS_DIR}/Makefile"; then
    sed -i '/romfs:/a \\t$(ROMFSINST) -p +x $(THISDIR)/update_adblock.sh /usr/bin/update_adblock.sh' "${SCRIPTS_DIR}/Makefile"
fi

echo "3. Updating NVRAM defaults (enable Zapret with strategy9 by default)..."
DEFAULTS_C="${TRUNK}/user/shared/defaults.c"
if [ -f "${DEFAULTS_C}" ]; then
    sed -i 's/{ "zapret_enable", "0" }/{ "zapret_enable", "1" }/' "${DEFAULTS_C}"
    if ! grep -q "zapret_strategy" "${DEFAULTS_C}"; then
        sed -i '/"zapret_enable"/a \\t{ "zapret_strategy", "9" },' "${DEFAULTS_C}"
    fi
fi

echo "4. Updating reset_ss.sh template (dnsmasq adblock & post_wan)..."
RESET_SS="${SCRIPTS_DIR}/reset_ss.sh"
if [ -f "${RESET_SS}" ]; then
    # Add conf-dir=/tmp/dnsmasq.d to dnsmasq.conf template
    if ! grep -q "conf-dir=/tmp/dnsmasq.d" "${RESET_SS}"; then
        sed -i 's|### add your options here|### add your options here\nconf-dir=/tmp/dnsmasq.d|' "${RESET_SS}"
    fi
    # Add mkdir -p /tmp/dnsmasq.d to start_script.sh template
    if ! grep -q "/tmp/dnsmasq.d" "${RESET_SS}"; then
        sed -i '/### Custom user script for tuning router before start/a mkdir -p /tmp/dnsmasq.d' "${RESET_SS}"
    fi
    # Add update_adblock.sh to post_wan_script.sh template
    if ! grep -q "update_adblock.sh" "${RESET_SS}"; then
        sed -i 's|if \[ "\$1" = "up" \] ; then|if [ "$1" = "up" ] ; then\n\t/usr/bin/update_adblock.sh \&|' "${RESET_SS}"
    fi
fi

echo "=== [PRE-BUILD] Custom modifications successfully applied! ==="
