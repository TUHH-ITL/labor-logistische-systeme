#!/usr/bin/env bash
# Startet die virtuelle Desktop-Sitzung (TigerVNC + noVNC) im Hintergrund und
# übergibt danach an das eigentliche Kommando (per docker-compose "bash").
set -euo pipefail

mkdir -p /home/ubuntu/.vnc
vncserver :1 -localhost yes -SecurityTypes None -geometry 1280x800 -depth 24 \
  >/home/ubuntu/.vnc/vncserver.log 2>&1

# Nur auf localhost binden, sonst wäre der Desktop ohne Passwort im ganzen
# WLAN erreichbar. Zugriff ausschließlich über http://localhost:6080.
websockify --web=/usr/share/novnc 127.0.0.1:6080 localhost:5901 \
  >/home/ubuntu/.vnc/websockify.log 2>&1 &

exec "$@"
