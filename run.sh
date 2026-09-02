#!/usr/bin/env bash
# Startet die Seminar-Umgebung und öffnet eine Shell im Container.
# Aufruf aus dem Repo-Verzeichnis:  ./run.sh
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "Es gibt noch keine .env-Datei."
  echo "Bitte einmalig ausführen:  cp .env.example .env"
  echo "und darin die ROS_DOMAIN_ID der eigenen Gruppe eintragen."
  exit 1
fi

# Grafische Programme aus dem Container auf dem Host-Display erlauben.
if command -v xhost >/dev/null 2>&1; then
  xhost +local:docker >/dev/null 2>&1 || true
fi

# Unter WSL die GPU durchreichen, sonst rendert Gazebo auf der CPU. Das Gerät
# gibt es nur dort, unter Linux und macOS bleibt es bei der Standardkonfiguration.
COMPOSE_FILES=(-f docker-compose.yml)
if [ -e /dev/dxg ]; then
  COMPOSE_FILES+=(-f docker-compose.wsl-gpu.yml)
fi

# Bei den noVNC-Images den Desktop-Port nur auf Loopback veröffentlichen,
# siehe docker-compose.vnc.yml. Ohne das wäre der passwortlose Desktop im
# ganzen Netz erreichbar.
VNC_ACTIVE=0
IMAGE_TAG_VALUE=$(sed -n 's/^[[:space:]]*IMAGE_TAG[[:space:]]*=[[:space:]]*//p' .env | tail -1 | tr -d '"'\''' | tr -d '[:space:]')
case "$IMAGE_TAG_VALUE" in
  *vnc*)
    COMPOSE_FILES+=(-f docker-compose.vnc.yml)
    VNC_ACTIVE=1
    ;;
esac

# Container starten, falls er nicht schon läuft.
docker compose "${COMPOSE_FILES[@]}" up -d

echo
echo "Umgebung läuft. Weitere Terminals öffnen mit:"
echo "    docker compose exec ros bash"
if [ "$VNC_ACTIVE" -eq 1 ]; then
  echo
  echo "Desktop im Browser öffnen:"
  echo "    http://localhost:6080/vnc.html"
fi
echo

exec docker compose exec ros bash
