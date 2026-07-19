#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/opt/xray"
SERVICE_FILE="/etc/systemd/system/vless2socks.service"

XRAY_VERSION="v26.7.11"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip"

echo "======================================"
echo "        Xray VLESS Installer"
echo "======================================"
echo

#
# Install dependencies
#
echo "[1/8] Installing dependencies..."

if command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --needed --noconfirm curl unzip nano
elif command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y curl unzip nano
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y curl unzip nano
else
    echo "Unsupported package manager."
    exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo
echo "[2/8] Downloading Xray..."
curl -L "$XRAY_URL" -o "$TMPDIR/xray.zip"


echo "[3/8] Extracting Xray..."
unzip -oq "$TMPDIR/xray.zip" -d "$TMPDIR"


echo "[4/8] Installing files..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo cp -a "$TMPDIR"/. "$INSTALL_DIR"/
sudo chmod +x "$INSTALL_DIR/xray"

echo
echo "======================================"
echo "A config.json is required."
echo
echo "Nano will now open."
echo
echo "Paste your ENTIRE config.json,"
echo "then:"
echo
echo "  Ctrl + O    Save"
echo "  Enter"
echo "  Ctrl + X    Exit"
echo "======================================"
echo

sudo nano "$INSTALL_DIR/config.json"

#
# Verify config exists
#
if [ ! -s "$INSTALL_DIR/config.json" ]; then
    echo
    echo "config.json is empty."
    exit 1
fi

echo
echo "[5/8] Creating systemd service..."

sudo tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=Xray VLESS Client
After=network-online.target
Wants=network-online.target

StartLimitIntervalSec=300
StartLimitBurst=10

[Service]
Type=simple

WorkingDirectory=/opt/xray
ExecStart=/opt/xray/xray run -c /opt/xray/config.json

Restart=always
RestartSec=240

KillSignal=SIGTERM
TimeoutStopSec=15

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/xray

StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo
echo "[6/8] Reloading systemd..."
sudo systemctl daemon-reload

echo "[7/8] Enabling service..."
sudo systemctl enable vless2socks.service

echo "[8/8] Starting service..."
sudo systemctl reset-failed vless2socks.service >/dev/null 2>&1 || true
sudo systemctl restart vless2socks.service

echo
echo "======================================"
echo "Installation complete!"
echo "======================================"
echo

systemctl --no-pager --full status vless2socks.service

echo
echo "Useful commands:"
echo "  systemctl status vless2socks"
echo "  journalctl -fu vless2socks"
echo "  systemctl restart vless2socks"