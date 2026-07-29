# Troubleshooting

Wenn ein Problem hier nicht steht, meldet es bitte als Issue im Repository.
Das Dokument lebt davon.

---

## permission denied while trying to connect to the Docker daemon socket

Der Benutzer ist nicht in der Docker-Gruppe oder war es beim Anmelden noch
nicht.

```bash
sudo usermod -aG docker $USER
```

Danach vollständig ab- und wieder anmelden. Ein neues Terminal genügt nicht.

---

## Grafische Programme starten nicht

Fehlermeldungen wie `cannot open display`, `qt.qpa.xcb: could not connect to
display` oder ein sofortiger Absturz von RViz.

**Unter Linux**, auf dem Host ausführen.

```bash
xhost +local:docker
echo $DISPLAY      # muss etwas wie :0 oder :1 ausgeben
```

Ist `$DISPLAY` leer, läuft eventuell eine Wayland-Sitzung ohne XWayland.
Dann bei der Anmeldung "Ubuntu on Xorg" wählen.

**OpenGL-Fehler**, etwa `Could not initialize GLX` oder ein schwarzes
RViz-Fenster. In der `.env` setzen.

```
LIBGL_ALWAYS_SOFTWARE=1
```

Danach `docker compose down && ./run.sh`. Läuft langsamer, aber stabil.

**Unter Windows** WSL aktualisieren.

```powershell
wsl --update
wsl --shutdown
```

---

## ros2 topic list zeigt nichts, obwohl eine Node läuft

Fast immer eine von drei Ursachen.

1. **Zwei getrennte Container.** Prüfen mit `docker ps`. Es darf nur ein
   `seminar-ros` laufen. Weitere Terminals immer mit
   `docker compose exec ros bash` öffnen, nie mit `docker run`.
2. **Unterschiedliche ROS_DOMAIN_ID.** Im Container prüfen mit
   `echo $ROS_DOMAIN_ID`. Muss in allen Terminals gleich sein.
3. **Overlay nicht gesourced.** `source ~/ws/install/setup.bash` ausführen.

---

## Ihr seht die Topics einer anderen Gruppe

Zwei Gruppen nutzen dieselbe `ROS_DOMAIN_ID`. Das ist im Labor gefährlich,
weil Fahrbefehle beim falschen Roboter landen können. Zuordnung in der `.env`
korrigieren und Container neu starten.

---

## Der TurtleBot wird nicht gefunden

Zuerst die Grundlagen prüfen.

```bash
ping <ip-des-roboters>          # erreichbar?
echo $ROS_DOMAIN_ID             # gleich wie auf dem Roboter?
ros2 daemon stop && ros2 daemon start
ros2 topic list
```

Bleibt die Liste leer, obwohl der Ping funktioniert, liegt es meist am
Netzwerkmodus.

**Unter Linux nativ** muss `network_mode: host` greifen. Prüfen mit.

```bash
docker inspect seminar-ros --format '{{.HostConfig.NetworkMode}}'
```

Es muss `host` ausgegeben werden.

**Unter Docker Desktop (Windows und macOS)** läuft der Container in einer
virtuellen Maschine. Die DDS-Erkennung über das WLAN funktioniert dort nicht
verlässlich, und daran lässt sich von eurer Seite nichts reparieren. Für die
Robotertermine bitte einen Leih-Laptop mit Linux nutzen oder per NoMachine auf
einem Laborrechner arbeiten.

**Eduroam und Gastnetze** blockieren häufig die Kommunikation zwischen
Endgeräten. Nutzt im Labor ausschließlich das dafür vorgesehene WLAN.

---

## colcon build schlägt nach einem Wechsel des Rechners fehl

Build-Artefakte aus einer anderen Umgebung. Zurücksetzen mit.

```bash
docker compose down -v
./run.sh
cd ~/ws && colcon build --symlink-install
```

Der Quellcode in `ws/src` bleibt dabei unberührt.

---

## Änderungen an einer Python-Datei wirken nicht

Wurde ohne `--symlink-install` gebaut, liegt im `install`-Verzeichnis eine
Kopie statt eines Verweises. Einmal sauber neu bauen.

```bash
cd ~/ws
rm -rf build install log
colcon build --symlink-install
source install/setup.bash
```

---

## Es lief gestern und heute nicht mehr

Sehr wahrscheinlich wurde etwas interaktiv im Container installiert, siehe
`docs/04-erste-schritte.md`, Abschnitt "Der wichtigste Stolperstein".
Abhängigkeiten gehören in `package.xml` oder `requirements.txt`.

---

## Kein Speicherplatz mehr

Docker-Images und alte Container belegen viel Platz.

```bash
docker system df       # Übersicht
docker system prune -a # löscht alle nicht genutzten Images
```

Achtung, danach muss das Seminar-Image erneut geladen werden.

---

## colcon build bricht mit "Killed" ab

Zu wenig Arbeitsspeicher, typisch unter Docker Desktop. Entweder die
Speicherzuweisung in den Docker-Desktop-Einstellungen erhöhen oder die
Parallelität begrenzen.

```bash
MAKEFLAGS="-j2" colcon build --symlink-install --parallel-workers 2
```
