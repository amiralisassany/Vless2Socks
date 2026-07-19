# Vless2Socks

A minimal installer that sets up an Xray VLESS client as a persistent SOCKS5 proxy using `systemd`.

## Installation

```bash

curl -fsSL https://raw.githubusercontent.com/amiralisassany/Vless2Socks/main/install.sh | bash

```

Paste your Xray `config.json` when prompted, save, and you're done.

## Service Management

```bash

systemctl status vless2socks

journalctl -fu vless2socks

systemctl restart vless2socks

```

