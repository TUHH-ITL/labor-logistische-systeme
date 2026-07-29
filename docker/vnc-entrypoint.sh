#!/usr/bin/env bash
# Startet die virtuelle Desktop-Sitzung (TigerVNC + noVNC) im Hintergrund und
# übergibt danach an das eigentliche Kommando (per docker-compose "bash").
set -euo pipefail

mkdir -p /home/ubuntu/.vnc
vncserver :1 -localhost yes -SecurityTypes None -geometry 1280x800 -depth 24 \
  >/home/ubuntu/.vnc/vncserver.log 2>&1

# websockify muss auf allen Interfaces lauschen, sonst leitet Docker
# published Ports (-p, und teils auch network_mode: host unter Docker
# Desktop) ins Leere: Docker adressiert die Container-IP, nicht dessen
# Loopback. Der eigentliche VNC-Server bleibt über "-localhost yes" auf
# Container-Loopback beschränkt und ist nur über diesen Proxy erreichbar.
websockify --web=/usr/share/novnc 0.0.0.0:6080 localhost:5901 \
  >/home/ubuntu/.vnc/websockify.log 2>&1 &

exec "$@"
